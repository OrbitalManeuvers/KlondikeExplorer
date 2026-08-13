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
//    StockOrigin: TPointF;
//    WasteOrigin: TPointF;
//    FoundationOrigins: array[TCardSuit] of TPointF;
//    TableauOrigins: array[TTableauIndex] of TPointF;

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
  I: Integer;
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

  var stackid: TStackIterator;

  // foundations
  stackid.Init(siFoundation1, siFoundation4);
  repeat
    var index := Ord(stackid.Current) - Ord(siFoundation1);
    ColX := Margin + index * (CardWidth + ColGap);
    Origins[stackid.Current] := PointF(ColX, TopRowY);
  until not stackid.MoveNext;

//  for I := 0 to 3 do
//  begin
//    ColX := Margin + I * (CardWidth + ColGap);
//    FoundationOrigins[TCardSuit(I)] := PointF(ColX, TopRowY);
//  end;

  // Waste aligns with tableau column 5 (index 4), spans into column 6
  Origins[siWaste] := PointF(Margin + 4 * (CardWidth + ColGap), TopRowY);
//  WasteOrigin := PointF(Margin + 4 * (CardWidth + ColGap), TopRowY);

  // Stock aligns with tableau column 7 (index 6)
  Origins[siStock] := PointF(Margin + 6 * (CardWidth + ColGap), TopRowY);
//  StockOrigin := PointF(Margin + 6 * (CardWidth + ColGap), TopRowY);

  // Tableau columns span all 7 positions
  stackid.Init(siTableau1, siTableau7);
  repeat
    var index := Ord(stackid.Current) - Ord(siTableau1);
    ColX := Margin + index * (CardWidth + ColGap);
    Origins[stackid.Current] := PointF(ColX, TableauRowY);
  until not stackid.MoveNext;

//  for I := 1 to 7 do
//  begin
//    ColX := Margin + (I - 1) * (CardWidth + ColGap);
//    TableauOrigins[I] := PointF(ColX, TableauRowY);
//  end;
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
