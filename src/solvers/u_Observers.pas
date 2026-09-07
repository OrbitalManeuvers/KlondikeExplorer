unit u_Observers;

interface

uses u_ObserverTypes;

type
  TSolverObserver = class(TInterfacedObject, ISolverObserver)
  private
    fLastBacktrack: Integer;
    fVisited: Integer;
    fExplored: Cardinal;
    fSolved: Boolean;

    procedure OnStateVisited(aDepth: Integer);
    procedure OnSolutionFound(aMoveCount: Integer);
    procedure OnBacktrack(aDepth: Integer);
    procedure OnProgress(aNodesExplored: Cardinal);

  end;

implementation


procedure TSolverObserver.OnBacktrack(aDepth: Integer);
begin
  fLastBacktrack := aDepth;
end;

procedure TSolverObserver.OnProgress(aNodesExplored: Cardinal);
begin
  fExplored := aNodesExplored;
end;

procedure TSolverObserver.OnSolutionFound(aMoveCount: Integer);
begin
  fSolved := True;
end;

procedure TSolverObserver.OnStateVisited(aDepth: Integer);
begin
  fVisited := aDepth;
end;

end.
