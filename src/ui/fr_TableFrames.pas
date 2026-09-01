unit fr_TableFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ControlList,
  System.Types, System.Skia, System.Actions, Vcl.ActnList, PngSpeedButton, Vcl.Skia,

  u_Types, u_CardStacks, u_Tables, u_TableDisplays, u_GameDisplays,
  u_Layouts, u_CardResources, u_Snapshots, u_MoveLists, u_AnimationTypes,
  fr_ContentFrames, u_SnapshotManagers;

type
  TDragInfo = record
    Active: Boolean;
    SourceStack: TStackId;
    CardIndex: Integer;
    CardCount: Integer;
    Cards: TArray<TCard>;
    GrabOffset: TPointF;      // mouse-down position relative to card top-left
  end;

  TTableAction = (taHint, taUndo, taRedo, taComplete, taRestart, taSnapshot);
  TTableActions = set of TTableAction;
  TTableActionEvent = procedure(Sender: TObject; aTableAction: TTableAction) of object;
  TCardClickEvent = procedure(Sender: TObject; aStackId: TStackId; aCardIndex: Integer) of object;
  TMoveRequestedEvent = procedure(Sender: TObject; aRequestedMove: TMove; aRequestedAnimate: Boolean) of object;

  TTableFrame = class(TContentFrame)
    skTable: TSkAnimatedPaintBox;
    TableActions: TActionList;
    actUndo: TAction;
    actRedo: TAction;
    actHint: TAction;
    actRestart: TAction;
    actAutoComplete: TAction;
    Toolbar: TPanel;
    btnHint: TSpeedButton;
    btnUndo: TSpeedButton;
    btnRedo: TSpeedButton;
    actSnapshot: TAction;
    btnSnapshot: TSpeedButton;
    btnRestart: TSpeedButton;
    btnComplete: TSpeedButton;
    lblHScore: TLabel;
    procedure skTableAnimationDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AProgress: Double; const AOpacity: Single);
    procedure skTableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure skTableMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure skTableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure skTableResize(Sender: TObject);
    procedure actUndoExecute(Sender: TObject);
    procedure actRedoExecute(Sender: TObject);
    procedure actHintExecute(Sender: TObject);
    procedure actRestartExecute(Sender: TObject);
    procedure actAutoCompleteExecute(Sender: TObject);
    procedure actSnapshotExecute(Sender: TObject);

  private
    fDisplay: TGameDisplay;
    fLayout: TLayout;
    fCardResources: TCardResources;
    fInitialState: TSnapshot;
    fPostAnimationState: TSnapshot; // created/freed as needed

    // this is what gets displayed
    fTable: TTable;

    // mouse handling
    fMouseIsDown: Boolean;
    fMouseDownPos: TPoint;
    fDragInfo: TDragInfo;
    fPreviewMode: Boolean;
    fOnMoveRequested: TMoveRequestedEvent;
    fOnTableAction: TTableActionEvent;
    fOnCardClick: TCardClickEvent;

    procedure HandleAnimationComplete(Sender: TObject; const Animation: IAnimation);
    procedure SetPreviewMode(const Value: Boolean);

    procedure SetValidActions(const Value: TTableActions);

    procedure DoRequestMove(aMove: TMove; aAnimate: Boolean = True);
    procedure DoCardClick(aStackId: TStackId; aCardIndex: Integer);
    procedure DoAction(aAction: TTableAction);
  public
    procedure InitContent; override;
    procedure DoneContent; override;

    // 9/1 refactor
    procedure ShowState(aSnapshot: TSnapshot); // standard update method
    procedure AnimateAndShowMove(aBeginState, aEndState: TSnapshot; aMove: TMove);
    procedure ShowHintMove(aMove: TMove);

    property ValidActions: TTableActions write SetValidActions;

    property OnTableAction: TTableActionEvent read fOnTableAction write fOnTableAction;
    property OnMoveRequested: TMoveRequestedEvent read fOnMoveRequested write fOnMoveRequested;
    property OnCardClick: TCardClickEvent read fOnCardClick write fOnCardClick;

    property PreviewMode: Boolean read fPreviewMode write SetPreviewMode;
  end;


implementation

{$R *.dfm}

