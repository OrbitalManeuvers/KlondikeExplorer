unit fr_SolutionFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ControlList,
  fr_ContentFrames, Vcl.Buttons;

type
  TSolutionFrame = class(TContentFrame)
    lblTitle: TLabel;
    pcSolutionPages: TPageControl;
    tsPlayer: TTabSheet;
    tsSolver: TTabSheet;
    PlayerMoveList: TControlList;
    btnPlayer: TSpeedButton;
    btnDFS: TSpeedButton;
    btnBeam: TSpeedButton;
    btnAStar: TSpeedButton;
    procedure SolutionTypeClick(Sender: TObject);
  private
  public
    procedure InitContent; override;
  end;


implementation

uses Vcl.Themes;


{$R *.dfm}

{ TSolutionFrame }

procedure TSolutionFrame.InitContent;
begin
  inherited;
  btnPlayer.Down := True;
end;

procedure TSolutionFrame.SolutionTypeClick(Sender: TObject);
begin
  if btnPlayer.Down then
    pcSolutionPages.ActivePageIndex := 0
  else
    pcSolutionPages.ActivePageIndex := 1;
end;


end.
