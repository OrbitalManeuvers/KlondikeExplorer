unit u_CardPools;

interface

uses System.Generics.Collections,
  u_Types, u_Tables, u_SolverTypes;

type
  TStockWastePool = record
  private
    fCards: array[0..51] of TCard;
    fCount: Integer;
    fInitialStockCount: Integer;
  public
    procedure Init(aTable: TTable);
    procedure ScanReachableMoves(aTable: TTable; aList: TList<TSolverMove>);
  end;

implementation

{ TStockWastePool }

uses
  System.SysUtils, System.Math,
  u_TableUtils, u_Utils, u_CardHelpers;

procedure TStockWastePool.Init(aTable: TTable);
var
  sCount, wCount, idx: Integer;
begin
  fInitialStockCount := aTable.Stock.Count;
  fCount := 0;

  // stock: top -> bottom (Last .. 0)
  sCount := aTable.Stock.Count;
  for idx := sCount - 1 downto 0 do
  begin
    fCards[fCount] := aTable.Stock.Cards[idx];
    Inc(fCount);
  end;

  // waste: bottom -> top (0 .. Last)
  wCount := aTable.Waste.Count;
  for idx := 0 to wCount - 1 do
  begin
    fCards[fCount] := aTable.Waste.Cards[idx];
    Inc(fCount);
  end;
end;

procedure TStockWastePool.ScanReachableMoves(aTable: TTable; aList: TList<TSolverMove>);
var
  stockList, wasteList: TList<TCard>;
  i, moveCount: Integer;
  initialRecycle, allowedAdditional, currentRecycle: Integer;
  draws: array[0..2] of Integer;
  seen: THashSet<string>;
  c: TCard;
  targetId: TStackId;
  sm: TSolverMove;
  key: string;
  // helper to emit solver move for a given exposed card if legal
  procedure EmitIfLegal(const card: TCard);
  begin
    // foundation move
    if IsNextFoundationCard(card, aTable) then
    begin
      targetId := SuitToStackId(card.Suit);
      key := Format('%s_F_%d_%d_%d_%d', [card.AsTwoCode, Ord(targetId), currentRecycle, draws[0], draws[1]]);
      if not seen.Contains(key) then
      begin
        seen.Add(key);
        sm.Move := NewMove(siWaste, targetId, 1);
        sm.DrawsBeforeRecycle1 := draws[0];
        sm.DrawsAfterRecycle1 := draws[1];
        sm.DrawsAfterRecycle2 := draws[2];
        sm.RecycleCount := currentRecycle;
        aList.Add(sm);
      end;
    end;

    // tableau move(s)
    if FindTableauTarget(card, aTable, targetId) then
    begin
      key := Format('%s_T_%d_%d_%d_%d', [card.AsTwoCode, Ord(targetId), currentRecycle, draws[0], draws[1]]);
      if not seen.Contains(key) then
      begin
        seen.Add(key);
        sm.Move := NewMove(siWaste, targetId, 1);
        sm.DrawsBeforeRecycle1 := draws[0];
        sm.DrawsAfterRecycle1 := draws[1];
        sm.DrawsAfterRecycle2 := draws[2];
        sm.RecycleCount := currentRecycle;
        aList.Add(sm);
      end;
    end;
  end;

begin
  // how many extra recycles we may perform (so that table.RecycleCount + extra < 3)
  initialRecycle := aTable.RecycleCount;
  allowedAdditional := 2 - initialRecycle;
  if allowedAdditional < 0 then
    Exit;

  stockList := TList<TCard>.Create;
  wasteList := TList<TCard>.Create;
  seen := THashSet<string>.Create;
  try
    // copy stacks (bottom..top)
    for i := 0 to aTable.Stock.Count - 1 do
      stockList.Add(aTable.Stock.Cards[i]);
    for i := 0 to aTable.Waste.Count - 1 do
      wasteList.Add(aTable.Waste.Cards[i]);

    draws[0] := 0; draws[1] := 0; draws[2] := 0;
    currentRecycle := 0;

    // initial exposed card (waste last) - available without performing a draw
    if wasteList.Count > 0 then
    begin
      c := wasteList[wasteList.Count - 1];
      EmitIfLegal(c);
    end;

    // simulate draws and recycles up to allowedAdditional recycles
    while True do
    begin
      // perform draws until stock exhausted
      while stockList.Count > 0 do
      begin
        moveCount := Min(3, stockList.Count);
        for i := 1 to moveCount do
        begin
          wasteList.Add(stockList[stockList.Count - 1]);
          stockList.Delete(stockList.Count - 1);
        end;
        Inc(draws[currentRecycle]);

        // new exposed card is last in waste
        if wasteList.Count > 0 then
        begin
          c := wasteList[wasteList.Count - 1];
          EmitIfLegal(c);
        end;
      end;

      // if we can recycle and there is something to recycle, do it and continue
      if (currentRecycle < allowedAdditional) and (wasteList.Count > 0) then
      begin
        // recycle: move waste (last..first) onto stock (append)
        while wasteList.Count > 0 do
        begin
          stockList.Add(wasteList[wasteList.Count - 1]);
          wasteList.Delete(wasteList.Count - 1);
        end;
        Inc(currentRecycle);
        // continue to next lap (draws for this lap will now be recorded in draws[currentRecycle])
        Continue;
      end;

      // nothing left to do
      Break;
    end;

  finally
    stockList.Free;
    wasteList.Free;
    seen.Free;
  end;
end;

end.
