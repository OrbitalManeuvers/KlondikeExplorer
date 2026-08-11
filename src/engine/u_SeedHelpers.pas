unit u_SeedHelpers;

interface

uses u_Types;

type
  TSeedHelper = record helper for TSeed
    function ToString: string;
  end;

implementation

uses System.SysUtils;

{ TSeedHelper }
function TSeedHelper.ToString: string;
begin
  if Value = 0 then
    Exit('');
  Result := Value.ToString;
  if not Name.IsEmpty then
    Result := Name + ' [' + Result + ']';
end;

end.
