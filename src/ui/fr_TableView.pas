unit fr_TableView;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ControlList,
  System.Types, System.Skia, System.Actions, Vcl.ActnList, PngSpeedButton, Vcl.Skia,

  u_Types, u_CardStacks, u_Tables, u_Games, u_TableDisplays, u_GameDisplays,
  u_Layouts, u_CardResources, u_Snapshots, u_MoveLists, u_AnimationTypes,
  u_SnapshotManagers;

type
  TDragInfo = record
    Active: Boolean;
    SourceStack: TStackId;
    CardIndex: Integer;
    CardCount: Integer;
    Cards: TArray<TCard>;
    GrabOffset: TPointF;      // mouse-down position relative to card top-left
  end;

  TTableView = class(TFrame)
    skTable: TSkAnimatedPaintBox;
    GameActions: TActionList;
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
    fGame: TKlondikeGame;
    fDisplay: TGameDisplay;
    fLayout: TLayout;
    fCardResources: TCardResources;
    fInitialState: TSnapshot;

    // transient
    fLocalTable: TTable;

    // mouse handling
    fMouseIsDown: Boolean;
    fMouseDownPos: TPoint;
    fDragInfo: TDragInfo;
    fPreviewMode: Boolean;

    procedure UpdateControls;
    procedure HandleAnimationComplete(Sender: TObject; const Animation: IAnimation);
    procedure DoExecuteMove(aMove: TMove; aImmediate: Boolean = False);
    procedure SetPreviewMode(const Value: Boolean);
    procedure UpdateHValue;
    procedure HandleStateChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; ASnapshotManager: TSnapshotManager); reintroduce; overload;
    destructor Destroy; override;

    procedure SetInitialState(aSnapshot: TSnapshot);
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

{ TTableView }

constructor TTableView.Create(AOwner: TComponent; ASnapshotManager: TSnapshotManager);
begin
  inherited Create(AOwner);

  // lifetime assets
  fGame := TKlondikeGame.Create(ASnapshotManager);
  fGame.OnStateChanged := HandleStateChanged;
  fDisplay := TGameDisplay.Create;
  fDisplay.OnAnimateComplete := HandleAnimationComplete;
  fCardResources := TCardResources.Create;
  TRenderUtils.SetResources(fCardResources);
  fLocalTable := TTable.Create;
  fInitialState := TSnapshot.Create;

  fDragInfo := Default(TDragInfo);
  fMouseIsDown := False;

  SetPreviewMode(True);

  // UI setup
  skTable.BackgroundColor := COLOR_TABLE_BK;
  UpdateControls;
end;

destructor TTableView.Destroy;
begin
  fDisplay.Free;
  fGame.Free;
  fCardResources.Free;
  fLocalTable.Free;
  fInitialState.Free;

  inherited;
end;

procedure TTableView.UpdateControls;
begin
  // game actions
  actUndo.Enabled := (not PreviewMode) and fGame.CanUndo;
  actRedo.Enabled := (not PreviewMode) and fGame.CanRedo;
  actHint.Enabled := (not PreviewMode);
  actRestart.Enabled := (not PreviewMode);
  actAutoComplete.Enabled := (not PreviewMode) and fGame.CanAutoComplete;

  actSnapshot.Enabled := (not PreviewMode);
end;

procedure TTableView.UpdateHValue;
begin
  var hScore := THeuristic.Score(fGame.Table);
  lblHScore.Caption := hScore.ToString;
end;

procedure TTableView.actSnapshotExecute(Sender: TObject);
begin

  //
end;

procedure TTableView.actUndoExecute(Sender: TObject);
begin
  fGame.Undo;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TTableView.actAutoCompleteExecute(Sender: TObject);
begin
//

end;

procedure TTableView.actHintExecute(Sender: TObject);
begin
  var hintMove: TMove;
  if fGame.GetNextHint(hintMove) then
  begin
    var anim := CreateHintAnimation(fGame.Table, hintMove, fLayout);
    fDisplay.Animation := anim;
    anim.Start;
  end;
end;

procedure TTableView.actRedoExecute(Sender: TObject);
begin
  fGame.Redo;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TTableView.actRestartExecute(Sender: TObject);
begin
  fGame.Restart;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TTableView.HandleAnimationComplete(Sender: TObject;
  const Animation: IAnimation);
begin
  var todoList := Animation.GetCompletionActions;
  for var todoItem := Low(TCompletionAction) to High(TCompletionAction) do
  begin
    if todoItem in todoList then
    begin
      case todoItem of
        caUpdateDisplay:
          begin
            fDisplay.UpdateTable(fGame.Table);
            UpdateControls;
          end;

      end;
    end;
  end;
end;

procedure TTableView.HandleStateChanged(Sender: TObject);
begin
  UpdateHValue;
  UpdateControls;
end;

procedure TTableView.SetInitialState(aSnapshot: TSnapshot);
begin
  aSnapshot.Restore(fLocalTable);
  fInitialState.Capture(fLocalTable);

  fGame.Initialize(fInitialState);
  fDisplay.UpdateTable(fLocalTable);

  SetPreviewMode(False);
end;

procedure TTableView.SetPreviewMode(const Value: Boolean);
begin
  if Value <> fPreviewMode then
  begin
    fPreviewMode := Value;
    fDisplay.PreviewMode := fPreviewMode;
  end;
  UpdateControls;
end;

procedure TTableView.skTableAnimationDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double;
  const AOpacity: Single);
