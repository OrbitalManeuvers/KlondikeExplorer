unit u_SnapshotServices.Intf;

interface

uses
  u_Snapshots,
  u_SnapshotTokens;

type
  ISnapshotServices = interface
    ['{68CC7486-4C5C-4A9F-95EB-7317F38F76E3}']

    // standard load/save
    function Save(aSnapshot: TSnapshot): TSnapshotToken;
    procedure Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
    procedure Delete(aToken: TSnapshotToken);

    // creating new snapshots
    function GetLibrarySaveName(var snapshotName: string): Boolean;
    function SaveToLibrary(const aName: string; aToken: TSnapshotToken): Boolean;
  end;

implementation

end.
