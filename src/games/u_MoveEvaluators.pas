unit u_MoveEvaluators;

interface

uses u_Types, u_MoveHelpers, u_CardStacks;

type
  // things a move can accomplish that make it worth ranking as a hint. the evaluator
  // is pure reward: eligibility (whether a move should be a hint at all) is decided
  // upstream by THintValidator, so every move that reaches here is already a good hint
  // and we only score how good it is relative to its peers.
  TMoveFeature = (
    mfImmediateProgress,  // lands a card on a foundation
    mfEnablesFoundation,  // exposes a card that could now go straight to a foundation
    mfInfoReveal,         // uncovers a face-down tableau card
    mfUsefulSpace,        // empties a column (validator ensures a King can use it)
    mfKingToEmptyTableau, // parks a King in an empty column
    mfWasteRelief,        // moves a card off the waste onto a tableau
    mfBookkeeping         // stock/waste mgmt
  );
  TMoveFeatures = set of TMoveFeature;

  TMoveEvaluator = class
  public
    // classify a loaded move into its earned features
    class function Classify(aMoveInfo: TMoveInfo): TMoveFeatures;
    // roll the features up into a single score for ranking; higher = better hint
    class function Score(aMoveInfo: TMoveInfo): Integer;
  end;

implementation

uses u_CardHelpers;

const
  // per-feature weights. tuned so combos float to the top under a plain sum:
  // a reveal-that-also-frees-an-ace outranks a bare reveal with no tiering logic.
  FeatureScores: array[TMoveFeature] of Integer = (
    5,  // mfImmediateProgress
    3,  // mfEnablesFoundation  (sets up progress rather than making it)
    4,  // mfInfoReveal
    2,  // mfUsefulSpace
    3,  // mfKingToEmptyTableau
    2,  // mfWasteRelief
    1   // mfBookkeeping
  );

{ TMoveEvaluator }

class function TMoveEvaluator.Classify(aMoveInfo: TMoveInfo): TMoveFeatures;
begin
  Result := [];

  // a stock/waste cycle move is only ever bookkeeping - it can't meaningfully earn
  // any tableau/foundation/waste feature, so classify and bail. this also prevents
  // downstream features from misfiring on a draw (e.g. an Ace turning up on the waste).
  if aMoveInfo.MoveType in [mtDraw, mtRecycle] then
  begin
    Include(Result, mfBookkeeping);
    Exit;
  end;

  // --- immediate progress: anything reaching a foundation ---
  if aMoveInfo.MoveType in [mtWasteToFoundation, mtTableauToFoundation] then
    Include(Result, mfImmediateProgress);

  // --- waste relief: playing a card off the waste onto a tableau exposes the next
  //     waste card and un-stalls the stock cycle. waste->foundation already scores
  //     via mfImmediateProgress. (the validator rejects an Ace onto a tableau, so we
  //     don't guard against it here.)
  if aMoveInfo.MoveType = mtWasteToTableau then
    Include(Result, mfWasteRelief);

  // --- king to an empty column: parks a King where it can anchor a build ---
  if (aMoveInfo.Target.Category = scTableau)
    and aMoveInfo.Target.Stack.IsEmpty
    and (aMoveInfo.MoveCards[0].Value = cvKing) then
    Include(Result, mfKingToEmptyTableau);

  // the source pile only matters for reveal/space questions when it's a tableau
  if aMoveInfo.Source.Category = scTableau then
  begin
    var source := aMoveInfo.Source.Stack;

    // --- useful space: emptying a column. the validator only admits a whole-column
    //     move when a King can actually use the space, so reaching here means it's
    //     already worthwhile - we simply recognize and reward it.
    if aMoveInfo.MoveCount = source.Count then
      Include(Result, mfUsefulSpace)
    // --- info reveal: taking the full face-up run exposes a face-down card ---
    // (mutually exclusive with emptying the column: if we took every card there's
    //  nothing left to reveal)
    else if (aMoveInfo.MoveCount = source.FaceUpCount)
      and (source.Count - source.FaceUpCount > 0) then
      Include(Result, mfInfoReveal);
  end;

  // --- enables foundation: the card this move newly exposes can go straight home ---
  // distinct from mfImmediateProgress (which is the move itself reaching a foundation);
  // this rewards setting up the next play. the exposed card is the one directly under
  // the moved run at the source. (the validator has already screened out the twin-trap
  // lateral shuffle, so a foundation-ready exposed card is unambiguous reward here.)
  var uncoveredIndex := -1;
  case aMoveInfo.Source.Category of
    scWaste:
      if aMoveInfo.Source.Stack.Count > 1 then
        uncoveredIndex := aMoveInfo.Source.Stack.Count - 2;
    scTableau:
      if aMoveInfo.Source.Stack.FaceUpCount > aMoveInfo.MoveCount then
        uncoveredIndex := aMoveInfo.Source.Stack.Count - aMoveInfo.MoveCount - 1;
  end;

  if uncoveredIndex >= 0 then
  begin
    var exposed := aMoveInfo.Source.Stack.Cards[uncoveredIndex];
    if aMoveInfo.NextFoundation[exposed.Suit] = exposed.Value then
      Include(Result, mfEnablesFoundation);
  end;
end;

class function TMoveEvaluator.Score(aMoveInfo: TMoveInfo): Integer;
begin
  Result := 0;
  var features := Classify(aMoveInfo);
  for var f := Low(TMoveFeature) to High(TMoveFeature) do
    if f in features then
      Inc(Result, FeatureScores[f]);
end;

end.
