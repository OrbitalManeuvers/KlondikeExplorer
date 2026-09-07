unit u_TestUtils;

interface

uses
  u_Types, u_CardHelpers, u_Tables;

type
  TTestUtils = class
  public
    class procedure PopulateRandomDeal(aTable: TTable);
    class procedure PopulateFoundation(aTable: TTable; aSuit: TCardSuit;
      aUpTo: TCardValue);

    // Place a tableau column with explicit face-down and face-up cards.
    // Cards are added bottom-to-top in array order.
    class procedure PlaceTableauRun(aTable: TTable; aColumn: TTableauIndex;
      const aFaceDown, aFaceUp: array of TCard);

    // Load the stock with cards in the given order (first element = bottom).
    class procedure PlaceStockCards(aTable: TTable;
      const aCards: array of TCard);
  end;

implementation

uses System.Classes, System.SysUtils, u_Utils,
  u_Snapshots, u_CardStacks, u_Dealers, u_Shufflers;

{ TTestUtils }

class procedure TTestUtils.PopulateFoundation(aTable: TTable;
  aSuit: TCardSuit; aUpTo: TCardValue);
begin
  var firstCard := NewCard(cvAce, aSuit);
  var lastCard := NewCard(aUpTo, aSuit);
  for var card := Ord(firstCard) to Ord(lastCard) do
    aTable.Foundation[aSuit].Add(card);
end;

class procedure TTestUtils.PopulateRandomDeal(aTable: TTable);
begin
  var deck := TCardStack.Create;
  try
    TDealer.PopulateNewDeck(deck);
    TShuffler.Shuffle(deck);
    TDealer.Deal(deck, aTable);
  finally
    deck.Free;
  end;
end;

class procedure TTestUtils.PlaceTableauRun(aTable: TTable;
  aColumn: TTableauIndex; const aFaceDown, aFaceUp: array of TCard);
var
  stack: TCardStack;
begin
  stack := aTable.Tableau[aColumn];
  for var i := 0 to High(aFaceDown) do
    stack.Add(aFaceDown[i]);
  for var i := 0 to High(aFaceUp) do
    stack.Add(aFaceUp[i]);
  stack.FaceUpCount := Length(aFaceUp);
end;

class procedure TTestUtils.PlaceStockCards(aTable: TTable;
  const aCards: array of TCard);
begin
  for var i := 0 to High(aCards) do
    aTable.Stock.Add(aCards[i]);
end;

end.
