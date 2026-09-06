unit u_SolverTypes;

interface

uses System.Generics.Collections,
  u_Types;

type
  TSolverResult = (srUnsolved, srSolved, srLimitReached, srCancelled);

  TSolverLimits = record
    MaxDepth: Integer;       // 0 = unlimited
    MaxNodes: Cardinal;      // 0 = unlimited
  end;

  TSolverOutcome = record
    Result: TSolverResult;
    Moves: TArray<TMove>;
    NodesExplored: Cardinal;
    MaxDepthReached: Integer;
  end;

  TSolverMove = record
    Move: TMove;                  // the eventual mtWasteToTableau/mtWasteToFoundation
    DrawsBeforeRecycle1: Integer; // draw operations on current stock
    DrawsAfterRecycle1: Integer;  // draw operations after 1st recycle (Lap 2)
    DrawsAfterRecycle2: Integer;  // draw operations after 2nd recycle (Lap 3)
    RecycleCount: Integer;        // 0, 1, or 2 recycles required
    function Unroll: TArray<TMove>;
  end;

implementation

uses u_MoveHelpers;

function TSolverMove.Unroll: TArray<TMove>;
var
  list: TList<TMove>;
  i: Integer;
begin
  list := TList<TMove>.Create;
  try
    // Lap 1: Draws on current stock
    for i := 1 to DrawsBeforeRecycle1 do
      list.Add(TMove.CreateDraw);

    // Lap 2: Recycle and draws
    if RecycleCount >= 1 then
    begin
      list.Add(TMove.CreateRecycle);
      for i := 1 to DrawsAfterRecycle1 do
        list.Add(TMove.CreateDraw);
    end;

    // Lap 3: Recycle and draws
    if RecycleCount >= 2 then
    begin
      list.Add(TMove.CreateRecycle);
      for i := 1 to DrawsAfterRecycle2 do
        list.Add(TMove.CreateDraw);
    end;

    // Finally, the board move itself
    list.Add(Move);
    Result := list.ToArray;
  finally
    list.Free;
  end;
end;

end.
