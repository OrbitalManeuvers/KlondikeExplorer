unit u_TestUnits;

interface

uses u_Types, u_Tables, u_Snapshots, u_SnapshotManagers, u_Logs;

type
  TTestResult = (trPass, trFail);

  TTestUnit = class
  private
    // assets come from owner
    fTable: TTable;
    fSnapshot: TSnapshot;
    fSnapshotManager: TSnapshotManager;
    fLog: TLog;
    fTestResult: TTestResult;
    procedure LogTestBegin;
    procedure LogTestResult;
  protected
    function TestId: string; virtual; abstract;
    procedure ExecuteTest; virtual; abstract;
    property Table: TTable read fTable;
    property Snapshot: TSnapshot read fSnapshot;
    property SnapshotManager: TSnapshotManager read fSnapshotManager;

    // log is accessible if needed, but descendants should use logging helpers
    property _Log: TLog read fLog;

    // logging helpers
    procedure Log(const aName, aValue: string);
    procedure LogError(const Msg: string);

  public
    procedure Execute(aTable: TTable; aSnapshot: TSnapshot;
      aSnapshotManager: TSnapshotManager; aLog: TLog);
    property TestResult: TTestResult read fTestResult;
  end;

  TTestUnitClass = class of TTestUnit;

implementation

uses u_LogTypes;

{ TTestUnit }

procedure TTestUnit.Execute(aTable: TTable; aSnapshot: TSnapshot;
  aSnapshotManager: TSnapshotManager; aLog: TLog);
begin
  fTable := aTable;
  fSnapshot := aSnapshot;
  fSnapshotManager := aSnapshotManager;

  fTestResult := trPass;
  LogTestBegin;
  try
    ExecuteTest;
  finally
    LogTestResult;
  end;
end;

procedure TTestUnit.Log(const aName, aValue: string);
begin
  _Log.Add(ekTestDetail, aName + ': ' + aValue);
end;

procedure TTestUnit.LogError(const Msg: string);
begin
  fTestResult := trFail;
  _Log.Add(ekTestError, Msg);
end;

procedure TTestUnit.LogTestBegin;
begin
  _Log.Add(ekTestBegin, TestId);
end;

procedure TTestUnit.LogTestResult;
const
  result_text: array[TTestResult] of string = ('Passed', 'Failed');
begin
  _Log.Add(ekTestSummary, TestId + ': ' + result_text[fTestResult]);
end;

end.
