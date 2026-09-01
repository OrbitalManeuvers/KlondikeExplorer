unit fr_GraphFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  Vcl.Buttons;

type
  TGraphFrame = class(TContentFrame)
    btnPlayer: TSpeedButton;
    btnDFS: TSpeedButton;
    btnBeam: TSpeedButton;
    btnAStar: TSpeedButton;
  private
  public
  end;


implementation

{$R *.dfm}

end.
