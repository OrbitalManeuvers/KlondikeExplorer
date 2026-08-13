unit u_Layouts;

interface

uses
  System.Types,
  u_Types;

type
  TLayout = record
    Size: TSize;
    CardWidth: Single;
    CardHeight: Single;
    StackOffset: Single;       // uniform Y offset per covered card
    WasteOffset: Single;       // horizontal offset between visible waste cards

    // origins (top-left of where first card sits)
    Origins: array[TStackId] of TPointF;

    procedure SetSize(aWidth, aHeight: Integer);

    // derived helpers
    function CardRect(const aOrigin: TPointF): TRectF;
    function TableauCardY(aCardIndex: Integer): Single;
    function WasteCardX(aVisibleIndex: Integer): Single;
  end;

implementation

uses
  u_DisplayConsts, u_TableUtils;

{ TLayout }

procedure TLayout.SetSize(aWidth, aHeight: Integer);
var
  Margin, ColGap: Single;
  TopRowY, TableauRowY: Single;
  ColX: Single;
begin
  Size.cx := aWidth;
  Size.cy := aHeight;

  Margin := aWidth * EDGE_MARGIN_FRACTION;
  ColGap := aWidth * COLUMN_GAP_FRACTION;

  // 7 columns of cards with 6 gaps between them, plus margins on each side
  CardWidth := (aWidth - 2 * Margin - 6 * ColGap) / 7;
  CardHeight := CardWidth * CARD_ASPECT_RATIO;
  StackOffset := CardHeight * OFFSET_FRACTION;
  WasteOffset := CardWidth * WASTE_OFFSET_FRACTION;

  TopRowY := Margin;
  TableauRowY := TopRowY + CardHeight + (aHeight * TOP_ROW_GAP_FRACTION);

  // Top row layout aligned to tableau columns:
  //   Foundations in columns 1-4 (left)
  //   Waste spans columns 5-6 (middle-right)
  //   Stock in column 7 (right)

  // Foundations align with tableau columns 1..4
  for var stackId := siFoundation1 to siFoundation4 do
  begin
    var foundationIndex := Ord(stackId) - Ord(siFoundation1);
    ColX := Margin + (foundationIndex * (CardWidth + ColGap));
    Origins[stackid] := PointF(ColX, TopRowY);
  end;

  // Waste aligns with tableau column 5 (index 4), spans into column 6
  Origins[siWaste] := PointF(Margin + 4 * (CardWidth + ColGap), TopRowY);

  // Stock aligns with tableau column 7 (index 6)
  Origins[siStock] := PointF(Margin + 6 * (CardWidth + ColGap), TopRowY);

  // Tableau columns span all 7 positions
  for var stackId := siTableau1 to siTableau7 do
  begin
    var tableauIndex := Ord(stackId) - Ord(siTableau1);
    ColX := Margin + (tableauIndex * (CardWidth + ColGap));
    Origins[stackid] := PointF(ColX, TableauRowY);
  end;

end;

function TLayout.CardRect(const aOrigin: TPointF): TRectF;
begin
  Result := RectF(aOrigin.X, aOrigin.Y, aOrigin.X + CardWidth, aOrigin.Y + CardHeight);
end;

function TLayout.TableauCardY(aCardIndex: Integer): Single;
begin
  Result := aCardIndex * StackOffset;
end;

function TLayout.WasteCardX(aVisibleIndex: Integer): Single;
begin
  Result := aVisibleIndex * WasteOffset;
end;

end.
