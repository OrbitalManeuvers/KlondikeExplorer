unit u_CardStacks;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections,
  System.Generics.Defaults,

  u_Types;

type
  TCardStack = class
  private
    fFaceUpCount: Integer;
    fCards: TList<TCard>;

    fUpdateCount: Integer;
    fChanged: Boolean;
    fOnChange: TNotifyEvent;
    function GetCount: Integer;
    procedure SetCount(const Value: Integer);
    procedure SetCard(Index: Integer; const Value: TCard);

    type
      TEnumerator = class
      private
        fStack: TCardStack;
        fIndex: Integer;
      public
        constructor Create(aStack: TCardStack);
        function GetCurrent: TCard;
        function MoveNext: Boolean;
        property Current: TCard read GetCurrent;
      end;

    function GetCard(Index: Integer): TCard;
    procedure SetFaceUpCount(const Value: Integer);
  protected
  public
    constructor Create;
    destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Change;

    procedure Add(aCard: TCard);
    function First: TCard;
    function Last: TCard;
    procedure Clear;
    function IsEmpty: Boolean;
    function HasCards: Boolean; // for the grammatically inclined

    procedure GetLastCards(aList: TList<TCard>; aCount: Integer);
    procedure RemoveLastCards(aList: TList<TCard>; aCount: Integer);

    procedure AddFrom(aSource: TCardStack); overload;
    procedure AddFrom(aSource: TList<TCard>); overload;

    // content changers, not protected by begin/endupdate
    // caller responsible for updating face up count
    procedure _AddFrom(aSource: TCardStack); overload;
    procedure _AddFrom(aSource: TList<TCard>); overload;
    function _Pop: TCard;

    property Cards[Index: Integer]: TCard read GetCard write SetCard; default;
    property Count: Integer read GetCount write SetCount;
    property FaceUpCount: Integer read fFaceUpCount write SetFaceUpCount;
    property _Cards: TList<TCard> read fCards;

    property OnChange: TNotifyEvent read fOnChange write fOnChange;

    function GetEnumerator: TEnumerator;

  end;


implementation

uses System.Math;


{ TCardStack }

constructor TCardStack.Create;
begin
  inherited Create;
  fCards := TList<TCard>.Create;
end;

destructor TCardStack.Destroy;
begin
  fCards.Free;
  inherited;
end;

procedure TCardStack.Add(aCard: TCard);
begin
  fCards.Add(aCard);
  Change;
end;

procedure TCardStack.AddFrom(aSource: TList<TCard>);
begin
  BeginUpdate;
  try
    _AddFrom(aSource);
    Change;
  finally
    EndUpdate;
  end;
end;

procedure TCardStack.AddFrom(aSource: TCardStack);
begin
  BeginUpdate;
  try
    _AddFrom(aSource);
    Change;
  finally
    EndUpdate;
  end;
end;

procedure TCardStack.BeginUpdate;
begin
  Inc(fUpdateCount);
end;

procedure TCardStack.Change;
begin
  fChanged := True;
  if fUpdateCount = 0 then
  begin
    if Assigned(fOnChange) then
      fOnChange(Self);
    fChanged := False;
  end;
end;

procedure TCardStack.Clear;
begin
  fCards.Clear;
end;

procedure TCardStack._AddFrom(aSource: TCardStack);
begin
  for var c in aSource do
    fCards.Add(c);
  Change;
end;

procedure TCardStack._AddFrom(aSource: TList<TCard>);
begin
  for var c in aSource do
    fCards.Add(c);
  Change;
end;

function TCardStack._Pop: TCard;
begin
  if Count > 0 then
  begin
    Result := Last;
    Self.Count := Self.Count - 1;
    Change;
  end
  else
    raise EListError.Create('Invalid pop')
end;

procedure TCardStack.EndUpdate;
begin
  if fUpdateCount > 0 then
    Dec(fUpdateCount);

  if (fUpdateCount = 0) and fChanged then
    Change;
end;

function TCardStack.GetCard(Index: Integer): TCard;
begin
  Result := fCards[Index];
end;

function TCardStack.GetCount: Integer;
begin
  Result := fCards.Count;
end;

function TCardStack.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

procedure TCardStack.GetLastCards(aList: TList<TCard>; aCount:Integer);
begin
  if aCount <= Self.Count then
  begin
    for var i := Self.Count - aCount to Self.Count - 1 do
      aList.Add(Cards[i]);
  end;
end;

function TCardStack.IsEmpty: Boolean;
begin
  Result := fCards.IsEmpty;
end;

function TCardStack.HasCards: Boolean;
begin
  Result := fCards.Count > 0;
end;

procedure TCardStack.RemoveLastCards(aList: TList<TCard>; aCount:Integer);
begin
  GetLastCards(aList, aCount);
  Self.Count := Self.Count - aList.Count;
  Change;
end;

function TCardStack.Last: TCard;
begin
  if Count > 0 then
    Result := fCards[Count - 1]
  else
    raise EListError.Create('Invalid Last')
end;

function TCardStack.First: TCard;
begin
  if Count > 0 then
    Result := fCards[0]
  else
    raise EListError.Create('Invalid First')
end;

procedure TCardStack.SetCard(Index: Integer; const Value: TCard);
begin
  fCards[Index] := Value;
  Change;
end;

procedure TCardStack.SetCount(const Value: Integer);
begin
  fCards.Count := Value;
  Change;
end;

procedure TCardStack.SetFaceUpCount(const Value: Integer);
begin
  if Value <> fFaceUpCount then
  begin
    var newValue := Min(Count, Value); // can't be more than count
    fFaceUpCount := Max(0, newValue);  // or less than zero
    Change;
  end;
end;

{ TCardStack.TEnumerator }

constructor TCardStack.TEnumerator.Create(aStack: TCardStack);
begin
  inherited Create;
  fStack := aStack;
  fIndex := -1;
end;

function TCardStack.TEnumerator.GetCurrent: TCard;
begin
  Result := fStack.Cards[fIndex];
end;

function TCardStack.TEnumerator.MoveNext: Boolean;
begin
  Result := fIndex < fStack.Count - 1;
  if Result then
    Inc(fIndex);
end;

end.
