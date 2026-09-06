unit u_HintValidators;

interface

uses u_MoveHelpers;

type
  THintValidator = class
    class function IsValidHint(aMoveInfo: TMoveInfo): Boolean;
  end;

implementation

uses u_Types, u_CardHelpers;

{ helper functions }

function IsUsefulTableauMove(aMoveInfo: TMoveInfo): Boolean;
begin
  Result := False;

  var source := aMoveInfo.Source.Stack;
  var faceDownCount := source.Count - source.FaceUpCount;

  { A tableau->tableau move is already legal; the only question is whether it makes
    progress. What matters is what the move leaves behind at the SOURCE, since the
    target side is validated. There are three ways it earns a hint. }

  // (1) info reveal: taking the whole face-up run flips a face-down card underneath
  if (aMoveInfo.MoveCount = source.FaceUpCount) and (faceDownCount > 0) then
    Exit(True);

  // (2) useful space: taking the WHOLE column only helps if a King can fill it.
  //     a King already leading the run is just shuffling between empties - no progress.
  if (aMoveInfo.MoveCount = source.Count) then
  begin
    if (aMoveInfo.MoveCards[0].Value < cvKing) and aMoveInfo.KingAvailable then
      Exit(True);
    // whole-column move that isn't a useful space is nothing else either
    Exit(False);
  end;

  // (3) enables foundation: cards remain face up, so the move exposes the card
  //     directly beneath the run. useful if that card is next for its foundation.
  if source.FaceUpCount > aMoveInfo.MoveCount then
  begin
    var exposed := source.Cards[source.Count - aMoveInfo.MoveCount - 1];

    // twin trap: if the target's top is the exposed card's twin, the exposed card
    // has the same options the moved run did - a lateral shuffle, not progress,
    // unless the exposed card is itself next for a foundation.
    if aMoveInfo.Target.Stack.HasCards
      and aMoveInfo.Target.Stack.Last.IsTwin(exposed)
      and (aMoveInfo.NextFoundation[exposed.Suit] <> exposed.Value) then
      Exit(False);

    Result := aMoveInfo.NextFoundation[exposed.Suit] = exposed.Value;
  end;
end;


function IsUsefulFoundationMove(aMoveInfo: TMoveInfo): Boolean;
begin
  Assert(aMoveInfo.Source.Stack.HasCards);
  Assert(aMoveInfo.Source.Stack.Last.Value <> cvKing);

  Result := False;

  { This hint is based on the principle that you cannot win a game while there are cards in the waste/stock system.
    Therefore, removing a card from the waste can be more positive than removing a card from the foundation is negative.
    Leave it up to the player, but it's a hint.

    My hypothesis: if you never exclude this type of move there are some deals you cannot solve.

    By virtual of mtFoundationToTableau existing, we know:

    - foundation card = Pred(tableau card)
    - foundation card.color <> tableau card.color

    Therefore, if
    - waste card = Pred(foundation card)
    - waste card.color <> foundation card.color

    then the waiting waste card could be played on top of the foundation card, and this might
    be the only chance the player has to remove the waste card, so it's a hint
  }

  // must be a card waiting
  if not aMoveInfo.Table.Waste.HasCards then
    Exit;

  // must be a non-King waiting
  var wasteCard := aMoveInfo.Table.Waste.Last;
  if wasteCard.Value = cvKing then
    Exit;

  var foundationCard := aMoveInfo.MoveCards[0];
  Result := (Ord(wasteCard) = Pred(foundationCard)) and (wasteCard.Color = foundationCard.OppositeColor);
end;

{ THintValidator }

class function THintValidator.IsValidHint(aMoveInfo: TMoveInfo): Boolean;
begin
  case aMoveInfo.MoveType of
    // stock/waste cycling: always a legal fallback hint
    mtDraw, mtRecycle:
      Result := True;

    // anything reaching a foundation is real progress
    mtWasteToFoundation, mtTableauToFoundation:
      Result := True;

    // pulling a card back off a foundation is a regression, never suggest it
    mtFoundationToTableau:
      Result := IsUsefulFoundationMove(aMoveInfo);

    // playing off the waste is worthwhile - except an Ace, which belongs home
    mtWasteToTableau:
      Result := (aMoveInfo.MoveCards.Count > 0)
        and (aMoveInfo.MoveCards[0].Value <> cvAce);

    // the hard case - a tableau shuffle only earns a hint if it accomplishes something
    mtTableauToTableau:
      Result := IsUsefulTableauMove(aMoveInfo);
  else
    Result := False;
  end;
end;

end.
