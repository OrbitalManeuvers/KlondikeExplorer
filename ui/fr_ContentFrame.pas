unit fr_ContentFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  u_Types,
  u_SnapshotTokens,
  u_SnapshotServices.Intf,
  u_Tables;

type
  TSnapshotSaveEvent = procedure(Sender: TObject; aTable: TTable; out aNewToken: Integer) of object;

  TContentFrame = class(TFrame)
    lblFrameCaption: TLabel;
  private
    fOnLog: TLogEvent;
  protected
    SnapshotServices: ISnapshotServices;
    procedure Log(const LogMsg: string);

    procedure InitContent; virtual;
    procedure DoneContent; virtual;

  public
    procedure Initialize(aFrameCaption: string; const aSnapshotServices: ISnapshotServices);
    procedure Finalize;

    procedure SessionReset(aSnapshot: TSnapshotToken); virtual;

    property OnLog: TLogEvent read fOnLog write fOnLog;
  end;

  TContentFrameClass = class of TContentFrame;

implementation

{$R *.dfm}

{ TContentFrame }

procedure TContentFrame.Initialize(aFrameCaption: string; const aSnapshotServices: ISnapshotServices);
begin
  lblFrameCaption.Caption := '  ' + Trim(aFrameCaption);
  SnapshotServices := aSnapshotServices;
  InitContent;
end;

procedure TContentFrame.Finalize;
begin
  DoneContent;
end;

procedure TContentFrame.InitContent;
begin
  //
end;

procedure TContentFrame.DoneContent;
begin
  //
end;

procedure TContentFrame.Log(const LogMsg: string);
begin
  if Assigned(fOnLog) then
    FonLog(Self, LogMsg);
end;

procedure TContentFrame.SessionReset(aSnapshot: TSnapshotToken);
begin
  //
end;


end.
