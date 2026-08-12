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

uses u_RenderUtils, u_Utils;

{ TGameDisplay }

procedure TGameDisplay.ClearDragOverlay;
begin
  //
end;

procedure TGameDisplay.Draw(aCanvas: ISkCanvas; const aLayout: TLayout);
begin
  inherited;
//  for var foundation := Low(TCardSuit) to High(TCardSuit) do
//  begin
//    var r := aLayout.CardRect(aLayout.FoundationOrigins[foundation]);
//    var c := NewCard(foundation, cvQueen);
//    TRenderUtils.DrawCard(aCanvas, c, r, True);
//  end;
//
//  for var tableau := Low(TTableauIndex) to High(TTableauIndex) do
//  begin
//    var r := aLayout.CardRect(aLayout.TableauOrigins[tableau]);
//    if Table.Tableau[tableau].IsEmpty then
//    begin
//      TRenderUtils.DrawEmptySlot(aCanvas, r);
//    end
//    else
//    begin
//
//    end;
//  end;






end;

procedure TGameDisplay.SetDragOverlay(const aCards: TArray<TCard>;
  aSourceStack: TStackId; aPos: TPointF);
begin
  //
end;



end.
