unit fr_LogWindow;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons,
  PngSpeedButton, Vcl.StdCtrls;

type
  TLogFrame = class(TFrame)
    LogMemo: TMemo;
    btnCopyLog: TPngSpeedButton;
    btnClear: TPngSpeedButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

end.
