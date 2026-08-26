program KlondikeExplorer;

uses
  Vcl.Forms,
  u_Main in 'ui\u_Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  fr_TableView in 'ui\fr_TableView.pas' {TableView: TFrame},
  u_Types in 'engine\u_Types.pas',
  u_MoveHelpers in 'engine\u_MoveHelpers.pas',
  u_Utils in 'engine\u_Utils.pas',
  u_SeedHelpers in 'engine\u_SeedHelpers.pas',
  u_CardHelpers in 'engine\u_CardHelpers.pas',
  u_CardStacks in 'engine\u_CardStacks.pas',
  u_Tables in 'engine\u_Tables.pas',
  u_SnapshotTypes in 'engine\u_SnapshotTypes.pas',
  u_SnapshotStorage in 'engine\u_SnapshotStorage.pas',
  u_Snapshots in 'engine\u_Snapshots.pas',
  u_SnapshotManagers in 'engine\u_SnapshotManagers.pas',
  u_MoveLists in 'engine\u_MoveLists.pas',
  u_MoveGenerators in 'engine\u_MoveGenerators.pas',
  u_TableUtils in 'engine\u_TableUtils.pas',
  u_MoveExecutors in 'engine\u_MoveExecutors.pas',
  u_Dealers in 'engine\u_Dealers.pas',
  u_Shufflers in 'engine\u_Shufflers.pas',
  u_MoveValidators in 'engine\u_MoveValidators.pas',
  u_TableDisplays in 'display\u_TableDisplays.pas',
  u_GameDisplays in 'display\u_GameDisplays.pas',
  u_AnimationTypes in 'display\u_AnimationTypes.pas',
  u_Animations in 'display\u_Animations.pas',
  u_Games in 'games\u_Games.pas',
  u_RenderUtils in 'display\u_RenderUtils.pas',
  u_Layouts in 'display\u_Layouts.pas',
  u_DisplayConsts in 'display\u_DisplayConsts.pas',
  u_HitTesters in 'display\u_HitTesters.pas',
  u_CardResources in 'display\u_CardResources.pas',
  u_HintAnimations in 'display\u_HintAnimations.pas',
  u_AnimationHelpers in 'display\u_AnimationHelpers.pas',
  u_IconResources in 'display\u_IconResources.pas',
  u_FontIconResources in 'display\u_FontIconResources.pas',
  u_FlybackAnimations in 'display\u_FlybackAnimations.pas',
  u_MoveAnimations in 'display\u_MoveAnimations.pas',
  u_Heuristics in 'engine\u_Heuristics.pas',
  u_Solvers in 'solvers\u_Solvers.pas',
  u_ObserverTypes in 'solvers\u_ObserverTypes.pas',
  u_Observers in 'solvers\u_Observers.pas',
  u_SolverTypes in 'solvers\u_SolverTypes.pas',
  u_BasicSolvers in 'solvers\u_BasicSolvers.pas',
  u_LogTypes in 'tests\u_LogTypes.pas',
  u_Logs in 'tests\u_Logs.pas',
  u_TestRunners in 'tests\u_TestRunners.pas',
  u_TestUnits in 'tests\u_TestUnits.pas',
  u_SnapshotTests in 'tests\u_SnapshotTests.pas',
  u_SnapshotLibraries in 'ui\u_SnapshotLibraries.pas',
  u_HintGenerators in 'games\u_HintGenerators.pas',
  u_AStarSolvers in 'solvers\u_AStarSolvers.pas',
  u_DealCreators in 'games\u_DealCreators.pas',
  u_SolvableDealCreators in 'games\u_SolvableDealCreators.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
