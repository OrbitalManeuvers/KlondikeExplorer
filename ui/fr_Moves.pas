unit fr_Moves;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ControlList,
  Vcl.StdCtrls, Vcl.Themes,

  u_EvalLists, Vcl.Grids, Vcl.ValEdit;

type
  TMovesFrame = class(TFrame)
    MoveList: TControlList;
    lblMoves: TLabel;
    lblCaption: TLabel;
    lblScore: TLabel;
    FactorList: TControlList;
    lblScoreFactor: TLabel;
    FeatureList: TValueListEditor;
    procedure MoveListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure MoveListItemClick(Sender: TObject);
    procedure FactorListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure FeatureListDrawCell(Sender: TObject; ACol, ARow: LongInt;
      Rect: TRect; State: TGridDrawState);
  private
    fEvals: TEvalList;
    fFeatureValues: TStrings;
    fOnSelectionChange: TNotifyEvent;
    function GetSelectedIndex: Integer;
    procedure UpdateDetail;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFrom(const Evaluations: TEvalList);
    property OnSelectionChange: TNotifyEvent read fOnSelectionChange write fOnSelectionChange;
    property SelectedIndex: Integer read GetSelectedIndex;
  end;

implementation

{$R *.dfm}

uses
  u_Moves.Render,
  u_Moves.Analysis;

{ TMovesFrame }
constructor TMovesFrame.Create(AOwner: TComponent);
begin
  inherited;
  fFeatureValues := TStringList.Create(dupIgnore, False, False);
  LoadFrom(nil);
end;

destructor TMovesFrame.Destroy;
begin
  fFeatureValues.Free;
  inherited;
end;

procedure TMovesFrame.Clear;
begin
  MoveList.ItemCount := 0;
  FactorList.ItemCount := 0;
end;

procedure TMovesFrame.FactorListBeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
begin
  var factor := TScoreFactor(AIndex);
  lblScoreFactor.Caption := FactorToStr(factor);
  if (SelectedIndex <> -1) and (factor in fEvals[SelectedIndex].Factors) then
    lblScoreFactor.Font.Color := clLime
  else
    lblScoreFactor.Font.Color := clGrayText;
end;

procedure TMovesFrame.FeatureListDrawCell(Sender: TObject; ACol, ARow: LongInt;
  Rect: TRect; State: TGridDrawState);
begin
  var v := (Sender as TValueListEditor);

  if ARow < FeatureList.Strings.Count then
  begin
    var cellText: string;
    if ACol = 0 then
      cellText := FeatureList.Strings.Names[aRow]
    else
      cellText := FeatureList.Strings.ValueFromIndex[aRow];

    var r := Rect;
    v.Canvas.Font.Color := StyleServices.GetSystemColor(clWindowText);
    if cellText = 'Y' then
      v.Canvas.Font.Color := clLime
    else if cellText = 'N' then
      v.Canvas.Font.Color := clRed;
    v.Canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    v.Canvas.TextRect(R, r.Left + 4, r.Top + 2, cellText);
  end;
end;

function TMovesFrame.GetSelectedIndex: Integer;
begin
  Result := MoveList.ItemIndex;
end;

procedure TMovesFrame.LoadFrom(const Evaluations: TEvalList);
begin
  MoveList.ItemCount := 0;
  MoveList.ItemIndex := -1;
  fEvals := Evaluations;
  if Assigned(fEvals) then
    MoveList.ItemCount := fEvals.Count;
  UpdateDetail;

end;

procedure TMovesFrame.MoveListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
  ARect: TRect; AState: TOwnerDrawState);
begin
  if (not Assigned(fEvals)) or (AIndex < 0) or (AIndex >= fEvals.Count) then
    Exit;

  lblCaption.Caption := fEvals[AIndex].Move.Description;
  lblScore.Caption := fEvals[AIndex].Score.ToString;
  var c := clLime;
  if fEvals[Aindex].Score <= 0 then
    c := StyleServices.GetSystemColor(clGrayText);
  lblScore.Font.Color := c;
end;

procedure TMovesFrame.MoveListItemClick(Sender: TObject);
begin
  UpdateDetail;
  if Assigned(fOnSelectionChange) then
    fOnSelectionChange(Self);
end;

procedure TMovesFrame.UpdateDetail;

  function b2s(value: Boolean): string;
  begin
    if value then Result := 'Y'
    else Result := 'N';
  end;

begin
  FactorList.ItemCount := Ord(High(TScoreFactor));
  FactorList.Invalidate;

  var f: TMoveFeatures;
  if SelectedIndex = -1 then
    FillChar(f, SizeOf(TMoveFeatures), 0)
  else
    f := fEvals[SelectedIndex].Features;

  fFeatureValues.Values['MovedRunLength'] := f.MovedRunLength.ToString;
  fFeatureValues.Values['NewBuildLength'] := f.NewBuildLength.ToString;
  fFeatureValues.Values['SourceResidualRunLen'] := f.SourceResidualRunLength.ToString;
  fFeatureValues.Values['RunDestinationsCount'] := f.RunDestinationsCount.ToString;
  fFeatureValues.Values['SourceFaceDownDistanceDelta'] := f.SourceFaceDownDistanceDelta.ToString;
  fFeatureValues.Values['SourceStackDepth'] := f.SourceStackDepth.ToString;
  fFeatureValues.Values['SourceFaceDownCount'] := f.SourceFaceDownCount.ToString;
  fFeatureValues.Values['TargetStackDepth'] := f.TargetStackDepth.ToString;
  fFeatureValues.Values['EmptyTableauCount'] := f.EmptyTableauCount.ToString;
  fFeatureValues.Values['HasHiddenKingInWaste'] := b2s(f.HasHiddenKingInWaste);
  fFeatureValues.Values['CanReverseImmediately'] := b2s(f.CanReverseImmediately);
  fFeatureValues.Values['IsOscillationProne'] := b2s(f.IsOscillationProne);
  fFeatureValues.Values['CanBeDelayed'] := b2s(f.CanBeDelayed);
  fFeatureValues.Values['BrokeBuild'] := b2s(f.BrokeBuild);
  fFeatureValues.Values['PreservedRun'] := b2s(f.PreservedRun);

  fFeatureValues.Values['P.table'] := f.Pressure.table.ToString;
  fFeatureValues.Values['P.king'] := f.Pressure.king.ToString;
  fFeatureValues.Values['P.card'] := f.Pressure.card.ToString;
  fFeatureValues.Values['P.reduces'] := f.Pressure.reduces.ToString;

  FeatureList.Strings := fFeatureValues;
  FeatureList.Enabled := True;

end;


end.
