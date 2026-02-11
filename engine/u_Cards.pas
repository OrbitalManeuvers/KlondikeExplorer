unit u_Cards;

interface

uses System.Classes, System.SysUtils, System.JSON,

  u_Types;

type
  // access and human readable rendering. use snapshots for engineering
  TCardHelper = record helper for TCard
  private
    function GetJSON: TJSONObject;
  public
    function Value: TCardValue;
    function Suit: TCardSuit;
    function Color: TCardColor;
    function OppositeColor: TCardColor;
    property AsJSON: TJSONObject read GetJSON;
    function AsText: string;
    function AsTwoCode: string; // e.g. 5D
    function ValueName(isShort: Boolean = True): string;
    function SuitName(isShort: Boolean = True): string; overload;
    function SuitName(aSuit: TCardSuit; isShort: Boolean = True): string; overload;
    function Equals(aValue: TCardValue; aSuit: TCardSuit): Boolean; overload;
    function Equals(aValue: TCard): Boolean; overload;
    function Matches(aValue: TCardValue; aColor: TCardColor): Boolean; overload;
    function Matches(aDescriptor: TCardDescriptor): Boolean; overload;
  end;

implementation

const
  KEY_VALUE = 'value';
  KEY_SUIT = 'suit';

const
  long_suit_names: array[TCardSuit] of string = ('Hearts', 'Diamonds', 'Clubs', 'Spades');
  long_value_names: array[TCardValue] of string = ('Ace', 'Two', 'Three', 'Four', 'Five',
    'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Jack', 'Queen', 'King');

  short_suit_names: array[TCardSuit] of string = ('H', 'D', 'C', 'S');
  short_value_names: array[TCardValue] of string = ('A', '2', '3', '4', '5', '6', '7',
    '8', '9', 'T', 'J', 'Q', 'K');


{ TCardHelper }
function TCardHelper.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_VALUE, long_value_names[Value]);
  Result.AddPair(KEY_SUIT, long_suit_names[Suit]);
end;

function TCardHelper.AsText: string;
begin
  Result := long_value_names[Value] + ' of ' + long_suit_names[Suit];
end;

function TCardHelper.AsTwoCode: string;
begin
  Result := short_value_names[Value] + short_suit_names[Suit];
end;

function TCardHelper.Suit: TCardSuit;
begin
  Result := TCardSuit(Self div (Ord(High(TCardValue)) + 1));
end;

function TCardHelper.SuitName(aSuit: TCardSuit; isShort: Boolean): string;
begin
  if isShort then
    Result := short_suit_names[aSuit]
  else
    Result := long_suit_names[aSuit];
end;

function TCardHelper.SuitName(isShort: Boolean): string;
begin
  Result := Self.SuitName(Self.Suit, isShort);
end;

function TCardHelper.Value: TCardValue;
begin
  Result := TCardValue(Self mod (Ord(High(TCardValue)) + 1));
end;

function TCardHelper.ValueName(isShort: Boolean): string;
begin
  if isShort then
    Result := short_value_names[Value]
  else
    Result := long_value_names[Value];
end;

function TCardHelper.Color: TCardColor;
begin
  if Suit in [csHearts, csDiamonds] then
    Result := ccRed
  else
    Result := ccBlack;
end;

function TCardHelper.OppositeColor: TCardColor;
begin
  if Self.Color = ccRed then
    Result := ccBlack
  else
    Result := ccRed;
end;

function TCardHelper.Equals(aValue: TCard): Boolean;
begin
  Result := (Self.Value = aValue.Value) and (Self.Suit = aValue.Suit);
end;

function TCardHelper.Equals(aValue: TCardValue; aSuit: TCardSuit): Boolean;
begin
  Result := (Self.Value = aValue) and (Self.Suit = aSuit);
end;

function TCardHelper.Matches(aValue: TCardValue; aColor: TCardColor): Boolean;
begin
  Result := (Self.Color = aColor) and (Self.Value = aValue);
end;

function TCardHelper.Matches(aDescriptor: TCardDescriptor): Boolean;
begin
  Result := Self.Matches(aDescriptor.Value, aDescriptor.Color);
end;


end.
