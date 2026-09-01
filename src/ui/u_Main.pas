unit u_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdActns, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.AppEvnts, Vcl.Tabs,

  u_SnapshotLibraries, u_SnapshotManagers, fr_TableFrames, u_Snapshots,
  fr_ContentFrames, fr_ResetFrames, fr_SolutionFrames, fr_GraphFrames,
  fr_StateFrames, fr_MoveFrames, u_StateManagers,
  u_SaveFiles, u_Games, u_Types, u_Tables;

type
  TMainForm = class(TForm)
    MainMenu: TActionMainMenuBar;
    MainActions: TActionManager;
    actFileExit: TFileExit;
    actOpenGame: TFileOpen;
    actSaveGameAs: TFileSaveAs;
    actSaveGame: TAction;
    actTests: TAction;
    actAbout: TAction;
    StatusBar: TStatusBar;
    actNewGame: TAction;
    LeftColumn: TPanel;
    LeftColumnSplitShape: TShape;
    LeftColumnBorderShape: TShape;
    CenterColumn: TPanel;
    VSplitter: TSplitter;
    RightColumn: TPanel;
    RightColumnSplitShape: TShape;
    HSplitter: TSplitter;
    procedure actOpenGameAccept(Sender: TObject);
    procedure actSaveGameAsAccept(Sender: TObject);
    procedure actSaveGameExecute(Sender: TObject);
    procedure actTestsExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure actNewGameExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    Game: TKlondikeGame;
    Table: TTable;
    InitialState: TSnapshot;
    SaveFile: TSaveFile;
    SnapshotManager: TSnapshotManager;
    SnapshotLibrary: TSnapshotLibrary;
    StateManager: TStateManager;
    ContentFrames: TList<TContentFrame>;

    ResetFrame: TResetFrame;
    SolutionFrame: TSolutionFrame;
    TableFrame: TTableFrame;
    GraphFrame: TGraphFrame;
    StateFrame: TStateFrame;
    MoveFrame: TMoveFrame;
    function SnapshotLibraryFileName(): string;
//    procedure UpdateControls;
    procedure RestartTo(aSnapshot: TSnapshot);
    procedure SyncTableFromGame;
    procedure HandleSnapshotManagerChange(Sender: TObject);
    procedure HandleGameStateChanged(Sender: TObject);
    procedure HandleResetFrameRestart(Sender: TObject; NewState: TSnapshot);
    procedure HandleTableAction(Sender: TObject; aTableAction: TTableAction);
    procedure HandleCardClick(Sender: TObject; aStackId: TStackId; aCardIndex: Integer);
    procedure HandleMoveRequested(Sender: TObject; aRequestedMove: TMove; aRequestedAnimate: Boolean);

    procedure InitContentFrames;
    procedure DoneContentFrames;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils, Vcl.Themes,
  u_MoveValidators;


{ Utility }
function RuntimeFilePath(const aFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), aFileName);
end;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  Game := TKlondikeGame.Create(SnapshotManager);
  Game.OnStateChanged := HandleGameStateChanged;
  Table := TTable.Create;
  InitialState := TSnapshot.Create;

  SnapshotManager := TSnapshotManager.Create;
  SnapshotManager.OnChange := HandleSnapshotManagerChange;

  SnapshotLibrary := TSnapshotLibrary.Create;
  var fileName := SnapshotLibraryFileName();
  if TFile.Exists(fileName) then
    SnapshotLibrary.LoadFromFile(fileName);

  StateManager := TStateManager.Create(SnapshotManager);

  ContentFrames := TList<TContentFrame>.Create;
  InitContentFrames;

  // update the status bar
  HandleSnapshotManagerChange(nil);

  SaveFile := TSaveFile.Create; // this is currently nothing
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  SaveFile.Free;

  DoneContentFrames;

  SnapshotManager.OnChange := nil;

  if SnapshotLibrary.Modified then
  begin
    var fileName := SnapshotLibraryFileName();
    SnapshotLibrary.SaveToFile(fileName);
  end;

  Table.Free;
  InitialState.Free;
  Game.Free;

  StateManager.Free;
  SnapshotLibrary.Free;
  SnapshotManager.Free;
end;

procedure TMainForm.InitContentFrames;
begin
  // LeftColumn
  ResetFrame := TResetFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  ResetFrame.Align := alTop;
  ResetFrame.Parent := LeftColumn;
  ResetFrame.OnRestart := HandleResetFrameRestart;
  ResetFrame.InitContent;
  ContentFrames.Add(ResetFrame);

  LeftColumnSplitShape.Align := alTop;
  LeftColumnSplitShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);
  LeftColumnBorderShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);

  SolutionFrame := TSolutionFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  SolutionFrame.Align := alClient;
  SolutionFrame.Parent := LeftColumn;
  SolutionFrame.InitContent;
  ContentFrames.Add(SolutionFrame);

  // CenterColumn
  MoveFrame := TMoveFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  MoveFrame.Align := alBottom;
  MoveFrame.Parent := CenterColumn;
  MoveFrame.InitContent;
  ContentFrames.Add(MoveFrame);

  HSplitter.Align := alBottom;

  StateFrame := TStateFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  StateFrame.Align := alClient;
  StateFrame.Parent := CenterColumn;
  StateFrame.InitContent;
  StateFrame.StateManager := StateManager;
  ContentFrames.Add(StateFrame);

  // RightColumn
  GraphFrame := TGraphFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  GraphFrame.Align := alBottom;
  GraphFrame.Parent := RightColumn;
  GraphFrame.InitContent;
  ContentFrames.Add(GraphFrame);

  RightColumnSplitShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);
  RightColumnSplitShape.Align := alBottom;

  TableFrame := TTableFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  TableFrame.Align := alClient;
  TableFrame.Parent := RightColumn;
  TableFrame.InitContent;
  TableFrame.PreviewMode := True;

  TableFrame.OnTableAction := HandleTableAction;
  TableFrame.OnMoveRequested := HandleMoveRequested;
  TableFrame.OnCardClick := HandleCardClick;

  ContentFrames.Add(TableFrame);

