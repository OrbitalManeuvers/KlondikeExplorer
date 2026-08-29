unit u_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdActns, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.StdCtrls,

  u_SnapshotLibraries, u_SnapshotManagers, fr_TableView, Vcl.AppEvnts, Vcl.Tabs,
  fr_ContentFrames, fr_ResetFrames, fr_SolutionFrames,
  u_SaveFiles;

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
    procedure actOpenGameAccept(Sender: TObject);
    procedure actSaveGameAsAccept(Sender: TObject);
    procedure actSaveGameExecute(Sender: TObject);
    procedure actTestsExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure actNewGameExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    SaveFile: TSaveFile;
    SnapshotManager: TSnapshotManager;
    SnapshotLibrary: TSnapshotLibrary;
    function SnapshotLibraryFileName(): string;
    procedure UpdateControls;
    procedure HandleSnapshotManagerChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils, Vcl.Themes,
  u_Snapshots, u_DealCreators;

const
  PANEL_MARGIN = 6;


{ Utility }
function RuntimeFilePath(const aFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), aFileName);
end;

{ TMainForm }
constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited;
  SnapshotManager := TSnapshotManager.Create;
  SnapshotManager.OnChange := HandleSnapshotManagerChange;

  SnapshotLibrary := TSnapshotLibrary.Create;
  var fileName := SnapshotLibraryFileName();
  if TFile.Exists(fileName) then
    SnapshotLibrary.LoadFromFile(fileName);

  // update the status bar
  HandleSnapshotManagerChange(nil);

  SaveFile := TSaveFile.Create;
end;

destructor TMainForm.Destroy;
begin
  SnapshotManager.OnChange := nil;

  if SnapshotLibrary.Modified then
  begin
    var fileName := SnapshotLibraryFileName();
    SnapshotLibrary.SaveToFile(fileName);
  end;
  SnapshotLibrary.Free;

  //
  if SaveFile.Modified then
  begin
    //
  end;

  // let inherited do all child cleanup
  inherited;

  // shared resources go last
  SnapshotManager.Free;
end;

procedure TMainForm.HandleSnapshotManagerChange(Sender: TObject);
begin
  if Assigned(SnapshotManager) then
    StatusBar.SimpleText := SnapshotManager.Storage.Stats.AsText;
end;

function TMainForm.SnapshotLibraryFileName: string;
begin
  Result := RuntimeFilePath('snapshot_library.json');
end;

procedure TMainForm.UpdateControls;
begin
 //
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

procedure TMainForm.FormCreate(Sender: TObject);
begin
  var rf := TResetFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  rf.Align := alTop;
  rf.Parent := LeftColumn;
  rf.InitContent;

  LeftColumnSplitShape.Align := alTop;
  LeftColumnSplitShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);
  LeftColumnBorderShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);
  LeftColumnBorderShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);

  RightColumnSplitShape.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);

  var sf := TSolutionFrame.Create(Self, SnapshotManager, SnapshotLibrary);
  sf.Align := alClient;
  sf.Parent := LeftColumn;
  sf.InitContent;


end;

end.
