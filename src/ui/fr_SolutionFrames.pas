unit fr_SolutionFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  Vcl.StdCtrls,
  u_GraphicButtonBars, Vcl.ComCtrls, Vcl.ControlList;

type
  TSolutionFrame = class(TContentFrame)
    lblTitle: TLabel;
    Placeholder: TShape;
    pcSolutionPages: TPageControl;
    tsPlayer: TTabSheet;
    tsSolver: TTabSheet;
    ControlList1: TControlList;
  private
    Selector: TButtonBar;
    procedure HandleSelectorClick(Sender: TObject);
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
  Selector := TButtonBar.Create(Self);
  Selector.Captions := ['Player', 'DFS', 'IDA*', 'A* '];
  Selector.ItemIndex := 0;
  Selector.BoundsRect := Placeholder.BoundsRect;
  Selector.Parent := Placeholder.Parent;
  Selector.OnClick := HandleSelectorClick;
  Placeholder.Hide;
end;

procedure TSolutionFrame.HandleSelectorClick(Sender: TObject);
begin
  if Selector.ItemIndex = 0 then
    pcSolutionPages.ActivePageIndex := 0
  else
    pcSolutionPages.ActivePageIndex := 1;
end;



end.
