unit u_SnapshotManagers;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

    u_Types,
    u_Snapshots,
    u_SnapshotStorage,
    u_SnapshotTokens;

const
  MAX_SNAPSHOTS = 1000; // low during dev


type
  TSnapshotManager = class
  private
    fStorage: TSnapshotStorage;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function Save(aSnapshot: TSnapshot): TSnapshotToken;
    procedure Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
    procedure Delete(aToken: TSnapshotToken);

    property Storage: TSnapshotStorage read fStorage;
  end;

implementation

{ TSnapshotManager }
constructor TSnapshotManager.Create;
begin
  inherited Create;
  fStorage := TSnapshotStorage.Create;
  Clear;
end;

destructor TSnapshotManager.Destroy;
begin
  Clear;
  fStorage.Free;
  inherited;
end;

procedure TSnapshotManager.Clear;
begin
  fStorage.Clear;
end;

procedure TSnapshotManager.Delete(aToken: TSnapshotToken);
begin
  fStorage.ReleaseMem(aToken);
end;

function TSnapshotManager.Save(aSnapshot: TSnapshot): TSnapshotToken;
begin
  var memToken := fStorage.AllocateMem;
  var P := fStorage.BufferOf(memToken);
  Move(aSnapshot.Buffer^, P^, SNAPSHOT_BUFFER_SIZE);

  Result := memToken;
end;

procedure TSnapshotManager.Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
var
  P: PSnapshotBuffer;
begin
  P := fStorage.BufferOf(aToken);
  Move(P^, aSnapshot.Buffer^, SNAPSHOT_BUFFER_SIZE);
end;


end.
