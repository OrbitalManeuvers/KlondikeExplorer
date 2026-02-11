unit u_Moves.Validators;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Cards,
  u_Tables,
  u_TableUtils;

type
  TValidator = class
    class function IsValidMove(aMove: TMove; aTable: TTable): Boolean;
  end;

implementation

uses System.Math,

  u_CardStacks,
  u_Moves.Analysis;

const
  LEGAL_MOVE_TARGETS: array[TStackCategory] of TStackCategories = (
  { Stock can move to }  [scWaste],
  { Waste can move to }  [scFoundation, scTableau, scStock],
  { Tabl  can move to }  [scTableau, scFoundation],
  { Found can move to }  [scTableau]
  );


type

  // base class
  TRule = class
    class function isValid(i: TMoveInfo): Boolean; virtual; abstract;
  end;
  TRuleClass = class of TRule;

  // rules per stack type, when it's the target of a move
  TTableauRules = class(TRule)
    class function isValid(i: TMoveInfo): Boolean; override;
  end;

  TFoundationRules = class(TRule)
    class function isValid(i: TMoveInfo): Boolean; override;
  end;

  TWasteRules = class(TRule)
    class function isValid(i: TMoveInfo): Boolean; override;
  end;

  TStockRules = class(TRule)
    class function isValid(i: TMoveInfo): Boolean; override;
  end;


// ------- Utils ------------------

// not useful unless id is known to be a foundation id
function IdToSuit(Id: TStackId): TCardSuit;
begin
  Result := TCardSuit( Ord(Id) - Ord(siFoundation1) );
end;

{ TForwardValidator }

class function TValidator.IsValidMove(aMove: TMove; aTable: TTable): Boolean;
const
  target_rules: array[TStackCategory] of TRuleClass = (
    { scStock }      TStockRules,
    { scWaste }      TWasteRules,
    { scTableau }    TTableauRules,
    { scFoundation } TFoundationRules
  );
var
  i: TMoveInfo;
begin
  Result := False;

  i := TMoveInfo.Create;
  try
    // populate move info structure
    i.Load(aMove, aTable);

    // check basic legality
    if not (i.Target.Category in LEGAL_MOVE_TARGETS[i.Source.Category]) then
      Exit;

    // if the move involves a count, make sure the target has enough cards
    if i.MoveCount > 0 then
    begin
      // a draw move is validated against the total of stock + waste.
      // the move might not contain these MoveCards, if a recycle is needed by the system
      if i.MoveType = mtDraw then
      begin
        if i.Table.Stock.Count + i.Table.Waste.Count < i.MoveCount then
          Exit;
      end
      else
      begin
        // all other move types require that the count matches
        if i.MoveCards.Count < i.MoveCount then
          Exit;
      end;
    end;

    // run target_rules
    var ruleClass := target_rules[i.Target.Category];
    if Assigned(ruleClass) then
    begin
      if not ruleClass.isValid(i) then
        Exit;
    end;

  finally
    i.Free;
  end;

  Result := True;
end;

{ TTableauRules - Tableau as target }

class function TTableauRules.isValid(i: TMoveInfo): Boolean;
begin
  Result := False;

  // -- this should not get generated
  if i.Source.Category = scTableau then
  begin
    Assert(i.MoveCount <= i.Source.Stack.FaceUpCount);
  end;

  // moving to an empty tableau requires a king at the base of the move list
  if i.Target.Stack.IsEmpty then
  begin
    // see if the Source list starts with a king
    if i.MoveCards[0].Value <> cvKing then
      Exit;
  end
  else
  begin
    // suit/color
    var faceUpCard := i.Target.Stack.Last;
    var firstMoveCard := i.MoveCards[0];

    if firstMoveCard.Color = faceUpCard.Color then
      Exit;

    // can't put anything onto an ace
    if faceUpCard.Value = cvAce then
      Exit;

    // so it has to be the next lowest card
    if firstMoveCard.Value <> Pred(faceUpCard.Value) then
      Exit;
  end;

  Result := True;
end;

{ TFoundationRules }

class function TFoundationRules.isValid(i: TMoveInfo): Boolean;
begin
  Result := False;

  // can only move 1 card at a time to a foundation pile
  if i.MoveCount <> 1 then
    Exit;

  // there's only one valid card per foundation pile
  var validSuit := IdToSuit(i.Target.Id);
  var validValue := cvAce;

  if i.Target.Stack.HasCards then
  begin
    var lastCard := i.Target.Stack.Last;
    if lastCard.Value = cvKing then
      Exit;
    validValue := Succ(lastCard.Value);
  end;

  if not i.MoveCards.Last.Equals(validValue, validSuit) then
    Exit;

  Result := True;
end;

{ TWasteRules }
class function TWasteRules.isValid(i: TMoveInfo): Boolean;
begin
  // Waste only accepts cards from Stock
  Result := i.Source.Id = siStock;
end;

{ TStockRules }
class function TStockRules.isValid(i: TMoveInfo): Boolean;
begin
  // Stock only accepts recycle moves
  Result := (i.Source.Id = siWaste) and (i.MoveCount = 0) and i.Table.Waste.HasCards;
end;



end.
