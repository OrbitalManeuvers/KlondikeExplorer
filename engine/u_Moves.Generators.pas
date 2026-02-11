unit u_Moves.Generators;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Tables,
  u_Cards,
  u_MoveLists
  ;

type
  TGenerator = class
  public
    class procedure GenerateMoves(aTable: TTable; aList: TMoveList);
  end;

implementation

uses System.Math,

  u_TableUtils;

type
  TListMoveHelper = class helper for TMoveList
    procedure AddMove(aSource, aTarget: TStackId; aCount: Integer = 1);
  end;

procedure TListMoveHelper.AddMove(aSource, aTarget: TStackId; aCount: Integer);
begin
  var m: TMove;
  m.Source := aSource;
  m.Target := aTarget;
  m.Count := aCount;
  Self.Add(m);
end;


{ TGenerator }

// coding pattern when every member of an enum must be accounted for
class procedure TGenerator.GenerateMoves(aTable: TTable; aList: TMoveList);
type
  TMoveTypeHandler = reference to procedure;
  TMoveTypeHandlers = array[TMoveType] of TMoveTypeHandler;
  TMoveTypes = set of TMoveType;
var
  source, target: TStackIterator;
  suit: TCardSuit;
  coverage: TMoveTypes;

  procedure cover(aMoveType: TmoveType; handler: TMoveTypeHandler);
  begin
    if Assigned(handler) then
    begin
      Handler();
      Include(coverage, aMoveType);
    end;
  end;

begin
  coverage := [];

  // The waste pile is never empty if there are playable cards. mtDraw will perform the recycle if needed.
  var playableCards := aTable.Stock.Count + aTable.Waste.Count;

  cover(mtDraw, procedure
    begin
      if playableCards > 0 then
      begin
        aList.AddMove(siStock, siWaste, Min(playableCards, 3));
      end;
    end
    );

  cover(mtWasteToTableau, procedure
    begin
      if aTable.Waste.HasCards then
      begin
        target.Init(siTableau1, siTableau7);
        repeat
          aList.AddMove(siWaste, target.Current);
        until not target.MoveNext;
      end;
    end
  );

  cover(mtWasteToFoundation, procedure
    begin
      if aTable.Waste.HasCards then
      begin
        suit := aTable.Waste.Last.Suit;
        aList.AddMove(siWaste, IdFromSuit(suit));
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
                aList.AddMove(source.Current, target.Current, count);
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
          aList.AddMove(source.Current, IdFromSuit(suit));
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
            aList.AddMove(IdFromSuit(s), target.Current);
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
