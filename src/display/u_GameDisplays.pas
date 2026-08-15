unit u_GameDisplays;

interface

uses System.Types, System.UITypes, System.Skia, System.Generics.Collections,
  u_Types, u_TableDisplays, u_AnimationTypes, u_AnimationHelpers, u_Layouts;

type
  TDragOverlay = record
    Active: Boolean;
    Cards: TArray<TCard>;
    Position: TPointF;       // current mouse position (top-left of dragged fan)
    SourceStack: TStackId;
  end;

  TDropTargetInfo = record
    Active: Boolean;
    Position: TPointF;
    Cards: TArray<TCard>;
  end;

  TAnimateCompleteEvent = procedure (Sender: TObject; const Animation: IAnimation) of object;

  TGameDisplay = class(TTableDisplay)
  private
    fAnimation: IAnimation;
    fDragOverlay: TDragOverlay;
    fDropTargetInfo: TDropTargetInfo;
    fDropPulse: TCycler;
    fOnAnimateComplete: TAnimateCompleteEvent;
    procedure RenderDragOverlay(aCanvas: ISkCanvas; const aLayout: TLayout);
    procedure RenderDropTarget(aCanvas: ISkCanvas; const aLayout: TLayout);
  public
    constructor Create;
    procedure Draw(aCanvas: ISkCanvas; const aLayout: TLayout); override;

    // Drag support
    procedure SetDragOverlay(const aCards: TArray<TCard>; aSourceStack: TStackId; aPos: TPointF);
    procedure ClearDragOverlay;

    procedure SetDropTarget(const aCards: TArray<TCard>; aPos: TPointF);
    procedure ClearDropTarget;

    property Animation: IAnimation read fAnimation write fAnimation;
    property OnAnimateComplete: TAnimateCompleteEvent read fOnAnimateComplete write fOnAnimateComplete;
  end;

implementation

uses u_RenderUtils, u_Utils, u_Animations;

{ TGameDisplay }

constructor TGameDisplay.Create;
begin
  inherited Create;
  fDropPulse.Init(1000, 0.4, 0.99, Stopwatch);
end;

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

  if fDropTargetInfo.Active then
    RenderDropTarget(aCanvas, aLayout);

  if fDragOverlay.Active then
    RenderDragOverlay(aCanvas, aLayout);

end;

procedure TGameDisplay.ClearDragOverlay;
begin
  fDragOverlay.Active := False;
  SetLength(fDragOverlay.Cards, 0);
end;

procedure TGameDisplay.SetDragOverlay(const aCards: TArray<TCard>; aSourceStack: TStackId;
  aPos: TPointF);
begin
  fDragOverlay.Active := True;
  fDragOverlay.Cards := aCards;
  fDragOverlay.Position := aPos;
end;

procedure TGameDisplay.SetDropTarget(const aCards: TArray<TCard>; aPos: TPointF);
begin
  fDropTargetInfo.Active := True;
  fDropTargetInfo.Cards := aCards;
  fDropTargetInfo.Position := aPos;
end;

procedure TGameDisplay.ClearDropTarget;
begin
  fDropTargetInfo.Active := False;
end;

procedure TGameDisplay.RenderDragOverlay(aCanvas: ISkCanvas; const aLayout: TLayout);
var
  Bundle: TCardBundle;
begin
  Bundle.Cards := fDragOverlay.Cards;
  Bundle.CardSize.cx := aLayout.CardWidth;
  Bundle.CardSize.cy := aLayout.CardHeight;
  TRenderUtils.DrawCardBundle(aCanvas, Bundle, fDragOverlay.Position);
end;

procedure TGameDisplay.RenderDropTarget(aCanvas: ISkCanvas; const aLayout: TLayout);
var
  Bundle: TCardBundle;
begin
  Bundle.Cards := fDropTargetInfo.Cards;
  Bundle.CardSize.cx := aLayout.CardWidth;
  Bundle.CardSize.cy := aLayout.CardHeight;
  Bundle.OutlineColor := TAlphaColors.Coral;
  TRenderUtils.DrawCardBundle(aCanvas, Bundle, fDropTargetInfo.Position, 0.5,
    fDropPulse.Value);
end;



end.
