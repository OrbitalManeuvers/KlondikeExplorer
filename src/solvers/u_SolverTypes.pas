unit u_SolverTypes;

interface

uses u_Types;

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

implementation

end.
