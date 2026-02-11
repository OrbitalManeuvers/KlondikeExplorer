unit u_CardStacks.Render;

interface

uses System.SysUtils, System.Generics.Collections, System.JSON,

  u_Types,
  u_Cards,
  u_CardStacks;

type
  TCardStackHelper = class helper for TCardStack
  private
    function GetJSON: TJSONObject;
  public
    property AsJSON: TJSONObject read GetJSON;
    function AsText: string;
  end;

  TListOfCardHelper = class helper for TList<TCard>
  private
    function GetJSON: TJSONArray;
  public
    property AsJSON: TJSONArray read GetJSON;
    function AsString: string;
  end;

implementation

const
  KEY_FACEUP = 'faceUp';
  KEY_CARDS = 'cards';


{ TListOfCardHelper }
function TListOfCardHelper.AsString: string;
begin
  Result := '';
  for var c in Self do
    Result := Result + c.AsTwoCode;
end;

function TListOfCardHelper.GetJSON: TJSONArray;
begin
  Result := TJSONArray.Create;
  for var c in Self do
    Result.Add(c.AsTwoCode);
end;


{ TCardStackHelper }

function TCardStackHelper.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_FACEUP, FaceUpCount);
  Result.AddPair(KEY_CARDS, _Cards.AsString);
end;

function TCardStackHelper.AsText: string;
begin
  if _Cards.Count = 0 then Result := ''
  else Result := FaceUpCount.ToHexString(1) + ':' + _Cards.AsString;
end;

end.
