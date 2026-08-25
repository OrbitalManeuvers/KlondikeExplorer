unit u_SolvableDealCreators;

interface

uses u_Types, u_DealCreators;

type
  TForwardDealCreator = class(TDealCreator)
  public
    class function Description: string; override;
    class function Solvability: TSolvability; override;
    class procedure CreateDeal(out Cards: TArray<TCard>); override;
  end;

  TReverseDealCreator = class(TDealCreator)
  public
    class function Description: string; override;
    class function Solvability: TSolvability; override;
    class procedure CreateDeal(out Cards: TArray<TCard>); override;
  end;

implementation

const
  MAX_ATTEMPTS = 10; // don't keep trying forever if something is wrong

{ TForwardDealCreator }

class procedure TForwardDealCreator.CreateDeal(out Cards: TArray<TCard>);
begin
(*
  - loop over MAX_ATTEMPTS
  - TCardStack -> TDealer -> TShuffler
  - send to TBasicSolver
*)
end;

class function TForwardDealCreator.Description: string;
begin
  Result := 'ForwardSolver';
end;

class function TForwardDealCreator.Solvability: TSolvability;
begin
  Result := svSolvable;
end;

{ TReverseDealCreator }

class procedure TReverseDealCreator.CreateDeal(out Cards: TArray<TCard>);
begin
  //

end;

class function TReverseDealCreator.Description: string;
begin
  Result := 'Unsolver';
end;

class function TReverseDealCreator.Solvability: TSolvability;
begin
  Result := svSolvable;
end;

end.
