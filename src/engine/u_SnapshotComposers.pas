unit u_SnapshotComposers;

interface

uses System.Generics.Collections,
  u_Types, u_Snapshots, u_CardStacks, u_Tables;

type
  // hold a list of cards
  TDeckPool = class
  private
    fCards: TList<TCard>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PopulateFullDeck;
    procedure Remove(aCard: TCard); // exception if the card isn't found
    function TakeAny: TCard; // exception if none left
    property Count: Integer read GetCount;
  end;

  // each authored slot. Cards are bottom-to-top; the engine only stores a
  // contiguous top run of face-up cards, so face-up is a single count.
  TSlotSpec = record
    Stack: TStackId;
    Cards: TArray<TCard>;
    FaceUpCount: Integer;
  end;

  // the entire text payload
  TSpecification = record
    Slots: TArray<TSlotSpec>;
  end;

  TComposerResult = record
    Success: Boolean;
    Error: string;
    class function Ok: TComposerResult; static;
    class function Fail(const aError: string): TComposerResult; static;
  end;

  // stateless: parse text -> TSpecification
  TSpecParser = class
  public
    class function TryParseLine(const aLine: string; out aSlotSpec: TSlotSpec): TComposerResult;
    class function TryParseSpec(const aValue: string; out aSpec: TSpecification): TComposerResult;
  end;

  // instance: spec -> table
  TTableComposer = class
  private
    fPool: TDeckPool;
    procedure DealAny(aStack: TCardStack; aCount: Integer);
    function TryFindSlot(const aSpec: TSpecification; aStack: TStackId;
      out aSlotSpec: TSlotSpec): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Compose(const aSpec: TSpecification; aTable: TTable): TComposerResult;
  end;

  // stateless: caller's text -> parse -> compose table -> snapshot
  TSnapshotComposer = class
  public
    class function Compose(const aText: string; aSnapshot: TSnapshot): TComposerResult;
  end;


implementation

uses System.Classes, System.SysUtils, System.StrUtils,
  u_CardHelpers, u_Utils;

// helper functions
function TextToStackId(const value: string): TStackId;
const
  stack_names: array[TStackId] of string = ('st', 'wa', 't1', 't2', 't3', 't4', 't5', 't6', 't7', 'h', 'd', 'c', 's');
begin
  var index := System.StrUtils.IndexText(value, stack_names);
  Result := TStackId(index);
end;


{ TDeckPool }
constructor TDeckPool.Create;
begin
  inherited Create;
  fCards := TList<TCard>.Create;
end;

destructor TDeckPool.Destroy;
begin
  fCards.Free;
  inherited;
end;

function TDeckPool.GetCount: Integer;
begin
  Result := fCards.Count;
end;

procedure TDeckPool.Remove(aCard: TCard);
begin
  var index := fCards.IndexOf(aCard);
  Assert(index >= 0, 'card not in pool: ' + aCard.AsTwoCode);
  fCards.Delete(index);
end;

function TDeckPool.TakeAny: TCard;
begin
  Result := fCards.Last;
  fCards.Delete(fCards.Count - 1);
end;

procedure TDeckPool.PopulateFullDeck;
begin
  for var c := Low(TCard) to High(TCard) do
    fCards.Add(c);
end;


{ TComposeResult }

class function TComposerResult.Fail(const aError: string): TComposerResult;
begin
  Result := Default(TComposerResult);
  Result.Error := aError;
end;

class function TComposerResult.Ok: TComposerResult;
begin
  Result := Default(TComposerResult);
  Result.Success := True;
end;

{ TSnapshotComposer }

