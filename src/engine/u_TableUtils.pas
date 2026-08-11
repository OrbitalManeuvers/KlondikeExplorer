unit u_TableUtils;

interface

uses u_Types, u_Tables;

type
  // usage: i.init(); repeat dostuff(i.current); until not i.movenext;
  TStackIterator = record
  strict private
    fEnd: TStackId;
  public
    Current: TStackId;
    procedure Init(aStart, aEnd: TStackId);
    function MoveNext: Boolean;
  end;

function IsNextFoundationCard(aCard: TCard; aTable: TTable): Boolean;
function FindTableauTarget(aCard: TCard; aTable: TTable; out aStackId: TStackId): Boolean;

implementation

uses u_CardHelpers, u_Utils;

function IsNextFoundationCard(aCard: TCard; aTable: TTable): Boolean;
begin
  // there is no next if there's already a king there
  if aTable.Foundation[aCard.Suit].HasCards and (aTable.Foundation[aCard.Suit].Last.Value = cvKing) then
    Exit(False);

  var required := cvAce;
  if aTable.Foundation[aCard.Suit].HasCards then
    required := Succ(aTable.Foundation[aCard.Suit].Last.Value);
  Result := aCard.Value = required;
end;

function FindTableauTarget(aCard: TCard; aTable: TTable; out aStackId: TStackId): Boolean;
begin
  Result := False;

  var stack: TStackIterator;
  stack.Init(siTableau1, siTableau7);
  repeat
    aStackId := stack.Current;

    // king can only go to an empty tableau
    if aCard.Value = cvKing then
    begin
      if aTable.Stacks[stack.Current].IsEmpty then
      begin
        Exit(True);
      end;
    end
    else if aTable.Stacks[stack.Current].HasCards then
    begin
      var curTop := aTable.Stacks[stack.Current].Last;
      if (curTop.Color = aCard.OppositeColor) and (curTop.Value = Succ(aCard.Value)) then
      begin
        Exit(True);
      end;
    end;

  until not stack.MoveNext;
end;

{ TStackIterator }
procedure TStackIterator.Init(aStart, aEnd: TStackId);
begin
  Current := aStart;
  fEnd := aEnd;
  Assert(fEnd > Current);
end;

function TStackIterator.MoveNext: Boolean;
begin
  Result := Current < fEnd;
  if Result then
    Inc(Current);
end;

end.
