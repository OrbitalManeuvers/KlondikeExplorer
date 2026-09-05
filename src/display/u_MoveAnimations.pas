unit u_MoveAnimations;

interface

uses System.Types,
  u_Types, u_AnimationTypes, u_Animations;

// aCardOffset is the per-card layout delta of the moving bundle (a tableau run
// cascades in Y). The caller sources it from the layout.
function CreateMoveAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; const aCardOffset: TPointF): IAnimation;

// a draw slides a horizontally-fanned, face-up bundle from the stock to the waste.
// aFanX is the per-card horizontal spacing of the resting waste fan.
function CreateDrawAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; aFanX: Single): IAnimation;

implementation

uses System.Skia,
  u_RenderUtils, u_FlybackAnimations;

const
  TOTAL_MS = 85;


function CreateMoveAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; const aCardOffset: TPointF): IAnimation;
begin
  Result := CreateFlybackAnimation(aCards, aStartPos, aEndPos, aCardSize, aCardOffset, TOTAL_MS);
end;

function CreateDrawAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF; aFanX: Single): IAnimation;
begin
  var fan := PointF(aFanX, 0);
  // aFanIn: the cards leave the stock stacked and spread to the full fan mid-flight.
  Result := CreateFlybackAnimation(aCards, aStartPos, aEndPos, aCardSize, fan, TOTAL_MS, True);
end;

end.
