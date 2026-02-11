unit u_Moves.Evaluators;

interface

uses System.Classes, System.Generics.Collections, System.Generics.Defaults,

  u_Types,
  u_Moves.Analysis,
  u_MoveLists,
  u_EvalLists,
  u_Tables;

type
  { TEvaluator }
  TEvaluator = class
  protected
    class procedure EvaluateMove(aMoveInfo: TMoveInfo; var aEval: TEvaluation);
  public
    class procedure Evaluate(aList: TMoveList; aTable: TTable; aResults: TEvalList);
  end;

implementation

uses System.SysUtils, System.Math,

  u_Cards,
  u_CardStacks,
  u_TableUtils;


{ TEvaluator }

// local effects and potential consequences
class procedure TEvaluator.Evaluate(aList: TMoveList; aTable: TTable; aResults: TEvalList);
var
  i: TMoveInfo;
begin

  i := TMoveInfo.Create;
  try

    // potential op: setLength(aResults, aList.count); use for loop. set results[index] := e;
    aResults.Capacity := aList.Count;

    for var m in aList do
    begin
      var e: TEvaluation;
      e.Move := m;
      e.Score := 0;
      e.Factors := [];

      // set up the move info object and evaluate the factors
      i.Load(m, aTable);
      TEvaluator.EvaluateMove(i, e);

      aResults.Add(e);
    end;

  finally
    i.Free;
  end;
end;

class procedure TEvaluator.EvaluateMove(aMoveInfo: TMoveInfo; var aEval: TEvaluation);

  procedure setFactor(factor: TScoreFactor; isSet: Boolean);
  begin
    if isSet then
      Include(aEval.Factors, factor);
  end;

  // doesn't cheat
  function uncoveredCardIndex: Integer;
  begin
    Result := -1;
    case aMoveInfo.Source.Category of 
      scWaste:
        if aMoveInfo.Source.Stack.Count > 1 then
          Result := aMoveInfo.Source.Stack.Count - 2;
      scTableau:
        if aMoveInfo.Source.Stack.FaceUpCount > aMoveInfo.MoveCount then
          Result := aMoveInfo.Source.Stack.Count - aMoveInfo.MoveCount - 1;
    end;
  end;  

