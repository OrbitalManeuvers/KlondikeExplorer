program KlondikeExplorer;

uses
  Vcl.Forms,
  u_Main in 'ui\u_Main.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  fr_ContentFrame in 'ui\fr_ContentFrame.pas' {ContentFrame: TFrame},
  fr_GameMode in 'ui\fr_GameMode.pas' {GameFrame: TFrame},
  fr_ExploreMode in 'ui\fr_ExploreMode.pas' {ExploreFrame: TFrame},
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
  u_DealGenerators in 'games\u_DealGenerators.pas',
  u_RenderUtils in 'display\u_RenderUtils.pas',
  u_Layouts in 'display\u_Layouts.pas',
  u_DisplayConsts in 'display\u_DisplayConsts.pas',
  u_HitTesters in 'display\u_HitTesters.pas',
  u_CardResources in 'display\u_CardResources.pas',
  u_HintAnimations in 'display\u_HintAnimations.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Klondike');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
