program KlodikeExplorer;

uses
  Vcl.Forms,
  f_Main in 'ui\f_Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  fr_LogWindow in 'ui\fr_LogWindow.pas' {LogFrame: TFrame},
  u_Types in 'engine\u_Types.pas',
  u_Cards in 'engine\u_Cards.pas',
  u_Snapshots in 'engine\u_Snapshots.pas',
  u_CardStacks in 'engine\u_CardStacks.pas',
  u_Tables in 'engine\u_Tables.pas',
  u_Dealers in 'engine\u_Dealers.pas',
  u_UnitTests in 'tests\u_UnitTests.pas',
  fr_ContentFrame in 'ui\fr_ContentFrame.pas' {ContentFrame: TFrame},
  fr_TestFrame in 'ui\fr_TestFrame.pas' {TestFrame: TFrame},
  fr_EngineWorkbench in 'ui\fr_EngineWorkbench.pas' {EngineWorkbench: TFrame},
  u_CardStacks.Render in 'render\u_CardStacks.Render.pas',
  u_Tables.Render in 'render\u_Tables.Render.pas',
  u_SnapshotManagers in 'engine\u_SnapshotManagers.pas',
  u_SnapshotStorage in 'engine\u_SnapshotStorage.pas',
  u_Shufflers in 'engine\u_Shufflers.pas',
  u_SnapshotLibraries in 'ui\u_SnapshotLibraries.pas',
  u_SeedLibraries in 'ui\u_SeedLibraries.pas',
  fr_Session in 'ui\fr_Session.pas' {SessionFrame: TFrame},
  u_StateManagers in 'ui\u_StateManagers.pas',
  u_EvalLists in 'engine\u_EvalLists.pas',
  u_Heuristics in 'engine\u_Heuristics.pas',
  u_MoveLists in 'engine\u_MoveLists.pas',
  u_Moves.Executors in 'engine\u_Moves.Executors.pas',
  u_Moves.Generators in 'engine\u_Moves.Generators.pas',
  u_Moves.Scorers in 'engine\u_Moves.Scorers.pas',
  u_Moves.Validators in 'engine\u_Moves.Validators.pas',
  u_Moves.Analysis in 'engine\u_Moves.Analysis.pas',
  u_Moves.Evaluators in 'engine\u_Moves.Evaluators.pas',
  u_TableUtils in 'engine\u_TableUtils.pas',
  fr_Moves in 'ui\fr_Moves.pas' {MovesFrame: TFrame},
  fr_States in 'ui\fr_States.pas' {StateFrame: TFrame},
  fr_Table in 'ui\fr_Table.pas' {TableFrame: TFrame},
  u_Moves.Render in 'render\u_Moves.Render.pas',
  u_TableViewers in 'ui\u_TableViewers.pas',
  u_CardGraphicsIntf in 'ui\u_CardGraphicsIntf.pas',
  dm_Resources in 'ui\dm_Resources.pas' {ProgramResources: TDataModule},
  dm_CardImages in 'ui\dm_CardImages.pas' {dmCardImages: TDataModule},
  u_SnapshotServices.Intf in 'ui\u_SnapshotServices.Intf.pas',
  u_SnapshotTokens in 'engine\u_SnapshotTokens.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Klondike Explorer';
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TProgramResources, ProgramResources);
  Application.CreateForm(TProgramResources, ProgramResources);
  Application.Run;
end.
