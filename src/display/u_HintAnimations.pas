unit u_HintAnimations;

interface

uses u_Types, u_Tables, u_AnimationTypes, u_Animations, u_Layouts;

// The animation has 3 phases:

// phase 1: fade in yellow outline around source  bundle
// phase 2: move bundle to target
// phase 3: fade out the bundle at the new location

function CreateHintAnimation(aTable: TTable; aMove: TMove; const aLayout: TLayout): IAnimation;

implementation

uses System.Types, System.UITypes, System.Skia, System.Math,
  u_DisplayConsts, u_RenderUtils, u_MoveHelpers;

const
  FADE_IN_MS = 300;
  MOVE_MS = 500;
  FADE_OUT_MS = 400;

  // stationary draw hint: pulse a highlight on the stock (fade in, hold, fade out)
  HL_FADE_IN_MS = 200;
  HL_HOLD_MS = 600;
  HL_FADE_OUT_MS = 200;

type
  THintAnimation = class(TAnimation)
  private
    fBundle: TCardBundle;
  protected
    function GetDuration: Cardinal; override;
    procedure Draw(aCanvas: ISkCanvas); override;
  public
    StartPos: TPointF;
    EndPos: TPointF;
  end;

  THighlightAnimation = class(TAnimation)
  protected
    function GetDuration: Cardinal; override;
    procedure Draw(aCanvas: ISkCanvas); override;
  public
    Rect: TRectF;           // where to draw the highlight
    Color: TAlphaColor;
  end;


// a draw hint doesn't move anything - the only action is "click the stock", so we
// just pulse a highlight on the stock pile in place.
function CreateDrawHintAnimation(const aLayout: TLayout): IAnimation;
begin
  var anim := THighlightAnimation.Create;
  anim.Rect := aLayout.CardRect(aLayout.Origins[siStock]);
  anim.Color := COLOR_BASIC_RED;
  Result := anim;
end;

function CreateHintAnimation(aTable: TTable; aMove: TMove; const aLayout: TLayout): IAnimation;
begin
  // draws are stationary - highlight the stock rather than sliding a card to the waste
  if aMove.GetMoveType = mtDraw then
    Exit(CreateDrawHintAnimation(aLayout));

  var anim := THintAnimation.Create;

  anim.StartPos := aLayout.Origins[aMove.Source];
  anim.EndPos := aLayout.Origins[aMove.Target];

  if aMove.Source in ALL_TABLEAUS then
  begin
    var cardIndex := aTable.Stacks[aMove.Source].Count - aMove.Count;
    anim.StartPos.Offset(0, aLayout.TableauCardY(cardIndex));
  end;

  if aMove.Source = siWaste then
  begin
    var count := Min(3, aTable.Waste.Count);
    anim.StartPos.Offset(aLayout.WasteOffset * (count - 1), 0);
  end;

  if aMove.Target in ALL_TABLEAUS then
  begin
    var cardIndex := aTable.Stacks[aMove.Target].Count;
    anim.EndPos.Offset(0, aLayout.TableauCardY(cardIndex));
  end;

  anim.fBundle.CardSize.cx := aLayout.CardWidth;
  anim.fBundle.CardSize.cy := aLayout.CardHeight;
  anim.fBundle.OutlineColor := COLOR_BASIC_RED;
  aTable.Stacks[aMove.Source].GetLastCards(anim.fBundle.Cards, aMove.Count);

  Result := anim;
end;

{ THintAnimation }


procedure THintAnimation.Draw(aCanvas: ISkCanvas);
var
  elapsed: Int64;
  phaseProgress: Single;
  currentPos: TPointF;
begin
  elapsed := Self.Elapsed;

  if elapsed < FADE_IN_MS then
  begin
    // Phase 1: fade in highlight outline at source position
    phaseProgress := elapsed / FADE_IN_MS;
    TRenderUtils.DrawCardBundle(aCanvas, fBundle, StartPos, 1.0, phaseProgress);
  end
  else if elapsed < FADE_IN_MS + MOVE_MS then
  begin
    // Phase 2: move bundle from source to target, full outline
    phaseProgress := (elapsed - FADE_IN_MS) / MOVE_MS;
    currentPos.X := StartPos.X + (EndPos.X - StartPos.X) * phaseProgress;
    currentPos.Y := StartPos.Y + (EndPos.Y - StartPos.Y) * phaseProgress;
    TRenderUtils.DrawCardBundle(aCanvas, fBundle, currentPos, 1.0, 1.0);
  end
  else
  begin
    // Phase 3: fade out at target position
    if Self.State = asRunning then
    begin
      phaseProgress := Min((elapsed - FADE_IN_MS - MOVE_MS) / FADE_OUT_MS, 1.0);
      TRenderUtils.DrawCardBundle(aCanvas, fBundle, EndPos,
        1.0 - phaseProgress, 1.0);
    end;
  end;
end;


function THintAnimation.GetDuration: Cardinal;
begin
  Result := FADE_IN_MS + FADE_OUT_MS + MOVE_MS;
end;

{ THighlightAnimation }

procedure THighlightAnimation.Draw(aCanvas: ISkCanvas);
var
  elapsed: Int64;
  opacity: Single;
begin
  elapsed := Self.Elapsed;

  if elapsed < HL_FADE_IN_MS then
    // fade in
    opacity := elapsed / HL_FADE_IN_MS
  else if elapsed < HL_FADE_IN_MS + HL_HOLD_MS then
    // hold at full
    opacity := 1.0
  else
    // fade out
    opacity := 1.0 - Min((elapsed - HL_FADE_IN_MS - HL_HOLD_MS) / HL_FADE_OUT_MS, 1.0);

  TRenderUtils.DrawCardHighlight(aCanvas, Rect, Color, opacity);
end;

function THighlightAnimation.GetDuration: Cardinal;
begin
  Result := HL_FADE_IN_MS + HL_HOLD_MS + HL_FADE_OUT_MS;
end;

end.
