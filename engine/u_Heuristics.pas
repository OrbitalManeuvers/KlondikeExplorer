unit u_Heuristics;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_MoveLists,
  u_SnapshotManagers,
  u_Snapshots,
  u_Tables;

type
  THeuristic = class
  public
//    class function Crapulate(aTable: TTable; aValidMoveCount: Integer): Double;
    class function Calculate(aTable: TTable; aValidMoveCount: Integer): Double;
  end;



implementation

uses System.Math,
  u_Cards;

(*

- Foundation progress (distance to goal).
- Number of legal moves (direct mobility measure).

- Average depth of face-down piles (buriedness).
- Number of empty tableau slots (openness / maneuverability).

Step 2. Direction of each factor

Number of legal moves (mobility)

More moves = better.

So contribution should decrease as mobility increases.

Example: mobility_term = 1 / (1 + moves) (a diminishing positive cost).

Average depth of face-down piles (buriedness)

Deeper piles = worse.

So contribution should increase with average depth.

Example: depth_term = avg_depth.

Foundation progress (distance to goal)

More cards in foundation = better.

So contribution should decrease as foundation count goes up.

Example: foundation_term = total_cards - foundation_count.

(That’s literally “how many cards remain out of foundation.”)

Number of empty tableau slots (openness)

More empty slots = better (more flexibility).

So contribution should decrease as empties increase.

Example: empties_term = 1 / (1 + empties) or (max_slots - empties).

mobility_term   = 1 / (1 + moves)
depth_term      = avg_depth
foundation_term = total_cards - foundation_count
empties_term    = (max_slots - empties)

h(n) = w1 * mobility_term
     + w2 * depth_term
     + w3 * foundation_term
     + w4 * empties_term

Set all wi = 1.0 to begin with. Later, tune weights by trial or by automatic parameter search.


Thinking with my brain
----------------------
worst cases:
  cards not in foundation = (52 - foundation)  - count
  (stock + waste) div 3 (+1) - count
  face down cards on tableau - adds difficulty factor by increasing counts
  valid moves available - subtracts points

-------------------------------------------------

Q: how many moves are likely left?

minimum = (52 - foundationCount) + tableauFaceDown

factors that can improve the state
 - # of available moves
 - # empty tableaus
 - # of face-up kings in tableaus
 - # (and depth) of foundation-ready sequences
 - depth of immediate waste receptivity
 - king potential:
   - if waste.top can play, is there an empty tableau and a king next?
   - if waste.top = king, is there an open tableau, or immediate potential to open one?

factors that can complicate the state:
 - ratio of move count to stock+waste
 -



*)

{ THeuristic }

class function THeuristic.Calculate(aTable: TTable; aValidMoveCount: Integer): Double;
begin
  Result := 0.0;

  // these are checked along the way
  var wasteImmediate := False;   // can the waste card be played now?
  var buriedWasteKing := False;  // if the waste top is playable, is the next card a king?

  // gather some stats about the foundation, while checking for a solved state
  var kingsOnFoundation: Integer := 0;
  var foundationCount: Integer := 0;
  var nextFoundationValue: array[TCardSuit] of TCardValue;

  // look at each foundation
  for var suit := Low(TCardSuit) to High(TCardSuit) do
  begin
    nextFoundationValue[suit] := cvAce;  // default value in case it's empty
    if aTable.Foundation[suit].HasCards then
    begin
      Inc(foundationCount, aTable.Foundation[suit].Count); // cards already "finished", for now
      if aTable.Foundation[suit].Last.Value = cvKing then
        Inc(kingsOnFoundation)  // this leaves the unreachable Ace as the nextFoundationValue
      else
        nextFoundationValue[suit] := Succ(aTable.Foundation[suit].Last.Value);
    end;
  end;

  // solved?
  if kingsOnFoundation = 4 then
    Exit;

  // check the waste playing to the foundation
  if aTable.Waste.HasCards then
  begin
    var c := aTable.Waste.Last;
    if nextFoundationValue[c.Suit] = c.Value then
      wasteImmediate := True;
  end;

  // gather some stats on the tableau stacks
  var emptyTableaus := 0;     // these have no cards
//  var kingBasedTableaus := 0; // these have a king as the first card
  var kingBasedRuns := 0;     // a king is the first face-up card on top of face down cards
  var foundationReady := 0;   // card on top of tableau is next required foundation card
  var faceDownCount := 0;

  // depth of immediate waste receptivity
  var buildMap: array[TTableauIndex] of TCardDescriptor;

  for var ti := Low(TTableauIndex) to High(TTableauIndex) do
  begin
    var stack := aTable.Tableau[ti];
    if stack.IsEmpty then
    begin
      Inc(emptyTableaus);
      buildMap[ti].Value := cvKing;  // this stack needs a king next
    end
    else
    begin
