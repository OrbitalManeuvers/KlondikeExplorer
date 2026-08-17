unit fr_GameMode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrame, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ControlList,
  System.Types, System.Skia, System.Actions, Vcl.ActnList, PngSpeedButton, Vcl.Skia,

  u_Types, u_CardStacks, u_DealGenerators, u_Tables, u_Games, u_TableDisplays, u_GameDisplays,
  u_Layouts, u_CardResources, u_Snapshots, u_MoveLists, u_AnimationTypes;

type
  TDragInfo = record
    Active: Boolean;
    SourceStack: TStackId;
    CardIndex: Integer;
    CardCount: Integer;
    Cards: TArray<TCard>;
    GrabOffset: TPointF;      // mouse-down position relative to card top-left
  end;

  TGameFrame = class(TContentFrame)
    pnlGameControls: TPanel;
    pcControlPages: TPageControl;
    tsSetupMode: TTabSheet;
    tsLiveMode: TTabSheet;
    StateList: TControlList;
    btnGenerateDeals: TSpeedButton;
    btnStartLiveMode: TSpeedButton;
    lblDealTitle: TLabel;
    lblDealDescription: TLabel;
    skTable: TSkAnimatedPaintBox;
    btnUndo: TPngSpeedButton;
    GameActions: TActionList;
    actRegen: TAction;
    actStartLiveMode: TAction;
    actUndo: TAction;
    btnRedo: TPngSpeedButton;
    actRedo: TAction;
    actHint: TAction;
    btnHint: TPngSpeedButton;
    btnRestart: TPngSpeedButton;
    actRestart: TAction;
    actEndLiveMode: TAction;
    btnEndGame: TPngSpeedButton;
    GroupBox1: TGroupBox;
    edtSnapshotName: TEdit;
    Label1: TLabel;
    btnSaveSnapshot: TPngSpeedButton;
    Label2: TLabel;
    btnNewDeals: TSpeedButton;
    btnSnapshots: TSpeedButton;
    rbStarting: TRadioButton;
    rbCurrentState: TRadioButton;
    procedure StateListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure StateListClick(Sender: TObject);
    procedure skTableAnimationDraw(ASender: TObject; const ACanvas: ISkCanvas;
      const ADest: TRectF; const AProgress: Double; const AOpacity: Single);
    procedure skTableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure skTableMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure skTableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure skTableResize(Sender: TObject);
    procedure actRegenExecute(Sender: TObject);
    procedure actStartLiveModeExecute(Sender: TObject);
    procedure actUndoExecute(Sender: TObject);
    procedure actRedoExecute(Sender: TObject);
    procedure actHintExecute(Sender: TObject);
    procedure actRestartExecute(Sender: TObject);
    procedure actEndLiveModeExecute(Sender: TObject);
    procedure StateListItemDblClick(Sender: TObject);
    procedure StartStateChange(Sender: TObject);
    procedure edtSnapshotNameChange(Sender: TObject);
    procedure btnSaveSnapshotClick(Sender: TObject);

  private
    fDealGenerator: TDealGenerator;
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

    procedure UpdateControls;
    procedure PreviewDeal(aIndex: Integer);
    procedure PreviewSnapshot(aIndex: Integer);
    procedure LoadDeal(aDealIndex: Integer; aTable: TTable); overload;
    procedure LoadDeal(aDealIndex: Integer; aDeck: TCardStack); overload;
    procedure HandleAnimationComplete(Sender: TObject; const Animation: IAnimation);
    procedure DoExecuteMove(aMove: TMove; aImmediate: Boolean = False);
    function ValidSnapshotName(const aName: string): Boolean;
    procedure UpdateStatePreview;
  public
    procedure InitContent; override;
    procedure DoneContent; override;


  end;


implementation

{$R *.dfm}

uses Vcl.Themes, System.Math,

  u_Dealers, u_RenderUtils, u_HitTesters, u_MoveHelpers, u_Animations,
  u_HintAnimations, u_DisplayConsts, u_FlybackAnimations, u_MoveAnimations,
  u_MoveGenerators, u_MoveValidators, u_Utils;

function InDeadZone(MouseDown, MouseUp: TPoint): Boolean;
const
  zone = 3;
begin
  Result := (Abs(MouseDown.X - MouseUp.X) < zone) and
    (Abs(MouseDown.Y - MouseUp.Y) < zone);
end;

{ TGameFrame }

