unit u_Tables.Render;

interface

uses System.Generics.Collections, System.JSON,

  u_CardStacks,
  u_CardStacks.Render,
  u_Tables,
  u_Types;

type
  TTableHelper = class helper for TTable
    function GetJSON: TJSONObject;
  private
    function GetCompact: string;
  public
    property AsJSON: TJSONObject read GetJSON;
    property AsCompact: string read GetCompact;
  end;

function StackTwoCode(Id: TStackId): string;
function ParseStackTwoCode(aCode: string; out Id: TStackId): Boolean;

implementation

uses System.SysUtils;

const
  KEY_FOUNDATION: array[TCardSuit] of string = ('hearts', 'diamonds', 'clubs', 'spades');
  KEY_STOCK = 'stock';
  KEY_WASTE = 'waste';
  KEY_TABLEAU = 'tableau%d';

const
  stack_two_codes: array[TStackId] of string = (
    'ST',
    'WA',
    'T1','T2','T3','T4','T5','T6','T7',
    'F1','F2','F3','F4'
    );

function StackTwoCode(Id: TStackId): string;
begin
  Result := stack_two_codes[Id];
end;

function ParseStackTwoCode(aCode: string; out Id: TStackId): Boolean;
begin
  for var st := Low(TStackId) to High(TStackId) do
  begin
    if SameText(stack_two_codes[st], aCode) then
    begin
      Id := st;
      Exit(True);
    end;
  end;

  Result := False;
end;

{ TTableHelper }

function TTableHelper.GetCompact: string;
var
  B: TStringBuilder;
begin
  B := TStringBuilder.Create;
  try
    for var id := Low(TStackId) to High(TStackId) do
    begin
      B.Append(stack_two_codes[id] + ':');
      B.Append(Stacks[id].AsText);
      B.Append('|');
    end;

    Result := B.ToString;

  finally
    B.Free;
  end;


//  Result := '';
//  for var id := Low(TStackId) to High(TStackId) do
//  begin
//    Result := Result + stack_two_codes[id] + Stacks[id].AsText + '|';
//  end;
  SetLength(Result, Length(Result) - 1);
end;

function TTableHelper.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_STOCK, Stock.AsJSON);
  Result.AddPair(KEY_WASTE, Waste.AsJSON);

  for var suit := Low(TCardSuit) to High(TCardSuit) do
    Result.AddPair(KEY_FOUNDATION[suit], Foundation[suit].AsJSON);

  for var ti := Low(TTableauIndex) to High(TTableauIndex) do
    Result.AddPair(Format(KEY_TABLEAU, [ti]), Tableau[ti].AsJSON);
end;

end.
