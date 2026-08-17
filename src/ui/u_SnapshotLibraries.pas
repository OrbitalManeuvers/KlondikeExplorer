unit u_SnapshotLibraries;

interface

uses System.Generics.Collections,
  u_Snapshots;

type
  TSnapshotEntry = record
    Name: string;
    Contents: string;
  end;

  TSnapshotLibrary = class
  private
    fEntries: TList<TSnapshotEntry>;
    fModified: Boolean;
    function GetCount: Integer;
    function GetName(I: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(const aName: string; aSnapshot: TSnapshot);
    function IndexOfName(const aName: string): Integer;
    procedure LoadSnapshot(I: Integer; aSnapshot: TSnapshot);
    procedure LoadFromFile(const aFileName: string);
    procedure SaveToFile(const aFileName: string);

    property Count: Integer read GetCount;
    property Names[I: Integer]: string read GetName;
    property Modified: Boolean read fModified;
  end;

implementation

uses System.SysUtils, System.IOUtils, System.JSON;

const
  KEY_NAME = 'name';
  KEY_CONTENTS = 'contents';

{ TSnapshotLibrary }

constructor TSnapshotLibrary.Create;
begin
  inherited Create;
  fEntries := TList<TSnapshotEntry>.Create;
end;

destructor TSnapshotLibrary.Destroy;
begin
  fEntries.Free;
  inherited;
end;

function TSnapshotLibrary.GetCount: Integer;
begin
  Result := fEntries.Count;
end;

function TSnapshotLibrary.GetName(I: Integer): string;
begin
  Result := fEntries[I].Name;
end;

procedure TSnapshotLibrary.Add(const aName: string; aSnapshot: TSnapshot);
var
  Entry: TSnapshotEntry;
begin
  Entry.Name := aName;
  Entry.Contents := aSnapshot.AsText;
  fEntries.Add(Entry);
  fModified := True;
end;

function TSnapshotLibrary.IndexOfName(const aName: string): Integer;
begin
  for var I := 0 to fEntries.Count - 1 do
    if fEntries[I].Name = aName then
      Exit(I);
  Result := -1;
end;

procedure TSnapshotLibrary.LoadSnapshot(I: Integer; aSnapshot: TSnapshot);
begin
  aSnapshot.AsText := fEntries[I].Contents;
end;

procedure TSnapshotLibrary.LoadFromFile(const aFileName: string);
var
  Json: string;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Entry: TSnapshotEntry;
begin
  fEntries.Clear;
  Json := TFile.ReadAllText(aFileName);
  Arr := TJSONObject.ParseJSONValue(Json) as TJSONArray;
  try
    for var I := 0 to Arr.Count - 1 do
    begin
      Obj := Arr.Items[I] as TJSONObject;
      Entry.Name := Obj.GetValue<string>(KEY_NAME);
      Entry.Contents := Obj.GetValue<string>(KEY_CONTENTS);
      fEntries.Add(Entry);
    end;
  finally
    Arr.Free;
  end;
end;

procedure TSnapshotLibrary.SaveToFile(const aFileName: string);
var
  Arr: TJSONArray;
  Obj: TJSONObject;
begin
  Arr := TJSONArray.Create;
  try
    for var I := 0 to fEntries.Count - 1 do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair(KEY_NAME, fEntries[I].Name);
      Obj.AddPair(KEY_CONTENTS, fEntries[I].Contents);
      Arr.AddElement(Obj);
    end;
    TFile.WriteAllText(aFileName, Arr.Format(2));
  finally
    Arr.Free;
  end;
  fModified := False;
end;

end.
