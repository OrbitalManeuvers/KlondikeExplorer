unit u_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdActns, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.StdCtrls,

  u_SnapshotLibraries, fr_TableView;

type
  TMainForm = class(TForm)
    MainMenu: TActionMainMenuBar;
    MainActions: TActionManager;
    actFileExit: TFileExit;
    LeftPanel: TPanel;
    TablePanel: TPanel;
    GraphPanel: TPanel;
    GroupBox1: TGroupBox;
    rbRandom: TRadioButton;
    rbSolvable: TRadioButton;
    rbSnapshot: TRadioButton;
    cbSnapshots: TComboBox;
    btnReset: TSpeedButton;
    actOpenGame: TFileOpen;
    actSaveGameAs: TFileSaveAs;
    actSaveGame: TAction;
    actTests: TAction;
    actAbout: TAction;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormAlignPosition(Sender: TWinControl; Control: TControl;
      var NewLeft, NewTop, NewWidth, NewHeight: Integer; var AlignRect: TRect;
      AlignInfo: TAlignInfo);
    procedure btnResetClick(Sender: TObject);
    procedure actOpenGameAccept(Sender: TObject);
    procedure actSaveGameAsAccept(Sender: TObject);
    procedure actSaveGameExecute(Sender: TObject);
    procedure actTestsExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
  private
    SnapshotLibrary: TSnapshotLibrary;
    TableView: TTableView;
    function SnapshotLibraryFileName(): string;
    procedure UpdateControls;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses System.IOUtils,
  u_SnapshotManagers;

const
  PANEL_MARGIN = 6;


{ Utility }
function RuntimeFilePath(const aFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), aFileName);
end;

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  SnapshotLibrary := TSnapshotLibrary.Create;
  var fileName := SnapshotLibraryFileName();
  if TFile.Exists(fileName) then
    SnapshotLibrary.LoadFromFile(fileName);

  TableView := TTableView.Create(Self);
  TableView.Align := alClient;
  TableView.Parent := TablePanel;

end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if SnapshotLibrary.Modified then
  begin
    var fileName := SnapshotLibraryFileName();
    SnapshotLibrary.SaveToFile(fileName);
  end;
end;

function TMainForm.SnapshotLibraryFileName: string;
begin
  Result := RuntimeFilePath('snapshot_library.json');
end;

procedure TMainForm.UpdateControls;
begin

  cbSnapshots.Enabled := rbSnapshot.Checked;
end;

procedure TMainForm.actAboutExecute(Sender: TObject);
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

procedure TMainForm.btnResetClick(Sender: TObject);
begin
  //
end;

procedure TMainForm.FormAlignPosition(Sender: TWinControl; Control: TControl;
  var NewLeft, NewTop, NewWidth, NewHeight: Integer; var AlignRect: TRect;
  AlignInfo: TAlignInfo);
begin
  if (Control = TablePanel) or (Control = GraphPanel) then
  begin
    var r := ClientRect;
    r.Left := LeftPanel.BoundsRect.Right + PANEL_MARGIN;
    r.Top := LeftPanel.Top;
    r.Bottom := LeftPanel.BoundsRect.Bottom;
    r.Right := r.Right - 6;

    if Control = TablePanel then
    begin
      r.Bottom := GraphPanel.Top - PANEL_MARGIN;
    end
    else if Control = GraphPanel then
    begin
      r.Top := r.Bottom - GraphPanel.Height;
    end;

    NewLeft := r.Left;
    NewTop := r.Top;
    NewWidth := r.Width;
    NewHeight := r.Height;
  end;
end;

end.
