unit u_SaveFiles;

interface

type
  TSaveFile = class
  private
    fModified: Boolean;
    fFileName: string;
    procedure SetFileName(const Value: string);
    //
  public
    property Modified: Boolean read fModified write fModified;
    property FileName: string read fFileName write SetFileName;
  end;

implementation

{ TSaveFile }

procedure TSaveFile.SetFileName(const Value: string);
begin
  fFileName := Value;
end;

end.
