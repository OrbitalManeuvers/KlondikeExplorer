unit u_CardPoolTests;

interface

uses
  u_Tables,
  DUnitX.TestFramework;

type
  [TestFixture]
  TCardPoolTests = class
  private
    Table: TTable;
  public
    constructor Create;
    destructor Destroy; override;

    [Test]
    procedure DrawThreeExposesThirdCard;

    [Test]
    procedure WasteCardMovesToFoundation;

    [Test]
    procedure EmptyStockAndWaste;

    [Test]
    procedure SingleCardInStock;

    [Test]
    procedure KingToEmptyTableau;

    [Test]
    procedure MultipleTableauTargets;
  end;

implementation

uses
  System.Generics.Collections,
  u_CardPools,
  u_CardHelpers,
  u_SolverTypes,
  u_Types,
  u_Utils;

constructor TCardPoolTests.Create;
begin
  inherited Create;
  Table := TTable.Create;

end;

destructor TCardPoolTests.Destroy;
begin
  Table.Free;
  inherited;
end;

procedure TCardPoolTests.DrawThreeExposesThirdCard;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
begin
  Table.Clear;
  Table.RecycleCount := 2;

  Table.Stock.Add(NewCard(cvAce, csHearts));
  Table.Stock.Add(NewCard(cvEight, csClubs));
  Table.Stock.Add(NewCard(cvNine, csClubs));

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(Table);
    pool.ScanReachableMoves(Table, moves);

    Assert.AreEqual(1, moves.Count);
    Assert.AreEqual(1, moves[0].DrawsBeforeRecycle1);
    Assert.AreEqual(0, moves[0].DrawsAfterRecycle1);
    Assert.AreEqual(0, moves[0].DrawsAfterRecycle2);
    Assert.AreEqual(0, moves[0].RecycleCount);
    Assert.AreEqual(siWaste, moves[0].Move.Source);
    Assert.AreEqual(1, moves[0].Move.Count);
  finally
    moves.Free;
  end;
end;

procedure TCardPoolTests.WasteCardMovesToFoundation;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
begin
  Table.Clear;
  Table.RecycleCount := 2; // No additional recycles allowed

  // Ace of Spades on waste - can move to foundation without any draws
  Table.Waste.Add(NewCard(cvAce, csSpades));

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(Table);
    pool.ScanReachableMoves(Table, moves);

    Assert.AreEqual(1, moves.Count);
    Assert.AreEqual(0, moves[0].DrawsBeforeRecycle1);
    Assert.AreEqual(0, moves[0].DrawsAfterRecycle1);
    Assert.AreEqual(0, moves[0].DrawsAfterRecycle2);
    Assert.AreEqual(0, moves[0].RecycleCount);
    Assert.AreEqual(siWaste, moves[0].Move.Source);
    Assert.AreEqual(siFoundation4, moves[0].Move.Target); // Spades = foundation 4
    Assert.AreEqual(1, moves[0].Move.Count);
  finally
    moves.Free;
  end;
end;

procedure TCardPoolTests.EmptyStockAndWaste;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
begin
  Table.Clear;
  Table.RecycleCount := 0;

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(Table);
    pool.ScanReachableMoves(Table, moves);

    Assert.AreEqual(0, moves.Count);
  finally
    moves.Free;
  end;
end;

procedure TCardPoolTests.SingleCardInStock;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
begin
  Table.Clear;
  Table.RecycleCount := 2; // No additional recycles allowed

  // Single Ace in stock - one draw exposes it
  Table.Stock.Add(NewCard(cvAce, csHearts));

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(Table);
    pool.ScanReachableMoves(Table, moves);

    Assert.AreEqual(1, moves.Count);
    Assert.AreEqual(1, moves[0].DrawsBeforeRecycle1);
    Assert.AreEqual(0, moves[0].DrawsAfterRecycle1);
    Assert.AreEqual(0, moves[0].DrawsAfterRecycle2);
    Assert.AreEqual(0, moves[0].RecycleCount);
    Assert.AreEqual(siWaste, moves[0].Move.Source);
    Assert.AreEqual(siFoundation1, moves[0].Move.Target); // Hearts = foundation 1
  finally
    moves.Free;
  end;
end;

procedure TCardPoolTests.KingToEmptyTableau;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
begin
  Table.Clear;
  Table.RecycleCount := 2; // No additional recycles allowed

  // King of Hearts in stock - one draw exposes it, can go to any empty tableau
  Table.Stock.Add(NewCard(cvKing, csHearts));

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(Table);
    pool.ScanReachableMoves(Table, moves);

    // King can go to any of 7 empty tableaus
    Assert.AreEqual(7, moves.Count);
    Assert.AreEqual(1, moves[0].DrawsBeforeRecycle1);
    Assert.AreEqual(siWaste, moves[0].Move.Source);
    // All targets should be tableaus
    Assert.IsTrue(moves[0].Move.Target in [siTableau1..siTableau7]);
  finally
    moves.Free;
  end;
end;

procedure TCardPoolTests.MultipleTableauTargets;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
  targetCount: Integer;
begin
  Table.Clear;
  Table.RecycleCount := 2; // No additional recycles allowed

  // Set up two tableaus with black 6s on top
  Table.Stacks[siTableau1].Add(NewCard(cvSix, csClubs));
  Table.Stacks[siTableau3].Add(NewCard(cvSix, csSpades));

  // 5 of Hearts in stock - can go to both tableaus after one draw
  Table.Stock.Add(NewCard(cvFive, csHearts));

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(Table);
    pool.ScanReachableMoves(Table, moves);

    // Should have 2 moves: 5H to tableau1 and 5H to tableau3
    targetCount := 0;
    for var m in moves do
      if m.Move.Target in [siTableau1, siTableau3] then
        Inc(targetCount);

    Assert.AreEqual(2, targetCount);
    Assert.AreEqual(1, moves[0].DrawsBeforeRecycle1);
    Assert.AreEqual(siWaste, moves[0].Move.Source);
  finally
    moves.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCardPoolTests);

end.

