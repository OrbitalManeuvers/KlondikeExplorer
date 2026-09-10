unit d_SnapshotComposerDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  u_SnapshotLibraries;

type
  TSnapshotComposerDlg = class(TForm)
    Label1: TLabel;
    edtSnapshotName: TEdit;
    mmoInstructions: TMemo;
    btnOK: TButton;
    btnCancel: TButton;
    Label2: TLabel;
    procedure btnOKClick(Sender: TObject);
    procedure edtSnapshotNameChange(Sender: TObject);
  private
    fValidName: Boolean;
    fLibrary: TSnapshotLibrary;
    procedure UpdateControls;
  public
    function Execute(aSnapshotLibrary: TSnapshotLibrary): Boolean;
  end;


implementation

uses u_Types, u_CardHelpers, u_Snapshots, u_SnapshotComposers;

{$R *.dfm}

procedure TSnapshotComposerDlg.edtSnapshotNameChange(Sender: TObject);
begin
  // validate name is unique
  fValidName := (edtSnapshotName.Text <> '') and (fLibrary.IndexOfName(edtSnapshotName.Text) = -1);

  UpdateControls;
end;

function TSnapshotComposerDlg.Execute(aSnapshotLibrary: TSnapshotLibrary): Boolean;
begin
  fLibrary := aSnapshotLibrary;
  UpdateControls;

  // to-do

  Result := ShowModal = mrOK;
  if Result then
    ShowMessage('Added to library');
end;

procedure TSnapshotComposerDlg.btnOKClick(Sender: TObject);
begin
  // to-do
  var snapshot := TSnapshot.Create;
  try
    var result := TSnapshotComposer.Compose(mmoInstructions.Text, snapshot);
    if result.Success then
    begin
      fLibrary.Add(edtSnapshotName.Text, snapshot);
      ModalResult := mrOK;
    end
    else
    begin
      ShowMessage(result.Error);
    end;

  finally
    snapshot.Free;
  end;

end;

procedure TSnapshotComposerDlg.UpdateControls;
begin
  // ok requires valid name, valid memo
  btnOK.Enabled := fValidName;
end;

end.