procedure TGameFrame.InitContent;
begin
  inherited;

  { !! }
  RandSeed := 12345;


  // lifetime assets
  fDealGenerator := TDealGenerator.Create;
  fGame := TKlondikeGame.Create;
  fDisplay := TGameDisplay.Create;
  fDisplay.PreviewTable(nil);
  fDisplay.OnAnimateComplete := HandleAnimationComplete;
  fCardResources := TCardResources.Create;
  TRenderUtils.SetResources(fCardResources);
  fLocalTable := TTable.Create;
  fInitialState := TSnapshot.Create;

  fDragInfo := Default(TDragInfo);
  fMouseIsDown := False;

  // UI setup
  lblDealTitle.Font.Color := StyleServices.GetStyleFontColor(sfCaptionTextNormal);
  lblDealDescription.Font.Color := StyleServices.GetStyleFontColor(sfCaptionTextInactive);
  pcControlPages.ActivePage := tsSetupMode;
  UpdateControls;

  skTable.BackgroundColor := COLOR_TABLE_BK;

//  fDisplay.PreviewTable(nil);
end;

procedure TGameFrame.DoneContent;
begin
  fDisplay.Free;
  fGame.Free;
  fDealGenerator.Free;
  fCardResources.Free;
  fLocalTable.Free;
  fInitialState.Free;

  inherited;
end;

procedure TGameFrame.edtSnapshotNameChange(Sender: TObject);
begin
  // live checking of name uniqueness
  UpdateControls;
end;

function TGameFrame.ValidSnapshotName(const aName: string): Boolean;
begin
  Result := (aName.Length > 0) and (SnapshotLibrary.IndexOfName(aName) = -1);
end;

procedure TGameFrame.UpdateControls;
begin
  var liveMode := pcControlPages.ActivePage = tsLiveMode;

  // setup page
  actStartLiveMode.Enabled := StateList.ItemIndex <> -1;
  actRegen.Enabled := btnNewDeals.Down;

  // game page
  actUndo.Enabled := liveMode and fGame.CanUndo;
  actRedo.Enabled := liveMode and fGame.CanRedo;
  actHint.Enabled := liveMode;
  actRestart.Enabled := liveMode;
  actEndLivemode.Enabled := liveMode;

  btnSaveSnapshot.Enabled := ValidSnapshotName(edtSnapshotName.Text);
end;

procedure TGameFrame.actStartLiveModeExecute(Sender: TObject);
begin
  var stateIndex := StateList.ItemIndex;
  if stateIndex <> -1 then
  begin

    if btnNewDeals.Down then
    begin
      // load selected deal into a table, then take a snapshot
      LoadDeal(stateIndex, fLocalTable);
      fInitialState.Capture(fLocalTable);
      edtSnapshotName.Text := fDealGenerator.Deals[stateIndex].Title;
    end
    else if btnSnapshots.Down then
    begin
      // load a snapshot with the selected library entry
      SnapshotLibrary.LoadSnapshot(stateIndex, fInitialState);
      edtSnapshotName.Text := SnapshotLibrary.Names[stateIndex];
    end;

    fGame.Initialize(fInitialState);  // does a Restart
    fDisplay.UpdateTable(fGame.Table);

    // switch to game controls
    pcControlPages.ActivePage := tsLiveMode;
  end;

  UpdateControls;
end;

procedure TGameFrame.actUndoExecute(Sender: TObject);
begin
  fGame.Undo;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TGameFrame.btnSaveSnapshotClick(Sender: TObject);
begin
  //
  if rbCurrentState.Checked then
  begin
    var s := TSnapshot.Create;
    try
      s.Capture(fGame.Table);
      SnapshotLibrary.Add(edtSnapshotName.Text, s);
    finally
      s.Free;
    end;
  end
  else if rbStarting.Checked then
  begin
    SnapshotLibrary.Add(edtSnapshotName.Text, fInitialState);
  end;
end;

procedure TGameFrame.actEndLiveModeExecute(Sender: TObject);
begin
  pcControlPages.ActivePage := tsSetupMode;
  fDisplay.PreviewTable(nil);

  StartStateChange(nil);
  UpdateControls;
end;

procedure TGameFrame.actHintExecute(Sender: TObject);
begin
  var hintMove: TMove;
  if fGame.GetNextHint(hintMove) then
  begin
    var anim := CreateHintAnimation(fGame.Table, hintMove, fLayout);
    fDisplay.Animation := anim;
    anim.Start;
  end;
end;

