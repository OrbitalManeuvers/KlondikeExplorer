unit u_MoveGeneratorTests;

interface

uses DUnitX.TestFramework,
  u_Types, u_Tables;

type
  [TestFixture]
  TMoveGeneratorTests = class
  private
    fTable: TTable;
  public
    constructor Create;
    destructor Destroy; override;

    [Test]
    procedure KingOnTableau_MultipleEmptyColumns_OneMoveGenerated;

    [Test]
    procedure KingInStock_MultipleEmptyColumns_OneMoveGenerated;
  end;

implementation

uses System.Generics.Collections,
  u_CardHelpers, u_Utils, u_TestUtils, u_SolverTypes,
  u_MoveGenerators, u_CardPools, u_MoveHelpers;

{ TMoveGeneratorTests }

constructor TMoveGeneratorTests.Create;
begin
  inherited Create;
  fTable := TTable.Create;
end;

destructor TMoveGeneratorTests.Destroy;
begin
  fTable.Free;
  inherited;
end;

procedure TMoveGeneratorTests.KingOnTableau_MultipleEmptyColumns_OneMoveGenerated;
var
  moves: TList<TSolverMove>;
  kingToEmptyCount: Integer;
begin
  // King of Spades face-up on column 1; columns 2-7 are empty.
  // The solver should generate only one king-to-empty-tableau move,
  // not six.
  fTable.Clear;
  TTestUtils.PlaceTableauRun(fTable, 1, [],
    [NewCard(cvKing, csSpades)]);

  moves := TList<TSolverMove>.Create;
  try
    TMoveGenerator.GenerateSolverMoves(fTable, moves);

    kingToEmptyCount := 0;
    for var m in moves do
    begin
      if (m.Move.Source = siTableau1) and
         (m.Move.Target in [siTableau2..siTableau7]) then
        Inc(kingToEmptyCount);
    end;

    Assert.AreEqual(1, kingToEmptyCount,
      'Should generate exactly 1 king-to-empty-tableau move');
  finally
    moves.Free;
  end;
end;

procedure TMoveGeneratorTests.KingInStock_MultipleEmptyColumns_OneMoveGenerated;
var
  pool: TStockWastePool;
  moves: TList<TSolverMove>;
  kingToEmptyCount: Integer;
begin
  // King of Hearts in the stock, all 7 tableaus empty.
  // After draw, only one king-to-empty move should be emitted.
  fTable.Clear;
  fTable.Stock.Add(NewCard(cvKing, csHearts));

  moves := TList<TSolverMove>.Create;
  try
    pool.Init(fTable);
    pool.ScanReachableMoves(fTable, moves);

    kingToEmptyCount := 0;
    for var m in moves do
      if m.Move.Target in [siTableau1..siTableau7] then
        Inc(kingToEmptyCount);

    Assert.AreEqual(1, kingToEmptyCount,
      'Card pool should emit exactly 1 king-to-empty-tableau move');
  finally
    moves.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMoveGeneratorTests);

end.
