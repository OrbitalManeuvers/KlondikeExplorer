unit u_DealCreators;

interface

uses System.Generics.Collections,
  u_Types;

type
  TSolvability = (svUnknown, svSolvable);

  TDealCreator = class
  public
    class function Description: string; virtual; abstract;
    class function Solvability: TSolvability; virtual; abstract;
    class procedure CreateDeal(out Cards: TArray<TCard>); virtual; abstract;
  end;

  TDealCreatorClass = class of TDealCreator;

function _DealCreatorRegistry: TList<TDealCreatorClass>;

implementation

uses System.SysUtils,
  u_Dealers, u_Shufflers, u_CardStacks;

type
  TRandomDealCreator = class(TDealCreator)
    class function Description: string; override;
    class function Solvability: TSolvability; override;
    class procedure CreateDeal(out Cards: TArray<TCard>); override;
  end;

var
  _registry: TList<TDealCreatorClass> = nil;

function _DealCreatorRegistry: TList<TDealCreatorClass>;
begin
  if _registry = nil then
    _registry := TList<TDealCreatorClass>.Create;
  Result := _registry;
end;

{ TRandomDealCreator }

class procedure TRandomDealCreator.CreateDeal(out Cards: TArray<TCard>);
begin
  var deck := TCardStack.Create;
  try
    TDealer.PopulateNewDeck(deck);
    TShuffler.Shuffle(deck);

    Cards := deck._Cards.ToArray;

  finally
    deck.Free;
  end;
end;

class function TRandomDealCreator.Description: string;
begin
  Result := 'Random';
end;

class function TRandomDealCreator.Solvability: TSolvability;
begin
  Result := svUnknown;
end;

initialization
  _DealCreatorRegistry.Add(TRandomDealCreator);

finalization
  FreeAndNil(_registry);

end.
