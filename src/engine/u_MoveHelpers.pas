unit u_MoveHelpers;

interface

uses System.Generics.Collections,
  u_Types, u_CardStacks, u_Tables;

type
  TMoveHelper = record helper for TMove
    function GetMoveType: TMoveType;
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

uses u_Utils, u_CardHelpers;

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
