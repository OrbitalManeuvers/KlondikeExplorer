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

  TGameDisplay = class(TTableDisplay)
  private
    fAnimation: IAnimation;
    fDragOverlay: TDragOverlay;
  public
    procedure Draw(aCanvas: ISkCanvas; const aLayout: TLayout); override;

    // Drag support
    procedure SetDragOverlay(const aCards: TArray<TCard>; aSourceStack: TStackId; aPos: TPointF);
    procedure ClearDragOverlay;
    property Animation: IAnimation read fAnimation write fAnimation;
  end;

implementation

uses u_RenderUtils, u_Utils, u_Animations;

{ TGameDisplay }

procedure TGameDisplay.ClearDragOverlay;
begin
  //
end;

procedure TGameDisplay.Draw(aCanvas: ISkCanvas; const aLayout: TLayout);
begin
  inherited;

  if Assigned(Animation) then
  begin
    if Animation.State = asComplete then
      Animation := nil
    else
      Animation.Draw(aCanvas);
  end;




end;

procedure TGameDisplay.SetDragOverlay(const aCards: TArray<TCard>;
  aSourceStack: TStackId; aPos: TPointF);
begin
  //
end;



end.
