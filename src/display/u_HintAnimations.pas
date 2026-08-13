unit u_HintAnimations;

interface

uses u_Types, u_Tables, u_AnimationTypes, u_Animations, u_Layouts;


// Note: No special table state needed in the display during this animation. The
// moving card(s) remain in place while "new" copies animate.

// The animation has 3 phases:

// for 1/2 second, fade in yellow outline around source  bundle
// for 1 second (regardless of distance) move bundle to target
// for 1/2 second fade out the bundle at the new location

function CreateHintAnimation(aTable: TTable; aMove: TMove; const aLayout: TLayout): IAnimation;

implementation

uses System.Types, System.Skia, System.Generics.Collections,
  u_RenderUtils, u_MoveHelpers;

const
  PHASE_FADE_IN = 500;
  PHASE_MOVE = 1000;
  PHASE_FADE_OUT = 300;

type
  THintAnimation = class(TAnimation)
  protected
    function GetDuration: Cardinal; override;
    procedure Draw(aCanvas: ISkCanvas); override;
  public
    Cards: TArray<TCard>;
    StartPos: TPointF;
    EndPos: TPointF;
    HintMove: TMove;
  end;

function CreateHintAnimation(aTable: TTable; aMove: TMove; const aLayout: TLayout): IAnimation;
begin
  var anim := THintAnimation.Create;
  anim.HintMove := aMove;

  // get card bundle
  var info := TMoveInfo.Create;
  info.Load(aMove, aTable);
  SetLength(anim.Cards, info.MoveCount);
  for var i := 0 to info.MoveCards.Count - 1 do
    anim.Cards[i] := info.MoveCards[i];


  // get start pos
  case info.Source.Category of
    scTableau: begin end;
  end;

  Result := anim;
end;

{ THintAnimation }


procedure THintAnimation.Draw(aCanvas: ISkCanvas);
begin
  inherited;

end;

function THintAnimation.GetDuration: Cardinal;
begin
  Result := PHASE_FADE_IN + PHASE_MOVE + PHASE_FADE_OUT;
end;

end.
