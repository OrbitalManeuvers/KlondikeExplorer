unit fr_ResetFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.Buttons,
  Vcl.StdCtrls, Vcl.ExtCtrls,

  u_Snapshots;

type
  TRestartEvent = procedure(Sender: TObject; NewState: TSnapshot) of object;

  TResetFrame = class(TContentFrame)
    lblTitle: TLabel;
    rbRandom: TRadioButton;
    rbSolvable: TRadioButton;
    rbSnapshot: TRadioButton;
    cbSnapshots: TComboBox;
    btnReset: TSpeedButton;
    procedure MethodClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
  private
    fOnRestart: TRestartEvent;
    procedure UpdateControls;
  public
    procedure InitContent; override;
    property OnRestart: TRestartEvent read fOnRestart write fOnRestart;
  end;


implementation

{$R *.dfm}

uses u_DealCreators, u_SolvableDealCreators;

{ TResetFrame }

procedure TResetFrame.InitContent;
begin
  inherited;
  cbSnapshots.Items.BeginUpdate;
  try
    for var i := 0 to SnapshotLibrary.Count - 1 do
      cbSnapshots.Items.Add(SnapshotLibrary.Names[i]);
    if cbSnapshots.Items.Count > 0 then
      cbSnapshots.ItemIndex := 0;
  finally
    cbSnapshots.Items.EndUpdate;
  end;
  UpdateControls;
end;

procedure TResetFrame.MethodClick(Sender: TObject);
begin
  //
  UpdateControls;
end;

procedure TResetFrame.UpdateControls;
begin
  cbSnapshots.Enabled := rbSnapshot.Checked;
  btnReset.Enabled := Assigned(fOnRestart);
end;

procedure TResetFrame.btnResetClick(Sender: TObject);
begin
  var newState := TSnapshot.Create;
  try
    if rbRandom.Checked then
    begin
      TRandomDealCreator.CreateState(newState);
      fOnRestart(Self, newState);
    end;

    if rbSolvable.Checked then
    begin
      TForwardDealCreator.CreateState(newState);
      fOnRestart(Self, newState);
    end;



  finally
    newState.Free;
  end;
end;


end.
