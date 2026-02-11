unit u_Dealers;

interface

uses System.Classes,

 u_CardStacks,
 u_Tables;

type
  TDealer = class
    class procedure Deal(aSource: TCardStack; aTable: TTable);
    class procedure PopulateNewDeck(aDeck: TCardStack);
  end;

implementation

uses System.SysUtils,

  u_Types,
  u_Moves.Executors;


{ TDealer }
class procedure TDealer.Deal(aSource: TCardStack; aTable: TTable);
begin
  aTable.Clear;

  // deal the deck out to the tableau stacks
  for var start := Low(TTableauIndex) to High(TTableauIndex) do
  begin
    // put one card in each column from start to High()
    for var ti := start to High(TTableauIndex) do
    begin
      aTable.Tableau[ti].Add(aSource._Pop);
    end;
  end;

  aTable.Stock._AddFrom(aSource);

  // a draw is implicit for the starting state (engine has no recycle state)
  var draw: TMove;
  draw.Source := siStock;
  draw.Target := siWaste;
  draw.Count := 3;
  TExecutor.ExecuteMove(aTable, draw);

  for var ti := Low(TTableauIndex) to High(TTableauIndex) do
    aTable.Tableau[ti].FaceUpCount := 1;

  aTable.Stock.FaceUpCount := 0;
  aTable.Waste.FaceUpCount := 0;
end;


class procedure TDealer.PopulateNewDeck(aDeck: TCardStack);
begin
  aDeck.Clear;
  for var c := Low(TCardOrdinal) to High(TCardOrdinal) do
    aDeck.Add(c);
end;

end.
