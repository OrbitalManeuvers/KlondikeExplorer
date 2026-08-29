unit u_FontIconResources;

interface

uses System.Types, System.Skia,
  u_Types, u_IconResources;

type
  TFontIconResources = class(TIconResources)
  private
    fTypeface: ISkTypeface;
    fFont: ISkFont;
    fPaintRed: ISkPaint;
    fPaintBlack: ISkPaint;
    fTablePaint: ISkPaint;
    fGlyphPaths: array[TCardSuit] of ISkPath;
    procedure BuildPaints;
    procedure BuildGlyphPaths;
    function PaintForSuit(aSuit: TCardSuit; aGhosted: Boolean): ISkPaint;
  public
    constructor Create;
    procedure DrawIcon(aCanvas: ISkCanvas; aSuit: TCardSuit; aLocation: TRectF;
      aGhosted: Boolean = False); override;
  end;

implementation

uses System.UITypes, Vcl.GraphUtil,
  u_DisplayConsts;

const
//  FONT_NAME = 'Arial';
  FONT_NAME = 'Segoe UI';
  FONT_SIZE = 100.0; // large size for good path precision

  SUIT_CHARS: array[TCardSuit] of Char = (
    #$2665,  // Hearts
    #$2666,  // Diamonds
    #$2663,  // Clubs
    #$2660   // Spades
  );

{ TFontIconResources }

constructor TFontIconResources.Create;
begin
  inherited Create;
  fTypeface := TSkTypeface.MakeFromName(FONT_NAME, TSkFontStyle.Normal);
  fFont := TSkFont.Create(fTypeface, FONT_SIZE);
  BuildPaints;
  BuildGlyphPaths;
end;

procedure TFontIconResources.BuildPaints;
begin
  fPaintRed := TSkPaint.Create;
  fPaintRed.Color := COLOR_BASIC_RED;
  fPaintRed.Style := TSkPaintStyle.Fill;
  fPaintRed.AntiAlias := True;

  fPaintBlack := TSkPaint.Create;
  fPaintBlack.Color := COLOR_BASIC_BLACK;
  fPaintBlack.Style := TSkPaintStyle.Fill;
  fPaintBlack.AntiAlias := True;

  fTablePaint := TSkPaint.Create;
  fTablePaint.Color := $10FFFFFF;
  fTablePaint.Style := TSkPaintStyle.Fill;
  fTablePaint.AntiAlias := True;
end;

procedure TFontIconResources.BuildGlyphPaths;
var
  Suit: TCardSuit;
  Glyphs: TArray<Word>;
  Path: ISkPath;
begin
  for Suit := Low(TCardSuit) to High(TCardSuit) do
  begin
    Glyphs := fFont.GetGlyphs(SUIT_CHARS[Suit]);
    Path := fFont.GetPath(Glyphs[0]);
    fGlyphPaths[Suit] := Path;
  end;
end;

function TFontIconResources.PaintForSuit(aSuit: TCardSuit; aGhosted: Boolean): ISkPaint;
begin
  if aGhosted then
    Result := fTablePaint
  else if aSuit in [csHearts, csDiamonds] then
    Result := fPaintRed
  else
    Result := fPaintBlack;
end;

procedure TFontIconResources.DrawIcon(aCanvas: ISkCanvas; aSuit: TCardSuit;
  aLocation: TRectF; aGhosted: Boolean);
var
  Path: ISkPath;
  Bounds: TRectF;
  ScaleX, ScaleY, Scale: Single;
  Dx, Dy: Single;
begin
  Path := fGlyphPaths[aSuit];
  Bounds := Path.Bounds;

  // Scale glyph path to fit within aLocation, preserving aspect ratio
  ScaleX := aLocation.Width / Bounds.Width;
  ScaleY := aLocation.Height / Bounds.Height;
  if ScaleX < ScaleY then
    Scale := ScaleX
  else
    Scale := ScaleY;

  // Center the scaled glyph within aLocation
  Dx := aLocation.Left + (aLocation.Width - Bounds.Width * Scale) / 2 - Bounds.Left * Scale;
  Dy := aLocation.Top + (aLocation.Height - Bounds.Height * Scale) / 2 - Bounds.Top * Scale;

  aCanvas.Save;
  aCanvas.Translate(Dx, Dy);
  aCanvas.Scale(Scale, Scale);
  aCanvas.DrawPath(Path, PaintForSuit(aSuit, aGhosted));
  aCanvas.Restore;
end;

end.
