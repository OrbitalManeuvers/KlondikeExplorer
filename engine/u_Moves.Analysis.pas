unit u_Moves.Analysis;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections, System.Generics.Defaults,

  u_Types,
  u_Tables,
  u_CardStacks;

type
  TScoreFactor = (

    // Card advances to foundation
    sfMoveToFoundation,

    // Move exposes another card that can immediately go to foundation
    sfEnablesFoundation,

    // Pulling back from foundation
    sfBacktrack,

    // Flip a hidden card face-up.
    sfUncoverFaceDown,

    // Removing a face-up card exposes another face-up card
    sfUncoverTableau,

    // Pile becomes empty.
    sfEmptyTableau,

    // A King is placed in an empty tableau
    sfKingToEmptyTableau,

    // Adds to a build
    sfBuildTableau,

    // Reveals new waste card
    sfNewWasteCard,

    // Waste card is permanently cleared
    sfWasteRemoval,

//    // Move frees a tableau for King placement
//    sfUnblockKingSlot,

    // Move blocks a card that could go to foundation
    sfBlockedFoundation
  );

  TScoreFactors = set of TScoreFactor;

  // Numeric and boolean features for richer move evaluation
  TMoveFeatures = record
    MovedRunLength: Integer;           // Number of cards moved as a run
    NewBuildLength: Integer;           // Length of run at target after move
    SourceResidualRunLength: Integer;  // Length of run left at source
    RunDestinationsCount: Integer;     // How many piles could accept the new top run
    SourceFaceDownDistanceDelta: Integer; // Change in face-up cards above next face-down (if any)
    SourceStackDepth: Integer;         // Total cards in source stack
    SourceFaceDownCount: Integer;      // Face-down cards remaining at source after move
    TargetStackDepth: Integer;         // Total cards in target stack (for tie-breaking)
    EmptyTableauCount: Integer;        // Number of empty tableaus (for move urgency calculation)
    HasHiddenKingInWaste: Boolean;     // True if the 2nd card in waste is a King when empty tableaus exist
    CanReverseImmediately: Boolean;    // True if move can be immediately reversed with no new effect
    IsOscillationProne: Boolean;       // True if move is likely part of a back-and-forth pattern
    CanBeDelayed: Boolean;             // True if move can be safely deferred (moves with low urgency)
    BrokeBuild: Boolean;               // True if move splits a run at source
    PreservedRun: Boolean;             // True if move carries an intact run

    // Pressure gauges. For all "count" type values -1 indicates it has not been calculated, or is N/A
    // so 0 - n is an actual count.
    Pressure: record
      table: Integer;        // total cards not in play - stock+waste
      king: Integer;         // number of kings that could be moved to a tableau if one was empty
      card: Integer;         // number of cards that could immediately stack on the move card
      reduces: Boolean;      // does this move reduce table pressure? (it's always only 1 card at a time)
    end;

    procedure Clear;
  end;

type
  // info about one "side" of a move
  TMoveComponent = record
    Id: TStackId;
    Category: TStackCategory;
    Stack: TCardStack;
  end;

  // hey callers: cache these if you need them more than once
  TPressureGauge = (pgTable, pgKing, pgCard);

  // summary info
  TMoveInfo = class
  private
    fMoveCards: TList<TCard>;
  public
    Table: TTable;
    MoveCount: Integer;
    MoveType: TMoveType;
    Source: TMoveComponent;
    Target: TMoveComponent;
    NextFoundation: array[TCardSuit] of TCardValue;
    EmptyTableauCount: Integer;

    constructor Create;
    destructor Destroy; override;

    property MoveCards: TList<TCard> read fMoveCards;
    procedure Load(const aMove: TMove; aTable: TTable);

    function ReadPressure(aGauge: TPressureGauge): Integer;
  end;

  TEvaluation = record
    Move: TMove;
    Score: Integer;
    Factors: TScoreFactors;
    Features: TMoveFeatures;
    procedure Assign(aSource: TEvaluation);
  end;

type
  TEvalComparer = class(TInterfacedObject, IComparer<TEvaluation>)
  public
    function Compare(const L, R: TEvaluation): Integer;
  end;


function FactorToStr(aFactor: TScoreFactor): string;
procedure FactorsToStr(aFactors: TScoreFactors; aList: TStrings);
function MoveTypeToStr(aMoveType: TMoveType): string;

function NewEvaluation(aSource: TEvaluation): TEvaluation;


implementation


uses System.TypInfo,

  u_Cards,
  u_TableUtils;

{ TEvalComparer }
function TEvalComparer.Compare(const L, R: TEvaluation): Integer;
begin
  Result := R.Score - L.Score;
end;


function FactorToStr(aFactor: TScoreFactor): string;
begin
  // use typeinfo to convert enum to string
  Result := GetEnumName(TypeInfo(TScoreFactor), Ord(aFactor));
end;

procedure FactorsToStr(aFactors: TScoreFactors; aList: TStrings);
begin
  for var sf := Low(TScoreFactor) to High(TScoreFactor) do
    if sf in aFactors then
      aList.Add(FactorToStr(sf));
