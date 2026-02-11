unit u_Snapshots;

interface

uses System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Tables,
  u_SnapshotStorage;

type
  TSnapshot = class
  private
    fBuffer: PSnapshotBuffer;
    function GetAsText: string;
    procedure SetAsText(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Capture(aTable: TTable);
    procedure Restore(aTable: TTable);

    property Buffer: PSnapshotBuffer read fBuffer;
    property AsText: string read GetAsText write SetAsText;
  end;

  { TSnapshotBufferStream
    simple, uni-directional reading or writing to snapshot byte array }
  TSnapshotBufferStream = record
  private
    fBuffer: PSnapshotBuffer;
    fIndex: TSnapshotBufferIndex;
  public
    procedure Init(aSnapshot: TSnapshot);
    function Read: Byte;
    procedure Write(B: Byte);
  end;

implementation

procedure TSnapshotBufferStream.Init(aSnapshot: TSnapshot);
begin
  fBuffer := aSnapshot.fBuffer;
  fIndex := Low(TSnapshotBufferIndex);
end;

function TSnapshotBufferStream.Read: Byte;
begin
  Result := fBuffer[fIndex];
  if fIndex < High(TSnapshotBufferIndex) then
    Inc(fIndex);
end;

procedure TSnapshotBufferStream.Write(B: Byte);
begin
  fBuffer[fIndex] := B;
  if fIndex < High(TSnapshotBufferIndex) then
    Inc(fIndex);
end;

{ TSnapshot }

constructor TSnapshot.Create;
begin
  inherited Create;
  New(fBuffer);
end;

destructor TSnapshot.Destroy;
begin
  Dispose(fBuffer);
  inherited;
end;

procedure TSnapshot.Capture(aTable: TTable);
begin
  var stream: TSnapshotBufferStream;
  stream.Init(Self);

  // capture contents of each card stack
  for var stackId := Low(TStackId) to High(TStackId) do
  begin
    var stack := aTable.Stacks[stackId];
    var faceUpIndex := stack.Count - stack.FaceUpCount;

    // each stack begins with its count
    stream.Write(stack.Count);

    // then each card
    for var cardIndex := 0 to stack.Count - 1 do
    begin
      var cardByte: Byte := stack.Cards[cardIndex];

      // if we're at or beyond the face up cards, mark this
      if cardIndex >= faceUpIndex then
        cardByte := cardByte or $80;

      stream.Write(cardByte);
    end;
  end;
end;

procedure TSnapshot.Restore(aTable: TTable);
begin
  aTable.Clear;

  var stream: TSnapshotBufferStream;
  stream.Init(Self);

  for var stackId := Low(TStackId) to High(TStackId) do
  begin
    var stack := aTable.Stacks[stackId];

    var cardCount := stream.Read;
    var faceUpCount := 0;

    for var cardIndex := 0 to cardCount - 1 do
    begin
      var cardByte: Byte := stream.Read;
      if (cardByte and $80) <> 0 then
      begin
        Inc(faceUpCount);
        cardByte := cardByte and $7F;
      end;

      stack.Add(cardByte);
    end;
    stack.FaceUpCount := faceUpCount;

  end;
end;

function TSnapshot.GetAsText: string;
begin
  SetLength(Result, SNAPSHOT_BUFFER_SIZE * 2); // two characters per byte

  var outputIndex := 1;
  for var bufferIndex: TSnapshotBufferIndex := 0 to SNAPSHOT_BUFFER_SIZE - 1 do
  begin
    var dataByte: Byte := fBuffer[bufferIndex];
    var charPair := dataByte.ToHexString(2);
    Result[outputIndex] := charPair[1];
    Inc(outputIndex);
    Result[outputIndex] := charPair[2];
    Inc(outputIndex);
  end;
end;

procedure TSnapshot.SetAsText(const Value: string);
begin
  if Length(Value) <> SNAPSHOT_BUFFER_SIZE * 2 then
    Exit;

  var inputIndex := 1;
  for var bufferIndex: TSnapshotBufferIndex := 0 to SNAPSHOT_BUFFER_SIZE - 1 do
  begin
    var charPair := '$' + Copy(Value, inputIndex, 2);
    var dataByte: Byte;
    if Byte.TryParse(charPair, dataByte) then
      fBuffer[bufferIndex] := dataByte;
    Inc(inputIndex, 2);
  end;
end;

end.
