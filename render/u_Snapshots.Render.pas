unit u_Snapshots.Render;

interface

uses System.JSON,
  u_Snapshots;

type
  TSnapshotHelper = class helper for TSnapshot
  private
    function GetAsString: string;
    procedure SetAsString(const Value: string);
  public
    property AsString: string read GetAsString write SetAsString;
  end;

implementation

uses System.Types, System.SysUtils, System.StrUtils,

  u_Types;

//  u_Tables.Render,
//  u_CardStacks;


function HexToFaceUp(const aStr: string): Integer;
begin
  Result.TryParse('$' + aStr, Result);
end;

//function BufferAsText(Buffer: PSnapshotBuffer): string;
//begin
//  Result := '';
//  if Assigned(Buffer) then
//  begin
//    SetLength(Result, SNAPSHOT_BUFFER_SIZE * 2); // two characters per byte
//
//    var outputIndex := 1;
//    for var bufferIndex: TSnapshotBufferIndex := 0 to SNAPSHOT_BUFFER_SIZE - 1 do
//    begin
//      var dataByte: Byte := fBuffer[bufferIndex];
//      var charPair := dataByte.ToHexString(2);
//      Result[outputIndex] := charPair[1];
//      Inc(outputIndex);
//      Result[outputIndex] := charPair[2];
//      Inc(outputIndex);
//    end;
//  end;
//end;


{ TSnapshotHelper }
function TSnapshotHelper.GetAsString: string;
begin
  Result := '';



//  for var id := Low(TStackId) to High(TStackId) do
//  begin
//    Result := Result + StackTwoCode(id) + Payload[id].AsString + '|';
//  end;
//  SetLength(Result, Result.Length - 1);
end;

// e.g.
// ST00161F04200619301A15210D2A07322702251123292C240A05|WA00|T10128|T2012201|T3012E172D|T401181B2B10|T5010B31001312|T6011E0C0E261D03|T7010F081C14092F33|F100|F200|F300|F400

procedure TSnapshotHelper.SetAsString(const Value: string);
//var
//  parts: TStringDynArray;
begin
//  // split into stacks
//  parts := SplitString(Value, '|');
//
//  // validate number of stacks
//  if Length(parts) = Ord(High(TStackId)) + 1 then
//  begin
//
//    for var i := 0 to Length(parts) - 1 do
//    begin
//      var line := parts[i];
//      var id: TStackId;
//      var stackCode := LeftStr(line, 2);
//
//      if ParseStackTwoCode(stackCode, id) then
//      begin
//        // the rest of the part is the stack save
//        Self.Payload[id].AsString := Copy(line, 3, Length(line));
//
//      end;
//    end;
//  end;
//
end;

end.
