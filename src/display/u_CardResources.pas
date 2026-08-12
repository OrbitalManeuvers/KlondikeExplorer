unit u_CardResources;

interface

uses
  System.Types, System.UITypes, System.Skia,
  u_Types;

type
  TCardResources = class
  private
    fSuitPaths: array[TCardSuit] of ISkPath;
    fCardOutline: ISkPath;
    fFontRank: ISkFont;
    fPaintRed: ISkPaint;
    fPaintBlack: ISkPaint;
    fPaintCardBack: ISkPaint;
    fPaintCardFace: ISkPaint;
    fPaintOutline: ISkPaint;
    function GetSuitPath(aSuit: TCardSuit): ISkPath;
    procedure BuildSuitPaths;
    procedure BuildPaints;
    procedure BuildFont;
    procedure BuildCardOutline;
  public
    constructor Create;

    property SuitPath[aSuit: TCardSuit]: ISkPath read GetSuitPath;
    property CardOutline: ISkPath read fCardOutline;
    property FontRank: ISkFont read fFontRank;
    property PaintRed: ISkPaint read fPaintRed;
    property PaintBlack: ISkPaint read fPaintBlack;
    property PaintCardBack: ISkPaint read fPaintCardBack;
    property PaintCardFace: ISkPaint read fPaintCardFace;
    property PaintOutline: ISkPaint read fPaintOutline;
  end;

implementation

uses
  System.Math;

const
  // Suit paths are built in a 0..100 x 0..100 unit space.
  // They get scaled to the desired size at draw time via canvas transform.
  UNIT_SIZE = 100;

{ TCardResources }

constructor TCardResources.Create;
begin
  inherited Create;
  BuildSuitPaths;
  BuildPaints;
  BuildFont;
  BuildCardOutline;
end;

function TCardResources.GetSuitPath(aSuit: TCardSuit): ISkPath;
begin
  Result := fSuitPaths[aSuit];
end;

procedure TCardResources.BuildSuitPaths;
var
  B: ISkPathBuilder;
begin
  // Heart: two arcs meeting at a point at the bottom
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(50, 85));                          // bottom point
  B.CubicTo(PointF(15, 55), PointF(0, 30), PointF(25, 10));   // left lobe lower
  B.CubicTo(PointF(40, -2), PointF(50, 10), PointF(50, 25));  // left lobe upper to center
  B.MoveTo(PointF(50, 85));                          // back to bottom
  B.CubicTo(PointF(85, 55), PointF(100, 30), PointF(75, 10)); // right lobe lower
  B.CubicTo(PointF(60, -2), PointF(50, 10), PointF(50, 25));  // right lobe upper to center
  B.Close;
  fSuitPaths[csHearts] := B.Detach;

  // Diamond: simple rhombus
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(50, 0));    // top
  B.LineTo(PointF(85, 50));   // right
  B.LineTo(PointF(50, 100));  // bottom
  B.LineTo(PointF(15, 50));   // left
  B.Close;
  fSuitPaths[csDiamonds] := B.Detach;

  // Club: three circles + stem
  B := TSkPathBuilder.Create;
  // Top circle
  B.AddCircle(50, 25, 20);
  // Left circle
  B.AddCircle(30, 55, 20);
  // Right circle
  B.AddCircle(70, 55, 20);
  // Stem
  B.MoveTo(PointF(42, 65));
  B.LineTo(PointF(35, 95));
  B.LineTo(PointF(65, 95));
  B.LineTo(PointF(58, 65));
  B.Close;
  fSuitPaths[csClubs] := B.Detach;

  // Spade: inverted heart shape + stem
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(50, 5));                            // top point
  B.CubicTo(PointF(15, 35), PointF(0, 55), PointF(25, 75));   // left lobe
  B.CubicTo(PointF(40, 88), PointF(50, 75), PointF(50, 62));  // left to center
  B.MoveTo(PointF(50, 5));                            // back to top
  B.CubicTo(PointF(85, 35), PointF(100, 55), PointF(75, 75)); // right lobe
  B.CubicTo(PointF(60, 88), PointF(50, 75), PointF(50, 62));  // right to center
  B.Close;
  // Stem
  B.MoveTo(PointF(42, 70));
  B.LineTo(PointF(35, 95));
  B.LineTo(PointF(65, 95));
  B.LineTo(PointF(58, 70));
  B.Close;
  fSuitPaths[csSpades] := B.Detach;
end;

procedure TCardResources.BuildPaints;
begin
  fPaintRed := TSkPaint.Create;
  fPaintRed.Color := TAlphaColors.Crimson;
  fPaintRed.Style := TSkPaintStyle.Fill;
  fPaintRed.AntiAlias := True;

  fPaintBlack := TSkPaint.Create;
  fPaintBlack.Color := TAlphaColors.Black;
  fPaintBlack.Style := TSkPaintStyle.Fill;
  fPaintBlack.AntiAlias := True;

  fPaintCardFace := TSkPaint.Create;
  fPaintCardFace.Color := TAlphaColors.White;
  fPaintCardFace.Style := TSkPaintStyle.Fill;
  fPaintCardFace.AntiAlias := True;

  fPaintCardBack := TSkPaint.Create;
  fPaintCardBack.Color := $FF1A237E;  // dark blue
  fPaintCardBack.Style := TSkPaintStyle.Fill;
  fPaintCardBack.AntiAlias := True;

  fPaintOutline := TSkPaint.Create;
  fPaintOutline.Color := TAlphaColors.Gray;
  fPaintOutline.Style := TSkPaintStyle.Stroke;
  fPaintOutline.StrokeWidth := 1.0;
  fPaintOutline.AntiAlias := True;
end;

procedure TCardResources.BuildFont;
var
  Typeface: ISkTypeface;
begin
  Typeface := TSkTypeface.MakeDefault;
  fFontRank := TSkFont.Create(Typeface, 14);  // size 14 is a placeholder; scaled at draw time
  fFontRank.Edging := TSkFontEdging.AntiAlias;
end;

procedure TCardResources.BuildCardOutline;
var
  B: ISkPathBuilder;
  RR: ISkRoundRect;
begin
  // Unit-size rounded rect (0,0 to 100,140 matching aspect ratio)
  RR := TSkRoundRect.Create;
  RR.SetRect(RectF(0, 0, 100, 140), 8, 8);

  B := TSkPathBuilder.Create;
  B.AddRoundRect(RR);
  fCardOutline := B.Detach;
end;

end.
