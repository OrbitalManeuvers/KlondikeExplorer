unit u_DealCreators;

interface

uses System.Classes, System.Generics.Collections,
  u_Types, u_Snapshots;

type
  TDealCreator = class
  private
    fLog: TStrings;
  public
    constructor Create;
    destructor Destroy; override;
    procedure CreateState(aState: TSnapshot); virtual; abstract;
    property Log: TStrings read fLog;
  end;
  TDealCreatorClass = class of TDealCreator;

  TRandomDealCreator = class(TDealCreator)
  public
    procedure CreateState(aState: TSnapshot); override;
  end;

implementation

uses System.SysUtils,
  u_Dealers, u_Shufflers, u_Tables, u_CardStacks;


{ TDealCreator }

constructor TDealCreator.Create;
begin
  inherited Create;
  fLog := TStringList.Create(dupIgnore, False, False);
end;

destructor TDealCreator.Destroy;
begin
  fLog.Free;
  inherited;
end;

{ TRandomDealCreator }
procedure TRandomDealCreator.CreateState(aState: TSnapshot);
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
