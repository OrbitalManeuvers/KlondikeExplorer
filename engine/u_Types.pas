unit u_Types;

interface

type
  // Basic card types
  // =========================================

  TCardSuit = (csHearts, csDiamonds, csClubs, csSpades);
  TCardColor = (ccRed, ccBlack);
  TCardValue = (cvAce, cvTwo, cvThree, cvFour, cvFive, cvSix, cvSeven,
    cvEight, cvNine, cvTen, cvJack, cvQueen, cvKing);

  TCardOrdinal = 0..51;

  TCard = TCardOrdinal;

  TCardDescriptor = record
    Value: TCardValue;
    Color: TCardColor;
  end;

  // Basic table types
  // =========================================

  TTableauIndex = 1..7;

  // flat access to all stacks
  TStackId = (
    siStock,
    siWaste,
    siTableau1,siTableau2,siTableau3,siTableau4,siTableau5,siTableau6,siTableau7,
    siFoundation1,siFoundation2,siFoundation3,siFoundation4
  );
  TStackIds = set of TStackId;

  TStackCategory = (
    scStock,
    scWaste,
    scTableau,
    scFoundation);
  TStackCategories = set of TStackCategory;


  // Basic move types
  // ==========================================
  TMoveType = (
    mtDraw,
    mtWasteToTableau,
    mtWasteToFoundation,
    mtTableauToTableau,
    mtTableauToFoundation,
    mtFoundationToTableau
  );

  TMove = record
    Source: TStackId;
    Target: TStackId;
    Count: Integer;
    function GetMoveType: TMoveType;
  end;

  TSeed = record
    Name: string;
    Value: Integer;
    function ToString: string;
  end;

  TLogEvent = procedure (Sender: TObject; const LogMsg: string) of object;

const
  SNAPSHOT_BUFFER_SIZE = (13 * 1) + 52; // 65 = 1-byte overhead for 13 stacks, plus 52 cards

type
//  TSnapshotToken = Cardinal;
  TSnapshotBuffer = array[0..SNAPSHOT_BUFFER_SIZE - 1] of Byte;
  PSnapshotBuffer = ^TSnapshotBuffer;
  TSnapshotBufferIndex = 0 .. SNAPSHOT_BUFFER_SIZE - 1;


const
  ALL_TABLEAUS: TStackIds = [siTableau1,siTableau2,siTableau3,siTableau4,siTableau5,siTableau6,siTableau7];

{ type conversions/coercions/creations }
function IdFromSuit(aSuit: TCardSuit): TStackId;
function IdToCategory(Id: TStackId): TStackCategory;
function NewMove(aMove: TMove): TMove;

function NewCard(aSuit: TCardSuit; aValue: TCardValue): TCard; overload;
//function NewCard(aOrdinal: TCardOrdinal): TCard; overload;
//function NewCard(aCard: TCard): TCard; overload;

//function CardOrdinal(aSuit: TCardSuit; aValue: TCardValue): TCardOrdinal;
function OppositeColor(aColor: TCardColor): TCardColor;

function NewSeed(const Name: string; Value: Integer): TSeed;


implementation

uses System.SysUtils;

function IdToCategory(Id: TStackId): TStackCategory;
begin
  case Id of
    siWaste: Result := scWaste;
    siFoundation1..siFoundation4: Result := scFoundation;
    siTableau1..siTableau7: Result := scTableau;
    else
      Result := scStock;
  end;
end;

function IdFromSuit(aSuit: TCardSuit): TStackId;
begin
  Result := TStackId( Ord(siFoundation1) + Ord(aSuit) );
end;

function NewMove(aMove: TMove): TMove;
begin
  Result.Source := aMove.Source;
  Result.Target := aMove.Target;
  Result.Count := aMove.Count;
end;

function NewCard(aSuit: TCardSuit; aValue: TCardValue): TCard;
begin
  Result := (Ord(aSuit) * (Ord(High(TCardValue)) + 1)) + Ord(aValue);
end;

function OppositeColor(aColor: TCardColor): TCardColor;
begin
  if aColor = ccRed then Result := ccBlack
  else Result := ccRed;
end;

function NewSeed(const Name: string; Value: Integer): TSeed;
begin
  Result.Name := Name;
  Result.Value := Value;
end;

{ TMove }
function TMove.GetMoveType: TMoveType; // caller should cache
var
  targetCat: TStackCategory;
begin
  targetCat := IdToCategory(Self.Target);
  Result := mtDraw;

  case IdToCategory(Self.Source) of
    scStock:
      begin
        Result := mtDraw;
      end;

    scWaste:
      begin
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

{ TSeed }
function TSeed.ToString: string;
begin
  if Value = 0 then
    Exit('');
  Result := Value.ToString;
  if not Name.IsEmpty then
    Result := Name + ' [' + Result + ']';
end;

end.
