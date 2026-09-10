unit u_SolverTypesTests;

interface

uses DUnitX.TestFramework,
  u_Types, u_Tables, u_SolverTypes;

type
  [TestFixture]
  TSolverTypeTests = class
  private
    fTable: TTable;
  public
    constructor Create;
    destructor Destroy; override;

    [Test]
    procedure Unroll_DirectWasteMove_ProducesOnlyBoardMove;

    [Test]
    procedure Unroll_DrawsThenRecycleThenDraws_CorrectSequence;

    [Test]
    procedure Execute_DrawFromStockThenMoveToFoundation;

    [Test]
    procedure Execute_RecycleThenDrawThenMoveToTableau;
  end;

implementation

uses u_CardHelpers, u_MoveHelpers, u_MoveExecutors, u_Utils, u_TestUtils;

{ TSolverTypeTests }

procedure TSolverTypeTests.Unroll_DirectWasteMove_ProducesOnlyBoardMove;
var
  sm: TSolverMove;
  moves: TArray<TMove>;
begin
  // A card already sitting on the waste, no draws or recycles needed.
  sm := Default(TSolverMove);
  sm.Move.Source := siWaste;
  sm.Move.Target := siFoundation1;
  sm.Move.Count  := 1;
  sm.DrawsBeforeRecycle1 := 0;
  sm.DrawsAfterRecycle1  := 0;
  sm.DrawsAfterRecycle2  := 0;
  sm.RecycleCount        := 0;

  moves := sm.Unroll;

  Assert.AreEqual(1, Length(moves), 'Should produce exactly 1 move');
  Assert.AreEqual(siWaste, moves[0].Source);
  Assert.AreEqual(siFoundation1, moves[0].Target);
  Assert.AreEqual(1, moves[0].Count);
end;

procedure TSolverTypeTests.Unroll_DrawsThenRecycleThenDraws_CorrectSequence;
var
  sm: TSolverMove;
  moves: TArray<TMove>;
  idx: Integer;
begin
  // 2 draws on current stock, then recycle, then 3 draws, then the board move.
  sm := Default(TSolverMove);
  sm.Move.Source := siWaste;
  sm.Move.Target := siTableau3;
  sm.Move.Count  := 1;
  sm.DrawsBeforeRecycle1 := 2;
  sm.DrawsAfterRecycle1  := 3;
  sm.DrawsAfterRecycle2  := 0;
  sm.RecycleCount        := 1;

  moves := sm.Unroll;

  // Expected: Draw, Draw, Recycle, Draw, Draw, Draw, BoardMove  = 7 moves
  Assert.AreEqual(7, Length(moves), 'Expected 2 draws + recycle + 3 draws + board move');

  idx := 0;

  // Lap 1: 2 draws
  Assert.AreEqual(siStock, moves[idx].Source, 'Draw 1 source');
  Assert.AreEqual(siWaste, moves[idx].Target, 'Draw 1 target');
  Inc(idx);
  Assert.AreEqual(siStock, moves[idx].Source, 'Draw 2 source');
  Assert.AreEqual(siWaste, moves[idx].Target, 'Draw 2 target');
  Inc(idx);

  // Recycle
  Assert.AreEqual(siWaste, moves[idx].Source, 'Recycle source');
  Assert.AreEqual(siStock, moves[idx].Target, 'Recycle target');
  Inc(idx);

  // Lap 2: 3 draws
  Assert.AreEqual(siStock, moves[idx].Source, 'Lap2 draw 1 source');
  Assert.AreEqual(siWaste, moves[idx].Target, 'Lap2 draw 1 target');
  Inc(idx);
  Assert.AreEqual(siStock, moves[idx].Source, 'Lap2 draw 2 source');
  Assert.AreEqual(siWaste, moves[idx].Target, 'Lap2 draw 2 target');
  Inc(idx);
  Assert.AreEqual(siStock, moves[idx].Source, 'Lap2 draw 3 source');
  Assert.AreEqual(siWaste, moves[idx].Target, 'Lap2 draw 3 target');
  Inc(idx);

  // Final board move
  Assert.AreEqual(siWaste, moves[idx].Source, 'Board move source');
  Assert.AreEqual(siTableau3, moves[idx].Target, 'Board move target');
  Assert.AreEqual(1, moves[idx].Count, 'Board move count');
end;

constructor TSolverTypeTests.Create;
begin
  inherited Create;
  fTable := TTable.Create;
end;

destructor TSolverTypeTests.Destroy;
begin
  fTable.Free;
  inherited;
end;

procedure TSolverTypeTests.Execute_DrawFromStockThenMoveToFoundation;
var
  sm: TSolverMove;
begin
  // Stock holds [Ace of Hearts] — one draw exposes it on the waste,
  // then the board move sends it to Foundation (Hearts).
  fTable.Clear;
  TTestUtils.PlaceStockCards(fTable,
    [TCard.NewCard(cvAce, csHearts)]);

  sm := Default(TSolverMove);
  sm.Move.Source := siWaste;
  sm.Move.Target := siFoundation1;   // Hearts
  sm.Move.Count  := 1;
  sm.DrawsBeforeRecycle1 := 1;
  sm.RecycleCount        := 0;

  TMoveExecutor.ExecuteSolverMove(fTable, sm);

  Assert.AreEqual(0, fTable.Stock.Count, 'Stock should be empty');
  Assert.AreEqual(0, fTable.Waste.Count, 'Waste should be empty');
  Assert.AreEqual(1, fTable.Foundation[csHearts].Count,
    'Hearts foundation should have the Ace');
  Assert.IsTrue(
    fTable.Foundation[csHearts].Last.Equals(cvAce, csHearts),
    'Foundation card should be Ace of Hearts');
end;

procedure TSolverTypeTests.Execute_RecycleThenDrawThenMoveToTableau;
var
  sm: TSolverMove;
begin
  // Stock is empty, waste holds a single 5H.
  // Recycle moves it to stock, one draw puts it back on waste,
  // then the board move places it on tableau 1's black 6.
  fTable.Clear;
  fTable.Waste.Add(TCard.NewCard(cvFive, csHearts));

  TTestUtils.PlaceTableauRun(fTable, 1,
    [],                                        // no face-down cards
    [TCard.NewCard(cvSix, csClubs)]);                // one face-up black 6

  sm := Default(TSolverMove);
  sm.Move.Source := siWaste;
  sm.Move.Target := siTableau1;
  sm.Move.Count  := 1;
  sm.DrawsBeforeRecycle1 := 0;
  sm.DrawsAfterRecycle1  := 1;   // one draw after recycle
  sm.RecycleCount        := 1;

  TMoveExecutor.ExecuteSolverMove(fTable, sm);

  Assert.AreEqual(0, fTable.Stock.Count, 'Stock should be empty');
  Assert.AreEqual(0, fTable.Waste.Count, 'Waste should be empty');
  Assert.AreEqual(2, fTable.Stacks[siTableau1].Count,
    'Tableau 1 should have 2 cards');
  Assert.IsTrue(
    fTable.Stacks[siTableau1].Last.Equals(cvFive, csHearts),
    'Top of tableau 1 should be 5 of Hearts');
  Assert.AreEqual(0, fTable.RecycleCount,
    'RecycleCount should be reset to 0 by the waste-to-tableau move');
end;

initialization
  TDUnitX.RegisterTestFixture(TSolverTypeTests);

end.