class function TSnapshotComposer.Compose(const aText: string; aSnapshot: TSnapshot): TComposerResult;
begin

  try
    // try to parse the spec, exit on fail
    var spec := Default(TSpecification);
    var parsed := TSpecParser.TryParseSpec(aText, spec);
    if not parsed.Success then
      Exit(TComposerResult.Fail(parsed.Error));

    var tableComposer := TTableComposer.Create;
    try
      var table := TTable.Create;
      try
        Result := tableComposer.Compose(spec, table);
        if Result.Success then
          aSnapshot.Capture(table);
      finally
        table.Free;
      end;

    finally
      tableComposer.Free;
    end;

  except
    on E: Exception do
    begin
      Result := TComposerResult.Fail(E.Message);
    end;
  end;

end;



{ TSpecParser }

class function TSpecParser.TryParseLine(const aLine: string; out aSlotSpec: TSlotSpec): TComposerResult;
begin
  aSlotSpec := Default(TSlotSpec);

  var parts := SplitString(aLine, ':');
  Assert(Length(parts) = 2);

  aSlotSpec.Stack := TextToStackId(parts[0]);

  if aSlotSpec.Stack in [siFoundation1..siFoundation4] then
  begin
    // foundations spec as a single card .Value
    // To parse this we'll take the suit character from a valid twocode for the same stack,
    // append that onto the user's text, and try to parse that as a twocode.
    var suit := u_Utils.StackIdToSuit(aSlotSpec.Stack);
    var ace := TCard.NewCard(cvAce, suit);
    var modelCardText := ace.AsTwoCode;

    var userCardText := parts[1] + modelCardText[2];
    var userCard: TCard;

    if TCard.TryParseTwoCode(userCardText, userCard) then
    begin
      // the cards that belong in this list are ace -> userCard
      // small protection against a wild loop
      Assert((userCard >= ace) and (userCard <= ace + 12));
      SetLength(aSlotSpec.Cards, (userCard - ace) + 1);
      for var c := ace to userCard do
        aSlotSpec.Cards[c - ace] := c;
      aSlotSpec.FaceupCount := Length(aSlotSpec.Cards);
    end;

  end
  else
  begin
    var cardList := SplitString(parts[1], ' ');
    for var cardName in cardList do
    begin
      var trimmed := Trim(cardName);
      if not trimmed.IsEmpty then
      begin
        // trailing '-' marks the card face down; strip it before parsing the twocode
        var faceDown := trimmed.EndsWith('-');
        if faceDown then
          trimmed := Trim(trimmed.Substring(0, trimmed.Length - 1));

        // face-up is a single contiguous top run: once a face-up card appears,
        // nothing beneath it (later in the list) may be face down.
        Assert(not (faceDown and (aSlotSpec.FaceUpCount > 0)), 'face-down card above a face-up card');

        var c: TCard;
        if TCard.TryParseTwoCode(trimmed, c) then
        begin
          var count := Length(aSlotSpec.Cards);
          SetLength(aSlotSpec.Cards, count + 1);
          aSlotSpec.Cards[count] := c;
          if not faceDown then
            Inc(aSlotSpec.FaceUpCount);
        end;
      end;
    end;
  end;
  Result := TComposerResult.OK;
end;

class function TSpecParser.TryParseSpec(const aValue: string; out aSpec: TSpecification): TComposerResult;
begin
  Result := TComposerResult.Fail('not yet implemented');
  // to-do

  aSpec := Default(TSpecification);
  var lines := TStringList.Create;
  try
    lines.Text := Trim(aValue);

    var stacks_seen: set of TStackId := [];

    // order is unimportant
    for var line in lines do
    begin
      var slotSpec := Default(TSlotSpec);
      Result := TryParseLine(Trim(line.ToUpper), slotSpec);
      if not Result.Success then
        Exit;

      // assert that this stack isn't in the set, then add it
      Assert(not (slotSpec.Stack in stacks_seen));
      Include(stacks_seen, slotSpec.Stack);

      var count := Length(aSpec.Slots);
      SetLength(aSpec.Slots, count + 1);
      aSpec.Slots[count] := slotSpec;
    end;

  finally
    lines.Free;
  end;

end;

{ TTableComposer }

