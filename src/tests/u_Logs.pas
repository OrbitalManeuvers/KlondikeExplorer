unit u_Logs;

interface

uses System.Classes, System.Generics.Collections,
  u_LogTypes;

type
  TLog = class
  private
    fEntries: TList<TLogEntry>;
    fOnChange: TNotifyEvent;
    function GetCount: Integer;
    function GetEntry(Index: Integer): TLogEntry;
    procedure Change;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(aKind: TLogEntryKind; const aMsg: string);

    property Entries[Index: Integer]: TLogEntry read GetEntry;
    property Count: Integer read GetCount;

    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

implementation

{ TLog }

constructor TLog.Create;
begin
  inherited Create;
  fEntries := TList<TLogEntry>.Create;
end;

destructor TLog.Destroy;
begin
  fEntries.Free;
  inherited;
end;

procedure TLog.Add(aKind: TLogEntryKind; const aMsg: string);
begin
  var entry := Default(TLogEntry);
  entry.Kind := aKind;
  entry.Msg := aMsg;
  fEntries.Add(entry);
  Change;
end;

procedure TLog.Change;
begin
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

function TLog.GetCount: Integer;
begin
  Result := fEntries.Count;
end;

function TLog.GetEntry(Index: Integer): TLogEntry;
begin
  Result := fEntries[Index];
end;

end.
