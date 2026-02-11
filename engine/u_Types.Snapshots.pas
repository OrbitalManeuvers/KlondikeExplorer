unit u_Types.Snapshots;

interface

uses
  u_Snapshots;

type
  TSnapshotToken = Cardinal;

  ISnapshotManager = interface
    ['{BDAD9161-E74B-41FE-AB13-292BA6EE79C7}']
    function SaveSnapshot(aSnapshot: TSnapshot): TSnapshotToken;
    procedure LoadSnapshot(aToken: TSnapshotToken; aSnapshot: TSnapshot);
    procedure DeleteSnapshot(aToken: TSnapshotToken);
  end;

const
  INVALID_SNAPSHOT: TSnapshotToken = 0;

implementation

end.
