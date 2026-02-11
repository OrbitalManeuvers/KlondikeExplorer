unit u_Moves.Render;

interface

uses System.JSON,

  u_Types,
  u_MoveLists,
  u_Moves.Analysis,
  u_Moves.Evaluators;

type
  TMoveListHelper = class helper for TMoveList
  private
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
  public
    property AsJSON: TJSONObject read GetJSON write SetJSON;
  end;

  TMoveHelper = record helper for TMove
    function AsJSON: TJSONObject;
    function Shortcode: string;
    function Description: string;
    procedure LoadFromShortCode(const S: string);
  end;

  TEvalHelper = record helper for TEvaluation
  private
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);

  public
    property AsJSON: TJSONObject read GetJSON write SetJSON;
    function AsString: string;
  end;

implementation

uses System.Classes, System.SysUtils, System.Generics.Collections,

  u_TableUtils,
  u_Snapshots;

const
  KEY_NAME = 'name';
  KEY_SEED = 'seed';
  KEY_MOVES = 'moves';

  KEY_DESCRIPTION = 'desc';
  KEY_CODE = 'code';

  _stack_names: array[TStackId] of string = (
    '',
    'Waste',
    'Tab 1',
    'Tab 2',
    'Tab 3',
    'Tab 4',
    'Tab 5',
    'Tab 6',
    'Tab 7',
    'Hearts',
    'Diamonds',
    'Clubs',
    'Spades'
  );


function TMoveHelper.AsJSON: TJSONObject;
begin
  Result := TJSONObject.Create;

end;

function TMoveHelper.Shortcode: string;
begin
  Result :=
    System.JSON.DecimalToHexMap[Ord(Source) + 1] +
    System.JSON.DecimalToHexMap[Ord(Target) + 1] +
    System.JSON.DecimalToHexMap[Count + 1];
end;

procedure TMoveHelper.LoadFromShortCode(const S: string);
begin
  Source := TStackId(StrToInt('$' + S[1]));
  Target := TStackId(StrToInt('$' + S[2]));
  Count  := StrToInt('$' + S[3]);
end;

function TMoveHelper.Description: string;
const
  fmt_move = '%d from %s to %s';
  fmt_move_nc = '%s to %s';
  fmt_waste = '%s to %s';
begin
  Result := '';

  if Source = siStock then // it's a draw
  begin
    Result := 'Draw';
    if Count <> 3 then
      Result := Result + ' ' + Count.ToString;
  end
  else
  begin
    var sourceCat := IdToCategory(Source);

    case sourceCat of
      scWaste:
        Result := Format(fmt_waste, [_stack_names[Source], _stack_names[Target]]);
      scFoundation, scTableau:
        begin
          if Count > 1 then
            Result := Format(fmt_move, [Count, _stack_names[Source], _stack_names[Target] ])
          else
            Result := Format(fmt_move_nc, [_stack_names[Source], _stack_names[Target] ]);
        end;
    end;
  end;
end;


{ TMoveListHelper }

function TMoveListHelper.GetJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair(KEY_NAME, Name);

  // write moves
  var a := TJSONArray.Create;
  for var I := 0 to Count - 1 do
  begin
    var o := TJSONObject.Create;
    o.AddPair(KEY_DESCRIPTION, Moves[i].Description);
    o.AddPair(KEY_CODE, Moves[I].Shortcode);
    a.Add(o);
  end;
  Result.AddPair(KEY_MOVES, a);
end;

procedure TMoveListHelper.SetJSON(const Value: TJSONObject);
begin

end;

{ TMoveEvalHelper }
procedure TEvalHelper.SetJSON(const Value: TJSONObject);
begin
  //
end;

function TEvalHelper.GetJSON: TJSONObject;
begin

  Result := TJSONObject.Create;
end;

function TEvalHelper.AsString: string;
begin
  Result := Move.Shortcode + ' [' + Score.ToString + '] ' + Move.Description;

//    Move: TMove;
//    Score: Integer;
//    Factors: TScoreFactors;



end;

end.
