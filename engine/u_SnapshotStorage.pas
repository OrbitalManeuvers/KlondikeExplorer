unit u_SnapshotStorage;

(*
This class provides an optimized memory allocation scheme tuned for snapshots.
Usage:
  myToken := Storage.AllocateMem;
  mySnapshotBuffer: PSnapshotBuffer := Storage.BufferOf(myToken);
  Storage.FreeMem(myToken);
*)

interface

uses System.SysUtils, System.Generics.Collections,

  u_Types, u_SnapshotTokens;

const
  BLOCK_SIZE = 1024 * 2;
  SNAPSHOTS_PER_BLOCK = BLOCK_SIZE div SNAPSHOT_BUFFER_SIZE;

type
  TMemoryStats = record
    History: record
      Allocations: Cardinal;    // how many allocations have been done
      Releases: Cardinal;       // how many allocations have been released
      BlocksCreated: Cardinal;  // times a new block was created
      BlocksCulled: Cardinal;   // an empty block is freed
      RecycledUsed: Cardinal;   // pulled a block out of recycle list
      PartialUsed: Cardinal;    // pulled a block out of partial list
    end;
    Lists: record
      TotalBlocks: Cardinal;    // how many blocks exist
      RecycleQueue: Cardinal;   // count in recycle list
      PartialQueue: Cardinal;   // count in partial list
    end;
    function AsText: string;
  end;

  TBlock = class
  private
    fBuffer: Pointer;
    fFreeCount: Integer;
    fFreeList: array[0 .. SNAPSHOTS_PER_BLOCK] of Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure ReInit;

    function AllocateUnit: Integer;
    procedure ReleaseUnit(aUnitIndex: Integer);
    function GetBuffer(aUnitIndex: Integer): PSnapshotBuffer;
    function IsFull: Boolean;
    function IsEmpty: Boolean;
  end;

  TSnapshotStorage = class
  private
    fStats: TMemoryStats;

    fBlocks: TObjectList<TBlock>;     // owns blocks
    fRecycledBlocks: TStack<TBlock>;  // recycled means completely empty, so could have been deleted
    fPartialBlocks: TStack<TBlock>;   // blocks with at least 1 opening

    fActiveBlock: TBlock;
    procedure CreateNewBlock;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function AllocateMem: TSnapshotToken;
    procedure ReleaseMem(aToken: TSnapshotToken);
    function BufferOf(aToken: TSnapshotToken): PSnapshotBuffer;
    property Stats: TMemoryStats read fStats;
  end;

implementation

const
  MAX_RECYCLE_BLOCKS = 3; // needs to be balanced against BLOCK_SIZE

{ TMemoryStats }
function TMemoryStats.AsText: string;
begin
  var fmt := 'H:[A:%d R:%d BC:%d BX:%d RU:%d PU:%d] L:[TB:%d RQ:%d PQ:%d]';
  Result := Format(fmt, [
    History.Allocations,
    History.Releases,
    History.BlocksCreated,
    History.BlocksCulled,
    History.RecycledUsed,
    History.PartialUsed,
    Lists.TotalBlocks,
    Lists.RecycleQueue,
    Lists.PartialQueue
  ]);
end;

{ TBlock }

constructor TBlock.Create;
begin
  inherited Create;
  fBuffer := AllocMem(BLOCK_SIZE);
  ReInit;
end;

procedure TBlock.ReInit;
begin
  for var i := Low(fFreeList) to High(fFreeList) do
    fFreeList[i] := i;
  fFreeCount := SNAPSHOTS_PER_BLOCK;
end;

destructor TBlock.Destroy;
begin
  FreeMem(fBuffer, BLOCK_SIZE);
  inherited;
end;

function TBlock.AllocateUnit: Integer;
begin
  Dec(fFreeCount);
  Result := fFreeList[fFreeCount];
end;

