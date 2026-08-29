unit fr_ContentFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_SnapshotManagers, u_SnapshotLibraries, Vcl.ExtCtrls;

type
  TContentFrame = class(TFrame)
    pnlBackground: TPanel;
  private
    fSnapshotManager: TSnapshotManager;
    fSnapshotLibrary: TSnapshotLibrary;
  protected
    property SnapshotManager: TSnapshotManager read fSnapshotManager;
    property SnapshotLibrary: TSnapshotLibrary read fSnapshotLibrary;
  public
    // globally owned resources usable by content frames
    constructor Create(AOwner: TComponent; ASnapshotManager: TSnapshotManager;
      ASnapshotLibrary: TSnapshotLibrary); reintroduce; overload;

    // lifetime resource mgmt
    procedure InitContent; virtual;
    procedure DoneContent; virtual;
  end;
  TContentFrameClass = class of TContentFrame;

implementation

{$R *.dfm}

{ TContentFrame }

constructor TContentFrame.Create(AOwner: TComponent;
  ASnapshotManager: TSnapshotManager; ASnapshotLibrary: TSnapshotLibrary);
begin
  inherited Create(AOwner);
  fSnapshotManager := ASnapshotManager;
  fSnapshotLibrary := ASnapshotLibrary;
end;

procedure TContentFrame.InitContent;
begin
  //
end;

procedure TContentFrame.DoneContent;
begin
  //
end;


end.