end;

procedure TMainForm.DoneContentFrames;
begin
  for var f in ContentFrames do
    f.DoneContent;
  ContentFrames.Free;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 //
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  //
  if SaveFile.Modified then
  begin
    //
  end;

end;

procedure TMainForm.RestartTo(aSnapshot: TSnapshot);
begin
  if aSnapshot <> InitialState then
    InitialState.Assign(aSnapshot);

  Game.Initialize(InitialState);
  TableFrame.ShowState(InitialState);
  InitialState.Restore(Table);

  StateManager.Clear;
  StateManager.CreateInitialState(InitialState);
end;

procedure TMainForm.HandleResetFrameRestart(Sender: TObject; NewState: TSnapshot);
begin
  RestartTo(NewState);
end;

procedure TMainForm.HandleSnapshotManagerChange(Sender: TObject);
begin
  if Assigned(SnapshotManager) then
    StatusBar.SimpleText := SnapshotManager.Storage.Stats.AsText;
end;

procedure TMainForm.HandleGameStateChanged(Sender: TObject);
begin
  var actions: TTableActions := [taHint, taRestart, taSnapshot];
  if Game.CanUndo then
    Include(actions, taUndo);
  if Game.CanRedo then
    Include(actions, taRedo);
  if Game.CanAutoComplete then
    Include(actions, taComplete);

  TableFrame.ValidActions := actions;
end;

procedure TMainForm.SyncTableFromGame;
begin
  var snapshot := TSnapshot.Create;
  try
    snapshot.Capture(Game.Table);
    snapshot.Restore(Table);
    TableFrame.ShowState(snapshot);
  finally
    snapshot.Free;
  end;
end;

procedure TMainForm.HandleTableAction(Sender: TObject; aTableAction: TTableAction);
begin
  case aTableAction of
    taHint:
      begin
        var hintMove: TMove;
        if Game.GetNextHint(hintMove) then
          TableFrame.ShowHintMove(hintMove);
      end;
    taUndo: begin Game.Undo; SyncTableFromGame; end;
    taRedo: begin Game.Redo; SyncTableFromGame; end;
    taComplete: ;
    taRestart: RestartTo(InitialState);
    taSnapshot: ;
  end;
end;

procedure TMainForm.HandleCardClick(Sender: TObject; aStackId: TStackId; aCardIndex: Integer);
begin
  var m := Default(TMove);
  if Game.GetAutoMove(aStackId, aCardIndex, m) then
    HandleMoveRequested(nil, m, True);
end;

procedure TMainForm.HandleMoveRequested(Sender: TObject; aRequestedMove: TMove; aRequestedAnimate: Boolean);
begin
  if TMoveValidator.IsValidMove(aRequestedMove, Game.Table) and Game.TryExecuteMove(aRequestedMove) then
  begin
    // animating or not, we need to capture the new state
    var newState := TSnapshot.Create;
    try
      newState.Capture(Game.Table);

      // if we're animating then send over the old state too, and the table will update itself after
      // the animation completes
      if aRequestedAnimate then
      begin
        var oldState := TSnapshot.Create;
        try
          oldState.Capture(Table); // where we haven't executed the move yet
          TableFrame.AnimateAndShowMove(oldState, newState, aRequestedMove);
        finally
          oldState.Free;
        end;
      end
      else
      begin
        // otherwise just adopt the new state and update the view
        newState.Restore(Table);
        TableFrame.ShowState(newState);
      end;
    finally
      newState.Free;
    end;

  end;

end;


function TMainForm.SnapshotLibraryFileName: string;
begin
  Result := RuntimeFilePath('snapshot_library.json');
end;

//procedure TMainForm.UpdateControls;
//begin
// //
//end;

procedure TMainForm.actAboutExecute(Sender: TObject);
begin
  //
end;

procedure TMainForm.actNewGameExecute(Sender: TObject);
begin
  //
end;

procedure TMainForm.actOpenGameAccept(Sender: TObject);
begin
  //
end;

procedure TMainForm.actSaveGameAsAccept(Sender: TObject);
begin
  //
end;

procedure TMainForm.actSaveGameExecute(Sender: TObject);
begin
  //
end;

procedure TMainForm.actTestsExecute(Sender: TObject);
begin
  //
end;



end.
