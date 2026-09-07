unit u_MoveGenerators;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Tables,
  u_CardHelpers,
  u_MoveLists,
  u_SolverTypes
  ;

type
  TMoveGenerator = class
  public
    class procedure GenerateMoves(aTable: TTable; aList: TMoveList);
    class procedure GenerateSolverMoves(aTable: TTable; aList: TList<TSolverMove>);
  end;

implementation

uses System.Math,
  u_TableUtils, u_Utils, u_CardPools, u_MoveValidators;


{ TMoveGenerator }

class procedure TMoveGenerator.GenerateMoves(aTable: TTable; aList: TMoveList);
var
  source, target: TStackIterator;
begin
  // don't create moves for a stalemate board
  if aTable.RecycleCount >= 3 then
    Exit;

  for var moveType := Low(TMoveType) to High(TMoveType) do
  begin

    case moveType of
      mtDraw:
        begin
          if aTable.Stock.HasCards then
            aList.Add(siStock, siWaste, 0);
        end;
      mtRecycle:
        begin
          // If we've recycled 3 times without a reset, we've exhausted all possible draw alignments
          if aTable.Stock.IsEmpty and aTable.Waste.HasCards and (aTable.RecycleCount < 3) then
            aList.Add(siWaste, siStock, 0);
        end;
      mtWasteToTableau:
        begin
          if aTable.Waste.HasCards then
          begin
            target.Init(siTableau1, siTableau7);
            repeat
              aList.Add(siWaste, target.Current);
            until not target.MoveNext;
          end;
        end;
      mtWasteToFoundation:
        begin
          if aTable.Waste.HasCards then
          begin
            var suit := aTable.Waste.Last.Suit;
            aList.Add(siWaste, SuitToStackId(suit));
          end;
        end;
      mtTableauToTableau:
        begin
          source.Init(siTableau1, siTableau7);
          repeat
            if aTable.Stacks[source.Current].HasCards then
            begin
              target.Init(siTableau1, siTableau7);
              repeat
                // if this one isn't also the source, generate moves
                if target.Current <> source.Current then
                begin
                  // create one move for each face up card
                  for var count := 1 to aTable.Stacks[source.Current].FaceUpCount do
                    aList.Add(source.Current, target.Current, count);
                end;
              until not target.MoveNext;
            end;
          until not source.MoveNext;
        end;
      mtTableauToFoundation:
        begin
          source.Init(siTableau1, siTableau7);
          repeat
            if aTable.Stacks[source.Current].HasCards then
            begin
              var suit := aTable.Stacks[source.Current].Last.Suit;
              aList.Add(source.Current, SuitToStackId(suit));
            end;
          until not source.MoveNext;
        end;
      mtFoundationToTableau:
        begin
          // don't generate any moves for a completed deck
          var atHome := 0;
          for var s := Low(TCardSuit) to High(TCardSuit) do
            Inc(atHome, aTable.Foundation[s].Count);
          if atHome = 52 then
            Exit;

          for var suit := Low(TCardSuit) to High(TCardSuit) do
          begin
            if aTable.Foundation[suit].HasCards and (aTable.Foundation[suit].Last.Value > cvTwo) then
            begin
              target.Init(siTableau1, siTableau7);
              repeat
                aList.Add(SuitToStackId(suit), target.Current);
              until not target.MoveNext;
            end;
          end;
        end;
    end;
  end;

end;

class procedure TMoveGenerator.GenerateSolverMoves(aTable: TTable; aList: TList<TSolverMove>);
var
  source, target: TStackIterator;
  pool: TStockWastePool;
  count: Integer;
  procedure AddBoardMove(const aMove: TMove);
  var
    solverMove: TSolverMove;
  begin
    if TMoveValidator.IsValidMove(aMove, aTable) then
    begin
      solverMove.Move := aMove;
      solverMove.DrawsBeforeRecycle1 := 0;
      solverMove.DrawsAfterRecycle1 := 0;
      solverMove.DrawsAfterRecycle2 := 0;
      solverMove.RecycleCount := 0;
      aList.Add(solverMove);
    end;
  end;
begin
  // don't create moves for a stalemate board
  if aTable.RecycleCount >= 3 then
    Exit;

  // tableau-to-tableau
  source.Init(siTableau1, siTableau7);
  repeat
    if aTable.Stacks[source.Current].HasCards then
    begin
      var kingToEmptyEmitted := False;
      target.Init(siTableau1, siTableau7);
      repeat
        if target.Current <> source.Current then
        begin
          for count := 1 to aTable.Stacks[source.Current].FaceUpCount do
          begin
            // A king moving to an empty column: all empty columns are
            // equivalent, so emit only the first one per source run.
            var baseCard := aTable.Stacks[source.Current].Cards[
              aTable.Stacks[source.Current].Count - count];
            if (baseCard.Value = cvKing) and aTable.Stacks[target.Current].IsEmpty then
            begin
              if kingToEmptyEmitted then
                Continue;
              kingToEmptyEmitted := True;
            end;
            AddBoardMove(NewMove(source.Current, target.Current, count));
          end;
        end;
      until not target.MoveNext;
    end;
  until not source.MoveNext;

  // tableau-to-foundation
  source.Init(siTableau1, siTableau7);
  repeat
    if aTable.Stacks[source.Current].HasCards then
      AddBoardMove(NewMove(source.Current,
        SuitToStackId(aTable.Stacks[source.Current].Last.Suit), 1));
  until not source.MoveNext;

  // foundation-to-tableau
  var atHome := 0;
  for var s := Low(TCardSuit) to High(TCardSuit) do
    Inc(atHome, aTable.Foundation[s].Count);
  if atHome <> 52 then
  begin
    for var suit := Low(TCardSuit) to High(TCardSuit) do
    begin
      if aTable.Foundation[suit].HasCards and (aTable.Foundation[suit].Last.Value > cvTwo) then
      begin
        var foundationKingToEmptyEmitted := False;
        var isKing := aTable.Foundation[suit].Last.Value = cvKing;
        target.Init(siTableau1, siTableau7);
        repeat
          if isKing and aTable.Stacks[target.Current].IsEmpty then
          begin
            if not foundationKingToEmptyEmitted then
            begin
              foundationKingToEmptyEmitted := True;
              AddBoardMove(NewMove(SuitToStackId(suit), target.Current, 1));
            end;
            // else skip duplicate king-to-empty
          end
          else
            AddBoardMove(NewMove(SuitToStackId(suit), target.Current, 1));
        until not target.MoveNext;
      end;
    end;
  end;

  // waste-derived moves: use pool scanner (this emits TSolverMove entries)
  pool.Init(aTable);
  pool.ScanReachableMoves(aTable, aList);
end;

end.


