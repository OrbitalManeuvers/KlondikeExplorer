unit u_RenderUtils;

interface

uses
  System.Types, System.UITypes, System.Skia,
  u_Types, u_CardResources;

type
  TRenderUtils = class
  private
    class var res: TCardResources;
  public
    class procedure DrawCard(const aCanvas: ISkCanvas; aCard: TCard;
      const aRect: TRectF; aFaceUp: Boolean);
    class procedure DrawCardBack(const aCanvas: ISkCanvas; const aRect: TRectF);
    class procedure DrawEmptySlot(const aCanvas: ISkCanvas; const aRect: TRectF);
    class procedure DrawCardHighlight(const aCanvas: ISkCanvas;
      const aRect: TRectF; aColor: TAlphaColor; aOpacity: Single);

    // called once by owner of resource instance
    class procedure SetResources(aRes: TCardResources);
  end;

implementation

uses
  System.Math, u_CardHelpers;

const
  // Proportions relative to card width/height for element placement
  RANK_FONT_FRACTION = 0.22;      // rank text size as fraction of card width
  SUIT_SMALL_FRACTION = 0.22;     // small suit icon size as fraction of card width
  SUIT_LARGE_FRACTION = 0.80;     // center suit icon size as fraction of card width
  CORNER_INSET_X = 0.08;          // X inset for corner elements as fraction of width
  CORNER_INSET_Y = 0.06;          // Y inset for corner elements as fraction of height
  BACK_INSET_FRACTION = 0.06;     // card back inner rect inset as fraction of card width
  CORNER_RADIUS_FRACTION = 0.08;  // rounded corner radius as fraction of card width
  SLOT_STROKE_WIDTH = 1.5;

{ TRenderUtils }

class procedure TRenderUtils.SetResources(aRes: TCardResources);
begin
  res := aRes;
end;

class procedure TRenderUtils.DrawCard(const aCanvas: ISkCanvas; aCard: TCard;
  const aRect: TRectF; aFaceUp: Boolean);
var
  CardW, CardH: Single;
  CornerRadius: Single;
  RR: ISkRoundRect;
  SuitPaint: ISkPaint;
  FontSize: Single;
  Font: ISkFont;
  RankText: string;
  TextBlob: ISkTextBlob;
  Scale: Single;
  SuitSize: Single;
  SuitX, SuitY: Single;
  SmallSuitSize: Single;
  SmallScale: Single;
begin
  if not aFaceUp then
  begin
    DrawCardBack(aCanvas, aRect);
    Exit;
  end;

  CardW := aRect.Width;
  CardH := aRect.Height;
  CornerRadius := CardW * CORNER_RADIUS_FRACTION;

  // Draw card face (white rounded rect)
  RR := TSkRoundRect.Create;
  RR.SetRect(aRect, CornerRadius, CornerRadius);
  aCanvas.DrawRoundRect(RR, res.PaintCardFace);

  // Draw outline
  aCanvas.DrawRoundRect(RR, res.PaintOutline);

  // Determine suit color paint
  if aCard.Color = ccRed then
    SuitPaint := res.PaintRed
  else
    SuitPaint := res.PaintBlack;

  // Draw rank text (top-left corner)
  FontSize := CardW * RANK_FONT_FRACTION;
  Font := TSkFont.Create(res.FontRank.Typeface, FontSize);
  Font.Edging := TSkFontEdging.AntiAlias;

  RankText := aCard.ValueName(True);
  // Use '10' instead of 'T' for display
  if aCard.Value = cvTen then
    RankText := '10';

  TextBlob := TSkTextBlob.MakeFromText(RankText, Font);
  if TextBlob <> nil then
    aCanvas.DrawTextBlob(TextBlob,
      aRect.Left + CardW * CORNER_INSET_X,
      aRect.Top + CardH * CORNER_INSET_Y + FontSize,
      SuitPaint);

  // Draw small suit icon (top-right area, below rank level)
  SmallSuitSize := CardW * SUIT_SMALL_FRACTION;
  SmallScale := SmallSuitSize / 100;  // suit paths are in 0..100 unit space

  aCanvas.Save;
  try
    aCanvas.Translate(
      aRect.Right - CardW * CORNER_INSET_X - SmallSuitSize,
      aRect.Top + CardH * CORNER_INSET_Y);
    aCanvas.Scale(SmallScale, SmallScale);
    for var Part in res.SuitParts[aCard.Suit] do
      aCanvas.DrawPath(Part, SuitPaint);
  finally
    aCanvas.Restore;
  end;

  // Draw large suit icon (centered in remaining vertical space)
  SuitSize := CardW * SUIT_LARGE_FRACTION;
  Scale := SuitSize / 100;  // suit paths are in 0..100 unit space

  SuitX := aRect.Left + (CardW - SuitSize) / 2;
  SuitY := aRect.Top + (CardH - SuitSize) / 2 + CardH * 0.10;  // nudge slightly below center

  aCanvas.Save;
  try
    aCanvas.Translate(SuitX, SuitY);
    aCanvas.Scale(Scale, Scale);
    for var Part in res.SuitParts[aCard.Suit] do
      aCanvas.DrawPath(Part, SuitPaint);
  finally
    aCanvas.Restore;
  end;
