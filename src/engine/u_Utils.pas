unit u_Utils;

interface

uses u_Types;

{ type conversions/coercions }
function SuitToStackId(aSuit: TCardSuit): TStackId;
function StackIdToSuit(Id: TStackId): TCardSuit;
function StackIdToCategory(Id: TStackId): TStackCategory;
function OppositeColor(aColor: TCardColor): TCardColor;

{ record initializers }
function NewMove(aMove: TMove): TMove; overload;
function NewMove(aSource, aTarget: TStackId; aCount: Integer): TMove; overload;
function NewCard(aSuit: TCardSuit; aValue: TCardValue): TCard;
function NewSeed(const Name: string; Value: Integer): TSeed;


implementation

uses System.SysUtils;

// not useful unless id is known to be a foundation id
function StackIdToSuit(Id: TStackId): TCardSuit;
begin
  Result := TCardSuit( Ord(Id) - Ord(siFoundation1) );
end;

function SuitToStackId(aSuit: TCardSuit): TStackId;
begin
  Result := TStackId( Ord(siFoundation1) + Ord(aSuit) );
end;

function StackIdToCategory(Id: TStackId): TStackCategory;
begin
  case Id of
    siWaste: Result := scWaste;
    siFoundation1..siFoundation4: Result := scFoundation;
    siTableau1..siTableau7: Result := scTableau;
    else
      Result := scStock;
  end;
end;

function OppositeColor(aColor: TCardColor): TCardColor;
begin
  if aColor = ccRed then Result := ccBlack
  else Result := ccRed;
end;

function NewMove(aMove: TMove): TMove;
begin
  Result.Source := aMove.Source;
  Result.Target := aMove.Target;
  Result.Count := aMove.Count;
end;

function NewMove(aSource, aTarget: TStackId; aCount: Integer): TMove;
begin
  Result.Source := aSource;
  Result.Target := aTarget;
  Result.Count := aCount;
end;

function NewCard(aSuit: TCardSuit; aValue: TCardValue): TCard;
begin
  Result := (Ord(aSuit) * (Ord(High(TCardValue)) + 1)) + Ord(aValue);
end;

function NewSeed(const Name: string; Value: Integer): TSeed;
begin
  Result.Name := Name;
  Result.Value := Value;
end;


end.
