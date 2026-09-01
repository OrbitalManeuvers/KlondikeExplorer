unit d_SaveSnapshotDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,

  u_SnapshotLibraries;

type
  TSaveSnapshotDlg = class(TForm)
    rbInitialState: TRadioButton;
    rbCurrentState: TRadioButton;
    edtName: TEdit;
    Label1: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    Label3: TLabel;
    procedure edtNameChange(Sender: TObject);
  private
    fLibrary: TSnapshotLibrary;
    procedure UpdateControls;
  public
    function Execute(aSnapshotLibrary: TSnapshotLibrary): Boolean;
  end;

implementation

{$R *.dfm}

{ TSaveSnapshotDlg }

procedure TSaveSnapshotDlg.edtNameChange(Sender: TObject);
begin
  UpdateControls;
end;

function TSaveSnapshotDlg.Execute(aSnapshotLibrary: TSnapshotLibrary): Boolean;
begin
  fLibrary := aSnapshotLibrary;
  UpdateControls;
  Result := ShowModal = mrOK;
end;

procedure TSaveSnapshotDlg.UpdateControls;
begin
  btnOK.Enabled := (edtName.Text <> '') and (fLibrary.IndexOfName(edtName.Text) = -1);
end;

end.
