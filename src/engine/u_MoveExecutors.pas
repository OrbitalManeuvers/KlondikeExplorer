unit u_MoveExecutors;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Tables,
  u_CardHelpers,
  u_CardStacks
  ;

type
  TMoveExecutor = class
  private
    class procedure UpdateFaceUp(const source, target: TCardStack; aMove: TMove);
  public
    class procedure ExecuteMove(aTable: TTable; aMove: TMove);
  end;


implementation

uses System.Math,
  u_MoveHelpers, u_Utils;

{ TMoveExecutor }

class procedure TMoveExecutor.ExecuteMove(aTable: TTable; aMove: TMove);
begin
  var source := aTable.Stacks[aMove.Source];
  var target := aTable.Stacks[aMove.Target];
  var moveType := aMove.GetMoveType;

  case moveType of

    mtDraw:
      begin
        var moveCount := Min(aMove.Count, source.Count);
        for var i := 1 to moveCount do
          target.Add(source._Pop);
      end;

    mtRecycle:
      begin
        while source.HasCards do
          target.Add(source._Pop);
        aTable.RecycleCount := aTable.RecycleCount + 1;
      end;

    // single and multi-card moves
    mtWasteToTableau,
    mtWasteToFoundation,
    mtTableauToTableau,
    mtTableauToFoundation,
    mtFoundationToTableau:
      begin
        // preserves order when moving multiple cards
        var list := TList<TCard>.Create;
        try
          source.GetLastCards(list, aMove.Count, True);
          target._AddFrom(list);
        finally
          list.Free;
        end;

        // if we remove anything from the waste/stock system, reset the table's recycle counter
        if aMove.Source = siWaste then
          aTable.RecycleCount := 0;
      end;
  end;

  UpdateFaceUp(source, target, aMove);
end;

class procedure TMoveExecutor.UpdateFaceUp(const source, target: TCardStack; aMove: TMove);
begin
  // handle face up status for tableau stacks
  if StackIdToCategory(aMove.Source) = scTableau then
  begin
    source.FaceUpCount := Max(0, source.FaceUpCount - aMove.Count);
    if (source.FaceUpCount = 0) and (source.Count > 0) then
      source.FaceUpCount := 1;
  end;

  if StackIdToCategory(aMove.Target) = scTableau then
  begin
    target.FaceUpCount := target.FaceUpCount + aMove.Count;
  end;
end;

end.

