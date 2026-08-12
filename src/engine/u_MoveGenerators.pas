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

// Experimenting with a coding pattern when every member of an enum must be accounted for.
// Delphi makes it too easy to add an enum that never gets checked by case statements.
class procedure TMoveGenerator.GenerateMoves(aTable: TTable; aList: TMoveList);
type
  TMoveTypeHandler = reference to procedure;
  TMoveTypeHandlers = array[TMoveType] of TMoveTypeHandler;
  TMoveTypes = set of TMoveType;
var
  source, target: TStackIterator;
  suit: TCardSuit;
  coverage: TMoveTypes;

  procedure cover(aMoveType: TMoveType; handler: TMoveTypeHandler);
  begin
    if Assigned(handler) then
    begin
      Handler();
      Include(coverage, aMoveType);
    end;
  end;

begin
  coverage := [];

  cover(mtDraw, procedure
    begin
      if aTable.Stock.HasCards then
      begin
        aList.Add(siStock, siWaste, Min(aTable.Stock.Count, 3));
      end;
    end
    );

  cover(mtRecycle, procedure
    begin
      if aTable.Stock.IsEmpty and aTable.Waste.HasCards then
      begin
        aList.Add(siWaste, siStock, 0);
      end;
    end
    );

  cover(mtWasteToTableau, procedure
    begin
      if aTable.Waste.HasCards then
      begin
        target.Init(siTableau1, siTableau7);
        repeat
          aList.Add(siWaste, target.Current);
        until not target.MoveNext;
      end;
    end
  );

  cover(mtWasteToFoundation, procedure
    begin
      if aTable.Waste.HasCards then
      begin
        suit := aTable.Waste.Last.Suit;
        aList.Add(siWaste, SuitToStackId(suit));
      end;
    end
  );

  cover(mtTableauToTableau, procedure
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
    end
  );

  cover(mtTableauToFoundation, procedure
    begin
      source.Init(siTableau1, siTableau7);
      repeat
        if aTable.Stacks[source.Current].HasCards then
        begin
          suit := aTable.Stacks[source.Current].Last.Suit;
          aList.Add(source.Current, SuitToStackId(suit));
        end;
      until not source.MoveNext;
    end
  );

  cover(mtFoundationToTableau, procedure
    begin
      // don't generate any moves for a completed deck
      var atHome := 0;
      for var s := Low(TCardSuit) to High(TCardSuit) do
        Inc(atHome, aTable.Foundation[s].Count);
      if atHome = 52 then
        Exit;

      for var s := Low(TCardSuit) to High(TCardSuit) do
      begin
        if aTable.Foundation[suit].HasCards and (aTable.Foundation[suit].Last.Value > cvTwo) then
        begin
          target.Init(siTableau1, siTableau7);
          repeat
            aList.Add(SuitToStackId(s), target.Current);
          until not target.MoveNext;
        end;
      end;
    end
  );

{$define EnumHandlerValidation}

{$ifdef EnumHandlerValidation}
  for var mt := Low(TMoveType) to High(TMoveType) do
    Assert(mt in coverage, Ord(mt).ToString);
{$endif}

end;

end.

