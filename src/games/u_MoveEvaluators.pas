unit u_MoveEvaluators;

interface

uses u_Types, u_MoveHelpers, u_CardStacks;

type
  // things a move can accomplish that make it worth suggesting as a hint.
  // we only ever reward good features - a move with none simply scores 0
  // and never enters the hint ring.
  TMoveFeature = (
    mfImmediateProgress,  // lands a card on a foundation
    mfEnablesFoundation,  // exposes a card that could now go straight to a foundation
    mfInfoReveal,         // uncovers a face-down tableau card
    mfUsefulSpace,        // empties a column while a King is waiting to use it
    mfKingToEmptyTableau, // parks a King in an empty column
    mfWasteRelief,        // moves a card off the waste onto a tableau
    mfBookkeeping         // stock/waste mgmt
  );
  TMoveFeatures = set of TMoveFeature;

  TMoveEvaluator = class
  private
    // is a King available (waste top or face-up in a tableau) to occupy a new space?
    // excludes aExceptStack so a column can't count itself.
    class function KingAvailable(aMoveInfo: TMoveInfo; aExceptStack: TCardStack): Boolean;
  public
    // classify a loaded move into its earned features
    class function Classify(aMoveInfo: TMoveInfo): TMoveFeatures;
    // roll the features up into a single score; higher = better hint, 0 = not a hint
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
    2,  // mfUsefulSpace  (only ever counts when a King can use the space)
    3,  // mfKingToEmptyTableau
    2,  // mfWasteRelief
    1   // mfBookkeeping
  );

{ TMoveEvaluator }

class function TMoveEvaluator.KingAvailable(aMoveInfo: TMoveInfo;
  aExceptStack: TCardStack): Boolean;
begin
  // a King on top of the waste can fill a space
  if aMoveInfo.Table.Waste.HasCards and (aMoveInfo.Table.Waste.Last.Value = cvKing) then
    Exit(True);

  // ...or any face-up King in a tableau (other than the column we're emptying)
  for var t := Low(TTableauIndex) to High(TTableauIndex) do
  begin
    var pile := aMoveInfo.Table.Tableau[t];
    if (pile = aExceptStack) or pile.IsEmpty then
      Continue;
    for var idx := pile.Count - pile.FaceUpCount to pile.Count - 1 do
      if pile.Cards[idx].Value = cvKing then
        Exit(True);
  end;

  Result := False;
end;

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

  // --- waste relief: playing a card off the waste onto a tableau is always
  //     slightly worthwhile (it exposes the next waste card and un-stalls the
  //     stock cycle). waste->foundation already scores via mfImmediateProgress.
  //     an Ace is the exception: it belongs on a foundation, so dropping it onto
  //     a tableau is never the right play.
  if (aMoveInfo.MoveType = mtWasteToTableau)
    and (aMoveInfo.MoveCards.Count > 0)
    and (aMoveInfo.MoveCards[0].Value <> cvAce) then
    Include(Result, mfWasteRelief);

  // --- king to an empty column: parks a King where it can anchor a build ---
  if (aMoveInfo.Target.Category = scTableau)
    and aMoveInfo.Target.Stack.IsEmpty
    and (aMoveInfo.MoveCards.Count > 0)
    and (aMoveInfo.MoveCards[0].Value = cvKing) then
    Include(Result, mfKingToEmptyTableau);

  // the source pile only matters for reveal/space questions when it's a tableau
  if aMoveInfo.Source.Category = scTableau then
  begin
    var source := aMoveInfo.Source.Stack;

    // --- useful space: emptying a column ONLY counts when a King can use it. ---
    // no King available => the move is a pointless shuffle => no credit (note 1).
    // a King-led stack relocating to another empty column is excluded by the
    // (bottom < King) guard: it wouldn't be emptying a column with cards beneath.
    if (aMoveInfo.MoveCount = source.Count)
      and (aMoveInfo.MoveCards[0].Value < cvKing) then
    begin
      if KingAvailable(aMoveInfo, source) then
        Include(Result, mfUsefulSpace);
    end
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
  // the moved run at the source.
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

    // --- twin trap (note 5): a tableau->tableau move that exposes a face-up card
    //     whose twin already sits on top of the target is a lateral shuffle - the
    //     exposed card has the same options the one we just moved did. It's only
    //     worthwhile if that exposed card is itself next for its foundation.
    var twinTrap := False;
    if (aMoveInfo.MoveType = mtTableauToTableau)
      and aMoveInfo.Target.Stack.HasCards
      and aMoveInfo.Target.Stack.Last.IsTwin(exposed)
      and (aMoveInfo.NextFoundation[exposed.Suit] <> exposed.Value) then
      twinTrap := True;

    if not twinTrap and (aMoveInfo.NextFoundation[exposed.Suit] = exposed.Value) then
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
