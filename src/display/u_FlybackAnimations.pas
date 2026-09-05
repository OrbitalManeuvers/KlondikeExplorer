unit u_FlybackAnimations;

interface

uses System.Types,
  u_Types, u_AnimationTypes, u_Animations;

function CreateFlybackAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; const aCardOffset: TPointF;
  aDuration: Cardinal = 0; aFanIn: Boolean = False): IAnimation;

implementation

uses System.Skia,
  u_RenderUtils, u_AnimationHelpers;

const
  TOTAL_MS = 150;

type
  TFlybackAnimation = class(TAnimation)
  private
    fBundle: TCardBundle;
    fStartPos: TPointF;
    fEndPos: TPointF;
    fDuration: Cardinal;
    fFanIn: Boolean;   // when set, the per-card offset grows from 0 to full over the flight
                       // (a draw spreading out); at Progress=1 it equals fBundle.CardOffset
  protected
    function GetDuration: Cardinal; override;
    procedure Draw(aCanvas: ISkCanvas); override;
  end;

function CreateFlybackAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; const aCardOffset: TPointF;
  aDuration: Cardinal; aFanIn: Boolean): IAnimation;
begin
  var anim := TFlybackAnimation.Create;
  anim.fBundle.Cards := aCards;
  anim.fBundle.CardSize := aCardSize;
  anim.fBundle.CardOffset := aCardOffset;   // every caller states its fan direction
  anim.fFanIn := aFanIn;
  anim.fStartPos := aStartPos;
  anim.fEndPos := aEndPos;
  anim.fDuration := aDuration;
  if aDuration = 0 then
    anim.fDuration := TOTAL_MS;
  anim.CompletionActions := [caUpdateDisplay];
  Result := anim;
end;

{ TFlybackAnimation }

procedure TFlybackAnimation.Draw(aCanvas: ISkCanvas);
var
  T: Single;
  Pos: TPointF;
begin
  T := Progress;
  Pos.X := fStartPos.X + (fEndPos.X - fStartPos.X) * T;
  Pos.Y := fStartPos.Y + (fEndPos.Y - fStartPos.Y) * T;

  if fFanIn then
  begin
    // spread the cards out over the flight: offset grows 0 -> full fan.
    // NOTE: card *order* is deliberately left as-built - the "reversed" fan is what
    // makes the landing frame line up with the resting waste. Do not reorder.
    var spread := EaseOutCubic(T);
    var bundle := fBundle;
    bundle.CardOffset := PointF(fBundle.CardOffset.X * spread, fBundle.CardOffset.Y * spread);
    TRenderUtils.DrawCardBundle(aCanvas, bundle, Pos);
  end
  else
    TRenderUtils.DrawCardBundle(aCanvas, fBundle, Pos);
end;

function TFlybackAnimation.GetDuration: Cardinal;
begin
  Result := fDuration;
end;

end.
