unit u_TableUtils;

interface

uses
  u_Types,
  u_Tables;

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

  TCardQuery = record
    SearchTable: TTable;
    SearchArea: TStackIds;
    SearchTargetCard: TCard;
    SearchTargetValue: TCardValue;
    SearchMinIndex: Integer;

    FoundIndex: Integer; // >= 0 if found
    FoundIn: TStackId;   // only valid if found
    FoundCard: TCard;    // only valid if found
  end;

  TMatchQuery = record
    SearchTable: TTable;
    SearchArea: TStackIds;
    SearchValue: TCardValue;
  end;

  // fast scans, no cheating, only sees face up cards
  TTableQuery = class
  private type
    TMatchCardProc = reference to function(aTarget, aCandidate: TCard; aCandidateIndex: Integer): Boolean;
    TMatchValueProc = reference to function(aTargetValue: TCardValue; aCandidate: TCard; aCandidateIndex: Integer): Boolean;

    class procedure SearchStack(var Q: TCardQuery; Id: TStackId; Proc: TMatchCardProc);
  public
    class function FindCard(var aQuery: TCardQuery): Boolean;
    class function FindCardValue(var aQuery: TCardQuery): Boolean;
    class function CountCardValue(var aQuery: TCardQuery): Integer;

    class function OpenTableauDestinations(aTable: TTable; const aCard: TCard; aExclude: TStackId): Integer;
  end;

implementation

uses
  u_Cards;

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


{ TTableQuery }

class procedure TTableQuery.SearchStack(var Q: TCardQuery; Id: TStackId; Proc: TMatchCardProc);
begin
  Assert(Assigned(Proc));
  Q.FoundIndex := -1;

  var stack := Q.SearchTable.Stacks[Id];
  var startIndex := stack.Count - stack.FaceUpCount;

  if (startIndex < 0) or (startIndex >= stack.Count) then
    Exit;

  // we can only see from the first face-up card onwards
  for var cardIndex := startIndex to stack.Count - 1 do
  begin
    if cardIndex < Q.SearchMinIndex then
      Continue;
    var c := stack.Cards[cardIndex];
    if Proc(Q.SearchTargetCard, c, cardIndex) then
    begin
      Q.FoundIndex := cardIndex;
      Q.FoundIn := Id;
      Q.FoundCard := c;
      Break;
    end;
  end;

end;

// these two methods needs to be combined somehow :) The only difference is the callback function

class function TTableQuery.FindCard(var aQuery: TCardQuery): Boolean;
begin
  Result := False;
  aQuery.FoundIndex := -1;

  var i: TStackIterator;
  i.Init(Low(TStackId), High(TStackId));

  repeat
    if i.Current in aQuery.SearchArea then
    begin
      TTableQuery.SearchStack(aQuery, i.Current,
        function (aTarget, aCandidate: TCard; aCandidateIndex: Integer): Boolean
        begin
          Result := aCandidate.Equals(aTarget);
        end
      );

      Result := aQuery.FoundIndex >= 0;
      if Result then
        Exit;
    end;

  until not i.MoveNext;
end;

class function TTableQuery.CountCardValue(var aQuery: TCardQuery): Integer;
begin
  Result := 0;

  var i: TStackIterator;
  i.Init(Low(TStackId), High(TStackId));

  repeat
    if i.Current in aQuery.SearchArea then
    begin
      TTableQuery.SearchStack(aQuery, i.Current,
        function (aTarget, aCandidate: TCard; aCandidateIndex: Integer): Boolean
        begin
          Result := (aCandidate.Value = aTarget.Value);
        end
      );

      if aQuery.FoundIndex >= 0 then
        Inc(Result);

      if Result = 4 then
        Exit;
    end;

  until not i.MoveNext;
end;

class function TTableQuery.FindCardValue(var aQuery: TCardQuery): Boolean;
begin
  Result := False;

  var i: TStackIterator;
  i.Init(Low(TStackId), High(TStackId));

  repeat
    if i.Current in aQuery.SearchArea then
    begin
      TTableQuery.SearchStack(aQuery, i.Current,
        function (aTarget, aCandidate: TCard; aCandidateIndex: Integer): Boolean
        begin
          Result := (aCandidate.Value = aTarget.Value);
        end
      );

      Result := aQuery.FoundIndex >= 0;
      if Result then
        Exit;
    end;

  until not i.MoveNext;
end;

// how many tableau piles could accept this card immediately?
class function TTableQuery.OpenTableauDestinations(aTable: TTable; const aCard: TCard; aExclude: TStackId): Integer;
begin
  Result := 0;

  var i: TStackIterator;
  i.Init(siTableau1, siTableau7);
  repeat
    if i.Current <> aExclude then
    begin
      if aCard.Value = cvKing then
      begin
        if aTable.Stacks[i.Current].IsEmpty then
          Inc(Result);
      end
      else
      begin
        // since the source isn't a King, there needs to be cards here
        if aTable.Stacks[i.Current].HasCards then
        begin
          var last := aTable.Stacks[i.Current].Last;
          if (last.Value = Succ(aCard.Value)) and (last.Color <> aCard.Color) then
            Inc(Result);
        end;
      end;
    end;
  until not i.MoveNext;

end;



end.