uses Vcl.Themes, System.Math,

  u_Dealers, u_RenderUtils, u_HitTesters, u_MoveHelpers, u_Animations,
  u_HintAnimations, u_DisplayConsts, u_FlybackAnimations, u_MoveAnimations,
  u_MoveGenerators, u_MoveValidators, u_Utils, u_Heuristics;

function InDeadZone(MouseDown, MouseUp: TPoint): Boolean;
const
  zone = 3;
begin
  Result := (Abs(MouseDown.X - MouseUp.X) < zone) and
    (Abs(MouseDown.Y - MouseUp.Y) < zone);
end;

{ TTableFrame }

procedure TTableFrame.InitContent;  // edit
begin
  // UI setup
  skTable.BackgroundColor := COLOR_TABLE_BK;

  fDisplay := TGameDisplay.Create;
  fDisplay.OnAnimateComplete := HandleAnimationComplete;
  fCardResources := TCardResources.Create;
  TRenderUtils.SetResources(fCardResources);
  fTable := TTable.Create;
  fInitialState := TSnapshot.Create;

  fDragInfo := Default(TDragInfo);
  fMouseIsDown := False;

  SetPreviewMode(True);

end;

procedure TTableFrame.DoneContent; // edit
begin
  fDisplay.Free;
  fCardResources.Free;
  fTable.Free;
  fInitialState.Free;

  inherited;
end;

procedure TTableFrame.actSnapshotExecute(Sender: TObject);  // remove. code goes in main
begin
  DoAction(taSnapshot);

//  var dlg := d_SaveSnapshotDlg.TSaveSnapshotDlg.Create(Application);
//  try
//    if dlg.Execute(SnapshotLibrary) then
//    begin
//      if dlg.rbInitialState.Checked then
//      begin
//        SnapshotLibrary.Add(dlg.edtName.Text, fInitialState);
//      end
//      else
//      begin
//        var snapshot := TSnapshot.Create;
//        try
//          snapshot.Capture(fGame.Table);
//          SnapshotLibrary.Add(dlg.edtName.Text, snapshot);
//        finally
//          snapshot.Free;
//        end;
//      end;
//    end;
//  finally
//    dlg.Free;
//  end;
end;

procedure TTableFrame.actUndoExecute(Sender: TObject); // ok
begin
  DoAction(taUndo);
end;

procedure TTableFrame.AnimateAndShowMove(aBeginState, aEndState: TSnapshot; aMove: TMove); // new
begin
  // this can be called before the previous animation has completed
  fDisplay.Animation := nil;

  // the animated cards can come from the post animation state
  aEndState.Restore(fTable);
  var cards: TArray<TCard>;
  fTable.Stacks[aMove.Source].GetLastCards(cards, aMove.Count, False);

  // save this state so we can switch to it after the animation completes
  fPostAnimationState.Free;
  fPostAnimationState := TSnapshot.Create;
  fPostAnimationState.Capture(fTable);

  // set up the animation state
  aBeginState.Restore(fTable);
  fDisplay.UpdateTable(fTable);

  // create move anim
  if Length(cards) > 0 then
  begin
    var startPos := fLayout.Origins[aMove.Source];
    if StackIdToCategory(aMove.Source) = scTableau then
    begin
      var offset := fLayout.TableauCardY(fTable.Stacks[aMove.Source].Count);
      startPos.Offset(0, offset);
    end;

    var endPos: TPointF := fLayout.Origins[aMove.Target];
    if StackIdToCategory(aMove.Target) = scTableau then
    begin
      var offset := fLayout.TableauCardY(fTable.Stacks[aMove.Target].Count);
      endPos.Offset(0, offset);
    end;

    var anim := CreateMoveAnimation(cards, startPos, endPos, TSizeF.Create(fLayout.CardWidth, fLayout.CardHeight));
    fDisplay.Animation := anim;
    anim.Start;
  end;

end;

procedure TTableFrame.ShowHintMove(aMove: TMove); // new
begin
  var anim := CreateHintAnimation(fTable, aMove, fLayout);
  fDisplay.Animation := anim;
  anim.Start;
end;


procedure TTableFrame.actAutoCompleteExecute(Sender: TObject); // ok
begin
  DoAction(taComplete);
end;

