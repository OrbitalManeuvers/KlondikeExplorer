unit fr_Session;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.Mask, Vcl.Buttons, Vcl.ControlList,

  u_Types,
  u_SeedLibraries,
  u_SnapshotManagers,
  u_SnapshotTokens,
  u_SnapshotLibraries;

type
  TSessionResetEvent = procedure (Sender: TObject; Token: TSnapshotToken) of object;

  TSessionFrame = class(TFrame)
    lblSession: TLabel;
    lblSelectedConfig: TLabel;
    edtRestartMethod: TEdit;
    bvlRight: TBevel;
    btnActivateRandom: TSpeedButton;
    btnReset: TSpeedButton;
    SeedList: TControlList;
    btnSaveSeed: TSpeedButton;
    btnActivateSeed: TSpeedButton;
    btnEditSeed: TSpeedButton;
    btnDeleteSeed: TSpeedButton;
    btnActivateSnapshot: TSpeedButton;
    SnapshotList: TControlList;
    btnEditSnapshot: TSpeedButton;
    btnDeleteSnapshot: TSpeedButton;
    lblSeedNameDisplay: TLabel;
    lblSnapshotNameDisplay: TLabel;
    pbDivider1: TPaintBox;
    lblRandSeeds: TLabel;
    edtLastGeneratedSeed: TEdit;
    Label2: TLabel;
    pbDivider2: TPaintBox;
    lblPredefinedSeeds: TLabel;
    pbDivider3: TPaintBox;
    lblSnapshots: TLabel;
    procedure btnActivateRandomClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnSaveSeedClick(Sender: TObject);
    procedure btnActivateSeedClick(Sender: TObject);
    procedure SeedListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure btnActivateSnapshotClick(Sender: TObject);
    procedure SnapshotListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure btnDeleteSnapshotClick(Sender: TObject);
    procedure btnEditSnapshotClick(Sender: TObject);
    procedure SeedListItemClick(Sender: TObject);
    procedure btnEditSeedClick(Sender: TObject);
    procedure btnDeleteSeedClick(Sender: TObject);
    procedure DividerPaint(Sender: TObject);
    procedure SnapshotListClick(Sender: TObject);
  private type
    TUIMode = (uiRandom, uiSeed, uiSnapshot);
  private
    fOnReset: TSessionResetEvent;
    fSeedLibrary: TSeedLibrary;
    fSnapshotLibrary: TSnapshotLibrary;

    // one or neither of these will be set. none = [random] mode
    fUIMode: TUIMode;
    fActiveSeed: TSeed;
    fActiveSnapshot: TSnapshotToken;
    fActiveRandom: Integer;

    procedure UpdateControls;
    procedure Reset;

    // library management
    function EditSeedProperties(const aCaption: string; var aSeed: TSeed): Boolean;

    // init
    procedure SetSeedLibrary(const Value: TSeedLibrary);
    procedure SetSnapshotLibrary(const Value: TSnapshotLibrary);
    procedure SetUIMode(aMode: TUIMode);
  public
    constructor Create(AOwner: TComponent); override;

    property SeedLibrary: TSeedLibrary read fSeedLibrary write SetSeedLibrary;
    property SnapshotLibrary: TSnapshotLibrary read fSnapshotLibrary write SetSnapshotLibrary;

    property OnReset: TSessionResetEvent read fOnReset write fOnReset;
  end;

implementation

uses Vcl.GraphUtil, Vcl.Themes;

{$R *.dfm}

{ TSessionFrame }
constructor TSessionFrame.Create(AOwner: TComponent);
begin
  inherited;
  SetUIMode(uiRandom);
end;

procedure TSessionFrame.btnActivateRandomClick(Sender: TObject);
begin
  SetUIMode(uiRandom);
end;

procedure TSessionFrame.btnActivateSeedClick(Sender: TObject);
begin
  SetUIMode(uiSeed);
end;

procedure TSessionFrame.btnActivateSnapshotClick(Sender: TObject);
begin
  SetUIMode(uiSnapshot);
end;

procedure TSessionFrame.btnDeleteSeedClick(Sender: TObject);
begin
  //
end;

procedure TSessionFrame.btnDeleteSnapshotClick(Sender: TObject);
begin
  //
end;

procedure TSessionFrame.btnEditSeedClick(Sender: TObject);
begin
  //
end;

procedure TSessionFrame.btnEditSnapshotClick(Sender: TObject);
begin
  //
end;

procedure TSessionFrame.btnResetClick(Sender: TObject);
begin
  Reset;
end;

procedure TSessionFrame.btnSaveSeedClick(Sender: TObject);
begin
  // save last random value as a new seed

  var seed: TSeed;
  seed.Value := fActiveRandom;
  seed.Name := '';
  if EditSeedProperties('Add Seed', seed) then
  begin
    fSeedLibrary.Add(seed);
    SeedList.ItemCount := fSeedLibrary.Count;
    SeedList.Invalidate;

    UpdateControls;
  end;

end;

