unit u_SnapshotTypes;

interface

type
  TSnapshotToken = record
    _block: Pointer;
    _index: Integer;
    class operator Equal(const a, b: TSnapshotToken): Boolean;
    class operator NotEqual(const a, b: TSnapshotToken): Boolean;
  end;

const
  SNAPSHOT_BUFFER_SIZE = (13 * 1) + 52; // 65 = 1-byte overhead for 13 stacks, plus 52 cards

type
  TSnapshotBuffer = array[0..SNAPSHOT_BUFFER_SIZE - 1] of Byte;
  PSnapshotBuffer = ^TSnapshotBuffer;
  TSnapshotBufferIndex = 0 .. SNAPSHOT_BUFFER_SIZE - 1;


const
  NO_SNAPSHOT: TSnapshotToken = (_block: nil; _index: -1);

implementation

{ TSnapshotToken }

class operator TSnapshotToken.Equal(const a, b: TSnapshotToken): Boolean;
begin
  Result := (a._block = b._block) and (a._index = b._index);
end;

class operator TSnapshotToken.NotEqual(const a, b: TSnapshotToken): Boolean;
begin
  Result := not (a = b);
end;

end.
