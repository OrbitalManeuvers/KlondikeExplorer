unit u_TableDisplays;

interface

uses System.Skia, System.Types, System.UITypes, System.Diagnostics,
  u_Types, u_Tables, u_Snapshots, u_Layouts, u_AnimationTypes, u_AnimationHelpers;

type
  TAnimationMask = record
    Active: Boolean;
    StackId: TStackId;
    HideCount: Integer;
  end;

  TDragOverlay = record
    Active: Boolean;
    Cards: TArray<TCard>;
    Position: TPointF;       // current mouse position (top-left of dragged fan)
    SourceStack: TStackId;
  end;

  TDropTargetInfo = record
    Active: Boolean;
    Position: TPointF;
    Cards: TArray<TCard>;
  end;

  TAnimateCompleteEvent = procedure (Sender: TObject; const Animation: IAnimation) of object;

  TTableDisplay = class
  private
    fTable: TTable;
    fSnapshot: TSnapshot;
    fPreviewMode: Boolean;
    fStopwatch: TStopwatch;
    fMask: TAnimationMask;

    fAnimation: IAnimation;
    fDragOverlay: TDragOverlay;
    fDropTargetInfo: TDropTargetInfo;
    fOnAnimateComplete: TAnimateCompleteEvent;

    fStockPulse: TCycler;
    fDropPulse: TCycler;
    function GetHiddenCount(aStackId: TStackId): Integer;
    procedure RenderDragOverlay(aCanvas: ISkCanvas; const aLayout: TLayout);
    procedure RenderDropTarget(aCanvas: ISkCanvas; const aLayout: TLayout);

  protected
    property Table: TTable read fTable;
    property Stopwatch: TStopwatch read fStopwatch;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearTable;

    procedure UpdateTable(aTable: TTable);

    procedure Draw(aCanvas: ISkCanvas; const aLayout: TLayout); virtual;

    // Drag support
    procedure SetDragOverlay(const aCards: TArray<TCard>; aSourceStack: TStackId; aPos: TPointF);
    procedure ClearDragOverlay;

    procedure SetDropTarget(const aCards: TArray<TCard>; aPos: TPointF);
    procedure ClearDropTarget;

    procedure Animate(const aAnimation: IAnimation; aStackId: TStackId = siTableau1; aMoveCount: Integer = 0);
    procedure CancelAnimation;

    property Animation: IAnimation read fAnimation write fAnimation;
    property OnAnimateComplete: TAnimateCompleteEvent read fOnAnimateComplete write fOnAnimateComplete;

    property PreviewMode: Boolean read fPreviewMode write fPreviewMode;
  end;

implementation

uses System.Math, Vcl.Skia,
  u_CardHelpers, u_RenderUtils, u_Utils, u_DisplayConsts;


{ TTableDisplay }

constructor TTableDisplay.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fSnapshot := TSnapshot.Create;
  fStopwatch := TStopwatch.Startnew;
  fStockPulse.Init(1000, 0.40, 0.99, fStopwatch);
  fDropPulse.Init(1000, 0.4, 0.99, Stopwatch);  // !! eliminate
end;

destructor TTableDisplay.Destroy;
begin
  fTable.Free;
  fSnapshot.Free;
  inherited;
end;

function TTableDisplay.GetHiddenCount(aStackId: TStackId): Integer;
begin
  Result := 0;
  if fMask.Active and (fMask.StackId = aStackId) then
    Inc(Result, fMask.HideCount);
  if fDragOverlay.Active and (fDragOverlay.SourceStack = aStackId) then
    Inc(Result, Length(fDragOverlay.Cards));
end;

procedure TTableDisplay.Draw(aCanvas: ISkCanvas; const aLayout: TLayout);
var
  paint: ISkPaint;
  frame: ISkPaint;
