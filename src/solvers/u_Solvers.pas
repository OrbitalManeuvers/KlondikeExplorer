unit u_Solvers;

interface

uses System.Classes,
  u_CardStacks, u_ObserverTypes, u_SolverTypes, u_Snapshots;

type
  TSolverLogEvent = procedure(Sender: TObject; const aLine: string) of object;

  TSolver = class
  private
    fObserver: ISolverObserver;
    fLimits: TSolverLimits;
    fCancelled: Boolean;
    fOnLog: TSolverLogEvent;
  protected
    procedure NotifyStateVisited(aDepth: Integer);
    procedure NotifyBacktrack(aDepth: Integer);
    procedure NotifyProgress(aNodesExplored: Cardinal);
    function IsCancelled: Boolean;

    procedure Log(const aLine: string);

  public
    constructor Create;
    destructor Destroy; override;

    function Solve(InitialState: TSnapshot): TSolverOutcome; virtual; abstract;
    procedure Cancel;

    property Observer: ISolverObserver read fObserver write fObserver;
    property Limits: TSolverLimits read fLimits write fLimits;
    property OnLog: TSolverLogEvent read fOnLog write fOnLog;
  end;

implementation

{ TSolver }

constructor TSolver.Create;
begin
  inherited Create;
end;

destructor TSolver.Destroy;
begin
  inherited;
end;

procedure TSolver.Cancel;
begin
  fCancelled := True;
end;

function TSolver.IsCancelled: Boolean;
begin
  Result := fCancelled;
end;

procedure TSolver.Log(const aLine: string);
begin
  //
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
