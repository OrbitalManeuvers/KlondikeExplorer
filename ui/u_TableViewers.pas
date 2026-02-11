unit u_TableViewers;

interface


uses System.Classes, System.SysUtils, System.Types, Vcl.Controls, Vcl.Themes,
  WinApi.Messages, WinApi.Windows, Vcl.Graphics,

  u_Types,
  u_Cards,
  u_Tables,
  u_CardStacks,
  u_CardGraphicsIntf;

type
  TLayoutSizes = record
    tablePadding: TSize;          // inside margin
    stackPadding: TSize;
    stackingOffsets: TSize;
    stackSpacing: TSize;
  end;

  TMoveHighlight = record
    count: Integer;
    source: TRect;
    target: TRect;
  end;

  // TTableViewer
  TTableViewer = class(TCustomControl)
  private
    Table: TTable;
    Images: ICardGraphics;
    Sizes: TLayoutSizes;
    CardSize: TSize; // cached from Images
    Stacks: array[TStackId] of TRect;

    fDebugMode: Boolean;
    fHighlight: TMoveHighlight;

    procedure UpdateLayout;
    procedure SetDebugMode(const Value: Boolean);

    // drawing utils
    procedure InvalidateHighlight;
    procedure FrameCell(target: TCanvas; cellRect: TRect);

    // draws a single card
    procedure DrawCard(card: TCard; faceUp: Boolean; where: TPoint; target: TCanvas; allowDebug: Boolean = False);

    // draws all stack types
    procedure DrawStack(stack: TCardStack; category: TStackCategory; target: TCanvas; cellRect: TRect);

  protected
    clTable: TColor;
    procedure Paint; override;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  public
    constructor Create(AOwner: TComponent; const ACardGraphic: ICardGraphics); reintroduce;
    destructor Destroy; override;

    property DebugMode: Boolean read fDebugMode write SetDebugMode;

    procedure LoadFrom(aTable: TTable);
    procedure HighlightMove(aMove: TMove);
    procedure ClearMove;
  end;


implementation

uses Vcl.GraphUtil, System.Math, System.StrUtils;

type
  TPenHelper = class helper for TPen
    procedure Config(aStyle: TPenStyle; aWidth: Integer; aColor: TColor);
  end;

procedure TPenHelper.Config(aStyle: TPenStyle; aWidth: Integer; aColor: TColor);
begin
  Self.Style := aStyle;
  Self.Width := aWidth;
  Self.Color := aColor;
end;


{ TTableViewer }

constructor TTableViewer.Create(AOwner: TComponent; const ACardGraphic: ICardGraphics);
begin
  inherited Create(AOwner);
  Images := aCardGraphic;
  Table := nil;

  CardSize := Images.GetCardSize;
  clTable := Vcl.GraphUtil.GetShadowColor(clMoneyGreen, -120);

  // set up static values
  Sizes.tablePadding := TSize.Create(4, 4);     // reserved internal border
  Sizes.stackPadding := TSize.Create(2, 2);     // padding inside each virtual stack cell
  Sizes.stackSpacing := TSize.Create(5, 6);     // how much space between stacks
  Sizes.stackingOffsets := TSize.Create(13, 13);  // how much to move stacked cards
end;

destructor TTableViewer.Destroy;
begin
  //
  inherited;
end;

procedure TTableViewer.UpdateLayout;
begin
  // this requires both the table and the images
  if (Table = nil) or (Images = nil) then
    Exit;

  // starting point
  var content := Bounds(0, 0, Width, Height);
  content.Inflate(-sizes.tablePadding.cx, -sizes.tablePadding.cy);

  var r: TRect;
  var id: TStackId;

  // set up foundation stacks
  r.TopLeft := content.TopLeft;
  r.Width := (sizes.stackPadding.cx * 2) + CardSize.cx;
  r.Height := (sizes.stackPadding.cy * 2) + CardSize.cy;
  for id := siFoundation1 to siFoundation4 do
  begin
    Stacks[id] := r;
    r.Offset(r.Width + sizes.stackSpacing.cx, 0);
  end;

  // waste pile
  r.Offset(sizes.StackSpacing.cx * 2, 0);
  r.Width := (sizes.stackPadding.cx * 2) + CardSize.cx;
  r.Width := Trunc(r.Width * 1.55);
  Stacks[siWaste] := r;

  // stock pile
  r.Offset(r.Width + Trunc(sizes.stackSpacing.cx * 1.5), 0);
  r.Width := (sizes.stackPadding.cx * 2) + CardSize.cx;
  Stacks[siStock] := r;

  // tableau piles
  r.Left := content.Left;
  r.Top := (sizes.stackPadding.cy * 2) + CardSize.cy + sizes.stackSpacing.cy;
  r.Width := (sizes.stackPadding.cx * 2) + CardSize.cx;
  for id := siTableau1 to siTableau7 do
  begin
    r.Height := (sizes.stackPadding.cy * 2) + CardSize.cy +
      (sizes.stackingOffsets.cy * (Table.Stacks[id].Count - 1));
    Stacks[id] := r;
    r.Offset(r.Width + sizes.stackSpacing.cx, 0);
  end;
