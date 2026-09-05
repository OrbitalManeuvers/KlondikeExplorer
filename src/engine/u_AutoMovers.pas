unit u_AutoMovers;

interface

uses u_Types, u_Tables;

type
  // Determines the natural "auto-move" for a clicked card on a given table state.
  // Pure logic: reads the table, returns a move. No state of its own.
  TAutoMover = class
    class function FindAutoMove(aTable: TTable; aStackId: TStackId; aCardIndex: Integer;
      out aMove: TMove): Boolean;
  end;

implementation

uses System.Math,
  u_Utils, u_TableUtils, u_CardHelpers;

class function TAutoMover.FindAutoMove(aTable: TTable; aStackId: TStackId; aCardIndex: Integer;
  out aMove: TMove): Boolean;
begin
  Result := False;

  case StackIdToCategory(aStackId) of

    // Stock - if cards: flip to waste; if empty: recycle waste back to stock
    scStock:
      begin
        if aTable.Stock.HasCards then
        begin
          aMove := NewMove(siStock, siWaste, Min(3, aTable.Stock.Count));
          Exit(True);
        end
        else if aTable.Waste.HasCards then
        begin
          aMove := NewMove(siWaste, siStock, 0);
          Exit(True);
        end;
      end;

    // Waste - only the topmost card moves. Try foundation first, then tableaus.
    scWaste:
      begin
        if aTable.Waste.HasCards then
        begin
          var c := aTable.Waste.Last;

          if IsNextFoundationCard(c, aTable) then
          begin
            aMove := NewMove(siWaste, SuitToStackId(c.Suit), 1);
            Exit(True);
          end;

          var targetId: TStackId;
          if FindTableauTarget(c, aTable, targetId) then
          begin
            aMove := NewMove(siWaste, targetId, 1);
            Exit(True);
          end;
        end
        else
        begin
          aMove := NewMove(siWaste, siStock, 0);
        end;
      end;

    // Tableau
    // - topmost card: foundation first, then another tableau
    // - buried face-up card: can only move its full run to another tableau
    scTableau:
      begin
        var c := aTable.Stacks[aStackId].Cards[aCardIndex];

        // topmost card can go to foundation
        if aCardIndex = aTable.Stacks[aStackId].Count - 1 then
          if IsNextFoundationCard(c, aTable) then
          begin
            aMove := NewMove(aStackId, SuitToStackId(c.Suit), 1);
            Exit(True);
          end;

        // otherwise (or if no foundation move) it must move to a valid tableau spot
        var target: TStackId;
        if FindTableauTarget(c, aTable, target) then
        begin
          aMove := NewMove(aStackId, target, aTable.Stacks[aStackId].Count - aCardIndex);
          Exit(True);
        end;
      end;

    // Foundation - only the single top card, only back to a tableau
    scFoundation:
      begin
        if aTable.Stacks[aStackId].HasCards then
        begin
          var c := aTable.Stacks[aStackId].Last;
          var target: TStackId;
          if FindTableauTarget(c, aTable, target) then
          begin
            aMove := NewMove(aStackId, target, 1);
            Exit(True);
          end;
        end;
      end;

  end;
end;

end.
