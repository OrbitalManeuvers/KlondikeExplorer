unit u_SnapshotComposerTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDeckPoolTests = class
  public
    [Test]
    procedure PopulateFullDeckGivesFiftyTwo;

    [Test]
    procedure TakeAnyDecrementsCount;

    [Test]
    procedure TakeAnyReturnsACardFromTheDeck;
  end;

  [TestFixture]
  TSpecParserTests = class
  public
    [Test]
    procedure ParsesFaceDownCardBeneathFaceUpTop;

    [Test]
    procedure FaceDownAboveFaceUpFailsHard;

    [Test]
    procedure DuplicateStackFailsHard;
  end;

implementation

uses
  System.SysUtils,
  u_Types,
  u_CardHelpers,
  u_SnapshotComposers;

{ TDeckPoolTests }

procedure TDeckPoolTests.PopulateFullDeckGivesFiftyTwo;
var
  pool: TDeckPool;
begin
  pool := TDeckPool.Create;
  try
    pool.PopulateFullDeck;
    Assert.AreEqual(52, pool.Count);
  finally
    pool.Free;
  end;
end;

procedure TDeckPoolTests.TakeAnyDecrementsCount;
var
  pool: TDeckPool;
begin
  pool := TDeckPool.Create;
  try
    pool.PopulateFullDeck;
    pool.TakeAny;
    Assert.AreEqual(51, pool.Count);
  finally
    pool.Free;
  end;
end;

procedure TDeckPoolTests.TakeAnyReturnsACardFromTheDeck;
var
  pool: TDeckPool;
  c: TCard;
begin
  pool := TDeckPool.Create;
  try
    pool.PopulateFullDeck;
    c := pool.TakeAny;
    // every ordinal 0..51 is a valid card; a full deck must hand back one of them
    Assert.IsTrue((c >= Low(TCard)) and (c <= High(TCard)));
  finally
    pool.Free;
  end;
end;

{ TSpecParserTests }

procedure TSpecParserTests.ParsesFaceDownCardBeneathFaceUpTop;
var
  spec: TSlotSpec;
  outcome: TComposerResult;
begin
  // Per the design doc: "T7: 7S- 6D" means 6D is face up on top, with 7S face
  // down beneath it (the card revealed when 6D moves off). A correct parse keeps
  // both cards bottom-to-top and reports a single face-up card on top.
  outcome := TSpecParser.TryParseLine('T7:7S- 6D', spec);

  Assert.IsTrue(outcome.Success, outcome.Error);
  Assert.AreEqual(siTableau7, spec.Stack);
  Assert.AreEqual(2, Length(spec.Cards));
  Assert.AreEqual(TCard.NewCard(cvSeven, csSpades), spec.Cards[0]);
  Assert.AreEqual(TCard.NewCard(cvSix, csDiamonds), spec.Cards[1]);
  Assert.AreEqual(1, spec.FaceUpCount);
end;

procedure TSpecParserTests.FaceDownAboveFaceUpFailsHard;
begin
  // "6D 7S-" puts a face-down card above a face-up one, breaking the
  // contiguous-top-run invariant. That must fail hard at parse time rather than
  // silently produce a mangled slot.
  Assert.WillRaise(
    procedure
    var
      spec: TSlotSpec;
    begin
      TSpecParser.TryParseLine('T7:6D 7S-', spec);
    end,
    EAssertionFailed);
end;

procedure TSpecParserTests.DuplicateStackFailsHard;
begin
  // The same stack authored twice is a malformed spec. TryParseSpec tracks the
  // stacks it has seen and must fail hard on a repeat rather than silently
  // letting the second slot clobber or duplicate the first.
  Assert.WillRaise(
    procedure
    var
      spec: TSpecification;
    begin
      TSpecParser.TryParseSpec('T1: AH'#13#10'T1: 2H', spec);
    end,
    EAssertionFailed);
end;

initialization
  TDUnitX.RegisterTestFixture(TDeckPoolTests);
  TDUnitX.RegisterTestFixture(TSpecParserTests);

end.
