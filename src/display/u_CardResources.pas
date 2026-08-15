unit u_CardResources;

interface

uses
  System.Types, System.UITypes, System.Skia, System.Generics.Collections,
  u_Types, u_IconResources;

type
  TSuitParts = TArray<ISkPath>;

  TCardResources = class
  private
    fCardOutline: ISkPath;
    fFontRank: ISkFont;
    fPaintRed: ISkPaint;
    fPaintBlack: ISkPaint;
    fPaintCardBack: ISkPaint;
    fPaintCardFace: ISkPaint;
    fPaintOutline: ISkPaint;
    fSuitIcons: TIconResources;
    procedure BuildPaints;
    procedure BuildFont;
    procedure BuildCardOutline;
    procedure BuildSuitIcons;
  public
    constructor Create;
    destructor Destroy; override;

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

//  BuildSuitPaths;
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

procedure TCardResources.BuildSuitIcons;
begin
  fSuitIcons := TFontIconResources.Create;
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