procedure TTableFrame.actHintExecute(Sender: TObject); // ok/move code to main
begin
  DoAction(taHint);
end;

procedure TTableFrame.actRedoExecute(Sender: TObject); // ok
begin
  DoAction(taRedo);
end;

procedure TTableFrame.actRestartExecute(Sender: TObject); // ok
begin
  DoAction(taRestart);
end;

procedure TTableFrame.HandleAnimationComplete(Sender: TObject; const Animation: IAnimation);  // edit
begin
  var todoList := Animation.GetCompletionActions;
  for var todoItem := Low(TCompletionAction) to High(TCompletionAction) do
  begin
    if todoItem in todoList then
    begin
      case todoItem of
        caUpdateDisplay:
          begin
            // 9/1 refactor:
            // this just needs to put the post-animation state into the table
            if Assigned(fPostAnimationState) then
            begin
              fPostAnimationState.Restore(fTable);
              FreeAndNil(fPostAnimationState);
            end;

            fDisplay.UpdateTable(fTable);
          end;

      end;
    end;
  end;
end;

procedure TTableFrame.ShowState(aSnapshot: TSnapshot);
begin
  aSnapshot.Restore(fTable);
  fDisplay.UpdateTable(fTable);
end;

procedure TTableFrame.SetPreviewMode(const Value: Boolean); // ok
begin
  if Value <> fPreviewMode then
  begin
    fPreviewMode := Value;
    fDisplay.PreviewMode := fPreviewMode;
    if fPreviewMode then
    begin
      for var a in TableActions do
        a.Enabled := False;
    end;
  end;
end;

procedure TTableFrame.SetValidActions(const Value: TTableActions); // keep
begin
  if not fPreviewMode then
  begin
    actUndo.Enabled := taUndo in Value;
    actRedo.Enabled := taRedo in Value;
    actHint.Enabled := taHint in Value;
    actRestart.Enabled := taRestart in Value;
    actSnapshot.Enabled := taSnapshot in Value;
  end;
end;

procedure TTableFrame.skTableAnimationDraw(ASender: TObject; const ACanvas: ISkCanvas;
  const ADest: TRectF; const AProgress: Double; const AOpacity: Single); // ok
begin
  if Assigned(fDisplay) then
    fDisplay.Draw(aCanvas, fLayout);
end;

procedure TTableFrame.DoAction(aAction: TTableAction); // ok
begin
  if Assigned(fOnTableAction) then
    fOnTableAction(Self, aAction);
end;

procedure TTableFrame.DoCardClick(aStackId: TStackId; aCardIndex: Integer);
begin
  if Assigned(fOnCardClick) then
    fOnCardClick(Self, aStackId, aCardIndex);
end;

procedure TTableFrame.DoRequestMove(aMove: TMove; aAnimate: Boolean);
begin
  if Assigned(fOnMoveRequested) then
    fOnMoveRequested(Self, aMove, aAnimate);
end;

procedure TTableFrame.skTableMouseDown(Sender: TObject; Button: TMouseButton;   // ok
  Shift: TShiftState; X, Y: Integer);
begin
  if fPreviewMode then
    Exit;

  fMouseDownPos := Point(X, Y);
  fMouseIsDown := True;
end;

