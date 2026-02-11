unit u_Moves.Scorers;

interface

uses System.Classes, System.Generics.Collections, System.Generics.Defaults,

  u_Types,
  u_EvalLists,
  u_Moves.Analysis;

type
  // standard scoring
  TScorer = class
  private
    class function ScoreFactors(const aFactors: TScoreFactors): Integer;
    class function ScoreFeatures(const aFeatures: TMoveFeatures): Integer;
    class function CalculateAdjustments(const aEval: TEvaluation): Integer;
  public
    class procedure AssignScores(aEvals: TEvalList);
  end;

implementation

const
  // Base scores for each factor - must include ALL TScoreFactor values
  FactorScores: array[TScoreFactor] of Integer = (
    100,  // sfMoveToFoundation
    75,   // sfEnablesFoundation
    -15,  // sfBacktrack
    50,   // sfUncoverFaceDown
    15,   // sfUncoverTableau
    40,   // sfEmptyTableau
    60,   // sfKingToEmptyTableau
    10,   // sfBuildTableau
    15,   // sfNewWasteCard  - a new opportunity appears after this move
    35,   // sfWasteRemoval - this move gives a card a permanent home.
    -20   // sfBlockedFoundation
  );

{ TScorer }

class procedure TScorer.AssignScores(aEvals: TEvalList);
begin
  for var i := 0 to aEvals.Count - 1 do
  begin
    var e: TEvaluation;
    e.Assign(aEvals[i]);

    var factorScore := TScorer.ScoreFactors(e.Factors);
    var featureScore := TScorer.ScoreFeatures(e.Features);

    e.Score := factorScore + featureScore;

    var adjustments := TScorer.CalculateAdjustments(e);
    e.Score := e.Score + adjustments;

    aEvals[i] := e;
  end;

  aEvals.Sort; //(comparer);

end;

class function TScorer.CalculateAdjustments(const aEval: TEvaluation): Integer;
begin
  Result := 0;

  // Apply heavy oscillation penalty
  if aEval.Features.IsOscillationProne then
  begin
    // Extreme penalty for moving a King-headed stack to an empty tableau
    if (sfKingToEmptyTableau in aEval.Factors) and (sfEmptyTableau in aEval.Factors) then
      Dec(Result, 200)  // Extreme penalty to ensure these moves are never chosen
    else
      Dec(Result, 80);  // Stronger penalty for other oscillation moves
  end;
  
  // Apply penalty for low urgency moves (tableau stack moves that can be safely deferred)
  if aEval.Features.CanBeDelayed then
  begin
    // Penalty unfluenced by the number of available empty tableaus
    // More empty tableaus = less urgency
    Dec(Result, aEval.Score + (aEval.Features.EmptyTableauCount * 5));
  end;
  
  // Context-sensitive reversibility penalty
  if aEval.Features.CanReverseImmediately then
  begin
    // Heavy penalty for reversible moves that don't accomplish much
    if (aEval.Features.NewBuildLength <= 2) and  // Short builds
       not (sfUncoverFaceDown in aEval.Factors) and  // No information gain
       not (sfEnablesFoundation in aEval.Factors) then  // No foundation setup
    begin
      Dec(Result, 30);  // Heavy penalty for likely oscillation moves
    end
    else
    begin
      Dec(Result, 10);  // Light penalty for productive reversible moves
    end;
  end;

  // look at sfNewWasteCard
  if sfNewWasteCard in aEval.Factors then
  begin
    // reducing table pressure is good
    if aEval.Features.Pressure.reduces then
      Inc(Result, 20);

    // the pressure is high this is even better
    if aEval.Features.Pressure.table > 19 then
      Inc(Result, 5)
    else if aEval.Features.Pressure.table < 6 then
      Dec(Result, 2);
  end;

  // what's the value of emptying a tableau right now?
  if (sfEmptyTableau in aEval.Factors) and aEval.Features.CanBeDelayed then
  begin
    // if there is king pressure this move is way more beneficial,
    // just remove the penalties
    if aEval.Features.Pressure.king > 0 then
      Result := 0;
  end;

  if sfWasteRemoval in aEval.Factors then
  begin
    if aEval.Features.HasHiddenKingInWaste then
      Inc(Result, 10);
  end;

  // evaluate backtrack with king pressure
  if sfBacktrack in aEval.Factors then
  begin
    if aEval.Features.Pressure.card > 0 then
      Inc(Result, 30)
    else
      Dec(Result, 40);
  end;

end;

class function TScorer.ScoreFactors(const aFactors: TScoreFactors): Integer;
begin
  Result := 0;
  
  for var factor := Low(TScoreFactor) to High(TScoreFactor) do
    if factor in aFactors then
      Inc(Result, FactorScores[factor]);
end;

class function TScorer.ScoreFeatures(const aFeatures: TMoveFeatures): Integer;
begin
  Result := 0;
  
  // Mobility and flexibility features
  if not aFeatures.CanBeDelayed then
  begin
    Inc(Result, aFeatures.NewBuildLength * 2);        // Longer builds = more mobility (reduced from 3)
    Inc(Result, aFeatures.RunDestinationsCount * 8);  // More destinations = better

    // Strategic positioning
    Inc(Result, aFeatures.MovedRunLength);            // Moving longer runs value (reduced from 2)
    Inc(Result, aFeatures.SourceResidualRunLength * 4); // Leaving behind runs is good

    // Information and reversibility
    Inc(Result, aFeatures.SourceFaceDownDistanceDelta * 6); // Getting closer to face-down cards


    // Tie-breaking features for depth and potential
    Inc(Result, aFeatures.SourceStackDepth);          // Deeper stacks preferred (1 point per card)
    Inc(Result, aFeatures.SourceFaceDownCount * 2);   // More face-down cards = more potential
    Inc(Result, aFeatures.TargetStackDepth);          // Prefer targets with more cards (more future potential)

    // Build structure preferences
    if aFeatures.PreservedRun then Inc(Result, 12);   // Moving intact runs is clean
    if aFeatures.BrokeBuild then Dec(Result, 8);      // Breaking builds has cost

  end;
//  if aFeatures.Pressure.reduces then Inc(Result, 10);

end;

end.
