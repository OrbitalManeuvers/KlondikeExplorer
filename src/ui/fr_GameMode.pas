unit fr_GameMode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrame, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.ControlList,
  System.Types, System.Skia, Vcl.Skia,

  u_Types, u_CardStacks, u_DealGenerators, u_Tables, u_Games, u_TableDisplays, u_GameDisplays,
  u_Layouts, u_CardResources;

type
//
//  TDragState = record
//    Active: Boolean;
//    SourceStack: TStackId;
//    CardIndex: Integer;
//    Cards: TArray<TCard>;
//    OriginalTable: TSnapshot;  // to restore on cancel
//    LastMousePos: TPointF;
//  end;

  TGameFrame = class(TContentFrame)
    pnlGameControls: TPanel;
    pcControlPages: TPageControl;
    tsSetup: TTabSheet;
    tsGame: TTabSheet;
    gbSeedControl: TGroupBox;
    gbDeals: TGroupBox;
    clDeals: TControlList;
    btnGenerateDeals: TSpeedButton;
    btnPlay: TSpeedButton;
    lblDealTitle: TLabel;
    lblDealDescription: TLabel;
    skTable: TSkAnimatedPaintBox;
    procedure btnGenerateDealsClick(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
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

  private
    fDealGenerator: TDealGenerator;
    fPreviewDealIndex: Integer;
    fGame: TKlondikeGame;
    fDisplay: TGameDisplay;
    fDragState: TDragState;
    fLayout: TLayout;
    fCardResources: TCardResources;
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
//    procedure DoNewGame;
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
  u_Dealers, u_RenderUtils;

{ TGameFrame }

procedure TGameFrame.InitContent;
begin
  inherited;

  // lifetime assets
  fDealGenerator := TDealGenerator.Create;
  fGame := TKlondikeGame.Create;
  fDisplay := TGameDisplay.Create;
  fCardResources := TCardResources.Create;
  TRenderUtils.SetResources(fCardResources);

  // UI setup
  lblDealTitle.Font.Color := StyleServices.GetStyleFontColor(sfCaptionTextNormal);
  lblDealDescription.Font.Color := StyleServices.GetStyleFontColor(sfCaptionTextInactive);
  pcControlPages.ActivePage := tsSetup;
  UpdateControls;

  skTable.BackgroundColor := $FF2b7529;

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
  btnPlay.Enabled := clDeals.ItemIndex <> -1;
end;

procedure TGameFrame.btnGenerateDealsClick(Sender: TObject);
begin
  // populate list of deals
  clDeals.ItemCount := 0;
  PreviewDeal(-1);

  fDealGenerator.GenerateDeals;

  clDeals.ItemCount := fDealGenerator.Count;
  UpdateControls;
end;

procedure TGameFrame.HandleTableChanged(Sender: TObject);
begin
// this needs re-thinking to consider animations

//  if Assigned(fDisplay) and Assigned(fGame) then
//    fDisplay.UpdateTable(fGame.Table);
end;

procedure TGameFrame.btnPlayClick(Sender: TObject);
begin
  var dealIndex := clDeals.ItemIndex;
  Assert((dealIndex >= 0) and (dealIndex < fDealGenerator.Count));
  StartGame(dealIndex);
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
  inherited;
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
  inherited;
  //
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

  finally
    deck.Free;
  end;

  // initialize display
  fDisplay.UpdateTable(fGame.Table);

  // switch to game controls
  pcControlPages.ActivePage := tsGame;
end;

end.
