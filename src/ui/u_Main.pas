unit u_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Actions, Vcl.ActnList,
  Vcl.StdActns, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, Vcl.ToolWin,
  Vcl.ActnCtrls, Vcl.ActnMenus, Vcl.ComCtrls,

  fr_ContentFrame;

type
  TContentType = (ctGameMode, ctExploreMode, ctTestMode);

  TMainForm = class(TForm)
    MainMenu: TActionMainMenuBar;
    MainActions: TActionManager;
    actFileExit: TFileExit;
    MainPages: TPageControl;
    tsGame: TTabSheet;
    tsExplore: TTabSheet;
    tsTests: TTabSheet;
    procedure MainPagesChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    ContentFrames: array[TContentType] of TContentFrame;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses fr_GameMode, fr_ExploreMode, u_SnapshotManagers;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  for var f := Low(TContentType) to High(TContentType) do
    ContentFrames[f] := nil;

  MainPages.ActivePage := tsGame;
  MainPagesChange(nil);

//  var s := TSnapshotManager.Create;
//  try
//    var stats := s.Storage.Stats;
//
//  finally
//    s.Free;
//  end;

end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  for var f := Low(TContentType) to High(TContentType) do
    if Assigned(ContentFrames[f]) then
      ContentFrames[f].DoneContent;
end;

procedure TMainForm.MainPagesChange(Sender: TObject);
begin
  var contentType := TContentType(MainPages.ActivePageIndex);

  if ContentFrames[contentType] = nil then
  begin
    var frameClass: TContentFrameClass := nil;
    case contentType of
      ctGameMode: frameClass := TGameFrame;
      ctExploreMode: frameClass := TExploreFrame;
      ctTestMode: ;
    end;

    if Assigned(frameClass) then
    begin
      var f := frameClass.Create(Self);
      f.Align := alClient;
      f.Parent := MainPages.ActivePage;

      f.InitContent;
      f.Visible := True;
      ContentFrames[contentType] := f;
    end;
  end;

  for var frame := Low(TContentType) to High(TContentType) do
    if Assigned(ContentFrames[frame]) then
      ContentFrames[frame].IsActive := frame = contentType;
end;

end.