begin
  aEval.Factors := [];
  aEval.Features.Clear;

  // detect basic factors
  for var sf := Low(TScoreFactor) to High(TScoreFactor) do
  begin
    case sf of
      sfMoveToFoundation:
        setFactor(sf, aMoveInfo.Target.Category = scFoundation);

      sfBacktrack:
        setFactor(sf, aMoveInfo.Source.Category = scFoundation);

      sfUncoverFaceDown:
        setFactor(sf,
          (aMoveInfo.Source.Category = scTableau) and
          (aMoveInfo.MoveCount < aMoveInfo.Source.Stack.Count) and
          (aMoveInfo.MoveCount = aMoveInfo.Source.Stack.FaceUpCount)
        );

      sfUncoverTableau:
        setFactor(sf,
          (aMoveInfo.Source.Category = scTableau) and (aMoveInfo.MoveCount > 0) and
          (aMoveInfo.MoveCount < aMoveInfo.Source.Stack.FaceUpCount)
        );

      sfEmptyTableau:
        setFactor(sf,
          (aMoveInfo.Source.Category = scTableau) and
          (aMoveInfo.Source.Stack.Count = aMoveInfo.MoveCount) and
          (aMoveInfo.MoveCards.First.Value < cvKing)
        );

      sfKingToEmptyTableau:
        setFactor(sf,
          (aMoveInfo.Target.Category = scTableau) and
          aMoveInfo.Target.Stack.IsEmpty and
          (aMoveInfo.MoveCards.First.Value = cvKing)
        );

      sfBuildTableau:
        setFactor(sf, aMoveInfo.Target.Category = scTableau);

      sfNewWasteCard:
        setFactor(sf,
          (aMoveInfo.MoveType = mtDraw) or
          ((aMoveInfo.Source.Id = siWaste) and (aMoveInfo.Source.Stack.Count > 1))
        );

      sfWasteRemoval:
        setFactor(sf,
          (aMoveInfo.Source.Id = siWaste) and
          (aMoveInfo.Target.Category in [scFoundation, scTableau])
        );

      sfBlockedFoundation:
        setFactor(sf,
          (aMoveInfo.Target.Category = scTableau) and aMoveInfo.Target.Stack.HasCards and
          (aMoveInfo.NextFoundation[aMoveInfo.Target.Stack.Last.Suit] = aMoveInfo.Target.Stack.Last.Value)
        );


    end;
  end;

  // if the tableau could be emptied, we need to measure king pressure.
  if sfEmptyTableau in aEval.Factors then
  begin
    if aEval.Features.Pressure.king = -1 then
      aEval.Features.Pressure.king := aMoveInfo.ReadPressure(pgKing);
  end;

  // sfEnablesFoundation - Detect when the face-up card directly under the move card
  // can immediately be played to its foundation (not the same as pressure)
  if aMoveInfo.Source.Category in [scWaste, scTableau] then
  begin
    var cardIndex := unCoveredCardIndex();
    if (cardIndex >= 0) and (cardIndex < aMoveInfo.Source.Stack.Count) then
    begin
      var c := aMoveInfo.Source.Stack.Cards[cardIndex];
      if aMoveInfo.NextFoundation[c.Suit] = c.Value then
        Include(aEval.Factors, sfEnablesFoundation);
    end;
  end;

  // Evaluate individual features
  aEval.Features.MovedRunLength := aMoveInfo.MoveCount;

  // New build length at target: in Klondike, all face-up cards in tableau are a legal run
  if aMoveInfo.Target.Category = scTableau then
    aEval.Features.NewBuildLength := aMoveInfo.Target.Stack.FaceUpCount + aMoveInfo.MoveCount;

  // Residual run length at source: face-up count after move
  if aMoveInfo.Source.Category = scTableau then
    aEval.Features.SourceResidualRunLength := Max(0, aMoveInfo.Source.Stack.FaceUpCount - aMoveInfo.MoveCount);

  // Run destinations count
  if aMoveInfo.Target.Category = scTableau then
    aEval.Features.RunDestinationsCount := TTableQuery.OpenTableauDestinations(aMoveInfo.Table, aMoveInfo.MoveCards.First, aMoveInfo.Source.Id);

  // Source face-down distance delta
  // Explanation: how many fewer face-up cards are above the next face-down (if any)
  // after the move than before.
  if aMoveInfo.Source.Category = scTableau then
  begin
    var before := aMoveInfo.Source.Stack.FaceUpCount;
    var after := Max(0, before - aMoveInfo.MoveCount);
    aEval.Features.SourceFaceDownDistanceDelta := before - after;
  end;

  // Source stack depth: total cards in source stack
  aEval.Features.SourceStackDepth := aMoveInfo.Source.Stack.Count;

  // Source face-down count: face-down cards remaining after move
  if aMoveInfo.Source.Category = scTableau then
    aEval.Features.SourceFaceDownCount := Max(0, aMoveInfo.Source.Stack.Count - aMoveInfo.Source.Stack.FaceUpCount);

  // Target stack depth: total cards in target stack (for tie-breaking)
  aEval.Features.TargetStackDepth := aMoveInfo.Target.Stack.Count;
  
  // Track empty tableaus for urgency calculation
  aEval.Features.EmptyTableauCount := aMoveInfo.EmptyTableauCount;
  
  // Check for hidden King in the 2nd waste pile card when empty tableaus exist
  aEval.Features.HasHiddenKingInWaste := False;
  if (aEval.Features.EmptyTableauCount > 0) and
     (aMoveInfo.Table.Waste.Count >= 2) and            // At least 2 cards in waste
     (aMoveInfo.Source.Id = siWaste) then              // Only relevant for waste moves
  begin
    // Check if the 2nd card is a King
    if (aMoveInfo.Table.Waste.Cards[aMoveInfo.Table.Waste.Count - 2].Value = cvKing) then
      aEval.Features.HasHiddenKingInWaste := True;
  end;
      
  // Detect stack moves that can be deferred.
  if (aMoveInfo.MoveType = mtTableauToTableau) and (aMoveInfo.MoveCount >= 1) then
  begin
    // detect if this move doesn't accomplish anything
    var doesNothing :=
      (not (sfUncoverFaceDown in aEval.Factors)) and // no information gain
      (not (sfEnablesFoundation in aEval.Factors));  // no immediate potential

    // the other case to detect is the move of an entire tableau pile. if there
    // is no king pressure, this move can be delayed
    if (not doesNothing) and (sfEmptyTableau in aEval.Factors) then
    begin
      if aEval.Features.Pressure.king = -1 then
        aEval.Features.Pressure.king := aMoveInfo.ReadPressure(pgKing);

      // if there is NO pressure, then this move can be delayed
      doesNothing := aEval.Features.Pressure.king = 0;
    end;

    aEval.Features.CanBeDelayed := doesNothing;
  end;

  // Can reverse immediately: True if move leaves at least one face-up card on source tableau
  aEval.Features.CanReverseImmediately := (aMoveInfo.Source.Category = scTableau) and
    (aMoveInfo.MoveCount < aMoveInfo.Source.Stack.FaceUpCount);

  // Detects when less than all the face up cards are taken by the move
  aEval.Features.BrokeBuild :=
    (aMoveInfo.Source.Category = scTableau) and
    (aMoveInfo.MoveCount < aMoveInfo.Source.Stack.FaceUpCount);

  // Preserved run 
  aEval.Features.PreservedRun :=
    (aMoveInfo.Source.Category = scTableau) and
    (aMoveInfo.MoveCount = aMoveInfo.Source.Stack.FaceUpCount);
    
  // Detect oscillation-prone moves
  // These are moves where cards move between tableaus without making strategic progress
  aEval.Features.IsOscillationProne := 
    // Both source and target are tableaus
    (aMoveInfo.Source.Category = scTableau) and (aMoveInfo.Target.Category = scTableau) and
    // No face-down cards are uncovered
    (not (sfUncoverFaceDown in aEval.Factors)) and
    // Not enabling any foundation moves
    (not (sfEnablesFoundation in aEval.Factors)) and
    // Only including cases where:
    (
      // Case 1: Moving multiple cards as a run
      (aMoveInfo.MoveCount > 1) or
      // Case 2: Moving a single card that just uncovers another tableau card
      (sfUncoverTableau in aEval.Factors)
    );

  // allow the scoring layer to evaluate pressure during a backtrack move
  if (sfBacktrack in aEval.Factors) and (aEval.Features.Pressure.card = -1) then
    aEval.Features.Pressure.card := aMoveInfo.ReadPressure(pgCard);

  // if the move changes the waste, measure table pressure
  if sfNewWasteCard in aEval.Factors then
  begin
    aEval.Features.Pressure.table := aMoveInfo.ReadPressure(pgTable);

    // if we're removing a card there's a delta
    if sfWasteRemoval in aEval.Factors then
      aEval.Features.Pressure.reduces := true;

