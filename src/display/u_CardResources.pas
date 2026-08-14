unit u_CardResources;

interface

uses
  System.Types, System.UITypes, System.Skia, System.Generics.Collections,
  u_Types, u_IconResources;

type
  TSuitParts = TArray<ISkPath>;

  TCardResources = class
  private
    fSuitParts: array[TCardSuit] of TSuitParts;
    fCardOutline: ISkPath;
    fFontRank: ISkFont;
    fPaintRed: ISkPaint;
    fPaintBlack: ISkPaint;
    fPaintCardBack: ISkPaint;
    fPaintCardFace: ISkPaint;
    fPaintOutline: ISkPaint;
    fSuitIcons: TIconResources;
    function GetSuitParts(aSuit: TCardSuit): TSuitParts;
    procedure BuildSuitPaths;
    procedure BuildPaints;
    procedure BuildFont;
    procedure BuildCardOutline;
    procedure BuildSuitIcons;
  public
    constructor Create;
    destructor Destroy; override;

    property SuitParts[aSuit: TCardSuit]: TSuitParts read GetSuitParts;
    property SuitIcons: TIconResources read fSuitIcons;
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
  System.Math,
  u_DisplayConsts, u_FontIconResources;

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
  BuildSuitIcons;
end;

destructor TCardResources.Destroy;
begin
  fSuitIcons.Free;
  inherited;
end;

function TCardResources.GetSuitParts(aSuit: TCardSuit): TSuitParts;
begin
  Result := fSuitParts[aSuit];
end;

procedure TCardResources.BuildSuitIcons;
begin
  fSuitIcons := TFontIconResources.Create;
end;

procedure TCardResources.BuildSuitPaths;
var
  B: ISkPathBuilder;
begin
  // Heart: single path, two lobes meeting at bottom point
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(50, 85));
  B.CubicTo(PointF(15, 55), PointF(0, 30), PointF(25, 10));
  B.CubicTo(PointF(40, -2), PointF(50, 10), PointF(50, 25));
  B.MoveTo(PointF(50, 85));
  B.CubicTo(PointF(85, 55), PointF(100, 30), PointF(75, 10));
  B.CubicTo(PointF(60, -2), PointF(50, 10), PointF(50, 25));
  B.Close;
  fSuitParts[csHearts] := [B.Detach];

  // Diamond: single rhombus path
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(50, 0));
  B.LineTo(PointF(85, 50));
  B.LineTo(PointF(50, 100));
  B.LineTo(PointF(15, 50));
  B.Close;
  fSuitParts[csDiamonds] := [B.Detach];

  // Club: separate paths for each part to avoid fill-rule overlap issues
  // Stem (drawn first, extends high so circles cover its top)
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(49, 52));
  B.LineTo(PointF(35, 95));
  B.LineTo(PointF(65, 95));
  B.LineTo(PointF(51, 52));
  B.Close;
  var ClubStem := B.Detach;
  // Top circle
  B := TSkPathBuilder.Create;
  B.AddCircle(50, 25, 19);
  var ClubTop := B.Detach;
  // Left circle
  B := TSkPathBuilder.Create;
  B.AddCircle(30, 55, 19);
  var ClubLeft := B.Detach;
  // Right circle
  B := TSkPathBuilder.Create;
  B.AddCircle(70, 55, 19);
  var ClubRight := B.Detach;
  // inner circle
  B := TSkPathBuilder.Create;
  B.AddCircle(50, 52, 10);
  var ClubInner := B.Detach;

  fSuitParts[csClubs] := [ClubStem, ClubInner, ClubLeft, ClubRight, ClubTop];

  // Spade: separate body and stem
  // Stem (drawn first, extends high so body covers its top)
  B := TSkPathBuilder.Create;
//  B.MoveTo(PointF(45, 20));
//  B.LineTo(PointF(35, 95));
//  B.LineTo(PointF(65, 95));
//  B.LineTo(PointF(55, 20));

  B.MoveTo(PointF(49, 52));
  B.LineTo(PointF(35, 95));
  B.LineTo(PointF(65, 95));
  B.LineTo(PointF(51, 52));

  B.Close;
  var SpadeStem := B.Detach;

  // Body (inverted heart)
  B := TSkPathBuilder.Create;
  B.MoveTo(PointF(50, 5));
  B.CubicTo(PointF(15, 35), PointF(0, 55), PointF(25, 72));
  B.CubicTo(PointF(40, 85), PointF(50, 72), PointF(50, 59));

  B.MoveTo(PointF(50, 5));
  B.CubicTo(PointF(85, 35), PointF(100, 55), PointF(75, 72));
  B.CubicTo(PointF(60, 85), PointF(50, 72), PointF(50, 59));
  B.Close;
  var SpadeBody := B.Detach;
  fSuitParts[csSpades] := [SpadeStem, SpadeBody];
end;

procedure TCardResources.BuildPaints;
begin
  fPaintRed := TSkPaint.Create;
  fPaintRed.Color := COLOR_BASIC_RED;
  fPaintRed.Style := TSkPaintStyle.Fill;
  fPaintRed.AntiAlias := True;

  fPaintBlack := TSkPaint.Create;
  fPaintBlack.Color := COLOR_BASIC_BLACK;
  fPaintBlack.Style := TSkPaintStyle.Fill;
  fPaintBlack.AntiAlias := True;

  fPaintCardFace := TSkPaint.Create;
  fPaintCardFace.Color := TAlphaColors.White;
  fPaintCardFace.Style := TSkPaintStyle.Fill;
  fPaintCardFace.AntiAlias := True;

  fPaintCardBack := TSkPaint.Create;
  fPaintCardBack.Color := COLOR_CARD_BACKFILL;  // dark blue
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
  Typeface := TSkTypeface.MakeFromName('Arial', TSkFontStyle.Bold);
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