begin
  if fPreviewMode then
  begin
    aCanvas.Clear(COLOR_PREVIEW_BK);

    paint := TSkPaint.Create;
    paint.Color := COLOR_PREVIEW_GRID; // soft blue drafting grid
    paint.Style := TSkPaintStyle.Stroke;
    paint.StrokeWidth := 1.0;
    paint.AntiAlias := True;

    const gridSpacing = 24.0;
    var maxX := aLayout.Size.cx;
    var maxY := aLayout.Size.cy;

    for var x := 0 to Round(maxX / gridSpacing) do
      aCanvas.DrawLine(x * gridSpacing, 0, x * gridSpacing, maxY, paint);

    for var y := 0 to Round(maxY / gridSpacing) do
      aCanvas.DrawLine(0, y * gridSpacing, maxX, y * gridSpacing, paint);

    // subtle outer framing
    frame := TSkPaint.Create;
    frame.Color := TAlphaColors.Black;
    frame.Style := TSkPaintStyle.Stroke;
    frame.StrokeWidth := 2.0;
    frame.AntiAlias := True;
    aCanvas.DrawRect(RectF(0, 0, maxX, maxY), frame);
  end;

  // draw foundation cards
  for var stackId := siFoundation1 to siFoundation4 do
  begin
    var r := aLayout.CardRect(aLayout.Origins[stackId]);

    // calculate the count
    var stackCardCount := Table.Stacks[stackId].Count - GetHiddenCount(stackId);

    if stackCardCount > 0 then
    begin
      var c := Table.Stacks[stackId].Cards[stackCardCount - 1];
      TRenderUtils.DrawCard(aCanvas, c, r, True);
    end
    else
    begin
      if not fPreviewMode then
        TRenderUtils.DrawEmptySuitSlot(aCanvas, r, StackIdToSuit(stackId));
    end;
  end;

  // draw waste cards (up to 3 visible, fanned right)
  var wasteCount := Table.Waste.Count - GetHiddenCount(siWaste);
  if wasteCount > 0 then
  begin
    var visibleCount := Min(3, wasteCount);
    var startIndex := wasteCount - visibleCount;
    for var I := 0 to visibleCount - 1 do
    begin
      var origin := aLayout.Origins[siWaste];
      origin.Offset(aLayout.WasteCardX(I), 0);
      var r := aLayout.CardRect(origin);
      var c := Table.Waste.Cards[startIndex + I];
      TRenderUtils.DrawCard(aCanvas, c, r, True);
    end;
  end;

  // draw stock
  begin
    var r := aLayout.CardRect(aLayout.Origins[siStock]);
    if Table.Stock.HasCards then
      TRenderUtils.DrawCardBack(aCanvas, r)
    else
    begin
      if Table.Waste.HasCards and (not fPreviewMode) then
        TRenderUtils.DrawCardHighlight(aCanvas, r, TAlphaColors.Coral, fStockPulse.Value)
      else if not fPreviewMode then
        TRenderUtils.DrawEmptySlot(aCanvas, r);
    end;
  end;

  // draw tableaus
  for var stackId := siTableau1 to siTableau7 do
  begin
    var r := aLayout.CardRect(aLayout.Origins[stackId]);

    var cardCount := Table.Stacks[stackId].Count - GetHiddenCount(stackId);

    if cardCount <= 0 then
    begin
      if not PreviewMode then
        TRenderUtils.DrawEmptySlot(aCanvas, r);
    end
    else
    begin
      for var cardIndex := 0 to cardCount - 1 do
      begin
        var c := Table.Stacks[stackId].Cards[cardIndex];
        var isFaceUp := cardIndex >= Table.Stacks[stackId].Count - Table.Stacks[stackId].FaceUpCount;
        TRenderUtils.DrawCard(aCanvas, c, r, isFaceUp);
        r.Offset(0, aLayout.StackOffset);
      end;
    end;
  end;

  if Assigned(Animation) then
  begin
    Animation.Draw(aCanvas);
    if Animation.State = asComplete then
    begin
      fMask.Active := False;
      var completedAnim := Animation;
      Animation := nil;
      if Assigned(fOnAnimateComplete) then
        fOnAnimateComplete(Self, completedAnim);
    end;
  end;

  if fDropTargetInfo.Active then
    RenderDropTarget(aCanvas, aLayout);

  if fDragOverlay.Active then
    RenderDragOverlay(aCanvas, aLayout);

end;

procedure TTableDisplay.ClearTable;
begin
  fTable.Clear;
end;

procedure TTableDisplay.UpdateTable(aTable: TTable);
begin
  fSnapshot.Capture(aTable);
  fSnapshot.Restore(fTable);
end;

procedure TTableDisplay.Animate(const aAnimation: IAnimation; aStackId: TStackId; aMoveCount: Integer);
begin
  CancelAnimation;
  fMask.Active := aMoveCount > 0;
  fMask.StackId := aStackId;
  fMask.HideCount := aMoveCount;

  fAnimation := aAnimation;
end;

procedure TTableDisplay.CancelAnimation;
begin
  fAnimation := nil;
  fMask.Active := False;
end;

procedure TTableDisplay.ClearDragOverlay;
begin
  fDragOverlay.Active := False;
  SetLength(fDragOverlay.Cards, 0);
end;

procedure TTableDisplay.SetDragOverlay(const aCards: TArray<TCard>; aSourceStack: TStackId; aPos: TPointF);
begin
  fDragOverlay.Active := True;
  fDragOverlay.Cards := aCards;
  fDragOverlay.SourceStack := aSourceStack;
  fDragOverlay.Position := aPos;
end;

procedure TTableDisplay.SetDropTarget(const aCards: TArray<TCard>; aPos: TPointF);
begin
  fDropTargetInfo.Active := True;
  fDropTargetInfo.Cards := aCards;
  fDropTargetInfo.Position := aPos;
end;

procedure TTableDisplay.ClearDropTarget;
begin
  fDropTargetInfo.Active := False;
end;

procedure TTableDisplay.RenderDragOverlay(aCanvas: ISkCanvas; const aLayout: TLayout);
var
  Bundle: TCardBundle;
begin
  Bundle.Cards := fDragOverlay.Cards;
  Bundle.CardSize.cx := aLayout.CardWidth;
  Bundle.CardSize.cy := aLayout.CardHeight;
  TRenderUtils.DrawCardBundle(aCanvas, Bundle, fDragOverlay.Position);
end;

procedure TTableDisplay.RenderDropTarget(aCanvas: ISkCanvas; const aLayout: TLayout);
var
  Bundle: TCardBundle;
begin
  Bundle.Cards := fDropTargetInfo.Cards;
  Bundle.CardSize.cx := aLayout.CardWidth;
  Bundle.CardSize.cy := aLayout.CardHeight;
  Bundle.OutlineColor := TAlphaColors.Coral;
  TRenderUtils.DrawCardBundle(aCanvas, Bundle, fDropTargetInfo.Position, 0.5,
    fDropPulse.Value);
end;

end.
