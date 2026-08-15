unit u_MoveAnimations;

interface

uses System.Types,
  u_Types, u_AnimationTypes, u_Animations;

function CreateMoveAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF): IAnimation;

implementation

uses System.Skia,
  u_RenderUtils, u_FlybackAnimations;

const
  TOTAL_MS = 80;


function CreateMoveAnimation(const aCards: TArray<TCard>;
  aStartPos, aEndPos: TPointF; const aCardSize: TSizeF): IAnimation;
begin
  Result := CreateFlybackAnimation(aCards, aStartPos, aEndPos, aCardSize, TOTAL_MS);
end;

end.
