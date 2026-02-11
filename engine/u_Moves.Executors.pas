unit u_Moves.Executors;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
//  u_Moves.Analysis,
  u_Tables,
  u_Cards,
  u_CardStacks
  ;

type
  TExecutor = class
  private
    class procedure UpdateFaceUp(const source, target: TCardStack; aMove: TMove);
  public
    class procedure ExecuteMove(aTable: TTable; aMove: TMove);
//    class function DescribeMove(aTable: TTable; aMove: TMove): string;
  end;


implementation

uses
  System.Math;

{ TMoveExecutor }

class procedure TExecutor.ExecuteMove(aTable: TTable; aMove: TMove);
begin
  var source := aTable.Stacks[aMove.Source];
  var target := aTable.Stacks[aMove.Target];
  var moveType := aMove.GetMoveType;

  case moveType of

    mtDraw:
      begin
        // a move can be generated that requires a recycle mid-transfer
        // so, it's easier to just empty the stock in natural order if it
        // doesn't contain enough cards, and then let the recycle happen
        if source.Count < aMove.Count then
        begin
          while source.HasCards do
            target.Add(source._Pop);
        end;

        if source.IsEmpty and target.HasCards then
        begin
          while target.HasCards do
            source.Add(target._Pop);

          // bump the table's recycle counter
          aTable.RecycleCount := aTable.RecycleCount + 1;
        end;

        // execute the move
        for var i := 1 to aMove.Count do
          target.Add(source._Pop);
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
          source.RemoveLastCards(list, aMove.Count);
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

class procedure TExecutor.UpdateFaceUp(const source, target: TCardStack; aMove: TMove);
begin
  // handle face up status for tableau stacks
  if IdToCategory(aMove.Source) = scTableau then
  begin
    source.FaceUpCount := Max(0, source.FaceUpCount - aMove.Count);
    if (source.FaceUpCount = 0) and (source.Count > 0) then
      source.FaceUpCount := 1;
  end;

  if IdToCategory(aMove.Target) = scTableau then
  begin
    target.FaceUpCount := target.FaceUpCount + aMove.Count;
  end;
end;




end.
