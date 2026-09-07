unit d_About;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TAboutBox = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
  private
  public
  end;


implementation

{$R *.dfm}



end.
