unit u_SolvableDealCreators;

interface

uses u_Types, u_DealCreators, u_Snapshots, u_ObserverTypes;

type
  TForwardDealCreator = class(TDealCreator)
  private
    fObserver: ISolverObserver;
  public
    procedure CreateState(aState: TSnapshot); override;
  end;

  TReverseDealCreator = class(TDealCreator)
  public
    procedure CreateState(aState: TSnapshot); override;
  end;

implementation

uses System.Classes, System.SysUtils,
  u_BasicSolvers, u_Tables, u_CardStacks, u_Dealers, u_MoveGenerators, u_MoveValidators,
  u_Shufflers, u_SolverTypes, u_Observers;

const
  MAX_ATTEMPTS = 20; // don't keep trying forever if something is wrong


{ TForwardDealCreator }
procedure TForwardDealCreator.CreateState(aState: TSnapshot);
begin
  fObserver := TSolverObserver.Create;

  var table := TTable.Create;
  try
    var deck := TCardStack.Create;
    try

      for var attempt := 1 to MAX_ATTEMPTS do
      begin

        // step 1 - populate and shuffle a new deck
        TDealer.PopulateNewDeck(deck);
        TShuffler.Shuffle(deck);

        // step 2 - put the deck on the table and capture it
        TDealer.Deal(deck, table);
        aState.Capture(table);

        // log snapshot
        Log.Add('Attempting: ' + aState.AsText);

        // step 3 - attempt to find a solution
        var solver := TDFSSolver.Create;
        try
          solver.Observer := fObserver;
          var limits := Default(TSolverLimits);
          limits.MaxNodes := 500000;
          solver.Limits := limits;

          var solverResult := solver.Solve(aState);

          if solverResult.Result = srSolved then
          begin
            //
            Exit;
          end;
        finally
          solver.Free;
        end;

      end;

      // failed MAX_ATTEMPTS
      raise Exception.Create('MAX_ATTEMPTS reached');

    finally
      deck.Free;
    end;

  finally
    table.Free;
  end;
end;


{ TReverseDealCreator }
procedure TReverseDealCreator.CreateState(aState: TSnapshot);
begin
  Assert(False, 'Not Implemented');
///

end;

end.
