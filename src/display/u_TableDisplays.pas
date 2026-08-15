unit u_TableDisplays;

interface

uses System.Skia, System.Types, System.UITypes, System.Diagnostics,
  u_Types, u_Tables, u_Snapshots, u_Layouts, u_AnimationHelpers;

type
  TTableDisplay = class
  private
    fTable: TTable;
    fSnapshot: TSnapshot;
    fPreviewMode: Boolean;
    fStopwatch: TStopwatch;
    fStockPulse: TCycler;

    procedure AdoptState(aTable: TTable);
  protected
    property PreviewMode: Boolean read fPreviewMode;
    property Table: TTable read fTable;
    property Stopwatch: TStopwatch read fStopwatch;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearTable;
    procedure PreviewTable(aTable: TTable);
    procedure UpdateTable(aTable: TTable);

    procedure Draw(aCanvas: ISkCanvas; const aLayout: TLayout); virtual;
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
end;

destructor TTableDisplay.Destroy;
begin
  fTable.Free;
  fSnapshot.Free;
  inherited;
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

  if fPreviewMode then
    aCanvas.SaveLayerAlpha(PREVIEW_ALPHA);
  try

    // draw foundation cards
    for var stackId := siFoundation1 to siFoundation4 do
    begin
      var r := aLayout.CardRect(aLayout.Origins[stackId]);
      if Table.Stacks[stackId].HasCards then
      begin
        var c := Table.Stacks[stackId].Last;
        TRenderUtils.DrawCard(aCanvas, c, r, True);
      end
      else
      begin
        if fPreviewMode then
          TRenderUtils.DrawEmptySlot(aCanvas, r)
        else
          TRenderUtils.DrawEmptySuitSlot(aCanvas, r, StackIdToSuit(stackId));
        end;
    end;

    // draw waste cards (up to 3 visible, fanned right)
    if Table.Waste.HasCards then
    begin
      var visibleCount := Min(3, Table.Waste.Count);
      var startIndex := Table.Waste.Count - visibleCount;
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
        if Table.Waste.HasCards then
          TRenderUtils.DrawCardHighlight(aCanvas, r, TAlphaColors.Coral, fStockPulse.Value)
        else
          TRenderUtils.DrawEmptySlot(aCanvas, r);
      end;
    end;

    // draw tableaus
    for var stackId := siTableau1 to siTableau7 do
    begin
      var r := aLayout.CardRect(aLayout.Origins[stackId]);
      if Table.Stacks[stackId].IsEmpty then
      begin
        TRenderUtils.DrawEmptySlot(aCanvas, r);
      end
      else
      begin
        for var cardIndex := 0 to Table.Stacks[stackId].Count - 1 do
        begin
          var c := Table.Stacks[stackId].Cards[cardIndex];
          var isFaceUp := cardIndex >= Table.Stacks[stackId].Count - Table.Stacks[stackId].FaceUpCount;
          TRenderUtils.DrawCard(aCanvas, c, r, isFaceUp);
          r.Offset(0, aLayout.StackOffset);
        end;
      end;
    end;

  finally
    if fPreviewMode then
      aCanvas.Restore;
  end;

end;

procedure TTableDisplay.AdoptState(aTable: TTable);
begin
  // just adopt the contents and next update will show new state
  fSnapshot.Capture(aTable);
  fSnapshot.Restore(fTable);
end;

procedure TTableDisplay.ClearTable;
begin
  fTable.Clear;
end;

procedure TTableDisplay.PreviewTable(aTable: TTable);
begin
  if Assigned(aTable) then
  begin
    AdoptState(aTable);
    fPreviewMode := True;
  end
  else
  begin
    ClearTable;
    fPreviewMode := True;
  end;
end;

procedure TTableDisplay.UpdateTable(aTable: TTable);
begin
  fPreviewMode := False;
  AdoptState(aTable);
end;

end.
