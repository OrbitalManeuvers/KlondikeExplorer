unit u_SnapshotManagers;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

    u_Types,
    u_Snapshots,
    u_SnapshotStorage,
    u_SnapshotTypes;

type
  TSnapshotManager = class
  private
    fOnChange: TNotifyEvent;
    fStorage: TSnapshotStorage;
    procedure Change;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function Save(aSnapshot: TSnapshot): TSnapshotToken;
    procedure Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
    procedure Delete(aToken: TSnapshotToken);

    property Storage: TSnapshotStorage read fStorage;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
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

procedure TSnapshotManager.Change;
begin
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

procedure TSnapshotManager.Clear;
begin
  fStorage.Clear;
  Change;
end;

procedure TSnapshotManager.Delete(aToken: TSnapshotToken);
begin
  fStorage.ReleaseMem(aToken);
  Change;
end;

function TSnapshotManager.Save(aSnapshot: TSnapshot): TSnapshotToken;
begin
{$ifdef safety_net}
  if fStorage.Stats.Lists.TotalBlocks > 1000 then
  begin
    Assert(False, 'Safety net: ' + fStorage.Stats.AsText);
  end;
{$endif}

  var memToken := fStorage.AllocateMem;
  var P := fStorage.BufferOf(memToken);
  Move(aSnapshot.Buffer^, P^, SNAPSHOT_BUFFER_SIZE);

  Result := memToken;
  Change;
end;

procedure TSnapshotManager.Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
var
  P: PSnapshotBuffer;
begin
  P := fStorage.BufferOf(aToken);
  Move(P^, aSnapshot.Buffer^, SNAPSHOT_BUFFER_SIZE);
  Change;
end;


end.
