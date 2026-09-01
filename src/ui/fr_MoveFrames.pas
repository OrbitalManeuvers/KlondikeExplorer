unit fr_MoveFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.StdCtrls;

type
  TMoveFrame = class(TContentFrame)
    lblTitle: TLabel;
    ControlList1: TControlList;
  private
  public
  end;


implementation

{$R *.dfm}

end.