end;

procedure TTableViewer.FrameCell(target: TCanvas; cellRect: TRect);
begin
  target.Pen.Style := psSolid;
  target.Pen.Width := 1;
  target.Pen.Color := Vcl.GraphUtil.GetShadowColor(clTable, -20);
  target.Polyline([
    Point(cellRect.Left, cellRect.Bottom),
    cellRect.TopLeft,
    Point(cellRect.Right, cellRect.Top)
  ]);

  target.Pen.Color := Vcl.GraphUtil.GetHighlightColor(clTable, 15);
  target.Polyline([
    Point(cellRect.Right, cellRect.Top),
    Point(cellRect.Right, cellRect.Bottom),
    cellRect.BottomRight,
    Point(cellRect.Left, cellRect.Bottom)
  ]);
end;

procedure TTableViewer.HighlightMove(aMove: TMove);
begin
  // if there's a move active already, it has to be invalidated
  if fHighlight.count > 0 then
    InvalidateHighlight;

  fHighlight.count := aMove.Count;
  if fHighlight.count = 0 then
    Exit;

  // figure out where to highlight
  fHighlight.source := Stacks[AMove.Source];

  // adjust the source rect based on stack type and card count
  var category := IdToCategory(AMove.Source);
  case category of
    scStock: ;

    scWaste:
      begin
        var cardsShowing := Min(3, Table.Waste.Count);
        Inc(fHighlight.source.Left, (cardsShowing - 1) * sizes.stackingOffsets.cx);
      end;

    scTableau:
      begin
        var stack := Table.Stacks[AMove.Source];
        var firstMoveIndex := stack.Count - aMove.Count;
        Inc(fHighlight.source.Top, firstMoveIndex * sizes.stackingOffsets.cy);

        // bottom goes past the last card
        fHighlight.source.Bottom := fHighlight.source.Top +
          ((aMove.Count - 1) * sizes.stackingOffsets.cy) +
          CardSize.cy +
          (sizes.stackPadding.cy * 2);
      end;

    scFoundation: ;
  end;

  // target
  var r := Rect(0, 0, 0, 0);
  category := IdToCategory(aMove.Target);
  if category in [scTableau, scFoundation, scWaste] then
  begin
    r := Stacks[aMove.Target];
    r.Top := r.Bottom - (sizes.stackPadding.cy + CardSize.cy);
    if (category = scTableau) and Table.Stacks[aMove.Target].HasCards then
      r.Offset(0, sizes.stackingOffsets.cy);
  end;
  fHighlight.target := r;

  InvalidateHighlight;
end;

procedure TTableViewer.InvalidateHighlight;
begin
  if (fHighlight.Count > 0) and HandleAllocated then
  begin
    InvalidateRect(Self.Handle, @fHighlight.source, False);
    InvalidateRect(Self.Handle, @fHighlight.target, False);
  end;
end;

procedure TTableViewer.ClearMove;
begin
  if fHighlight.Count > 0 then
  begin
    fHighlight.Count := 0;
    InvalidateHighlight;
  end;
end;

procedure TTableViewer.DrawCard(card: TCard; faceUp: Boolean; where: TPoint; target: TCanvas; allowDebug: Boolean);
begin
  if Assigned(Images) then
  begin
    Images.Draw(card, faceUp or DebugMode, where, target, DebugMode and allowDebug);
  end;
end;

