unit u_Seeds.Render;

interface

uses System.JSON,

  u_Seeds;

type
  TSeedListJSONHelper = class helper for TSeedList
  private
    function GetJSON: TJSONArray;
    procedure SetJSON(const Value: TJSONArray);
  public
    property AsJSON: TJSONArray read GetJSON write SetJSON;
  end;

  TSeedJSONHelper = record helper for TSeed
  private
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read GetJSON write SetJSON;
  end;

implementation

uses System.Generics.Collections;

const
  KEY_NAME = 'name';
  KEY_VALUE = 'value';


{ TSeedJSONHelper }

function TSeedJSONHelper.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_VALUE, Value);
end;

procedure TSeedJSONHelper.SetJSON(const Value: TJSONObject);
begin
  Value.TryGetValue(KEY_NAME, Name);
  Value.TryGetValue(KEY_VALUE, Self.Value);

end;

{ TSeedsJSONHelper }

function TSeedListJSONHelper.GetJSON: TJSONArray;
begin
  Result := TJSONArray.Create;
  for var i := 0 to Count - 1 do
  begin
    var o := Seeds[i].AsJSON;
    Result.Add(o);
  end;
end;

procedure TSeedListJSONHelper.SetJSON(const Value: TJSONArray);
var
  obj: TJSONObject;
begin
  for var I := 0 to Value.Count - 1 do
  begin
    obj := Value.Items[i] as TJSONObject;
    var s: TSeed;
    s.AsJSON := obj;

    Self.Add(s);
  end;
end;


end.
