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
    tsSetup: TTabSheet;
    tsGame: TTabSheet;
    gbSeedControl: TGroupBox;
    gbDeals: TGroupBox;
    clDeals: TControlList;
    btnGenerateDeals: TSpeedButton;
    btnStartGame: TSpeedButton;
    lblDealTitle: TLabel;
    lblDealDescription: TLabel;
    skTable: TSkAnimatedPaintBox;
    btnUndo: TPngSpeedButton;
    GameActions: TActionList;
    actRegen: TAction;
    actStartGame: TAction;
    actUndo: TAction;
    btnRedo: TPngSpeedButton;
    actRedo: TAction;
    actHint: TAction;
    btnHint: TPngSpeedButton;
    btnRestart: TPngSpeedButton;
    actRestart: TAction;
    actEndGame: TAction;
    btnEndGame: TPngSpeedButton;
    procedure clDealsBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure clDealsClick(Sender: TObject);
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
    procedure actStartGameExecute(Sender: TObject);
    procedure actUndoExecute(Sender: TObject);
    procedure actRedoExecute(Sender: TObject);
    procedure actHintExecute(Sender: TObject);
    procedure actRestartExecute(Sender: TObject);
    procedure actEndGameExecute(Sender: TObject);
    procedure clDealsItemDblClick(Sender: TObject);

  private
    fDealGenerator: TDealGenerator;
    fPreviewDealIndex: Integer;
    fGame: TKlondikeGame;
    fDisplay: TGameDisplay;
    fLayout: TLayout;
    fCardResources: TCardResources;

    // transient
    fLocalTable: TTable;

    // mouse handling
    fMouseIsDown: Boolean;
    fMouseDownPos: TPoint;
    fDragInfo: TDragInfo;

    procedure UpdateControls;
    procedure PreviewDeal(aIndex: Integer);
    procedure LoadDeal(aDealIndex: Integer; aTable: TTable); overload;
    procedure LoadDeal(aDealIndex: Integer; aDeck: TCardStack); overload;
    procedure HandleTableChanged(Sender: TObject);
    procedure HandleAnimationComplete(Sender: TObject; const Animation: IAnimation);
    procedure DoExecuteMove(aMove: TMove; aImmediate: Boolean = False);
  public
    procedure InitContent; override;
    procedure DoneContent; override;


    // Game actions
//    procedure DoQuickMove(const aHit: THitInfo);
//    procedure DoUndo;
//    procedure DoRedo;
//    procedure DoHint;
//    procedure DoRestart;
//    procedure DoAutoComplete;

    // Drag management
//    procedure BeginDrag(const aHit: THitInfo);
//    procedure UpdateDrag(aPos: TPointF);
//    procedure EndDrag(aPos: TPointF);
//    procedure CancelDrag;

    // State transitions
    procedure StartGame(aDealIndex: Integer);
//    procedure EndGame;

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

  fDragInfo := Default(TDragInfo);
  fMouseIsDown := False;

  // UI setup
  lblDealTitle.Font.Color := StyleServices.GetStyleFontColor(sfCaptionTextNormal);
  lblDealDescription.Font.Color := StyleServices.GetStyleFontColor(sfCaptionTextInactive);
  pcControlPages.ActivePage := tsSetup;
  UpdateControls;

  skTable.BackgroundColor := COLOR_TABLE_BK;

  PreviewDeal(-1);
end;

procedure TGameFrame.DoneContent;
begin
  fDisplay.Free;
  fGame.Free;
  fDealGenerator.Free;
  fCardResources.Free;
  fLocalTable.Free;

  inherited;
end;

procedure TGameFrame.UpdateControls;
begin
  var inSetup := pcControlPages.ActivePage = tsSetup;
  var inGame := not inSetup;

  // setup page
  actStartGame.Enabled := inSetup and (clDeals.ItemIndex <> -1);
  actRegen.Enabled := inSetup;

  // game page
  actUndo.Enabled := inGame and fGame.CanUndo;
  actRedo.Enabled := inGame and fGame.CanRedo;
  actHint.Enabled := inGame;
  actRestart.Enabled := inGame;
  actEndGame.Enabled := inGame;

end;

procedure TGameFrame.actStartGameExecute(Sender: TObject);
begin
  var dealIndex := clDeals.ItemIndex;
  Assert((dealIndex >= 0) and (dealIndex < fDealGenerator.Count));
  StartGame(dealIndex);
  UpdateControls;
end;

procedure TGameFrame.actUndoExecute(Sender: TObject);
begin
  fGame.Undo;
  fDisplay.UpdateTable(fGame.Table);
  UpdateControls;
end;

procedure TGameFrame.actEndGameExecute(Sender: TObject);
begin
  pcControlPages.ActivePage := tsSetup;
  fDealGenerator.Clear;
  clDeals.ItemCount := 0;

  fDisplay.PreviewTable(nil);

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
  // populate list of deals
  clDeals.ItemCount := 0;
  PreviewDeal(-1);

  fDealGenerator.GenerateDeals;

  clDeals.ItemCount := fDealGenerator.Count;
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

procedure TGameFrame.HandleTableChanged(Sender: TObject);
begin
// this needs re-thinking to consider animations

//  if Assigned(fDisplay) and Assigned(fGame) then
//    fDisplay.UpdateTable(fGame.Table);
end;

procedure TGameFrame.clDealsBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < fDealGenerator.Count) then
  begin
    lblDealTitle.Caption := fDealGenerator.Deals[AIndex].Title;
    lblDealDescription.Caption := fDealGenerator.Deals[AIndex].Difficulty.AsString;
  end;
end;

procedure TGameFrame.clDealsClick(Sender: TObject);
begin
  UpdateControls;
  PreviewDeal(-1);

  // send the selected deal to the display for preview
  if clDeals.ItemIndex >= 0 then
    PreviewDeal(clDeals.ItemIndex);
end;

procedure TGameFrame.clDealsItemDblClick(Sender: TObject);
begin
  if actStartGame.Enabled then
    actStartGame.Execute;
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

procedure TGameFrame.PreviewDeal(aIndex: Integer);
begin
  if aIndex <> fPreviewDealIndex then
  begin
    fPreviewDealIndex := aIndex;

    if fPreviewDealIndex >= 0 then
    begin
      var temp := TTable.Create;
      try
        LoadDeal(aIndex, temp);
        fDisplay.PreviewTable(temp);
      finally
        temp.Free;
      end;
    end
    else
    begin
      fDisplay.PreviewTable(nil);
    end;
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
  if pcControlPages.ActivePage = tsGame then
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
      if TValidator.IsValidMove(m, fGame.Table) then
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
      if TValidator.IsValidMove(m, fGame.Table) then
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

procedure TGameFrame.StartGame(aDealIndex: Integer);
begin
  // initialize game
  var deck := TCardStack.Create;
  try
    LoadDeal(aDealIndex, deck);

    fGame.InitializeGame(deck);
    fGame.Table.OnChange := Self.HandleTableChanged; // not sure if this will be used
    fGame.Restart;
    fGame.BuildHintList;

  finally
    deck.Free;
  end;

  // initialize display
  fDisplay.UpdateTable(fGame.Table);

  // switch to game controls
  pcControlPages.ActivePage := tsGame;
end;


end.