procedure TTableViewer.DrawStack(stack: TCardStack; category: TStackCategory; target: TCanvas; cellRect: TRect);
begin
  if category in [scStock, scWaste, scFoundation] then
  begin
    FrameCell(target, cellRect);
  end;

  // if there are no cards in the stack, we're done
  if stack.Count = 0 then
    Exit;

  // top left corner of card image
  var topLeft := cellRect.TopLeft;
  topLeft.Offset(sizes.stackPadding.cx, sizes.stackPadding.cy);

  case category of

    scStock:
      begin
        var c := stack.Last;
        DrawCard(c, False, topLeft, target);

        target.Font.Name := 'Segoe UI';
        target.Font.Size := 10;
        target.Font.Color := StyleServices.GetSystemColor(clWindowText);

        var caption := stack.Count.ToString();
        var textSize := target.TextExtent(caption);
        var textRect: TRect;

        textRect.Top := cellRect.CenterPoint.Y - (textSize.cy div 2);
        textRect.Height := textSize.cy;
        textRect.Left := cellRect.Left + sizes.stackPadding.cx;
        textRect.Right := cellRect.Right - sizes.stackPadding.cx;

        cellRect := textRect;
        cellRect.Inflate(0, 2);
        Inc(cellRect.Left, sizes.stackSpacing.cx * 2);
        Dec(cellRect.Right, sizes.stackSpacing.cx * 2);

        target.Brush.Style := bsSolid;
        target.Brush.Color := StyleServices.GetSystemColor(clWebRoyalBlue);
        target.FillRect(cellRect);
        target.TextRect(textRect, caption, [tfSingleLine, tfCenter]);
      end;

    scWaste:
      begin
        // try to draw 3 cards
        var drawCount := Min(3, stack.Count);
        var cardIndex := stack.Count - drawCount;
        while cardIndex < stack.Count do
        begin
          var c := stack.Cards[cardIndex];
          DrawCard(c, True, topLeft, target);
          topLeft.Offset(sizes.stackingOffsets.cx, 0);
          Inc(cardIndex);
        end;
      end;

    scTableau:
      begin
        for var cardIndex := 0 to stack.Count - 1 do
        begin
          var c := stack[cardIndex];
          DrawCard(c, cardIndex >= stack.Count - stack.FaceUpCount, topLeft, target, cardIndex < stack.Count - 1);
          Inc(topLeft.Y, sizes.stackingOffsets.cy);
        end;

        Dec(topLeft.Y, sizes.stackingOffsets.cy);
        cellRect.Bottom := topLeft.Y + CardSize.cy + sizes.stackPadding.cy;
        FrameCell(target, cellRect);
      end;

    scFoundation:
      begin
        DrawCard(stack.Last, True, topLeft, target);
      end;
  end;
end;

procedure TTableViewer.Paint;
var
  r: TRect;
  cellRect: TRect;
begin
  Canvas.Brush.Color := clTable;
  Canvas.FillRect(Canvas.ClipRect);

  // early exit when things aren't set up yet
  if (not Assigned(Images)) or (not Assigned(Table)) then
    Exit;

  var b := TBitmap.Create(ClientWidth, ClientHeight);
  try
    r := Self.ClientRect;
    b.Canvas.Brush.Color := clTable;
    b.Canvas.Brush.Style := bsSolid;
    b.Canvas.FillRect(r);

    // draw stacks
    for var id := Low(TStackId) to High(TStackId) do
    begin
      var category := IdToCategory(id);
      cellRect := Stacks[id];

      // ?clip rect?

      DrawStack(Table.Stacks[id], category, b.Canvas, cellRect);

      if fDebugMode then
      begin
        b.Canvas.Brush.Style := bsClear;
        b.Canvas.Pen.Config(psSolid, 1, GetHighlightColor(clTable, 20));
        b.Canvas.Rectangle(cellRect);
      end;
    end;

    // show move highlight
    if fHighlight.Count > 0 then
    begin
      b.canvas.Brush.Style := bsClear;
      b.Canvas.Pen.Config(psInsideFrame, 2, clYellow);
      b.Canvas.Rectangle(fHighlight.source);

      if not fHighlight.target.IsEmpty then
      begin
        b.Canvas.Pen.Config(psDash, 1, clLime);
        b.Canvas.Rectangle(fHighlight.target);
      end;
    end;

    r := Canvas.ClipRect;
    Canvas.CopyRect(r, b.Canvas, r);

  finally
    b.Free;
  end;
end;

procedure TTableViewer.LoadFrom(aTable: TTable);
begin
  Table := aTable;
  UpdateLayout;
  ClearMove;
  Invalidate;
end;

procedure TTableViewer.SetDebugMode(const Value: Boolean);
begin
  fDebugMode := Value;
  Invalidate;
end;

procedure TTableViewer.WMSize(var Message: TWMSize);
begin
  inherited;
  UpdateLayout;
end;


end.