function TSessionFrame.EditSeedProperties(const aCaption: string; var aSeed: TSeed): Boolean;
begin
  Result := False;

  var prompts: array of string := ['Name:', 'Value:'];
  var values: array of string := [aSeed.Name, aSeed.Value.ToString];

  if InputQuery(aCaption, prompts, values) then
  begin
    aSeed.name := values[0];
    aSeed.value := values[1].ToInteger;
    Result := True;
  end;
end;

procedure TSessionFrame.DividerPaint(Sender: TObject);
begin
  if Sender is TPaintBox then
  begin
    var pb := TPaintBox(Sender);
    var c := TPaintBox(Sender).Canvas;
    c.Brush.Color := $004080FF; //StyleServices.GetSystemColor(clBtnHighlight);
    c.Brush.Style := bsSolid;
    c.Rectangle(pb.ClientRect);
  end;
end;

procedure TSessionFrame.Reset;
begin
  // pre-reset values
  case fUIMode of

    uiRandom:
      begin
        var value := Random(MaxInt);
        if Random(100) < 50 then
          value := -value;
        edtLastGeneratedSeed.Text := value.ToString;
        fActiveRandom := value;
        RandSeed := value;
      end;

    uiSeed:
      begin
        RandSeed := fActiveSeed.Value;
      end;

    uiSnapshot: begin end;
  end;

  // send the reset event
  if Assigned(fOnReset) then
    fOnReset(Self, fActiveSnapshot);
  UpdateControls;
end;

procedure TSessionFrame.SeedListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if AIndex < fSeedLibrary.Count then
    lblSeedNameDisplay.Caption := fSeedLibrary[AIndex].ToString;
end;

procedure TSessionFrame.SeedListItemClick(Sender: TObject);
begin
  UpdateControls;
end;

procedure TSessionFrame.SetSeedLibrary(const Value: TSeedLibrary);
begin
  fSeedLibrary := Value;
  SeedList.ItemCount := 0;
  if Assigned(fSeedLibrary) then
    SeedList.ItemCount := fSeedLibrary.Count;
end;

procedure TSessionFrame.SetSnapshotLibrary(const Value: TSnapshotLibrary);
begin
  fSnapshotLibrary := Value;
  SnapshotList.ItemCount := 0;
  if Assigned(fSnapshotLibrary) then
    SnapshotList.ItemCount := fSnapshotLibrary.Count;
end;

procedure TSessionFrame.SetUIMode(aMode: TUIMode);
begin
  fUIMode := aMode;

  if fUIMode = uiSeed then
  begin
    fActiveSeed := SeedLibrary.Seeds[SeedList.ItemIndex];
    edtRestartMethod.Text := fActiveSeed.ToString;
  end
  else
  begin
    fActiveSeed.Value := 0;
    fActiveSeed.Name := ''; // not really necessary?
  end;

  if fUIMode = uiSnapshot then
  begin
    // by the time we get here, a snapshot should have a token
    fActiveSnapshot := SnapshotLibrary.Tokens[SnapshotList.ItemIndex];
    edtRestartMethod.Text := SnapshotLibrary.Names[SnapshotList.ItemIndex] + ' [snapshot]';
  end
  else
  begin
    fActiveSnapshot := NO_SNAPSHOT;
  end;

  if fUIMode = uiRandom then
  begin
    edtRestartMethod.Text := '[New Random Per Reset]';
  end
  else
  begin
    fActiveRandom := 0;
    edtLastGeneratedSeed.Text := '';
  end;

  UpdateControls;
end;

procedure TSessionFrame.SnapshotListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  if Assigned(fSnapshotLibrary) and (AIndex < fSnapshotLibrary.Count) then
    lblSnapshotNameDisplay.Caption := fSnapshotLibrary.Names[AIndex]
  else
    lblSnapshotNameDisplay.Caption := '';
end;

procedure TSessionFrame.SnapshotListClick(Sender: TObject);
begin
  UpdateControls;
end;

procedure TSessionFrame.UpdateControls;
begin
  // which section is active?
  lblRandSeeds.Enabled := (fActiveSeed.Value = 0) and (fActiveSnapshot = NO_SNAPSHOT);
  lblPredefinedSeeds.Enabled := fActiveSeed.Value <> 0;
  lblSnapshots.Enabled := fActiveSnapshot <> NO_SNAPSHOT;

  // update sections
  var hasSelection := SeedList.ItemIndex <> -1;
  btnActivateSeed.Enabled := hasSelection;
  btnEditSeed.Enabled := hasSelection;
  btnDeleteSeed.Enabled := hasSelection;

  hasSelection := SnapshotList.ItemIndex <> -1;
  btnActivateSnapshot.Enabled := hasSelection;
  btnEditSnapshot.Enabled := hasSelection;
  btnDeleteSnapshot.Enabled := hasSelection;

  btnSaveSeed.Enabled := edtLastGeneratedSeed.Text <> '';
  btnActivateRandom.Enabled := fUIMode <> uiRandom;
end;

end.
