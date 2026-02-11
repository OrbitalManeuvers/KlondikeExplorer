unit f_Main;

{$define statetobin} // write state files to bin folder
{-define statetohome}  // write state files to Home folder

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.AppEvnts, Vcl.ExtCtrls,
  System.Generics.Collections, Vcl.StdCtrls,

  fr_LogWindow,
  fr_ContentFrame,
  fr_Session,
  u_Types,
  u_SnapshotTokens,
  u_SnapshotManagers,
  u_SeedLibraries,
  u_SnapshotLibraries,
  u_SnapshotServices.Intf,
  fr_EngineWorkbench;

type
  TMainForm = class(TForm)
    StatusBar: TStatusBar;
    AppEvents: TApplicationEvents;
    phLog: TShape;
    phSession: TShape;
    PageControl: TPageControl;
    tsEngineWorkbench: TTabSheet;
    tsSolverWorkbench: TTabSheet;
    tsAutomatedTests: TTabSheet;
    shpSpacerH: TShape;
    shpSpacerV: TShape;
    procedure StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
    procedure AppEventsIdle(Sender: TObject; var Done: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
  private
    LogFrame: TLogFrame;
    SessionFrame: TSessionFrame;
    SnapshotManager: TSnapshotManager;
    SnapshotLibrary: TSnapshotLibrary;
    SeedLibrary: TSeedLibrary;
    LastMemStatus: string;

    // services for content frames
    _snapshotServices: ISnapshotServices;

    // content
    ContentFrames: TList<TContentFrame>;
    TestFrame: TContentFrame;
    EngineFrame: TEngineWorkbench;
//    SolverFrame: TFrame;


    procedure Log(const aMsg: string);
    procedure PositionFrame(aFrame: TFrame; aPlaceHolder: TShape);
    procedure InitContentFrame(aFrame: TContentFrame; const aFrameCaption: string; aParentPage: TTabSheet);
    procedure SaveState;
    procedure LoadState;
    function StateFileName(): string;

    // events
    procedure HandleReset(Sender: TObject; Token: TSnapshotToken); overload;
    procedure HandleLog(Sender: TObject; const LogMsg: string);
    procedure HandleLibraryChange(Sender: TObject);

  public
    //
  end;

var
  MainForm: TMainForm;

implementation

uses System.UITypes, Vcl.GraphUtil, Vcl.Themes, System.JSON, System.IOUtils,

  fr_TestFrame,
  u_Cards,
  u_CardStacks,
  u_Snapshots;

{$R *.dfm}

type
  TSnapshotServices = class(TInterfacedObject, ISnapshotServices)
  private
    fOnLibraryChange: TNotifyEvent;
    { ISnapshotServices }
    function Save(aSnapshot: TSnapshot): TSnapshotToken;
    procedure Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
    procedure Delete(aToken: TSnapshotToken);

    // creating new snapshots
    function GetLibrarySaveName(var snapshotName: string): Boolean;
    function SaveToLibrary(const aName: string; aToken: TSnapshotToken): Boolean;

  private
    SnapshotManager: TSnapshotManager;
    SnapshotLibrary: TSnapshotLibrary;
  public
    constructor Create(aSnapshotManager: TSnapshotManager; aSnapshotLibrary: TSnapshotLibrary);
    property OnLibraryChange: TNotifyEvent read fOnLibraryChange write fOnLibraryChange;
  end;

{ TSnapshotServices }
constructor TSnapshotServices.Create(aSnapshotManager: TSnapshotManager; aSnapshotLibrary: TSnapshotLibrary);
begin
  inherited Create;
  SnapshotManager := aSnapshotManager;
  SnapshotLibrary := aSnapshotLibrary;
end;

function TSnapshotServices.Save(aSnapshot: TSnapshot): TSnapshotToken;
begin
  Result := SnapshotManager.Save(aSnapshot);
end;

procedure TSnapshotServices.Load(aToken: TSnapshotToken; aSnapshot: TSnapshot);
begin
  SnapshotManager.Load(aToken, aSnapshot);
end;

procedure TSnapshotServices.Delete(aToken: TSnapshotToken);
begin
  SnapshotManager.Delete(aToken);
end;

function TSnapshotServices.GetLibrarySaveName(var snapshotName: string): Boolean;
begin
  Result := False;

  var prompts: array of string := ['Name:'];
  var values: array of string := [snapshotName];

  if InputQuery('Save Snapshot', prompts, values,
    function (const Values: array of string): Boolean
    begin
      Result := SnapshotLibrary.IndexOf(values[0]) = -1;
      if not Result then
        ShowMessage('Dupe name.');

    end) then
  begin
    snapshotName := values[0];
    Result := True;
  end;
end;

function TSnapshotServices.SaveToLibrary(const aName: string; aToken: TSnapshotToken): Boolean;
begin
  Result := False;
  SnapshotLibrary.Add(aName, aToken);
  if Assigned(fOnLibraryChange) then
    fOnLibraryChange(Self);
end;


{ TMainForm }

{$region 'Startup-Shutdown'}
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // snapshots
  SnapshotManager := TSnapshotManager.Create;

  // libraries
  SnapshotLibrary := TSnapshotLibrary.Create(SnapshotManager);
  SeedLibrary := TSeedLibrary.Create;
  LoadState;

  // services for content frames
  var services := TSnapshotServices.Create(SnapshotManager, SnapshotLibrary);
  services.OnLibraryChange := HandleLibraryChange;

  // our permanent reference
  _snapshotServices := services;

  // format spacers to use style color
  shpSpacerH.Brush.Color := StyleServices.GetSystemColor(clBtnShadow);
  shpSpacerH.Pen.Color := shpSpacerH.Brush.Color;
  shpSpacerV.Brush.Color := shpSpacerH.Brush.Color;
  shpSpacerV.Pen.Color := shpSpacerH.Brush.Color;

  // log frame
  LogFrame := TLogFrame.Create(Application);
  PositionFrame(LogFrame, phLog);

  // session frame
  SessionFrame := TSessionFrame.Create(Application);
  PositionFrame(SessionFrame, phSession);

  // session connections
  SessionFrame.OnReset := HandleReset;
//  SessionFrame.OnSnapshotReset := HandleReset;
  SessionFrame.SnapshotLibrary := SnapshotLibrary;
  SessionFrame.SeedLibrary := SeedLibrary;

  // list for simplicity of addressing all content frames
  ContentFrames := TList<TContentFrame>.Create;

  PageControlChange(nil);

  Log('Startup complete.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  ContentFrames.Free;
  SnapshotManager.Free;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  for var f in ContentFrames do
  begin
    f.Finalize;
  end;
  SaveState;
end;

procedure TMainForm.InitContentFrame(aFrame: TContentFrame; const aFrameCaption: string;
  aParentPage: TTabSheet);
begin
  aFrame.Parent := aParentPage;
  aFrame.Align := alClient;
  aFrame.Initialize(aFrameCaption, _snapshotServices);
  aFrame.OnLog := HandleLog;

  ContentFrames.Add(aFrame);
  aParentPage.Update;

  Log('Created ' + aFrame.ClassName + '  (' + aFrameCaption + ')' );
end;

procedure TMainForm.PositionFrame(aFrame: TFrame; aPlaceHolder: TShape);
begin
  aFrame.Parent := aPlaceholder.Parent;
  aFrame.BoundsRect := aPlaceholder.BoundsRect;
  aFrame.Align := aPlaceholder.Align;
  aPlaceholder.Hide;
end;

{$endregion}

{$region 'State-Save-Load'}

procedure TMainForm.LoadState;
begin
  var fileName := StateFileName();
  if TFile.Exists(fileName) then
  begin
    var JSON := TJSONValue.ParseJSONValue(TFile.ReadAllText(fileName)) as TJSONObject;
    try
      SeedLibrary.LoadFrom(JSON);
      SnapshotLibrary.LoadFrom(JSON);
    finally
      JSON.Free;
    end;
  end;
end;

procedure TMainForm.SaveState;
begin
  if SnapshotLibrary.Modified or SeedLibrary.Modified then
  begin
    var fileName := StateFileName();
    var JSON := TJSONObject.Create;
    try
      SeedLibrary.SaveTo(JSON);
      SnapshotLibrary.SaveTo(JSON);
      TFile.WriteAllText(fileName, JSON.Format());
    finally
      JSON.Free;
    end;
  end;
end;

function TMainForm.StateFileName: string;
const
  fnStateFile = 'KlondikeExplorerState.json';
begin

{$ifdef statetobin}
  Result := TPath.Combine(ExtractFilePath(Application.ExeName), fnStateFile);
{$endif}

{$ifdef statetohome}
  var folder := TPath.Combine(TPath.GetHomePath, 'KlondikeExplorer');
  Result := TPath.Combine(folder, fnStateFile);
{$endif}

end;

{$endregion}

{$region 'Event handlers'}
procedure TMainForm.HandleLibraryChange(Sender: TObject);
begin
  if Assigned(SessionFrame) then
    SessionFrame.SnapshotLibrary := SnapshotLibrary;
end;

procedure TMainForm.HandleLog(Sender: TObject; const LogMsg: string);
begin
  Log(LogMsg);
end;

procedure TMainForm.HandleReset(Sender: TObject; Token: TSnapshotToken);
begin
  if Token <> NO_SNAPSHOT then
    Log('Snapshot reset')
  else
    Log('Reset');
  for var c in ContentFrames do
    c.SessionReset(Token);
end;

{$endregion}


procedure TMainForm.AppEventsIdle(Sender: TObject; var Done: Boolean);
begin
  // show mem status
  if Assigned(SnapshotManager) then
  begin
    var s := SnapshotManager.Storage.Stats.AsText;
    if s <> LastMemStatus then
    begin
      LastMemStatus := s;
      StatusBar.Invalidate;
    end;
  end;
end;

procedure TMainForm.Log(const aMsg: string);
begin
  var s := Format('[%s] %s', [FormatDateTime('hh:mm:ss', Now), aMsg]);
  LogFrame.LogMemo.Lines.Add(s);
end;

procedure TMainForm.PageControlChange(Sender: TObject);
begin
  // make sure content has been created

  if (PageControl.ActivePage = tsAutomatedTests) and (not Assigned(TestFrame)) then
  begin
    TestFrame := TTestFrame.Create(Application);
    InitContentFrame(TestFrame, 'Test Suite', tsAutomatedTests);
  end;

  if (PageControl.ActivePage = tsEngineWorkbench) and (not Assigned(EngineFrame)) then
  begin
    EngineFrame := TEngineWorkbench.Create(Application);
    InitContentFrame(EngineFrame, '', tsEngineWorkbench);
    //
  end;

  if (PageControl.ActivePage = tsSolverWorkbench) and (not Assigned(nil)) then
  begin
    //
  end;
end;

procedure TMainForm.StatusBarDrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  c: TCanvas;
begin
  if Panel.Index = 0 then
  begin
    c := StatusBar.Canvas;

    var textSize := c.TextExtent(LastMemStatus);
    var textRect := Rect;
    c.Font.Color := StyleServices.GetSystemColor(clWindowText); //  GetStyleFontColor(sfButtonTextNormal);
    c.TextRect(textRect, LastMemStatus, [tfSingleLine, tfLeft, tfVerticalCenter]);
  end;

end;

end.
