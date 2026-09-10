unit fr_ContentFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_SnapshotManagers, u_SnapshotLibraries, u_StateManagers, u_Snapshots, Vcl.ExtCtrls;

type
  TContentFrame = class(TFrame)
    pnlBackground: TPanel;
  private
    fSnapshotManager: TSnapshotManager;
    fSnapshotLibrary: TSnapshotLibrary;
    fLogPath: string;
  protected
//    property SnapshotManager: TSnapshotManager read fSnapshotManager;
//    property SnapshotLibrary: TSnapshotLibrary read fSnapshotLibrary;
//    property LogPath: string read fLogPath;
  public
//    // globally owned resources usable by content frames
//    constructor Create(AOwner: TComponent; ASnapshotManager: TSnapshotManager;
//      ASnapshotLibrary: TSnapshotLibrary; const aLogPath: string); reintroduce; overload;

    // lifetime resource mgmt
    procedure InitContent; virtual;
    procedure DoneContent; virtual;

    // cursor change notification (base does nothing; views override)
    // aSnapshot is the cursor's table already expanded by the main form
    procedure HandleCursorChange(aNode: TStateNode; aSnapshot: TSnapshot); virtual;

    // snapshot library changed (base does nothing; views override)
    procedure HandleSnapshotLibraryChanged; virtual;

    property SnapshotManager: TSnapshotManager read fSnapshotManager write fSnapshotManager;
    property SnapshotLibrary: TSnapshotLibrary read fSnapshotLibrary write fSnapshotLibrary;
    property LogPath: string read fLogPath write fLogPath;

  end;
  TContentFrameClass = class of TContentFrame;

implementation

{$R *.dfm}

{ TContentFrame }

//constructor TContentFrame.Create(AOwner: TComponent;
//  ASnapshotManager: TSnapshotManager; ASnapshotLibrary: TSnapshotLibrary; const ALogPath: string);
//begin
//  inherited Create(AOwner);
//  fSnapshotManager := ASnapshotManager;
//  fSnapshotLibrary := ASnapshotLibrary;
//  fLogPath := ALogPath;
//end;

procedure TContentFrame.InitContent;
begin
  //
end;

procedure TContentFrame.DoneContent;
begin
  //
end;

procedure TContentFrame.HandleCursorChange(aNode: TStateNode; aSnapshot: TSnapshot);
begin
  // descendants can override as needed
end;

procedure TContentFrame.HandleSnapshotLibraryChanged;
begin
  // descendants can override as needed
end;


end.
