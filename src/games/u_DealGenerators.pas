unit u_DealGenerators;

interface

uses System.Generics.Collections,
  u_Types;

type
  TDifficulty = (ddUnknown, ddUnsolved, ddEasy, ddMedium, ddDifficult);

  TDeal = record
    Title: string;
    Difficulty: TDifficulty;
    Cards: TArray<TCard>;
  end;

  TDealGenerator = class
  private
    fDeals: TList<TDeal>;
    function GetCount: Integer;
    function GetDeal(Index: Integer): TDeal;
    procedure GenerateSolvableDeals;
    procedure GenerateRandomDeals(aCount: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure GenerateDeals(aRandomCount: Integer = 2); // params?

    property Count: Integer read GetCount;
    property Deals[Index: Integer]: TDeal read GetDeal;
  end;


  TDifficultyHelper = record helper for TDifficulty
    function AsString: string;
  end;

implementation

uses System.SysUtils,
  u_Dealers, u_CardStacks, u_Shufflers, u_BasicSolvers, u_SolverTypes,
  u_Snapshots;

{ TDifficultyHelper }

function TDifficultyHelper.AsString: string;
begin
  case Self of
    ddUnknown: Result := '';
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

procedure TDealGenerator.GenerateDeals(aRandomCount: Integer);
begin
  Clear;
  GenerateSolvableDeals;
  GenerateRandomDeals(aRandomCount);
end;

procedure TDealGenerator.GenerateRandomDeals(aCount: Integer);

begin
  for var i := 1 to aCount do
  begin
    var cards := TCardStack.Create;
    TDealer.PopulateNewDeck(cards);
    TShuffler.Shuffle(cards);

    var deal := Default(TDeal);
    deal.Title := 'Random-' + i.ToString;
    deal.Difficulty := ddUnsolved;
    deal.Cards := cards._Cards.ToArray;
    fDeals.Add(deal);
  end;
end;

procedure TDealGenerator.GenerateSolvableDeals;
begin
  Exit;

  var limits := Default(TSolverLimits);
  limits.MaxDepth := 1000;
  limits.MaxNodes := 1000;

  var solver := TBasicSolver.Create;
  try
    solver.Limits := limits;

    var deck := TCardStack.Create;
    try

      var seedList := TList<Integer>.Create;
      try
        for var i := 1 to 1 do
          seedList.Add(Round(Random()));

        var snapshot := TSnapshot.Create;
        try
          // attempt each
          for var attempt := 0 to seedList.Count - 1 do
          begin
            RandSeed := seedList[attempt];
            TDealer.PopulateNewDeck(deck);
            TShuffler.Shuffle(deck);

            // save the deck as-is
            var temp := TCardStack.Create;
            try
              temp.AddFrom(deck);

              var result := solver.Solve(temp);
              if result.Result = srSolved then
              begin
                var deal := Default(TDeal);
                var seed: Integer := seedList[attempt];
                deal.Title := 'BasicSolver-' + seed.ToString;
                deal.Difficulty := ddEasy;
                for var i := 0 to deck.Count - 1 do
                  deal.Cards[i] := deck.Cards[i];

                fDeals.Add(deal);
              end;


            finally
              temp.Free;
            end;

          end;
        finally
          snapshot.Free;
        end;

      finally
        seedList.Free;
      end;

    finally
      deck.Free;
    end;

  finally
    solver.Free;
  end;

end;

function TDealGenerator.GetCount: Integer;
begin
  Result := fDeals.Count;
end;

function TDealGenerator.GetDeal(Index: Integer): TDeal;
begin
  Result := fDeals[Index];
end;


end.
