unit u_DealCreators;

interface

uses System.Generics.Collections,
  u_Types, u_Snapshots;

type
  TDealCreator = class
  public
    class procedure CreateState(aState: TSnapshot); virtual; abstract;
  end;
  TDealCreatorClass = class of TDealCreator;

  TRandomDealCreator = class(TDealCreator)
    class procedure CreateState(aState: TSnapshot); override;
  end;

implementation

uses System.SysUtils,
  u_Dealers, u_Shufflers, u_Tables, u_CardStacks;



{ TRandomDealCreator }

class procedure TRandomDealCreator.CreateState(aState: TSnapshot);
begin
  var deck := TCardStack.Create;
  try
    TDealer.PopulateNewDeck(deck);
    TShuffler.Shuffle(deck);

    var table := TTable.Create;
    try
      TDealer.Deal(deck, table);
      aState.Capture(table);
    finally
      table.Free;
    end;

  finally
    deck.Free;
  end;
end;


end.
