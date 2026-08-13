unit u_MoveHelpers;

interface

uses System.Generics.Collections,
  u_Types, u_CardStacks, u_Tables;

type
  TMoveHelper = record helper for TMove
    function GetMoveType: TMoveType;
    function AsText: string;
  end;

  // info about one "side" of a move
  TMoveComponent = record
    Id: TStackId;
    Category: TStackCategory;
    Stack: TCardStack;
  end;

  // summary info
  TMoveInfo = class
  private
    fMoveCards: TList<TCard>;
  public
    Table: TTable;
    MoveCount: Integer;
    MoveType: TMoveType;
    Source: TMoveComponent;
    Target: TMoveComponent;
    NextFoundation: array[TCardSuit] of TCardValue;

    constructor Create;
    destructor Destroy; override;

    property MoveCards: TList<TCard> read fMoveCards;
    procedure Load(const aMove: TMove; aTable: TTable);
  end;



implementation

uses System.SysUtils,
  u_Utils, u_CardHelpers;

const
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


{ TMoveHelper }
function TMoveHelper.GetMoveType: TMoveType; // caller should cache
var
  targetCat: TStackCategory;
begin
  targetCat := IdToCategory(Self.Target);
  Result := mtDraw;

  case IdToCategory(Self.Source) of
    scStock:
      begin
        if Self.Target = siWaste then
          Result := mtDraw;
      end;

    scWaste:
      begin
        if Self.Target = siStock then
          Result := mtRecycle
        else
          case targetCat of
            scTableau: Result := mtWasteToTableau;
            scFoundation: Result := mtWasteToFoundation;
          end;
      end;

    scTableau:
      begin
        case targetCat of
          scTableau: Result := mtTableauToTableau;
          scFoundation: Result := mtTableauToFoundation;
        end;
      end;

    scFoundation:
      begin
        case targetCat of
          scTableau: Result := mtFoundationToTableau;
        end;
      end;
  end;
end;

function TMoveHelper.AsText: string;
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


{ TMoveInfo }

constructor TMoveInfo.Create;
begin
  inherited Create;
  fMoveCards := TList<TCard>.Create;
end;

destructor TMoveInfo.Destroy;
begin
  fMoveCards.Free;
  inherited;
end;

procedure TMoveInfo.Load(const aMove: TMove; aTable: TTable);
begin
  Self.Table := aTable;
  Self.MoveCount := aMove.Count;
  Self.Source.Id := aMove.Source;
  Self.Source.Category := IdToCategory(Self.Source.Id);
  Self.Source.Stack := aTable.Stacks[aMove.Source];

  Self.Target.Id := aMove.Target;
  Self.Target.Category := IdToCategory(Self.Target.Id);
  Self.Target.Stack := aTable.Stacks[Self.Target.Id];
  Self.MoveType := aMove.GetMoveType;

  fMoveCards.Count := 0;
  Self.Source.Stack.GetLastCards(fMoveCards, Self.MoveCount, False);

  // a quick setup of which foundation cards are required next
  for var f := Low(TCardSuit) to High(TCardSuit) do
  begin
    // setting a King to an Ace just as an unreachable value
    if Table.Foundation[f].IsEmpty or (Table.Foundation[f].Last.Value = cvKing) then
      NextFoundation[f] := cvAce
    else
      NextFoundation[f] := Succ(Table.Foundation[f].Last.Value);
  end;

end;


end.
