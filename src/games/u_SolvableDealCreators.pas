unit u_SolvableDealCreators;

interface

uses u_Types, u_DealCreators, u_Snapshots;

type
  TForwardDealCreator = class(TDealCreator)
  public
    class procedure CreateState(aState: TSnapshot); override;
  end;

  TReverseDealCreator = class(TDealCreator)
  public
    class procedure CreateState(aState: TSnapshot); override;
  end;

implementation

uses u_BasicSolvers;

const
  MAX_ATTEMPTS = 10; // don't keep trying forever if something is wrong


{ TForwardDealCreator }
class procedure TForwardDealCreator.CreateState(aState: TSnapshot);
begin

  //


end;


{ TReverseDealCreator }
class procedure TReverseDealCreator.CreateState(aState: TSnapshot);
begin

///

end;

end.
