unit u_SeedLibraries;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections, System.JSON,
  u_Types;

type
  TSeedLibrary = class
  private
    fModified: Boolean;
    fSeeds: TList<TSeed>;
    function GetCount: Integer;
    function GetSeed(I: Integer): TSeed;
    procedure SetSeed(I: Integer; const Value: TSeed);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const aName: string; aValue: Integer); overload;
    procedure Add(aSeed: TSeed); overload;
    function IndexOf(const aName: string): Integer;

    property Count: Integer read GetCount;
    property Seeds[I: Integer]: TSeed read GetSeed write SetSeed; default;

    procedure LoadFrom(const JSON: TJSONValue);
    procedure SaveTo(const JSON: TJSONObject);

    property Modified: Boolean read fModified write fModified;
  end;


implementation

type
  { TSeedHelper }
  TSeedHelper = record helper for TSeed
  private
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read GetJSON write SetJSON;
  end;

const
  KEY_SEEDS = 'seeds';

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

{ TSeedLibrary }

constructor TSeedLibrary.Create;
begin
  inherited Create;
  fSeeds := TList<TSeed>.Create;
end;

destructor TSeedLibrary.Destroy;
begin
  fSeeds.Free;
  inherited;
end;

function TSeedLibrary.GetCount: Integer;
begin
  Result := fSeeds.Count;
end;

function TSeedLibrary.GetSeed(I: Integer): TSeed;
begin
  Result := fSeeds[I];
end;

procedure TSeedLibrary.Add(aSeed: TSeed);
begin
  fSeeds.Add(NewSeed(aSeed.Name, aSeed.Value));
  Modified := True;
end;

procedure TSeedLibrary.Add(const aName: string; aValue: Integer);
begin
  fSeeds.Add(NewSeed(aName, aValue));
  Modified := True;
end;

function TSeedLibrary.IndexOf(const aName: string): Integer;
begin
  Result := -1;
  for var i := 0 to Count - 1 do
    if SameText(aName, Seeds[i].Name) then
      Exit(i);
end;

procedure TSeedLibrary.LoadFrom(const JSON: TJSONValue);
begin
  var itemArray: TJSONArray;
  if JSON.TryGetValue(KEY_SEEDS, itemArray) then
  begin
    for var obj in itemArray do
    begin
      var seed: TSeed;
      obj.TryGetValue(KEY_NAME, seed.Name);
      obj.TryGetValue(KEY_VALUE, Seed.Value);
      fSeeds.Add(seed);
    end;
  end;

  Modified := False;
end;

procedure TSeedLibrary.SaveTo(const JSON: TJSONObject);
begin
  var itemArray := TJSONArray.Create;

  for var i := 0 to Self.Count - 1 do
  begin
    var seed := Self.Seeds[i];

    var obj := TJSONObject.Create;
    obj.AddPair(KEY_NAME, seed.Name);
    obj.AddPair(KEY_VALUE, seed.Value);
    itemArray.Add(obj);
  end;

  JSON.AddPair(KEY_SEEDS, itemArray);
  Modified := False;
end;

procedure TSeedLibrary.SetSeed(I: Integer; const Value: TSeed);
begin
  fSeeds[i] := NewSeed(Value.Name, Value.Value);
  Modified := True;
end;

end.