begin
  if Assigned(fDisplay) then
    fDisplay.Draw(aCanvas, fLayout);
end;

procedure TTableView.DoExecuteMove(aMove: TMove; aImmediate: Boolean);
begin
  // get current table state
  fGame.CopyTableTo(fLocalTable);

  // ensure we can execute the move
  if not fGame.TryExecuteMove(aMove) then
    Exit;

  // temp
  if aImmediate or (aMove.Source = siStock) or (aMove.Target = siStock) then
  begin
    fDisplay.UpdateTable(fGame.Table);
    UpdateControls;
    Exit;
  end;

  // remove and save the source cards from the local table
  var cards: TArray<TCard>;
  fLocalTable.Stacks[aMove.Source].GetLastCards(cards, aMove.Count, True);
  fLocalTable.Stacks[aMove.Source].FaceUpCount := fLocalTable.Stacks[aMove.Source].FaceUpCount - aMove.Count;

  // this is the table we want to display until the animation completes
  fDisplay.UpdateTable(fLocalTable);

  // create move anim
  var startPos := fLayout.Origins[aMove.Source];
  if StackIdToCategory(aMove.Source) = scTableau then
  begin
    var offset := fLayout.TableauCardY(fLocalTable.Stacks[aMove.Source].Count);
    startPos.Offset(0, offset);
  end;

  var endPos: TPointF := fLayout.Origins[aMove.Target];
  if StackIdToCategory(aMove.Target) = scTableau then
  begin
    var offset := fLayout.TableauCardY(fLocalTable.Stacks[aMove.Target].Count);
    endPos.Offset(0, offset);
  end;

  var anim := CreateMoveAnimation(cards, startPos, endPos, TSizeF.Create(fLayout.CardWidth, fLayout.CardHeight));
  fDisplay.Animation := anim;
  anim.Start;

end;

procedure TTableView.skTableMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if not fPreviewMode then
  begin
    fMouseDownPos := Point(X, Y);
    fMouseIsDown := True;
  end;
end;

procedure TTableView.skTableMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
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
    var hitInfo := THitTester.GetHitInfo(fLayout, fGame.Table, fMouseDownPos);
    if (not hitInfo.Valid) or (not hitInfo.IsFaceUp) then
    begin
      // in this case you clicked the mouse on an invalid spot, then you dragged it.
      // we can erase this operation's future. nothing matters until you release the mouse
      fMouseIsDown := False;
      Exit;
    end;

    // grab current game state
    fGame.CopyTableTo(fLocalTable);

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
      var visIndex := Min(3, fGame.Table.Waste.Count) - 1;
      cardOrigin.Offset(fLayout.WasteCardX(visIndex), 0);
    end;
    fDragInfo.GrabOffset := PointF(fMouseDownPos.X - cardOrigin.X,
      fMouseDownPos.Y - cardOrigin.Y);

    // build list of drag cards, remove from local table
    fDragInfo.CardCount := fLocalTable.Stacks[hitInfo.StackId].Count - hitInfo.CardIndex;
    fLocalTable.Stacks[hitInfo.StackId].GetLastCards(fDragInfo.Cards, fDragInfo.CardCount, True);
    fLocalTable.Stacks[hitInfo.StackId].FaceUpCount := fLocalTable.Stacks[hitInfo.StackId].FaceUpCount - fDragInfo.CardCount;

    // send local table to display
    fDisplay.UpdateTable(fLocalTable);

    // fall through ...
  end;

  if fDragInfo.Active then
  begin
    // update the display
    var drawPos := PointF(mousePos.X - fDragInfo.GrabOffset.X, mousePos.Y - fDragInfo.GrabOffset.Y);
    fDisplay.SetDragOverlay(fDragInfo.Cards, fDragInfo.SourceStack, drawPos);

    // check drop target
    var hitInfo := THitTester.GetHitInfo(fLayout, fGame.Table, mousePos);
    if hitInfo.Valid then
    begin
      var m := NewMove(fDragInfo.SourceStack, hitInfo.StackId, fDragInfo.CardCount);
      if TMoveValidator.IsValidMove(m, fGame.Table) then
      begin
        var dropPoint := fLayout.Origins[m.Target];
        case StackIdToCategory(m.Target) of
          scFoundation: ;
          scTableau:
            begin
              var spacing := fLayout.StackOffset * fGame.Table.Stacks[m.Target].Count;
              dropPoint.Offset(0, spacing);
            end;
        end;

        fDisplay.SetDropTarget(fDragInfo.Cards, dropPoint);
      end;
    end

  end;

end;

procedure TTableView.skTableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
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

    var hitInfo := THitTester.GetHitInfo(fLayout, fGame.Table, mousePos);
    if hitInfo.Valid then
    begin
      var m := NewMove(fDragInfo.SourceStack, hitInfo.StackId, fDragInfo.CardCount);
      if TMoveValidator.IsValidMove(m, fGame.Table) then
      begin
        DoExecuteMove(m, True);
      end;
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
    var hitInfo := THitTester.GetHitInfo(fLayout, fGame.Table, mousePos);
    if hitInfo.Valid then
    begin
      var autoMove := Default(TMove);
      if fGame.GetAutoMove(hitInfo.StackId, hitInfo.CardIndex, autoMove) then
      begin
        DoExecuteMove(autoMove);
      end;
    end;

  end;
  fMouseIsDown := False;

end;

procedure TTableView.skTableResize(Sender: TObject);
begin
  fLayout.SetSize(skTable.ClientWidth, skTable.ClientHeight);
end;


end.
