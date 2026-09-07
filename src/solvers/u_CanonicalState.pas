unit u_CanonicalState;

{  Solver-oriented canonical representation of a table state.

   Identical to TSnapshot's binary layout except the seven tableau columns
   are sorted lexicographically.  Sorting makes states that differ only in
   which physical column holds a given pile hash-equivalent — the solver
   doesn't care which column a pile sits in, only what piles exist.

   Usage:
     var cs: TCanonicalState;
     cs.Capture(table);
     var h := cs.Hash;            // 64-bit hash for the visited set   }

interface

uses u_Types, u_Tables, u_CardStacks;

type
  TCanonicalState = record
  private const
    // Same geometry as TSnapshotBuffer: 52 cards + 13 stack counts + 1 recycle
    BUFFER_SIZE = 66;
    // Maximum bytes one stack can occupy: 1 count byte + up to 52 card bytes
    MAX_STACK_BYTES = 53;
  private
    fBuffer: array[0..BUFFER_SIZE - 1] of Byte;
    fLength: Integer;  // actual bytes written (always = BUFFER_SIZE for a full table)

    class function WriteStack(aStack: TCardStack;
      var aDest: array of Byte; aOffset: Integer): Integer; static;
    class function CompareColumns(const aBuf: array of Byte;
      aOffA, aLenA, aOffB, aLenB: Integer): Integer; static;
  public
    procedure Capture(aTable: TTable);
    function Hash: UInt64;
  end;

implementation

uses System.Hash;

{ TCanonicalState }

class function TCanonicalState.WriteStack(aStack: TCardStack;
  var aDest: array of Byte; aOffset: Integer): Integer;
var
  faceUpIndex, cardByte: Integer;
begin
  // write count
  aDest[aOffset] := Byte(aStack.Count);
  Result := 1;

  faceUpIndex := aStack.Count - aStack.FaceUpCount;
  for var i := 0 to aStack.Count - 1 do
  begin
    cardByte := aStack.Cards[i];
    if i >= faceUpIndex then
      cardByte := cardByte or $80;
    aDest[aOffset + Result] := Byte(cardByte);
    Inc(Result);
  end;
end;

class function TCanonicalState.CompareColumns(const aBuf: array of Byte;
  aOffA, aLenA, aOffB, aLenB: Integer): Integer;
var
  minLen, i: Integer;
begin
  if aLenA < aLenB then
    minLen := aLenA
  else
    minLen := aLenB;

  for i := 0 to minLen - 1 do
  begin
    if aBuf[aOffA + i] < aBuf[aOffB + i] then
      Exit(-1);
    if aBuf[aOffA + i] > aBuf[aOffB + i] then
      Exit(1);
  end;

  if aLenA < aLenB then
    Result := -1
  else if aLenA > aLenB then
    Result := 1
  else
    Result := 0;
end;

procedure TCanonicalState.Capture(aTable: TTable);
var
  // Temporary workspace for the 7 tableau columns before sorting.
  // Each column: 1 count byte + up to 24 card bytes (realistic max in Klondike).
  colBuf: array[0..7 * MAX_STACK_BYTES - 1] of Byte;
  colOffset: array[0..6] of Integer;
  colLen: array[0..6] of Integer;
  colOrder: array[0..6] of Integer;
  pos, written: Integer;
  tmp: Integer;
  sorted: Boolean;
begin
  pos := 0;

  // Stock
  Inc(pos, WriteStack(aTable.Stock, fBuffer, pos));

  // Waste
  Inc(pos, WriteStack(aTable.Waste, fBuffer, pos));

  // Capture 7 tableau columns into temp buffer
  var tempPos := 0;
  for var col := 0 to 6 do
  begin
    colOffset[col] := tempPos;
    colOrder[col] := col;
    var stackId := TStackId(Ord(siTableau1) + col);
    written := WriteStack(aTable.Stacks[stackId], colBuf, tempPos);
    colLen[col] := written;
    Inc(tempPos, written);
  end;

  // Insertion sort columns by their byte content
  for var i := 1 to 6 do
  begin
    tmp := colOrder[i];
    var j := i - 1;
    sorted := False;
    while (j >= 0) and not sorted do
    begin
      if CompareColumns(colBuf,
           colOffset[colOrder[j]], colLen[colOrder[j]],
           colOffset[tmp], colLen[tmp]) > 0 then
      begin
        colOrder[j + 1] := colOrder[j];
        Dec(j);
      end
      else
        sorted := True;
    end;
    colOrder[j + 1] := tmp;
  end;

  // Write sorted columns into fBuffer
  for var i := 0 to 6 do
  begin
    var col := colOrder[i];
    for var b := 0 to colLen[col] - 1 do
    begin
      fBuffer[pos] := colBuf[colOffset[col] + b];
      Inc(pos);
    end;
  end;

  // Foundations (fixed order by suit)
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    Inc(pos, WriteStack(aTable.Foundation[suit], fBuffer, pos));

  // Recycle count
  fBuffer[pos] := Byte(aTable.RecycleCount);
  Inc(pos);

  fLength := pos;
end;

function TCanonicalState.Hash: UInt64;
begin
  // FNV-1a 64-bit — fast, no allocation, good distribution
  const FNV_OFFSET: UInt64 = 14695981039346656037;
  const FNV_PRIME: UInt64 = 1099511628211;

  {$Q-}  // UInt64 multiplication intentionally wraps
  Result := FNV_OFFSET;
  for var i := 0 to fLength - 1 do
  begin
    Result := Result xor UInt64(fBuffer[i]);
    Result := Result * FNV_PRIME;
  end;
  {$Q+}
end;

end.
