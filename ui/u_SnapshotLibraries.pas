unit u_SnapshotLibraries;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections,
  System.JSON,

  u_Types,
  u_Snapshots,
  u_SnapshotTokens,
  u_SnapshotManagers;

type
  TSnapshotLibrary = class
  private type
    TItem = record
      name: string;
      contents: string;
      token: TSnapshotToken;
    end;
  private
    fItems: TList<TItem>;
    fSnapshotManager: TSnapshotManager;
    fModified: Boolean;
    function GetCount: Integer;
    function GetName(AIndex: Integer): string;
    procedure SetName(AIndex: Integer; const Value: string);
    function GetToken(AIndex: Integer): TSnapshotToken;
  protected
    property SnapshotManager: TSnapshotManager read fSnapshotManager;
  public
    constructor Create(aSnapshotManager: TSnapshotManager);
    destructor Destroy; override;

    procedure Add(const aName: string; aToken: TSnapshotToken); overload;
    procedure Add(const aName: string; aSnapshot: TSnapshot); overload;
    procedure Add(const aName: string; const aContents: string); overload;

    function IndexOf(aName: string): Integer;
    procedure Load(aIndex: Integer; aSnapshot: TSnapshot);

    property Count: Integer read GetCount;
    property Names[AIndex: Integer]: string read GetName write SetName;
    property Tokens[AIndex: Integer]: TSnapshotToken read GetToken;

    procedure LoadFrom(const JSON: TJSONValue);
    procedure SaveTo(const JSON: TJSONObject);

    property Modified: Boolean read fModified write fModified;
  end;

implementation

const
  KEY_SNAPSHOTS = 'snapshots';

  KEY_NAME = 'name';
  KEY_CONTENTS = 'contents';

{ TSnapshotLibrary }

constructor TSnapshotLibrary.Create(aSnapshotManager: TSnapshotManager);
begin
  inherited Create;
  fSnapshotManager := aSnapshotManager;
  fItems := TList<TItem>.Create;
end;

destructor TSnapshotLibrary.Destroy;
begin
  fItems.Free;
  inherited;
end;

function TSnapshotLibrary.GetCount: Integer;
begin
  Result := fItems.Count;
end;

function TSnapshotLibrary.GetName(AIndex: Integer): string;
begin
  Result := fItems[AIndex].name;
end;

function TSnapshotLibrary.GetToken(AIndex: Integer): TSnapshotToken;
begin
  // not all snapshots in the library have tokens yet, so check for needing to create one
  var item := fItems[AIndex];

  if item.token = NO_SNAPSHOT then
  begin
    Assert(item.contents <> '');
    var s := TSnapshot.Create;
    try
      s.AsText := item.contents;
      item.token := fSnapshotManager.Save(s);
      fItems[AIndex] := item;
    finally
      s.Free;
    end;
  end;

  Result := item.token;

  Assert(Result <> NO_SNAPSHOT); // we shouldn't leave here empty handed
end;

function TSnapshotLibrary.IndexOf(aName: string): Integer;
begin
  for var i := 0 to fItems.Count - 1 do
  begin
    if SameText(fItems[i].name, aName) then
      Exit(i);
  end;
  Result := -1;
end;

procedure TSnapshotLibrary.Add(const aName: string; aToken: TSnapshotToken);
begin
  var i: TItem;
  i.name := aName;
  i.token := aToken;
  i.contents := '';
  fItems.Add(i);
  Modified := True;
end;

procedure TSnapshotLibrary.Add(const aName: string; aSnapshot: TSnapshot);
begin
  var token := fSnapshotManager.Save(aSnapshot);
  Add(aName, token);
end;

procedure TSnapshotLibrary.Add(const aName: string; const aContents: string);
begin
  var i: TItem;
  i.name := aName;
  i.token := NO_SNAPSHOT;
  i.contents := aContents;
  fItems.Add(i);
  Modified := True;
end;

procedure TSnapshotLibrary.Load(aIndex: Integer; aSnapshot: TSnapshot);
begin
  fSnapshotManager.Load(fItems[aIndex].token, aSnapshot);
end;

procedure TSnapshotLibrary.LoadFrom(const JSON: TJSONValue);
begin
  var itemArray: TJSONArray;

  if JSON.TryGetValue(KEY_SNAPSHOTS, itemArray) then
  begin
    for var obj in itemArray do
    begin
      var nameStr: string;
      var contentStr: string;
      obj.TryGetValue(KEY_NAME, nameStr);
      obj.TryGetValue(KEY_CONTENTS, contentStr);

      if (not nameStr.IsEmpty) and (not contentStr.IsEmpty) then
      begin
        Add(nameStr, contentStr);
      end;
    end;
  end;

  Modified := False;
end;

procedure TSnapshotLibrary.SaveTo(const JSON: TJSONObject);
begin
  Assert(Assigned(fSnapshotManager));

  var snapshot := TSnapshot.Create;
  try

    var itemArray := TJSONArray.Create;

    for var item in fItems do
    begin

      var contentStr := item.contents;
      if (contentStr = '') and (item.token <> NO_SNAPSHOT) then
      begin
        fSnapshotManager.Load(item.token, snapshot);
        contentStr := snapshot.AsText;
      end;

      var itemObject := TJSONObject.Create;
      try
        itemObject.AddPair(KEY_NAME, item.name);
        itemObject.AddPair(KEY_CONTENTS, contentStr);
        itemArray.Add(itemObject);
      except
        itemObject.Free;
        raise;
      end;
    end;

    JSON.AddPair(KEY_SNAPSHOTS, itemArray);

  finally
    snapshot.Free;
  end;
  Modified := True;
end;

procedure TSnapshotLibrary.SetName(AIndex: Integer; const Value: string);
begin
  var i := fItems[AIndex];
  i.name := Value;
  fItems[AIndex] := i;
  Modified := True;
end;


end.
