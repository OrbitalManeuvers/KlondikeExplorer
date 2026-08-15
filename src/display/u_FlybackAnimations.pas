unit u_FlybackAnimations;

interface

uses System.Types,
  u_Types, u_AnimationTypes, u_Animations;

function CreateFlybackAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF;
  aDuration: Cardinal = 0): IAnimation;

implementation

uses System.Skia,
  u_RenderUtils;

const
  TOTAL_MS = 150;

type
  TFlybackAnimation = class(TAnimation)
  private
    fBundle: TCardBundle;
    fStartPos: TPointF;
    fEndPos: TPointF;
    fDuration: Cardinal;
  protected
    function GetDuration: Cardinal; override;
    procedure Draw(aCanvas: ISkCanvas); override;
  end;

function CreateFlybackAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; aDuration: Cardinal): IAnimation;
begin
  var anim := TFlybackAnimation.Create;
  anim.fBundle.Cards := aCards;
  anim.fBundle.CardSize := aCardSize;
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
  TRenderUtils.DrawCardBundle(aCanvas, fBundle, Pos);
end;

function TFlybackAnimation.GetDuration: Cardinal;
begin
  Result := fDuration;
end;

end.
