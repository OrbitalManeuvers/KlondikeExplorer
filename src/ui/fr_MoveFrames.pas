unit fr_MoveFrames;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.StdCtrls,

  u_Types, u_StateManagers, u_Snapshots, u_Tables, u_MoveHelpers;

type
  TMoveSelectedEvent = procedure(Sender: TObject; aMoveIndex: Integer) of object;

  TMoveFrame = class(TContentFrame)
    lblTitle: TLabel;
    MovesList: TControlList;
    lblMoveName: TLabel;
    lblHValue: TLabel;
    shHintStatus: TShape;
    procedure MovesListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
    procedure MovesListItemClick(Sender: TObject);
  private type
    TMoveRow = record
      Caption: string;
      Executed: Boolean;
      HValue: Single;
      OriginalIndex: Integer;
      Score: Integer;
      M: TMove;
    end;
  private
    fRows: TList<TMoveRow>;
    fTable: TTable;
    fMoveInfo: TMoveInfo;
    fHintRows: TList<Integer>;    // indices into fRows (sorted), best-first, no zeros
    fHintCycle: Integer;          // which ring position the next hint returns
    fHintRowHighlight: Integer;   // fRows index of the last hint handed out (-1 = none)
    fOnMoveSelected: TMoveSelectedEvent;
    procedure Clear;
  public
    procedure InitContent; override;
    procedure DoneContent; override;
    procedure HandleCursorChange(aNode: TStateNode; aSnapshot: TSnapshot); override;

    // hint ring: best-first, dud-free. the frame owns the cycle; each call returns the
    // next hint move and advances, wrapping around. False when there are no hints.
    function NextHintMove(out aMove: TMove): Boolean;

    property OnMoveSelected: TMoveSelectedEvent read fOnMoveSelected write fOnMoveSelected;
  end;


implementation

{$R *.dfm}

uses Vcl.Themes, System.Generics.Defaults,
  u_MoveEvaluators, u_MoveValidators;

{ TMoveFrame }

procedure TMoveFrame.InitContent;
begin
  inherited;
  fTable := TTable.Create;
  fRows := TList<TMoveRow>.Create;
  fMoveInfo := TMoveInfo.Create(fTable);
  fHintRows := TList<Integer>.Create;
  Clear;
end;

procedure TMoveFrame.DoneContent;
begin
  MovesList.ItemCount := 0;
  fMoveInfo.Free;
  fRows.Free;
  fTable.Free;
  fHintRows.Free;

  inherited;
end;

procedure TMoveFrame.MovesListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas; ARect: TRect;
  AState: TOwnerDrawState);
begin
  // echo of the last hint handed out by NextHintMove: frame that row in gold to match
  // the table's move highlight, so "press Hint" reads as one gesture across both views.
  if (AIndex = fHintRowHighlight) and (AIndex >= 0) then
  begin
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := clWebGold;
    ACanvas.FrameRect(ARect);
  end;

  if (AIndex >= 0) and (AIndex < fRows.Count) then
  begin
    var row := fRows[AIndex];
    lblMoveName.Caption := row.Caption;
    if row.Executed then
    begin
      lblHValue.Caption := Format('%f', [row.HValue]);
      if row.HValue > 0 then
        lblHValue.Font.Color := clRed
      else
        lblHValue.Font.Color := clGreen;
    end
    else
      lblHValue.Caption := '';

    if row.Score = 0 then
    begin
      shHintStatus.Brush.Style := bsClear;
      shHintStatus.Pen.Color := clWebCrimson;// StyleServices.GetStyleColor(scButtonDisabled);
    end
    else
    begin
      shHintStatus.Brush.Style := bsSolid;
      shHintStatus.Pen.Color := clMoneyGreen;
      shHintStatus.Brush.Color := clMoneyGreen;
    end;

  end;
end;

procedure TMoveFrame.MovesListItemClick(Sender: TObject);
begin
  if (MovesList.ItemCount > 0) and (MovesList.ItemIndex >= 0) and Assigned(fOnMoveSelected) then
    fOnMoveSelected(Self, fRows[MovesList.ItemIndex].OriginalIndex);
  fHintRowHighlight := -1;
  MovesList.Invalidate;
end;

procedure TMoveFrame.Clear;
begin
  fRows.Clear;
  MovesList.ItemIndex := -1;
  MovesList.ItemCount := 0;
  fHintRows.Clear;
  fHintCycle := 0;
  fHintRowHighlight := -1;
end;

procedure TMoveFrame.HandleCursorChange(aNode: TStateNode; aSnapshot: TSnapshot);
begin
  inherited;
  Clear;

  // load the snapshot into our local table
  aSnapshot.Restore(fTable);

  for var moveIndex := 0 to aNode.Moves.Count - 1 do
  begin
    var m := aNode.Moves[moveIndex];

    var row := Default(TMoveRow);
    row.M := m;
    row.Caption := m.AsText;
    row.OriginalIndex := moveIndex;

    var childNode := aNode.ChildForMove(moveIndex);
    row.Executed := Assigned(childNode);
    if row.Executed then
      row.hValue := childNode.HValue - aNode.HValue;

    // evaluate the move for hint sorting
    fMoveInfo.Load(m);

    row.Score := TMoveEvaluator.Score(fMoveInfo);
    if row.Score <> 0 then
      row.Caption := row.Caption + ' (' + row.Score.ToString + ')';

    fRows.Add(row);
  end;

  // sort rows best-first (highest score at top)
  fRows.Sort(TComparer<TMoveRow>.Construct(
    function(const A, B: TMoveRow): Integer
    begin
      if A.Score > B.Score then
        Result := -1
      else if A.Score < B.Score then
        Result := 1
      else
        Result := 0;
    end
  ));

  // build the hint ring from the SORTED rows so cycling is best-first. we store the
  // fRows index (not OriginalIndex) so both the returned move and the row highlight are
  // direct. every non-zero row is a hint; draw/recycle always score 1 (mfBookkeeping),
  // so there's always at least one hint unless the board is a true dead end.
  for var i := 0 to fRows.Count - 1 do
    if fRows[i].Score <> 0 then
      fHintRows.Add(i);

  MovesList.ItemCount := fRows.Count;
end;

function TMoveFrame.NextHintMove(out aMove: TMove): Boolean;
begin
  if fHintRows.Count = 0 then
  begin
    fHintRowHighlight := -1;
    Exit(False);
  end;

  var rowIndex := fHintRows[fHintCycle mod fHintRows.Count];
  aMove := fRows[rowIndex].M;

  // remember which row we just handed out so the frame can highlight it (paint TBD),
  // and advance the ring for the next press.
  fHintRowHighlight := rowIndex;
  Inc(fHintCycle);

  MovesList.Invalidate;
  Result := True;
end;

end.