procedure TTableFrame.skTableMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); // edit
begin
  if not fMouseIsDown then
    Exit;

  var mousePos := point(X, Y);
  if (not fDragInfo.Active) and InDeadZone(fMouseDownPos, mousePos) then
    Exit;

  fDisplay.ClearDropTarget;

  if not fDragInfo.Active then
  begin

    // validate we're trying to pick up a face up card
    var hitInfo := THitTester.GetHitInfo(fLayout, fTable, fMouseDownPos);
    if (not hitInfo.Valid) or (not hitInfo.IsFaceUp) then
    begin
      // in this case you clicked the mouse on an invalid spot, then you dragged it.
      // we can erase this operation's future. nothing matters until you release the mouse
      fMouseIsDown := False;
      Exit;
    end;

    // assemble the drag operation
    fDragInfo.Active := True;
    fDragInfo.SourceStack := hitInfo.StackId;
    fDragInfo.CardIndex := hitInfo.CardIndex;

    // compute grab offset (mouse position relative to card top-left)
    var cardOrigin := fLayout.Origins[hitInfo.StackId];
    if hitInfo.StackId in ALL_TABLEAUS then
      cardOrigin.Offset(0, fLayout.TableauCardY(hitInfo.CardIndex))
    else if hitInfo.StackId = siWaste then
    begin
      var visIndex := Min(3, fTable.Waste.Count) - 1;
      cardOrigin.Offset(fLayout.WasteCardX(visIndex), 0);
    end;
    fDragInfo.GrabOffset := PointF(fMouseDownPos.X - cardOrigin.X,
      fMouseDownPos.Y - cardOrigin.Y);

    // build list of drag cards, remove from local table
    fDragInfo.CardCount := fTable.Stacks[hitInfo.StackId].Count - hitInfo.CardIndex;
    fTable.Stacks[hitInfo.StackId].GetLastCards(fDragInfo.Cards, fDragInfo.CardCount, True);
    fTable.Stacks[hitInfo.StackId].FaceUpCount := fTable.Stacks[hitInfo.StackId].FaceUpCount - fDragInfo.CardCount;

    // send local table to display
    fDisplay.UpdateTable(fTable);

    // fall through ...
  end;

  if fDragInfo.Active then
  begin
    // update the display
    var drawPos := PointF(mousePos.X - fDragInfo.GrabOffset.X, mousePos.Y - fDragInfo.GrabOffset.Y);
    fDisplay.SetDragOverlay(fDragInfo.Cards, fDragInfo.SourceStack, drawPos);

    // check drop target
    var hitInfo := THitTester.GetHitInfo(fLayout, fTable, mousePos);
    if hitInfo.Valid then
    begin
      var m := NewMove(fDragInfo.SourceStack, hitInfo.StackId, fDragInfo.CardCount);
      if TMoveValidator.IsValidMove(m, fTable) then
      begin
        var dropPoint := fLayout.Origins[m.Target];
        case StackIdToCategory(m.Target) of
          scFoundation: ;
          scTableau:
            begin
              var spacing := fLayout.StackOffset * fTable.Stacks[m.Target].Count;
              dropPoint.Offset(0, spacing);
            end;
        end;

        fDisplay.SetDropTarget(fDragInfo.Cards, dropPoint);
      end;
    end

  end;

end;

procedure TTableFrame.skTableMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer); // edit
begin
  fDisplay.ClearDropTarget;
  fDisplay.ClearDragOverlay;

  // if an invalid drag operation was attempted, we're done
  if not fMouseIsDown then
    Exit;

  var mousePos := point(X, Y);

  if fDragInfo.Active then
  begin
    fDragInfo.Active := False;

    var hitInfo := THitTester.GetHitInfo(fLayout, fTable, mousePos);
    if hitInfo.Valid then
    begin
      var m := NewMove(fDragInfo.SourceStack, hitInfo.StackId, fDragInfo.CardCount);
      if TMoveValidator.IsValidMove(m, fTable) then
        DoRequestMove(m, True);
    end
    else
    begin
      // show flyback animation
      var dropPos := PointF(mousePos.X - fDragInfo.GrabOffset.X, mousePos.Y - fDragInfo.GrabOffset.Y);
      var homePos := PointF(fMouseDownPos.X - fDragInfo.GrabOffset.X, fMouseDownPos.Y - fDragInfo.GrabOffset.Y);
      var anim := CreateFlybackAnimation(fDragInfo.Cards, dropPos, homePos,
        TSizeF.Create(fLayout.CardWidth, fLayout.CardHeight));
      fDisplay.Animation := anim;
      anim.Start;
    end;

  end
  else if InDeadZone(fMouseDownPos, mousePos) then
  begin
    // this is a click ... does it matter?
    var hitInfo := THitTester.GetHitInfo(fLayout, fTable, mousePos);
    if hitInfo.Valid then
    begin
      var autoMove := Default(TMove);
      DoCardClick(hitInfo.StackId, hitInfo.CardIndex);
    end;

  end;

  fMouseIsDown := False;
end;

procedure TTableFrame.skTableResize(Sender: TObject); // odious but ok
begin
  fLayout.SetSize(skTable.ClientWidth, skTable.ClientHeight);
end;


end.
