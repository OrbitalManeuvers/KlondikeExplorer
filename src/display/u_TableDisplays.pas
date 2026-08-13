unit u_TableDisplays;

interface

uses System.Skia, System.Types,
  u_Types, u_Tables, u_Snapshots, u_Layouts;

type
  TTableDisplay = class
  private
    fTable: TTable;
    fSnapshot: TSnapshot;
    fPreviewMode: Boolean;
    procedure AdoptState(aTable: TTable);
  protected
    property PreviewMode: Boolean read fPreviewMode;
    property Table: TTable read fTable;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearTable;
    procedure PreviewTable(aTable: TTable);
    procedure UpdateTable(aTable: TTable);

    procedure Draw(aCanvas: ISkCanvas; const aLayout: TLayout); virtual;
  end;

implementation

uses u_CardHelpers, u_RenderUtils, u_Utils, System.Math;

{ TTableDisplay }

constructor TTableDisplay.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fSnapshot := TSnapshot.Create;
end;

destructor TTableDisplay.Destroy;
begin
  fTable.Free;
  fSnapshot.Free;
  inherited;
end;

procedure TTableDisplay.Draw(aCanvas: ISkCanvas; const aLayout: TLayout);
begin
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
      TRenderUtils.DrawEmptySlot(aCanvas, r);
    end;
  end;

//  for var suit := Low(TCardSuit) to High(TCardSuit) do
//  begin
//    var r := aLayout.CardRect(aLayout.FoundationOrigins[suit]);
//    if Table.Foundation[suit].HasCards then
//    begin
//      var c := Table.Foundation[suit].Last;
//      TRenderUtils.DrawCard(aCanvas, c, r, True);
//    end
//    else
//    begin
//      TRenderUtils.DrawEmptySlot(aCanvas, r);
//    end;
//  end;

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
      TRenderUtils.DrawEmptySlot(aCanvas, r); // this needs something else
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

//  for var tableau := Low(TTableauIndex) to High(TTableauIndex) do
//  begin
//    var r := aLayout.CardRect(aLayout.TableauOrigins[tableau]);
//    if Table.Tableau[tableau].IsEmpty then
//    begin
//      TRenderUtils.DrawEmptySlot(aCanvas, r);
//    end
//    else
//    begin
//      for var cardIndex := 0 to Table.Tableau[tableau].Count - 1 do
//      begin
//        var c := Table.Tableau[tableau].Cards[cardIndex];
//        var isFaceUp := cardIndex >= Table.Tableau[tableau].Count - Table.Tableau[tableau].FaceUpCount;
//        TRenderUtils.DrawCard(aCanvas, c, r, isFaceUp);
//        r.Offset(0, aLayout.StackOffset);
//      end;
//    end;
//  end;

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
    fPreviewMode := False;
  end;
end;

procedure TTableDisplay.UpdateTable(aTable: TTable);
begin
  fPreviewMode := False;
  AdoptState(aTable);
end;

end.
