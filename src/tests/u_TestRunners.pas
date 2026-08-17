unit u_TestRunners;

interface

uses u_TestUnits, u_Logs, u_Tables, u_Snapshots, u_SnapshotManagers;

type
  TTestRunner = class
  private
    fLog: TLog; // not owned

  private
    fTable: TTable;
    fSnapshot: TSnapshot;
    fSnapshotManager: TSnapshotManager;

  public
    constructor Create(aLog: TLog);
    destructor Destroy; override;

  end;

implementation

uses u_SnapshotTests;

const
  ACTIVE_TESTS: array[1..1] of TTestUnitClass = (
    TSnapshotTests
  );

{ TTestRunner }

constructor TTestRunner.Create(aLog: TLog);
begin
  inherited Create;
  fLog := aLog;
end;

destructor TTestRunner.Destroy;
begin

  inherited;
end;

end.
