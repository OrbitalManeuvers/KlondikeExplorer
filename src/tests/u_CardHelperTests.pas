unit u_CardHelperTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCardHelperTests = class
  public
    // TryParseTwoCode is the inverse of AsTwoCode
    [Test]
    procedure TryParseTwoCode_EveryCardRoundTrips;

    [Test]
    procedure TryParseTwoCode_IsCaseInsensitive;

    [Test]
    procedure TryParseTwoCode_IgnoresSurroundingWhitespace;

    [Test]
    procedure TryParseTwoCode_RejectsWrongLength;

    [Test]
    procedure TryParseTwoCode_RejectsUnknownRankOrSuit;
  end;

implementation

uses
  u_Types, u_CardHelpers;

{ TCardHelperTests }

procedure TCardHelperTests.TryParseTwoCode_EveryCardRoundTrips;
begin
  // the anchoring test: parser and renderer read the same rank/suit tables,
  // so every card must survive a render/parse round trip
  for var card: TCard := Low(TCardOrdinal) to High(TCardOrdinal) do
  begin
    var code := card.AsTwoCode;

    var parsed: TCard;
    Assert.IsTrue(TCard.TryParseTwoCode(code, parsed),
      'failed to parse ' + code + ' (' + card.AsText + ')');
    Assert.AreEqual(Integer(card), Integer(parsed), 'round trip mismatch for ' + code);
  end;
end;

procedure TCardHelperTests.TryParseTwoCode_IsCaseInsensitive;
begin
  var upper: TCard;
  var lower: TCard;

  Assert.IsTrue(TCard.TryParseTwoCode('QH', upper), 'QH should parse');
  Assert.IsTrue(TCard.TryParseTwoCode('qh', lower), 'qh should parse');
  Assert.AreEqual(Integer(upper), Integer(lower), 'case should not change the card');

  // mixed case, and the ten's rank letter
  var mixed: TCard;
  Assert.IsTrue(TCard.TryParseTwoCode('tD', mixed), 'tD should parse');
  Assert.AreEqual(Integer(TCard.NewCard(cvTen, csDiamonds)), Integer(mixed));
end;

procedure TCardHelperTests.TryParseTwoCode_IgnoresSurroundingWhitespace;
begin
  var padded: TCard;
  Assert.IsTrue(TCard.TryParseTwoCode('  7C  ', padded), 'padded code should parse');
  Assert.AreEqual(Integer(TCard.NewCard(cvSeven, csClubs)), Integer(padded));

  // whitespace alone trims away to nothing, which is not a code
  var blank: TCard;
  Assert.IsFalse(TCard.TryParseTwoCode('   ', blank), 'whitespace is not a code');
end;

procedure TCardHelperTests.TryParseTwoCode_RejectsWrongLength;
begin
  var card: TCard;
  Assert.IsFalse(TCard.TryParseTwoCode('', card), 'empty string');
  Assert.IsFalse(TCard.TryParseTwoCode('A', card), 'rank only');
  Assert.IsFalse(TCard.TryParseTwoCode('H', card), 'suit only');
  Assert.IsFalse(TCard.TryParseTwoCode('AHH', card), 'three characters');
  Assert.IsFalse(TCard.TryParseTwoCode('10D', card), 'ten spelled out is not a twocode');
end;

procedure TCardHelperTests.TryParseTwoCode_RejectsUnknownRankOrSuit;
begin
  var card: TCard;

  // bad rank, good suit
  Assert.IsFalse(TCard.TryParseTwoCode('1H', card), '1 is not a rank');
  Assert.IsFalse(TCard.TryParseTwoCode('XH', card), 'X is not a rank');

  // good rank, bad suit
  Assert.IsFalse(TCard.TryParseTwoCode('AX', card), 'X is not a suit');
  Assert.IsFalse(TCard.TryParseTwoCode('7B', card), 'B is not a suit');

  // suit and rank in the wrong order
  Assert.IsFalse(TCard.TryParseTwoCode('HA', card), 'suit before rank');
end;

initialization
  TDUnitX.RegisterTestFixture(TCardHelperTests);

end.
