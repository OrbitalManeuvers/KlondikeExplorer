unit fr_ContentFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,

  u_SnapshotLibraries;

type
  TContentFrame = class(TFrame)
  private
    fIsActive: Boolean;
    fSnapshotLibrary: TSnapshotLibrary;
    procedure SetIsActive(const Value: Boolean); virtual;
  protected
  public
  public
    procedure InitContent; virtual;
    procedure DoneContent; virtual;

    property IsActive: Boolean read fIsActive write SetIsActive;
    property SnapshotLibrary: TSnapshotLibrary read fSnapshotLibrary write fSnapshotLibrary;
  end;

  TContentFrameClass = class of TContentFrame;

implementation

{$R *.dfm}

{ TContentFrame }

procedure TContentFrame.InitContent;
begin
  // create permanent resources
end;

procedure TContentFrame.DoneContent;
begin
  // free resources
end;

procedure TContentFrame.SetIsActive(const Value: Boolean);
begin
  // allow frames to deactivate
  fIsActive := Value;
end;

end.
