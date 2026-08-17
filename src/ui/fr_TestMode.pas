unit fr_TestMode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrame, Vcl.StdCtrls,
  Vcl.ControlList, Vcl.ExtCtrls, Vcl.Buttons, Vcl.CheckLst,

  u_Logs, u_TestRunners;

type
  TTestFrame = class(TContentFrame)
    ControlPanel: TPanel;
    LogView: TControlList;
    lblEntryType: TLabel;
    lblEntryText: TLabel;
    CheckListBox1: TCheckListBox;
    SpeedButton1: TSpeedButton;
    procedure LogViewBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
  private
    fLog: TLog;
    fRunner: TTestRunner;
    procedure HandleLogChange(Sender: TObject);
  public
    procedure InitContent; override;
    procedure DoneContent; override;
  end;


implementation

{$R *.dfm}

uses u_LogTypes;

procedure TTestFrame.InitContent;
begin
  inherited;
  fLog := TLog.Create;
  fLog.OnChange := HandleLogChange;

  fLog.Add(ekTestSummary, 'Startup');
  fRunner := TTestRunner.Create(fLog);

end;

procedure TTestFrame.DoneContent;
begin
  fRunner.Free;
  fLog.Free;


  inherited;
end;

procedure TTestFrame.HandleLogChange(Sender: TObject);
begin
  LogView.ItemCount := fLog.Count;
end;

procedure TTestFrame.LogViewBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if (AIndex >= 0) and (AIndex < fLog.Count) then
  begin
    lblEntryText.Caption := fLog.Entries[AIndex].Msg;
  end;
  //
end;

end.
