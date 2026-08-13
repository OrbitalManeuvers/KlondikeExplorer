unit u_HitTesters;

interface

uses
  System.Types,
  u_Types, u_Layouts, u_Tables;

type
  THitInfo = record
    Valid: Boolean;
    StackId: TStackId;
    CardIndex: Integer;      // index within the stack (-1 for empty stack click)
    IsFaceUp: Boolean;
  end;

  THitTester = class
    class function GetHitInfo(const Layout: TLayout; Table: TTable; MousePos: TPointF): THitInfo;
  end;

implementation

uses
  System.Math;

{ THitTester }

class function THitTester.GetHitInfo(const Layout: TLayout; Table: TTable;
  MousePos: TPointF): THitInfo;
var
  R: TRectF;
  I: Integer;
  CardIdx: Integer;
  StackCount: Integer;
  FaceUpCount: Integer;
  StackTop: Single;
  RelY: Single;
  VisibleCount: Integer;
  WasteX: Single;
begin
  Result := Default(THitInfo);

  // Check stock
  R := Layout.CardRect(Layout.Origins[siStock]);
  if R.Contains(MousePos) then
  begin
    Result.Valid := True;
    Result.StackId := siStock;
    Result.CardIndex := -1;
    Result.IsFaceUp := False;
    Exit;
  end;

  // Check waste (up to 3 visible cards, fanned right)
  if Table.Waste.HasCards then
  begin
    VisibleCount := Min(3, Table.Waste.Count);
    // Check from topmost (rightmost) to bottom so top card wins
    for I := VisibleCount - 1 downto 0 do
    begin
      WasteX := Layout.Origins[siWaste].X + Layout.WasteCardX(I);
      R := Layout.CardRect(PointF(WasteX, Layout.Origins[siWaste].Y));
      if R.Contains(MousePos) then
      begin
        Result.Valid := True;
        Result.StackId := siWaste;
        // Map visible index back to actual card index in the stack
        Result.CardIndex := Table.Waste.Count - VisibleCount + I;
        Result.IsFaceUp := True;
        Exit;
      end;
    end;
  end
  else
  begin
    // Empty waste slot
    R := Layout.CardRect(Layout.Origins[siWaste]);
    if R.Contains(MousePos) then
    begin
      Result.Valid := True;
      Result.StackId := siWaste;
      Result.CardIndex := -1;
      Result.IsFaceUp := False;
      Exit;
    end;
  end;

  // Check foundations
  for var stackId := siFoundation1 to siFoundation4 do
  begin
    R := Layout.CardRect(Layout.Origins[stackId]);
    if R.Contains(MousePos) then
    begin
      Result.Valid := True;
      Result.StackId := stackId;
      if Table.Stacks[stackId].HasCards then
        Result.CardIndex := Table.Stacks[stackId].Count - 1
      else
        Result.CardIndex := -1;
      Result.IsFaceUp := Table.Stacks[stackId].HasCards;
      Exit;
    end;
  end;

//  for var Suit := Low(TCardSuit) to High(TCardSuit) do
//  begin
//    R := Layout.CardRect(Layout.FoundationOrigins[Suit]);
//    if R.Contains(MousePos) then
//    begin
//      Result.Valid := True;
//      Result.StackId := TStackId(Ord(siFoundation1) + Ord(Suit));
//      if Table.Foundation[Suit].HasCards then
//        Result.CardIndex := Table.Foundation[Suit].Count - 1
//      else
//        Result.CardIndex := -1;
//      Result.IsFaceUp := Table.Foundation[Suit].HasCards;
//      Exit;
//    end;
//  end;

  // Check tableaus
  for var stackId := siTableau1 to siTableau7 do

//  for var TabIdx := Low(TTableauIndex) to High(TTableauIndex) do
  begin
    StackCount := Table.Stacks[stackId].Count;
    FaceUpCount := Table.Stacks[stackId].FaceUpCount;
    StackTop := Layout.Origins[stackId].Y;

    if StackCount = 0 then
    begin
      // Empty tableau — check the slot area
      R := Layout.CardRect(Layout.Origins[stackId]);
      if R.Contains(MousePos) then
      begin
        Result.Valid := True;
        Result.StackId := stackId;
        Result.CardIndex := -1;
        Result.IsFaceUp := False;
        Exit;
      end;
    end
    else
    begin
      // Check if mouse X is within this column
      if (MousePos.X >= Layout.Origins[stackId].X) and
         (MousePos.X <= Layout.Origins[stackId].X + Layout.CardWidth) then
      begin
        // Check if mouse Y is within the stack's vertical extent
        // The last card occupies a full card rect; all others show only StackOffset
        var StackBottom := StackTop + (StackCount - 1) * Layout.StackOffset + Layout.CardHeight;

        if (MousePos.Y >= StackTop) and (MousePos.Y <= StackBottom) then
        begin
          RelY := MousePos.Y - StackTop;

          // Determine which card index was hit
          // Each card except the last occupies StackOffset height
          CardIdx := Trunc(RelY / Layout.StackOffset);
          // Clamp to last card (which occupies full card height)
          CardIdx := Min(CardIdx, StackCount - 1);

          Result.Valid := True;
          Result.StackId := stackId;
          Result.CardIndex := CardIdx;
          Result.IsFaceUp := CardIdx >= (StackCount - FaceUpCount);
          Exit;
        end;
      end;
    end;
  end;

//  for var TabIdx := Low(TTableauIndex) to High(TTableauIndex) do
//  begin
//    StackCount := Table.Tableau[TabIdx].Count;
//    FaceUpCount := Table.Tableau[TabIdx].FaceUpCount;
//    StackTop := Layout.TableauOrigins[TabIdx].Y;
//
//    if StackCount = 0 then
//    begin
//      // Empty tableau — check the slot area
//      R := Layout.CardRect(Layout.TableauOrigins[TabIdx]);
//      if R.Contains(MousePos) then
//      begin
//        Result.Valid := True;
//        Result.StackId := TStackId(Ord(siTableau1) + TabIdx - 1);
//        Result.CardIndex := -1;
//        Result.IsFaceUp := False;
//        Exit;
//      end;
//    end
//    else
//    begin
//      // Check if mouse X is within this column
//      if (MousePos.X >= Layout.TableauOrigins[TabIdx].X) and
//         (MousePos.X <= Layout.TableauOrigins[TabIdx].X + Layout.CardWidth) then
//      begin
//        // Check if mouse Y is within the stack's vertical extent
//        // The last card occupies a full card rect; all others show only StackOffset
//        var StackBottom := StackTop + (StackCount - 1) * Layout.StackOffset + Layout.CardHeight;
//
//        if (MousePos.Y >= StackTop) and (MousePos.Y <= StackBottom) then
//        begin
//          RelY := MousePos.Y - StackTop;
//
//          // Determine which card index was hit
//          // Each card except the last occupies StackOffset height
//          CardIdx := Trunc(RelY / Layout.StackOffset);
//          // Clamp to last card (which occupies full card height)
//          CardIdx := Min(CardIdx, StackCount - 1);
//
//          Result.Valid := True;
//          Result.StackId := TStackId(Ord(siTableau1) + TabIdx - 1);
//          Result.CardIndex := CardIdx;
//          Result.IsFaceUp := CardIdx >= (StackCount - FaceUpCount);
//          Exit;
//        end;
//      end;
//    end;
//  end;

end;

end.
