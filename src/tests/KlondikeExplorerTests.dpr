program KlondikeExplorerTests;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Init,
  DUnitX.Loggers.Console,
  DUnitX.RunResults,
  DUnitX.TestRunner,
  u_CardPoolTests in 'u_CardPoolTests.pas',
  u_CardPools in '..\solvers\u_CardPools.pas',
  u_Types in '..\engine\u_Types.pas',
  u_Tables in '..\engine\u_Tables.pas',
  u_CardHelpers in '..\engine\u_CardHelpers.pas',
  u_SolverTypes in '..\solvers\u_SolverTypes.pas',
  u_MoveHelpers in '..\engine\u_MoveHelpers.pas',
  u_CardStacks in '..\engine\u_CardStacks.pas',
  u_Utils in '..\engine\u_Utils.pas',
  u_TableUtils in '..\engine\u_TableUtils.pas',
  u_SnapshotTests in 'u_SnapshotTests.pas',
  u_Dealers in '..\engine\u_Dealers.pas',
  u_Shufflers in '..\engine\u_Shufflers.pas',
  u_Snapshots in '..\engine\u_Snapshots.pas',
  u_SnapshotTypes in '..\engine\u_SnapshotTypes.pas',
  u_SolverTypesTests in 'u_SolverTypesTests.pas',
  u_TestUtils in 'u_TestUtils.pas',
  u_MoveExecutors in '..\engine\u_MoveExecutors.pas',
  u_MoveValidators in '..\engine\u_MoveValidators.pas',
  u_CanonicalState in '..\solvers\u_CanonicalState.pas',
  u_CanonicalStateTests in 'u_CanonicalStateTests.pas',
  u_MoveGenerators in '..\engine\u_MoveGenerators.pas',
  u_MoveGeneratorTests in 'u_MoveGeneratorTests.pas',
  u_MoveLists in '..\engine\u_MoveLists.pas';

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;

    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    runner.FailsOnNoAsserts := True;

    logger := TDUnitXConsoleLogger.Create(
      TDUnitX.Options.ConsoleMode = TDUnitXConsoleMode.Quiet);
    runner.AddLogger(logger);

    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := 1;

    // temp
//    readln;

  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
