unit u_CanonicalStateTests;

interface

uses DUnitX.TestFramework,
  u_Types, u_Tables;

type
  [TestFixture]
  TCanonicalStateTests = class
  private
    fTable: TTable;
  public
    constructor Create;
    destructor Destroy; override;

    [Test]
    procedure SwappedTableauColumns_SameHash;

    [Test]
    procedure DifferentFoundationHeights_DifferentHash;

    [Test]
    procedure DifferentRecycleCount_DifferentHash;

    [Test]
    procedure SameState_ConsistentHash;
  end;

implementation

uses u_CardHelpers, u_Utils, u_TestUtils, u_CanonicalState;

{ TCanonicalStateTests }

constructor TCanonicalStateTests.Create;
begin
  inherited Create;
  fTable := TTable.Create;
end;

destructor TCanonicalStateTests.Destroy;
begin
  fTable.Free;
  inherited;
end;

procedure TCanonicalStateTests.SwappedTableauColumns_SameHash;
var
  cs1, cs2: TCanonicalState;
begin
  // Build a table with a King of Spades on column 1 and a Queen of Hearts
  // on column 3 (all other columns empty).
  fTable.Clear;
  TTestUtils.PlaceTableauRun(fTable, 1, [],
    [NewCard(cvKing, csSpades)]);
  TTestUtils.PlaceTableauRun(fTable, 3, [],
    [NewCard(cvQueen, csHearts)]);

  cs1.Capture(fTable);

  // Now swap: Queen of Hearts on column 1, King of Spades on column 3.
  fTable.Clear;
  TTestUtils.PlaceTableauRun(fTable, 1, [],
    [NewCard(cvQueen, csHearts)]);
  TTestUtils.PlaceTableauRun(fTable, 3, [],
    [NewCard(cvKing, csSpades)]);

  cs2.Capture(fTable);

  Assert.AreEqual(cs1.Hash, cs2.Hash,
    'Swapping columns should produce the same canonical hash');
end;

procedure TCanonicalStateTests.DifferentFoundationHeights_DifferentHash;
var
  cs1, cs2: TCanonicalState;
begin
  // Hearts foundation up through Ace
  fTable.Clear;
  TTestUtils.PopulateFoundation(fTable, csHearts, cvAce);
  cs1.Capture(fTable);

  // Hearts foundation up through Three
  fTable.Clear;
  TTestUtils.PopulateFoundation(fTable, csHearts, cvThree);
  cs2.Capture(fTable);

  Assert.AreNotEqual(cs1.Hash, cs2.Hash,
    'Different foundation heights should produce different hashes');
end;

procedure TCanonicalStateTests.DifferentRecycleCount_DifferentHash;
var
  cs1, cs2: TCanonicalState;
begin
  fTable.Clear;
  TTestUtils.PlaceStockCards(fTable,
    [NewCard(cvFive, csHearts)]);
  fTable.RecycleCount := 0;
  cs1.Capture(fTable);

  // Same cards, different recycle count
  fTable.Clear;
  TTestUtils.PlaceStockCards(fTable,
    [NewCard(cvFive, csHearts)]);
  fTable.RecycleCount := 1;
  cs2.Capture(fTable);

  Assert.AreNotEqual(cs1.Hash, cs2.Hash,
    'Different recycle counts should produce different hashes');
end;

procedure TCanonicalStateTests.SameState_ConsistentHash;
var
  cs1, cs2: TCanonicalState;
begin
  // Capture the same state twice and verify the hash is identical.
  fTable.Clear;
  TTestUtils.PlaceTableauRun(fTable, 2, [],
    [NewCard(cvJack, csDiamonds), NewCard(cvTen, csClubs)]);
  TTestUtils.PlaceStockCards(fTable,
    [NewCard(cvAce, csSpades)]);
  TTestUtils.PopulateFoundation(fTable, csHearts, cvTwo);

  cs1.Capture(fTable);
  cs2.Capture(fTable);

  Assert.AreEqual(cs1.Hash, cs2.Hash,
    'Same table state should always produce the same hash');
end;

initialization
  TDUnitX.RegisterTestFixture(TCanonicalStateTests);

end.
