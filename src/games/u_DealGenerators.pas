unit u_DealGenerators;

interface

uses System.Generics.Collections,
  u_Types;

type
  TDifficulty = (ddUnsolved, ddEasy, ddMedium, ddDifficult);

  TDeal = record
    Title: string;
    Difficulty: TDifficulty;
    Cards: array[TCardOrdinal] of TCardOrdinal;
  end;

  TDealGenerator = class
  private
    fDeals: TList<TDeal>;
    function GetCount: Integer;
    function GetDeal(Index: Integer): TDeal;
    procedure GenerateSolvableDeals;
    procedure GenerateRandomDeals;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure GenerateDeals(); // params?

    property Count: Integer read GetCount;
    property Deals[Index: Integer]: TDeal read GetDeal;
  end;


  TDifficultyHelper = record helper for TDifficulty
    function AsString: string;
  end;

implementation

uses u_Dealers, u_CardStacks, u_Shufflers;

{ TDifficultyHelper }

function TDifficultyHelper.AsString: string;
begin
  case Self of
    ddUnsolved: Result := 'Unsolved';
    ddEasy: Result := 'Easy';
    ddMedium: Result := 'Medium';
    ddDifficult: Result := 'Difficult';
  end;
end;


{ TDealGenerator }

constructor TDealGenerator.Create;
begin
  inherited Create;
  fDeals := TList<TDeal>.Create;
end;

destructor TDealGenerator.Destroy;
begin
  fDeals.Free;
  inherited;
end;

procedure TDealGenerator.Clear;
begin
  fDeals.Clear;
end;

procedure TDealGenerator.GenerateDeals;
begin
  Clear;
  GenerateSolvableDeals;
  GenerateRandomDeals;
end;

procedure TDealGenerator.GenerateRandomDeals;
begin
  // create one random deal
  var cards := TCardStack.Create;
  TDealer.PopulateNewDeck(cards);
  TShuffler.Shuffle(cards);

  var deal := Default(TDeal);
  deal.Title := 'Random';
  deal.Difficulty := ddUnsolved;

  // needs to be formalized
  for var i := 0 to cards.Count - 1 do
    deal.Cards[i] := cards.Cards[i];

  fDeals.Add(deal);

  // ---

  cards.Clear;
  TDealer.PopulateNewDeck(cards);
  TShuffler.Shuffle(cards);

  deal := Default(TDeal);
  deal.Title := 'Random2';
  deal.Difficulty := ddUnsolved;

  for var i := 0 to cards.Count - 1 do
    deal.Cards[i] := cards.Cards[i];

  fDeals.Add(deal);
end;

procedure TDealGenerator.GenerateSolvableDeals;
begin
  //
end;

function TDealGenerator.GetCount: Integer;
begin
  Result := FDeals.Count;
end;

function TDealGenerator.GetDeal(Index: Integer): TDeal;
begin
  Result := fDeals[Index];
end;


end.
