unit u_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdActns, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.StdCtrls,
  System.Generics.Collections, Vcl.AppEvnts, Vcl.Tabs,

  u_SnapshotLibraries, u_SnapshotManagers, fr_TableFrames, u_Snapshots,
  fr_ContentFrames, fr_ResetFrames, fr_GraphFrames,
  fr_StateFrames, fr_MoveFrames, u_StateManagers,
  u_SaveFiles, u_Types, u_Tables;

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
    InitialState: TSnapshot;
    SaveFile: TSaveFile;
    SnapshotManager: TSnapshotManager;
    SnapshotLibrary: TSnapshotLibrary;
    StateManager: TStateManager;
    Snapshot: TSnapshot;
    ContentFrames: TList<TContentFrame>;

    ResetFrame: TResetFrame;
    TableFrame: TTableFrame;
    GraphFrame: TGraphFrame;
    StateFrame: TStateFrame;
    MoveFrame: TMoveFrame;
    function SnapshotLibraryFileName(): string;
    procedure RestartTo(aSnapshot: TSnapshot);
    procedure HandleSnapshotManagerChange(Sender: TObject);
    procedure HandleResetFrameRestart(Sender: TObject; NewState: TSnapshot);
    procedure HandleTableAction(Sender: TObject; aTableAction: TTableAction);
    procedure HandleCardClick(Sender: TObject; aStackId: TStackId; aCardIndex: Integer);
    procedure HandleMoveRequested(Sender: TObject; aRequestedMove: TMove; aRequestedAnimate: Boolean);
      procedure ProposeMove(Sender: TObject; const aMove: TMove; out aValid: Boolean; out aTargetCount: Integer);

    procedure HandleCursorChange(Sender: TObject; aNode: TStateNode; aIsStep: Boolean);
    procedure HandleMoveSelected(Sender: TObject; aMoveIndex: Integer);
    procedure HandleStateNavigate(Sender: TObject; aNode: TStateNode);

    procedure SaveSnapshotPrompt;

    procedure InitContentFrames;
    procedure DoneContentFrames;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils, Vcl.Themes,
  u_MoveValidators, d_SaveSnapshotDlg, u_Heuristics, u_Authors;


{ Utility }
function RuntimeFilePath(const aFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), aFileName);
end;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  InitialState := TSnapshot.Create;

  SnapshotManager := TSnapshotManager.Create;
  SnapshotManager.OnChange := HandleSnapshotManagerChange;

  SnapshotLibrary := TSnapshotLibrary.Create;
  var fileName := SnapshotLibraryFileName();
  if TFile.Exists(fileName) then
    SnapshotLibrary.LoadFromFile(fileName);

  Snapshot := TSnapshot.Create; // working snapshot

  StateManager := TStateManager.Create(SnapshotManager);
  StateManager.OnCursorChange := HandleCursorChange;

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

  InitialState.Free;
  Snapshot.Free;

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

  // CenterColumn
  MoveFrame := TMoveFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  MoveFrame.Align := alBottom;
  MoveFrame.Parent := CenterColumn;
  MoveFrame.InitContent;
  MoveFrame.OnMoveSelected := HandleMoveSelected;
  ContentFrames.Add(MoveFrame);

  HSplitter.Align := alBottom;

  StateFrame := TStateFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  StateFrame.Align := alClient;
  StateFrame.Parent := CenterColumn;
  StateFrame.InitContent;
  StateFrame.StateManager := StateManager;
  StateFrame.OnNavigate := HandleStateNavigate;
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
  TableFrame.OnProposeMove := ProposeMove;

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

  // the new state begins at the StateManager
  StateManager.Clear;
  TableFrame.PreviewMode := False;

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

procedure TMainForm.HandleStateNavigate(Sender: TObject; aNode: TStateNode);
begin
  StateManager.SetCursor(aNode);
end;

procedure TMainForm.ProposeMove(Sender: TObject; const aMove: TMove; out aValid: Boolean; out aTargetCount: Integer);
begin
  aValid := StateManager.Cursor.Moves.IndexOfMove(aMove) <> -1;

  // aTargetCount positions the drop-ghost below the cards already in a tableau target.
  // 0 tells the table frame to use its own displayed table's target-stack count, which is
  // the current cursor state — exactly the value we'd otherwise recompute here.
  aTargetCount := 0;
end;

procedure TMainForm.HandleTableAction(Sender: TObject; aTableAction: TTableAction);
begin
  case aTableAction of
    taHint:
      begin
        // MoveFrame owns the best-first, dud-free hint ring and its own cycle.
        var hintMove: TMove;
        if MoveFrame.NextHintMove(hintMove) then
          TableFrame.ShowHintMove(hintMove);
      end;

    taComplete: ;
    taRestart: RestartTo(InitialState);
    taSnapshot: SaveSnapshotPrompt;
  end;
end;

procedure TMainForm.HandleCardClick(Sender: TObject; aStackId: TStackId; aCardIndex: Integer);
begin
  var m: TMove;
  if not StateManager.FindAutoMoveAtCursor(aStackId, aCardIndex, m) then
    Exit;

  var moveIndex := StateManager.Cursor.Moves.IndexOfMove(m);
  Assert(moveIndex <> -1); // an auto-move must exist in the cursor's generated move list
  StateManager.ExecuteMoveAtCursor(moveIndex, auPlayer);
end;

procedure TMainForm.HandleCursorChange(Sender: TObject; aNode: TStateNode; aIsStep: Boolean);
begin
  // moving the cursor invalidates any selected-move highlight
  TableFrame.ClearMoveHighlight;

  // expand the token once here so content frames never need to touch tokens
  StateManager.LoadState(aNode, Snapshot);

  // currently: supplies MoveFrame and StateFrame; MoveFrame rebuilds its hint ring
  // and resets its own cycle here
  for var f in ContentFrames do
    f.HandleCursorChange(aNode, Snapshot);

  // set up table view
  if aIsStep and Assigned(aNode.Parent) then
  begin
    var move := aNode.Parent.Moves[aNode.ParentMoveIndex];
    TableFrame.AnimateAndShowMove(move, Snapshot);
  end
  else
    TableFrame.ShowState(Snapshot, aNode.HValue);
end;

procedure TMainForm.HandleMoveSelected(Sender: TObject; aMoveIndex: Integer);
begin
  // a selected move gets a steady highlight on the table until the cursor moves.
  TableFrame.ShowMoveHighlight(StateManager.Cursor.Moves[aMoveIndex]);
end;

procedure TMainForm.HandleMoveRequested(Sender: TObject; aRequestedMove: TMove; aRequestedAnimate: Boolean);
begin
  // find move
  var moveIndex := StateManager.Cursor.Moves.IndexOfMove(aRequestedMove);

  Assert(moveIndex <> -1); // this would need to be investigated
  StateManager.ExecuteMoveAtCursor(moveIndex, auPlayer, aRequestedAnimate);
end;

procedure TMainForm.SaveSnapshotPrompt;
begin
  var dlg := d_SaveSnapshotDlg.TSaveSnapshotDlg.Create(Application);
  try
    if dlg.Execute(SnapshotLibrary) then
    begin
      if dlg.rbInitialState.Checked then
      begin
        SnapshotLibrary.Add(dlg.edtName.Text, InitialState);
      end
      else
      begin
        StateManager.LoadState(StateManager.Cursor, Snapshot);
        SnapshotLibrary.Add(dlg.edtName.Text, Snapshot);
      end;
    end;
  finally
    dlg.Free;
  end;
end;

function TMainForm.SnapshotLibraryFileName: string;
begin
  Result := RuntimeFilePath('snapshot_library.json');
end;

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