procedure TGameFrame.actRedoExecute(Sender: TObject);
begin
  fGame.Redo;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TGameFrame.actRegenExecute(Sender: TObject);
begin
  fDisplay.PreviewTable(nil);

  // populate list of deals
  fDealGenerator.GenerateDeals;

  StateList.ItemCount := fDealGenerator.Count;
  UpdateControls;
end;

procedure TGameFrame.actRestartExecute(Sender: TObject);
begin
  fGame.Restart;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TGameFrame.HandleAnimationComplete(Sender: TObject;
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

procedure TGameFrame.StateListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if btnNewDeals.Down then
  begin
    if (AIndex >= 0) and (AIndex < fDealGenerator.Count) then
    begin
      lblDealTitle.Caption := fDealGenerator.Deals[AIndex].Title;
      lblDealDescription.Caption := fDealGenerator.Deals[AIndex].Difficulty.AsString;
    end;
  end
  else
  begin
    if (AIndex >= 0) and (AIndex < SnapshotLibrary.Count) then
    begin
      lblDealTitle.Caption := SnapshotLibrary.Names[AIndex];
      lblDealDescription.Caption := ddUnknown.AsString;
    end;
  end;
end;

procedure TGameFrame.StateListClick(Sender: TObject);
begin
  UpdateStatePreview;
  UpdateControls;
end;

procedure TGameFrame.UpdateStatePreview;
begin
  fDisplay.PreviewTable(nil);
  var index := StateList.ItemIndex;
  if index <> -1 then
  begin
    if btnNewDeals.Down then
    begin
      PreviewDeal(index);
    end
    else if btnSnapshots.Down then
    begin
      PreviewSnapshot(index);
    end;

  end;

end;

procedure TGameFrame.StateListItemDblClick(Sender: TObject);
begin
  if actStartLiveMode.Enabled then
    actStartLiveMode.Execute;
end;

procedure TGameFrame.StartStateChange(Sender: TObject);
begin
  StateList.ItemIndex := -1;
  if btnNewDeals.Down then
  begin
    StateList.ItemCount := fDealGenerator.Count;
  end
  else
  begin
    StateList.ItemCount := SnapshotLibrary.Count;
  end;
end;

procedure TGameFrame.LoadDeal(aDealIndex: Integer; aDeck: TCardStack);
begin
  aDeck.Clear;
  for var cardIndex := Low(TCardOrdinal) to High(TCardOrdinal) do
    aDeck.Add(fDealGenerator.Deals[aDealIndex].Cards[cardIndex]);
end;

procedure TGameFrame.LoadDeal(aDealIndex: Integer; aTable: TTable);
begin
  var deck := TCardStack.Create;
  try
    LoadDeal(aDealIndex, deck);
    Assert(deck.Count = 52);
    TDealer.Deal(deck, aTable);
  finally
    deck.Free;
  end;
end;

procedure TGameFrame.PreviewSnapshot(aIndex: Integer);
begin
  var snapshot := TSnapshot.Create;
  try
    SnapshotLibrary.LoadSnapshot(aIndex, snapshot);
    var temp := TTable.Create;
    try
      snapshot.Restore(temp);
      fDisplay.PreviewTable(temp);
    finally
      temp.Free;
    end;
  finally
    snapshot.Free;
  end;
end;

procedure TGameFrame.PreviewDeal(aIndex: Integer);
begin
  var temp := TTable.Create;
  try
    LoadDeal(aIndex, temp);
    fDisplay.PreviewTable(temp);
  finally
    temp.Free;
  end;
end;

procedure TGameFrame.skTableAnimationDraw(ASender: TObject;
  const ACanvas: ISkCanvas; const ADest: TRectF; const AProgress: Double;
  const AOpacity: Single);
begin
  if Assigned(fDisplay) then
    fDisplay.Draw(aCanvas, fLayout);
end;

procedure TGameFrame.DoExecuteMove(aMove: TMove; aImmediate: Boolean);
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

procedure TGameFrame.skTableMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if pcControlPages.ActivePage = tsLiveMode then
  begin
    fMouseDownPos := Point(X, Y);
    fMouseIsDown := True;
  end;
end;

procedure TGameFrame.skTableMouseMove(Sender: TObject; Shift: TShiftState; X,
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

procedure TGameFrame.skTableMouseUp(Sender: TObject; Button: TMouseButton;
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

procedure TGameFrame.skTableResize(Sender: TObject);
begin
  fLayout.SetSize(skTable.ClientWidth, skTable.ClientHeight);
end;


end.