end;

class procedure TRenderUtils.DrawCardBack(const aCanvas: ISkCanvas;
  const aRect: TRectF);
var
  CardW: Single;
  CornerRadius: Single;
  Inset: Single;
  InnerRect: TRectF;
  RR: ISkRoundRect;
begin
  CardW := aRect.Width;
  CornerRadius := CardW * CORNER_RADIUS_FRACTION;

  // Outer white card shape
  RR := TSkRoundRect.Create;
  RR.SetRect(aRect, CornerRadius, CornerRadius);
  aCanvas.DrawRoundRect(RR, res.PaintCardFace);
  aCanvas.DrawRoundRect(RR, res.PaintOutline);

  // Inner dark blue rect (inset to show white border)
  Inset := CardW * BACK_INSET_FRACTION;
  InnerRect := RectF(
    aRect.Left + Inset,
    aRect.Top + Inset,
    aRect.Right - Inset,
    aRect.Bottom - Inset);

  RR := TSkRoundRect.Create;
  RR.SetRect(InnerRect, CornerRadius * 0.7, CornerRadius * 0.7);
  aCanvas.DrawRoundRect(RR, res.PaintCardBack);
end;

class procedure TRenderUtils.DrawEmptySlot(const aCanvas: ISkCanvas;
  const aRect: TRectF);
var
  CardW: Single;
  CornerRadius: Single;
  RR: ISkRoundRect;
  Paint: ISkPaint;
begin
  CardW := aRect.Width;
  CornerRadius := CardW * CORNER_RADIUS_FRACTION;

  Paint := TSkPaint.Create;
  Paint.Color := $10FFFFFF;  // semi-transparent gray
  Paint.Style := TSkPaintStyle.Stroke;
  Paint.StrokeWidth := SLOT_STROKE_WIDTH;
  Paint.AntiAlias := True;

  RR := TSkRoundRect.Create;
  RR.SetRect(aRect, CornerRadius, CornerRadius);
  aCanvas.DrawRoundRect(RR, Paint);
end;

class procedure TRenderUtils.DrawCardHighlight(const aCanvas: ISkCanvas;
  const aRect: TRectF; aColor: TAlphaColor; aOpacity: Single);
var
  CardW: Single;
  CornerRadius: Single;
  RR: ISkRoundRect;
  Paint: ISkPaint;
  Alpha: Byte;
begin
  if aOpacity <= 0 then
    Exit;

  CardW := aRect.Width;
  CornerRadius := CardW * CORNER_RADIUS_FRACTION;
  Alpha := Round(aOpacity * 255);

  Paint := TSkPaint.Create;
  Paint.Color := (aColor and $00FFFFFF) or (Cardinal(Alpha) shl 24);
  Paint.Style := TSkPaintStyle.Stroke;
  Paint.StrokeWidth := 3.0;
  Paint.AntiAlias := True;

  RR := TSkRoundRect.Create;
  RR.SetRect(aRect, CornerRadius, CornerRadius);
  aCanvas.DrawRoundRect(RR, Paint);
end;

end.