constructor TTableComposer.Create;
begin
  inherited Create;
  fPool := TDeckPool.Create;
  fPool.PopulateFullDeck;
end;

destructor TTableComposer.Destroy;
begin
  // to-do
//  Assert(fPool.Count = 0, 'cards remaining');

  fPool.Free;
  inherited;
end;

// deal `aCount` arbitrary (don't-care) cards from the pool onto aStack
procedure TTableComposer.DealAny(aStack: TCardStack; aCount: Integer);
begin
  for var i := 1 to aCount do
    aStack.Add(fPool.TakeAny);
end;

// find the authored slot for a stack, if the user authored one
function TTableComposer.TryFindSlot(const aSpec: TSpecification; aStack: TStackId;
  out aSlotSpec: TSlotSpec): Boolean;
begin
  for var slot in aSpec.Slots do
    if slot.Stack = aStack then
    begin
      aSlotSpec := slot;
      Exit(True);
    end;
  Result := False;
end;

function TTableComposer.Compose(const aSpec: TSpecification; aTable: TTable): TComposerResult;
begin
  Result := TComposerResult.Fail('not implemented');

  // first step is to remove all the authored cards, plus any required cards. this leaves the pool
  // with everything else
  for var slot in aSpec.Slots do
  begin
    for var target in slot.Cards do
      fPool.Remove(target);
  end;

  // foundations first. All foundation cards are already removed from the pool.
  for var i := 0 to Length(aSpec.Slots) - 1 do
    if aSpec.Slots[i].Stack in [siFoundation1..siFoundation4] then
    begin
      var suit := StackIdToSuit(aSpec.Slots[i].Stack);
      for var c in aSpec.Slots[i].cards do
        aTable.Foundation[suit].Add(c);
      aTable.Foundation[suit].FaceUpCount := aTable.Foundation[suit].Count;
    end;

  // waste: two arbitrary cards, then the authored card on top
  for var i := 0 to Length(aSpec.Slots) - 1 do
    if aSpec.Slots[i].Stack = siWaste then
    begin
      DealAny(aTable.Waste, 2);
      aTable.Waste.Add(aSpec.Slots[i].Cards[0]);
      aTable.Waste.FaceUpCount := aTable.Waste.Count;
      Break;
    end;

  // tableaus: visit every column, authored or not, and make it look freshly
  // dealt. column k expects k cards. backfill face-down beneath the authored
  // cards up to the expected count, then place the authored cards on top.
  for var col := siTableau1 to siTableau7 do
  begin
    var expected := Ord(col) - Ord(siTableau1) + 1;
    var stack := aTable.Stacks[col];

    var slot: TSlotSpec;
    if TryFindSlot(aSpec, col, slot) then
    begin
      // backfill to the expected height if the pool can cover it, else just
      // place the authored cards (a short but valid column). authored overage
      // clamps to zero backfill.
      var backfill := expected - Length(slot.Cards);
      if (backfill > 0) and (fPool.Count >= backfill) then
        DealAny(stack, backfill);

      for var c in slot.Cards do
        stack.Add(c);
      stack.FaceUpCount := slot.FaceUpCount;
    end
    else
    begin
      // no authored cards: a plain fresh deal, top card face up
      if fPool.Count >= expected then
      begin
        DealAny(stack, expected);
        stack.FaceUpCount := 1;
      end;
    end;
  end;

  // stock last, after every other stack has claimed its cards. drain whatever
  // remains into the stock, then position the authored card 3rd from the top so
  // it surfaces on the waste after one draw (mtDraw pops up to 3).
  DealAny(aTable.Stock, fPool.Count);

  var stockSlot: TSlotSpec;
  if TryFindSlot(aSpec, siStock, stockSlot) then
    aTable.Stock._Cards.Insert(aTable.Stock.Count - 2, stockSlot.Cards[0]);

  Result := TComposerResult.Ok;
end;


end.