end;

function MoveTypeToStr(aMoveType: TMoveType): string;
begin
  Result := GetEnumName(TypeInfo(TMoveType), Ord(aMoveType));
end;

function NewEvaluation(aSource: TEvaluation): TEvaluation;
begin
  Result.Assign(aSource);
end;



{ TMoveFeatures }
procedure TMoveFeatures.Clear;
begin
  MovedRunLength := 0;
  NewBuildLength := 0;
  SourceResidualRunLength := 0;
  RunDestinationsCount := 0;
  SourceFaceDownDistanceDelta := 0;
  SourceStackDepth := 0;
  SourceFaceDownCount := 0;
  TargetStackDepth := 0;
  EmptyTableauCount := 0;
  HasHiddenKingInWaste := False;
  CanReverseImmediately := False;
  IsOscillationProne := False;
  CanBeDelayed := False;
  BrokeBuild := False;
  PreservedRun := False;
  Pressure.table := -1;
  pressure.king := -1;
  pressure.card := -1;
  Pressure.reduces := False;
end;

{ TMoveInfo }

constructor TMoveInfo.Create;
begin
  inherited Create;
  fMoveCards := TList<TCard>.Create;
end;

destructor TMoveInfo.Destroy;
begin
  fMoveCards.Free;
  inherited;
end;

procedure TMoveInfo.Load(const aMove: TMove; aTable: TTable);
begin
  Self.Table := aTable;
  Self.MoveCount := aMove.Count;
  Self.Source.Id := aMove.Source;
  Self.Source.Category := IdToCategory(Self.Source.Id);
  Self.Source.Stack := aTable.Stacks[aMove.Source];

  Self.Target.Id := aMove.Target;
  Self.Target.Category := IdToCategory(Self.Target.Id);
  Self.Target.Stack := aTable.Stacks[Self.Target.Id];
  Self.MoveType := aMove.GetMoveType;

  fMoveCards.Count := 0;
  Self.Source.Stack.GetLastCards(fMoveCards, Self.MoveCount);

  // a quick setup of which foundation cards are required next
  for var f := Low(TCardSuit) to High(TCardSuit) do
  begin
    // setting a King to an Ace just as an unreachable value
    if Table.Foundation[f].IsEmpty or (Table.Foundation[f].Last.Value = cvKing) then
      NextFoundation[f] := cvAce
    else
      NextFoundation[f] := Succ(Table.Foundation[f].Last.Value);
  end;

  // count empty tableaus for move urgency analysis
  for var ti := Low(TTableauIndex) to High(TTableauIndex) do
    if aTable.Tableau[ti].IsEmpty then
      Inc(EmptyTableauCount);
end;

function TMoveInfo.ReadPressure(aGauge: TPressureGauge): Integer;
begin
  Result := 0;

  case aGauge of

    // much ado about nothing, but ... future-proofing blah blah
    pgTable: Result := Table.Stock.Count + Table.Waste.Count;

    // this one is not free
    pgKing:
      begin
//        Assert(False, 'hey implement this already');
        // definition: king on top of the waste, or a king face-up within a tableau

        // check the waste pile for a king on top
        if Table.Waste.HasCards and (Table.Waste.Last.Value = cvKing) then
        begin
          Result := Result + 1;
        end;

        // check each of the tableau stacks except for the source
        var q: TCardQuery;
        q.SearchArea := ALL_TABLEAUS;
        Exclude(q.SearchArea, Source.Id);
        q.SearchTable := Table;
        q.SearchTargetValue := cvKing;
        q.SearchMinIndex := 1; // don't find kings at the base of a tableau already

        Result := Result + TTableQuery.CountCardValue(q);
      end;

    // definitely not free
    pgCard:
      begin
        Assert(
          (Target.Category = scTableau) and
          (MoveCount = 1) and (not MoveCards.IsEmpty),
          'what is happening here?'
        );

        // counts the number of cards that could immediately be played on top of the move card
        Result := 0;

        // we have to be moving a 3 or above to exclude aces
        var moveCard := MoveCards.First;
        if moveCard.Value >= cvThree then
        begin
          var targetValue := Pred(moveCard.Value); // i.e. -1
          var targetColor := OppositeColor(moveCard.Color);

          // candidates are the tops of waste or tableaus ... this is convenient on purpose ...
          var i: TStackIterator;
          i.Init(siWaste, siTableau7);
          repeat

            // omit the planned target
            if i.Current <> Target.Id then
            begin
              var stack := Self.Table.Stacks[i.Current];
              if stack.HasCards and stack.Last.Matches(targetValue, targetColor) then
              begin
                Inc(Result);
              end;
            end;

            // there is a maximum here ...
            if Result = 2 then
              Break;

          until not i.MoveNext;
        end;
      end;

  end;
end;

{ TEvaluation }

procedure TEvaluation.Assign(aSource: TEvaluation);
begin
  Self.Move := aSource.Move;
  Self.Score := aSource.Score;
  Self.Factors := aSource.Factors;
  Self.Features := aSource.Features;
end;


end.
