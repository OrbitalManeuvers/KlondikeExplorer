unit u_Heuristics;

interface

uses u_Tables;

type
  THeuristic = class
    class function Score(Table: TTable): Single;
  end;

implementation

uses u_Types, u_CardHelpers;

{ THeuristic }

class function THeuristic.Score(Table: TTable): Single;
begin
  // every card not in a foundation requires at least one move to get there
  var foundationTotal := 0;
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    Inc(foundationTotal, Table.Foundation[suit].Count);

  Result := 52 - foundationTotal;

  // every face down card requires at least 1 move to uncover it
  var faceDown := 0;

  // a foundation cannot be started without the Ace, so add penalty for
  // the depth of buried aces in the tableaus
  var buriedAceDepth := 0;

  var allAcesPlayed := True;
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if Table.Foundation[suit].IsEmpty then
    begin
      allAcesPlayed := False;
      Break;
    end;

  for var tableau := Low(TTableauIndex) to High(TTableauIndex) do
  begin
    var stack := Table.Tableau[tableau];
    Inc(faceDown, stack.Count - stack.FaceUpCount);

    if not allAcesPlayed then
    begin
      // only look at face down cards
      for var i := 0 to stack.Count - stack.FaceUpCount - 1 do
      begin
        if stack.Cards[i].Value = cvAce then
        begin
          Inc(buriedAceDepth, stack.Count - i);
          Break;
        end;
      end;
    end;
  end;

  Result := Result + faceDown + buriedAceDepth;

  // cards trapped in the stock/waste cycle are harder to access than tableau cards
  Result := Result + (Table.Stock.Count + Table.Waste.Count) * 0.5;
end;

end.