procedure TBlock.ReleaseUnit(aUnitIndex: Integer);
begin
  Inc(fFreeCount);
  fFreeList[fFreeCount] := aUnitIndex;
end;

function TBlock.GetBuffer(aUnitIndex: Integer): PSnapshotBuffer;
begin
  Result := PSnapshotBuffer(PByte(fBuffer) + (aUnitIndex * SNAPSHOT_BUFFER_SIZE));
end;

function TBlock.IsFull: Boolean;
begin
  Result := fFreeCount = 0;
end;

function TBlock.IsEmpty: Boolean;
begin
  Result := fFreeCount = SNAPSHOTS_PER_BLOCK;
end;

{ TSnapshotStorage }
constructor TSnapshotStorage.Create;
begin
  inherited Create;
  fBlocks := TObjectList<TBlock>.Create(True);
  fRecycledBlocks := TStack<TBlock>.Create;
  fPartialBlocks := TStack<TBlock>.Create;

  Clear;
end;

destructor TSnapshotStorage.Destroy;
begin
  fPartialBlocks.Free;
  fRecycledBlocks.Free;
  fBlocks.Free;
  inherited;
end;

procedure TSnapshotStorage.Clear;
begin
  fRecycledBlocks.Clear;
  fPartialBlocks.Clear;
  fBlocks.Clear;
  FillChar(fStats, SizeOf(fStats), 0);

  // init the first block
  CreateNewBlock;
end;

procedure TSnapshotStorage.CreateNewBlock;
begin
  fActiveBlock := TBlock.Create;
  fBlocks.Add(fActiveBlock);

  fStats.Lists.TotalBlocks := fBlocks.Count;
  Inc(fStats.History.BlocksCreated);
end;

function TSnapshotStorage.AllocateMem: TSnapshotToken;
begin
  // make sure the active block is ready
  if (fActiveBlock = nil) or fActiveBlock.IsFull then
  begin
    // check partial, then recycled, before creating a new block
    if fPartialBlocks.Count > 0 then
    begin
      fActiveBlock := fPartialBlocks.Pop;

      Inc(fStats.History.PartialUsed); // the number of times we've reused a partial block
      fStats.Lists.PartialQueue := fPartialBlocks.Count;
    end
    else if fRecycledBlocks.Count > 0 then
    begin
      fActiveBlock := fRecycledBlocks.Pop;
      fActiveBlock.ReInit;

      Inc(fStats.History.RecycledUsed); // number of times we've reused a recycled block
      fStats.Lists.RecycleQueue := fRecycledBlocks.Count;
    end
    else
    begin
      CreateNewBlock; // stats updated in here
    end;
  end;

  Result._block := fActiveBlock;
  Result._index := fActiveBlock.AllocateUnit;

  Inc(fStats.History.Allocations);
end;

procedure TSnapshotStorage.ReleaseMem(aToken: TSnapshotToken);
begin
  var block := TBlock(aToken._block);
  var wasFull := block.IsFull;

  block.ReleaseUnit(aToken._index);

  if block.IsEmpty then
  begin
    if block <> fActiveBlock then
    begin
      if fRecycledBlocks.Count < MAX_RECYCLE_BLOCKS then
      begin
        fRecycledBlocks.Push(block);
        fStats.Lists.RecycleQueue := fRecycledBlocks.Count;
      end
      else
      begin
        fBlocks.Remove(block);
        Inc(fStats.History.BlocksCulled);
        fStats.Lists.TotalBlocks := fBlocks.Count;
      end;
    end;
  end
  else if wasFull and (block <> fActiveBlock) then
  begin
    fPartialBlocks.Push(block);
    fStats.Lists.PartialQueue := fPartialBlocks.Count;
  end;

  Inc(fStats.History.Releases);
end;

function TSnapshotStorage.BufferOf(aToken: TSnapshotToken): PSnapshotBuffer;
begin
  Result := TBlock(aToken._block).GetBuffer(aToken._index);
end;

end.
