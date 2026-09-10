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
    Label1: TLabel;
    rgMethod: TRadioGroup;
    procedure MethodClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
  private
    fOnRestart: TRestartEvent;
    procedure UpdateControls;
    procedure ReloadSnapshots;
  public
    procedure InitContent; override;
    procedure HandleSnapshotLibraryChanged; override;
    property OnRestart: TRestartEvent read fOnRestart write fOnRestart;
  end;


implementation

{$R *.dfm}

uses System.IOUtils,
  u_DealCreators, u_SolvableDealCreators;

{ TResetFrame }

procedure TResetFrame.InitContent;
begin
  inherited;
  ReloadSnapshots;
  UpdateControls;
end;

procedure TResetFrame.HandleSnapshotLibraryChanged;
begin
  inherited;
  ReloadSnapshots;
end;

// rebuild the combo from the library, keeping the current selection if that
// same name still exists, otherwise falling back to the first item
procedure TResetFrame.ReloadSnapshots;
begin
  var selectedName := '';
  if cbSnapshots.ItemIndex >= 0 then
    selectedName := cbSnapshots.Items[cbSnapshots.ItemIndex];

  cbSnapshots.Items.BeginUpdate;
  try
    cbSnapshots.Items.Clear;
    for var i := 0 to SnapshotLibrary.Count - 1 do
      cbSnapshots.Items.Add(SnapshotLibrary.Names[i]);

    var restored := cbSnapshots.Items.IndexOf(selectedName);
    if restored >= 0 then
      cbSnapshots.ItemIndex := restored
    else if cbSnapshots.Items.Count > 0 then
      cbSnapshots.ItemIndex := 0;
  finally
    cbSnapshots.Items.EndUpdate;
  end;
end;

procedure TResetFrame.MethodClick(Sender: TObject);
begin
  UpdateControls;
end;

procedure TResetFrame.UpdateControls;
begin
  cbSnapshots.Enabled := rbSnapshot.Checked;
  rgMethod.Enabled := rbSolvable.Checked;

  btnReset.Enabled := Assigned(fOnRestart);
end;

procedure TResetFrame.btnResetClick(Sender: TObject);
begin
  var newState := TSnapshot.Create;
  try

    if rbRandom.Checked or rbSolvable.Checked then
    begin
      // use random as the default
      var creatorClass: TDealCreatorClass := nil;

      if rbRandom.Checked then
        creatorClass := TRandomDealCreator
      else if rbSolvable.Checked then
      begin
        case rgMethod.ItemIndex of
          0: creatorClass := TForwardDealCreator;
          1: creatorClass := TReverseDealCreator;
        end;
      end;

      Assert(Assigned(creatorClass));

      var creator := creatorClass.Create;
      try

        try
          creator.CreateState(newState);
          fOnRestart(Self, newState);
        except
          on E: Exception do
          begin
            // save the creator's log if we have a LogFolder
            if (Self.LogPath <> '') and TDirectory.Exists(Self.LogPath) then
            begin
              var fileName := TPath.Combine(Self.LogPath, 'solver_fail.txt');
              creator.Log.SaveToFile(fileName);

              raise;
            end;

          end;

        end;

      finally
        creator.Free;
      end;
    end;

    if rbSnapshot.Checked then
    begin
      var index := cbSnapshots.ItemIndex;
      SnapshotLibrary.LoadSnapshot(index, newState);
      fOnRestart(Self, newState);
    end;

  finally
    newState.Free;
  end;
end;


end.
