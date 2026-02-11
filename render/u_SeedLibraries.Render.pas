unit u_SeedLibraries.Render;

interface

uses System.SysUtils, System.Generics.Collections, System.JSON,

  u_Types,
  u_SeedLibraries;

type
  TSeedLibraryHelper = class helper for TSeedLibrary
  private
    function GetJSON: TJSONArray;
    procedure SetJSON(const Value: TJSONArray);
  public
    property AsJSON: TJSONArray read GetJSON write SetJSON;
  end;

  TSeedHelper = record helper for TSeed
  private
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read GetJSON write SetJSON;
  end;

implementation

const
  KEY_NAME = 'name';
  KEY_VALUE = 'value';

{ TSeedHelper }

function TSeedHelper.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);
  Result.AddPair(KEY_VALUE, Value);
end;

procedure TSeedHelper.SetJSON(const Value: TJSONObject);
begin
  Value.TryGetValue(KEY_NAME, Name);
  Value.TryGetValue(KEY_VALUE, Self.Value);
end;

{ TSeedLibraryHelper }

function TSeedLibraryHelper.GetJSON: TJSONArray;
begin
  Result := TJSONArray.Create;

  for var i := 0 to Self.Count - 1 do
  begin
    var seed := Self.Seeds[i];
    var obj := seed.AsJSON;
    Result.Add(obj);
  end;
end;

procedure TSeedLibraryHelper.SetJSON(const Value: TJSONArray);
begin
  for var obj in Value do
  begin
    var seed: TSeed;
    seed.AsJSON := obj as TJSONObject;
    Self.Add(seed);
  end;
end;

end.