(*
WasteAdvance is bonus when Pressure is high (because exposing options matters).

WasteAdvance is neutral when Pressure is low (few cards left, info gain is weaker).
      *)

//
//    if (aMoveInfo.Source.Id = siWaste) and (aMoveInfo.MoveCount = 1) then
//      aEval.Features.Pressure.wasteDelta := -1;




  end;

end;

//  // sfUnblockKingSlot - if this move empties a tableau, then here we detect
//  // if there is a King immediately playable to the empty tableau. This means
//  // either a King on the top of the Waste stack, or a face-up King at any
//  // position in any tableau except the move source.
//  if (sfEmptyTableau in aEval.Factors) and
//    (aMoveInfo.MoveType in [mtTableauToTableau, mtTableauToFoundation]) and
//    (aMoveInfo.EmptyTableauCount = 0) then
//  begin
//    // check the waste pile for a king on top
//    if (not aMoveInfo.Table.Waste.IsEmpty) and
//      (aMoveInfo.Table.Waste.Last.Value = cvKing) then
//    begin
//      Include(aEval.Factors, sfUnblockKingSlot);
//    end
//    else
//    begin
//      // exclude the source stack, but the target stack is ok
//      var q: TCardQuery;
//      q.SearchArea := ALL_TABLEAUS;
//      Exclude(q.SearchArea, aMoveInfo.Source.Id);
//      q.SearchTable := aMoveInfo.Table;
//      q.SearchTarget.Value := cvKing;
//      q.SearchMinIndex := 1; // don't find kings at the base of a tableau already
//
//      if TTableQuery.FindCardValue(q) then
//      begin
//        Include(aEval.Factors, sfUnblockKingSlot);
//      end;
//    end;
//
//  end;



end.
