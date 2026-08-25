unit u_MoveGenerators;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Tables,
  u_CardHelpers,
  u_MoveLists
  ;

type
  TMoveGenerator = class
  public
    class procedure GenerateMoves(aTable: TTable; aList: TMoveList);
  end;

implementation

uses System.Math,
  u_TableUtils, u_Utils;


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
            aList.Add(siStock, siWaste, Min(aTable.Stock.Count, 3));
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

end.

