unit u_GameDisplays;

interface

uses System.Types, System.Skia, System.Generics.Collections,
  u_Types, u_TableDisplays, u_AnimationTypes, u_Layouts;

type
  TDragOverlay = record
    Active: Boolean;
    Cards: TArray<TCard>;
    Position: TPointF;       // current mouse position (top-left of dragged fan)
    SourceStack: TStackId;
  end;

  TAnimateCompleteEvent = procedure (Sender: TObject; const Animation: IAnimation) of object;

  TGameDisplay = class(TTableDisplay)
  private
    fAnimation: IAnimation;
    fDragOverlay: TDragOverlay;
    fOnAnimateComplete: TAnimateCompleteEvent;
    procedure RenderDragOverlay(aCanvas: ISkCanvas; const aLayout: TLayout);
  public
    procedure Draw(aCanvas: ISkCanvas; const aLayout: TLayout); override;

    // Drag support
    procedure SetDragOverlay(const aCards: TArray<TCard>; aSourceStack: TStackId; aPos: TPointF);
    procedure ClearDragOverlay;
    property Animation: IAnimation read fAnimation write fAnimation;
    property OnAnimateComplete: TAnimateCompleteEvent read fOnAnimateComplete write fOnAnimateComplete;
  end;

implementation

uses u_RenderUtils, u_Utils, u_Animations;

{ TGameDisplay }

procedure TGameDisplay.Draw(aCanvas: ISkCanvas; const aLayout: TLayout);
begin
  inherited;

  if Assigned(Animation) then
  begin
    Animation.Draw(aCanvas);
    if Animation.State = asComplete then
    begin
      if Assigned(fOnAnimateComplete) then
        fOnAnimateComplete(Self, Animation);
      Animation := nil;
    end;
  end;

  if fDragOverlay.Active then
    RenderDragOverlay(aCanvas, aLayout);
end;

procedure TGameDisplay.ClearDragOverlay;
begin
  fDragOverlay.Active := False;
  SetLength(fDragOverlay.Cards, 0);
end;

procedure TGameDisplay.SetDragOverlay(const aCards: TArray<TCard>;
  aSourceStack: TStackId; aPos: TPointF);
begin
  fDragOverlay.Active := True;
  fDragOverlay.Cards := aCards;
  fDragOverlay.Position := aPos;
end;

procedure TGameDisplay.RenderDragOverlay(aCanvas: ISkCanvas;
  const aLayout: TLayout);
var
  Bundle: TCardBundle;
begin
  Bundle.Cards := fDragOverlay.Cards;
  Bundle.CardSize.cx := aLayout.CardWidth;
  Bundle.CardSize.cy := aLayout.CardHeight;
  TRenderUtils.DrawCardBundle(aCanvas, Bundle, fDragOverlay.Position);
end;



end.
