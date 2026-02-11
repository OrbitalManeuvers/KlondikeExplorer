unit u_SnapshotTokens;

interface

type
  TSnapshotToken = record
    _block: Pointer;
    _index: Integer;
    class operator Equal(const a, b: TSnapshotToken): Boolean;
    class operator NotEqual(const a, b: TSnapshotToken): Boolean;
  end;

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
