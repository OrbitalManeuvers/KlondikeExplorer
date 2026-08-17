unit u_LogTypes;

interface

type
  TLogEntryKind = (ekTestBegin, ekTestDetail, ekTestError, ekTestSummary);

  TLogEntry = record
    Kind: TLogEntryKind;
    Msg: string;
  end;

implementation

end.