//      // is a face up king at the base of the stack?
//      if (stack.FaceUpCount = stack.Count) and (stack.First.Value = cvKing) then
//        Inc(kingBasedTableaus);

      // foundation ready?
      if nextFoundationValue[stack.Last.Suit] = stack.Last.Value then
        Inc(foundationReady);

      // if a king is the first face-up card then take note
      var faceUpIndex := stack.Count - stack.FaceUpCount;
      if stack[faceUpIndex].Value = cvKing then
        Inc(kingBasedRuns);


      // fill in the build map for what's needed next
      buildMap[ti].Color := stack.Last.OppositeColor;
      // only set this for non aces
      if stack.Last.Value > cvAce then
        buildMap[ti].Value := Pred(stack.Last.Value);

      // could the waste card move here right now?
      if aTable.Waste.HasCards and aTable.Waste.Last.Matches(buildMap[ti]) then
        wasteImmediate := True;
    end;
  end;

  // check how many cards could come off the waste immediately
  var immediateWasteRun := 0;
  for var wi := aTable.Waste.Count - 1 downto 0 do
  begin
    var movingCard := aTable.Waste[wi];

    // if this is an ace, we'll count it, and keep going - an ace always has a home
    if movingCard.Value = cvAce then
    begin
      Inc(immediateWasteRun);
      Continue;
    end;

    var placed := False;

    // can this go anywhere?
    for var ti := Low(TTableauIndex) to High(TTableauIndex) do
    begin
      var required := buildMap[ti];

      // a king's color doesn't matter
      var isLegal := (required.Value = cvKing) and (movingCard.Value = cvKing);
      if not isLegal then
        isLegal := movingCard.Matches(required);

      if isLegal then
      begin
        // count the match
        Inc(immediateWasteRun);
        placed := True;

        // update the map with the next expected value
        if movingCard.Value > cvAce then
          buildMap[ti].Value := Pred(movingCard.Value);
        buildMap[ti].Color := movingCard.OppositeColor;

        Break;
      end;
    end;

    // have to place cards sequentially
    if not placed then
      Break;

  end;

  // if the top waste card can be played, is the next waste card a king?
  if wasteImmediate and (aTable.Waste.Count > 1) then
  begin
    if aTable.Waste[aTable.Waste.Count - 2].Value = cvKing then
      buriedWasteKing := True;
  end;

  // put everything together, starting with the worst case scenario of the amount
  // of moves remaining, from a somewhat mechanical pov
  var minimumSteps := (52 - foundationCount) + faceDownCount;

  var outOfPlay := aTable.Stock.Count + aTable.Waste.Count;
  Inc(minimumSteps, outOfPlay);

  // try estimate the opportunities
  var ops: Double := 0.0;

(*
 - king potential:
   - if waste.top can play, is there an empty tableau and a king next?
   - if waste.top = king, is there an open tableau, or immediate potential to open one?

*)

  // let's say 20% of the available moves might be productive
  ops := ops + (0.2 * aValidMoveCount);

  // empty tableaus represent ways to progress
  ops := ops + (0.3 * emptyTableaus);

  // king-based runs
  // these need empty tableaus to unblock whatever they cover
  var deficit := kingBasedRuns - emptyTableaus;
  if deficit > 0 then
    ops := ops - (0.5 * deficit);

  // foundation-ready tableaus
  ops := ops + (0.2 * foundationReady);

  // immediate waste move potential
  ops := ops + (0.1 * immediateWasteRun);

  //
  if wasteImmediate and buriedWasteKing and (emptyTableaus > 0) then
    ops := ops + (0.3 * 2);


  Result := minimumSteps - ops;
end;

(*
class function THeuristic.Crapulate(aTable: TTable; aValidMoveCount: Integer): Double;
begin
//  Result := 0.0;

  // the mobility term
  var mobility_term: Double := 1 / (1 + aValidMoveCount);

  // depth term and empties term
  var depth_term: Double;
  var face_down_count := 0;
  var empties_count := 0;
  for var ti := Low(TTableauIndex) to High(TTableauIndex) do
  begin
    if aTable.Tableau[ti].IsEmpty then
      Inc(empties_count)
    else
      Inc(face_down_count, aTable.Tableau[ti].Count - aTable.Tableau[ti].FaceUpCount);
  end;

  // depth term is average depth of stacks that have cards at all
  if face_down_count > 0 then
    depth_term := face_down_count / (7 - empties_count)
  else
    depth_term := 0;

  // the empties count alone is misleading - it's offset by having a king at the base,
  // so start with the number of kings that can still be on the tableau
  var kings_on_foundation := 0;
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if aTable.Foundation[suit].HasCards and (aTable.Foundation[suit].Last.Value = cvKing) then
      Inc(kings_on_foundation);

  // btw - if this is 4 then we're done
  if kings_on_foundation = Ord(High(TCardSuit)) + 1 then
  begin
    Exit(0.0);
  end;

  // and how many are actually there
  var kings_as_bases := 0;
  for var ti := Low(TTableauIndex) to High(TTableauIndex) do
    if aTable.Tableau[ti].HasCards and (aTable.Tableau[ti].First.Value = cvKing) then
      Inc(kings_as_bases);

  var empties_term := empties_count + (kings_as_bases * 0.8); // almost as good as empties

  // foundation term
  var foundationCount := 0;
  for var cs := Low(TCardSuit) to High(TCardSuit) do
    Inc(foundationCount, aTable.Foundation[cs].Count);
  var foundation_term := 52 - foundationCount;

  var homeless_term := aTable.Stock.Count + aTable.Waste.Count;


  result :=
    (1.0 * mobility_term) +
    (1.0 * depth_term) +
    (1.0 * foundation_term) +
    (1.0 * empties_term) +
    (0.5 * homeless_term);



end;
*)

end.
