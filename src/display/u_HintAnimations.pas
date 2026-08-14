unit u_HintAnimations;

interface

uses u_Types, u_Tables, u_AnimationTypes, u_Animations, u_Layouts;

// The animation has 3 phases:

// phase 1: fade in yellow outline around source  bundle
// phase 2: move bundle to target
// phase 3: fade out the bundle at the new location

function CreateHintAnimation(aTable: TTable; aMove: TMove; const aLayout: TLayout): IAnimation;

implementation

uses System.Types, System.UITypes, System.Skia, System.Generics.Collections,
  System.Math,
  u_RenderUtils, u_MoveHelpers, u_DisplayConsts;

const
  FADE_IN_MS = 300;
  MOVE_MS = 500;
  FADE_OUT_MS = 800;

type
  THintAnimation = class(TAnimation)
  private
    procedure DrawCardBundle(aCanvas: ISkCanvas; where: TPointF; outlineOpacity: Single; groupOpacity: Single);
  protected
    function GetDuration: Cardinal; override;
    procedure Draw(aCanvas: ISkCanvas); override;
  public
    Cards: TArray<TCard>;
    StartPos: TPointF;
    EndPos: TPointF;
    CardSize: TSizeF;
    OutlineColor: TAlphaColor;
  end;

function CreateHintAnimation(aTable: TTable; aMove: TMove; const aLayout: TLayout): IAnimation;
begin
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

  anim.CardSize.cx := aLayout.CardWidth;
  anim.CardSize.cy := aLayout.CardHeight;
  anim.OutlineColor := TAlphaColors.Hotpink;
  aTable.Stacks[aMove.Source].GetLastCards(anim.cards, aMove.Count);

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
    DrawCardBundle(aCanvas, StartPos, phaseProgress, 1.0);
  end
  else if elapsed < FADE_IN_MS + MOVE_MS then
  begin
    // Phase 2: move bundle from source to target, full outline
    phaseProgress := (elapsed - FADE_IN_MS) / MOVE_MS;
    currentPos.X := StartPos.X + (EndPos.X - StartPos.X) * phaseProgress;
    currentPos.Y := StartPos.Y + (EndPos.Y - StartPos.Y) * phaseProgress;
    DrawCardBundle(aCanvas, currentPos, 1.0, 1.0);
  end
  else
  begin
    // Phase 3: fade out at target position
    if Self.State = asRunning then
    begin
      phaseProgress := Min((elapsed - FADE_IN_MS - MOVE_MS) / FADE_OUT_MS, 1.0);
//      if phaseProgress > 1.0 then
//        phaseProgress := 1.0;
      DrawCardBundle(aCanvas, EndPos, 1.0, 1.0 - phaseProgress);
    end;
  end;
end;

procedure THintAnimation.DrawCardBundle(aCanvas: ISkCanvas; where: TPointF;
  outlineOpacity: Single; groupOpacity: Single);
var
  cardRect: TRectF;
  alpha: Byte;
begin
  alpha := Round(groupOpacity * 255);
  aCanvas.SaveLayerAlpha(alpha);
  try
    for var i := 0 to High(Cards) do
    begin
      cardRect := TRectF.Create(where, CardSize.cx, CardSize.cy);
      TRenderUtils.DrawCard(aCanvas, Cards[i], cardRect, True);
      TRenderUtils.DrawCardHighlight(aCanvas, cardRect, OutlineColor, outlineOpacity);
      where.Offset(0, CardSize.cy * OFFSET_FRACTION);
    end;
  finally
    aCanvas.Restore;
  end;
end;


function THintAnimation.GetDuration: Cardinal;
begin
  Result := FADE_IN_MS + FADE_OUT_MS + MOVE_MS;
end;

end.
