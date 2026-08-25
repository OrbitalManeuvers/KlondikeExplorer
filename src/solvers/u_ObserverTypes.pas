unit u_ObserverTypes;

interface

type
  ISolverObserver = interface
    procedure OnStateVisited(aDepth: Integer);
    procedure OnSolutionFound(aMoveCount: Integer);
    procedure OnBacktrack(aDepth: Integer);
    procedure OnProgress(aNodesExplored: Cardinal);
  end;


implementation

end.
