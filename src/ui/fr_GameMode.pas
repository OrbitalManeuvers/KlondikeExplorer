unit fr_GameMode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrame, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ControlList,
  System.Types, System.Skia, System.Actions, Vcl.ActnList, PngSpeedButton, Vcl.Skia,

  u_Types, u_CardStacks, u_DealGenerators, u_Tables, u_Games, u_TableDisplays, u_GameDisplays,
  u_Layouts, u_CardResources, u_Snapshots;

type
  TDragInfo = record
    Active: Boolean;
    SourceStack: TStackId;
    CardIndex: Integer;
    Cards: TArray<TCard>;
    OriginalTable: TSnapshot;  // to restore on cancel
    LastMousePos: TPointF;
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

  private
    fDealGenerator: TDealGenerator;
    fPreviewDealIndex: Integer;
    fGame: TKlondikeGame;
    fDisplay: TGameDisplay;
    fDragInfo: TDragInfo;
    fLayout: TLayout;
    fCardResources: TCardResources;

    // mouse handling
    fMouseIsDown: Boolean;
    fMouseDownPos: TPoint;



    procedure UpdateControls;
    procedure PreviewDeal(aIndex: Integer);
    procedure LoadDeal(aDealIndex: Integer; aTable: TTable); overload;
    procedure LoadDeal(aDealIndex: Integer; aDeck: TCardStack); overload;
    procedure HandleTableChanged(Sender: TObject);
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

uses Vcl.Themes,

  u_Dealers, u_RenderUtils, u_HitTesters, u_MoveHelpers, u_Animations,
  u_HintAnimations, u_DisplayConsts;

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

  // lifetime assets
  fDealGenerator := TDealGenerator.Create;
  fGame := TKlondikeGame.Create;
  fDisplay := TGameDisplay.Create;
  fDisplay.PreviewTable(nil);
  fCardResources := TCardResources.Create;
  TRenderUtils.SetResources(fCardResources);

  fDragInfo := Default(TDragInfo);

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

procedure TGameFrame.skTableMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  fMouseDownPos := Point(X, Y);
  fMouseIsDown := True;
  //
end;

procedure TGameFrame.skTableMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited;
  //
end;

procedure TGameFrame.skTableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  var where := point(X, Y);
  if InDeadZone(fMouseDownPos, where) then
  begin
    // this is a click ... does it matter?
    var hitInfo := THitTester.GetHitInfo(fLayout, fGame.Table, where);
    if hitInfo.Valid then
    begin
      //
      var autoMove := Default(TMove);
      if fGame.GetAutoMove(hitInfo.StackId, hitInfo.CardIndex, autoMove) then
      begin
        //

        if fGame.TryExecuteMove(autoMove) then
        begin
          fDisplay.UpdateTable(fGame.Table);
          UpdateControls;
        end;

        //ShowMessage(autoMove.AsText);

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
