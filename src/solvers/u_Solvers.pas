unit u_Solvers;

interface

uses u_CardStacks, u_ObserverTypes, u_SolverTypes;

type
  TSolver = class
  private
    fObserver: ISolverObserver;
    fLimits: TSolverLimits;
    fCancelled: Boolean;
  protected
    procedure NotifyStateVisited(aDepth: Integer);
    procedure NotifyBacktrack(aDepth: Integer);
    procedure NotifyProgress(aNodesExplored: Cardinal);
    function IsCancelled: Boolean;
  public
    function Solve(aDeck: TCardStack): TSolverOutcome; virtual; abstract;
    procedure Cancel;

    property Observer: ISolverObserver read fObserver write fObserver;
    property Limits: TSolverLimits read fLimits write fLimits;
  end;

implementation

{ TSolver }

procedure TSolver.Cancel;
begin
  fCancelled := True;
end;

function TSolver.IsCancelled: Boolean;
begin
  Result := fCancelled;
end;

procedure TSolver.NotifyStateVisited(aDepth: Integer);
begin
  if Assigned(fObserver) then
    fObserver.OnStateVisited(aDepth);
end;

procedure TSolver.NotifyBacktrack(aDepth: Integer);
begin
  if Assigned(fObserver) then
    fObserver.OnBacktrack(aDepth);
end;

procedure TSolver.NotifyProgress(aNodesExplored: Cardinal);
begin
  if Assigned(fObserver) then
    fObserver.OnProgress(aNodesExplored);
end;

end.
