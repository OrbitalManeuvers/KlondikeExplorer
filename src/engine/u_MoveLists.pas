unit u_MoveLists;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types;


type
  TMoveList = class
  private
    fName: string;
    fItems: TList<TMove>;

    fUpdateCount: Integer;
    fChanged: Boolean;
    fOnChange: TNotifyEvent;

    function GetMove(I: Integer): TMove;
    function GetCount: Integer;
    procedure Change;

    type
      TEnumerator = class
      private
        fList: TMoveList;
        fIndex: Integer;
      public
        constructor Create(aList: TMoveList);
        function GetCurrent: TMove;
        function MoveNext: Boolean;
        property Current: TMove read GetCurrent;
      end;

  public
    constructor Create(aName: string = '');
    destructor Destroy; override;
    procedure Clear;

    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Add(aMove: TMove); overload;
    procedure Add(aSource, aTarget: TStackId; aCount: Integer = 1); overload;
    function IndexOfMove(aMove: TMove): Integer;

    property Name: string read fName write fName;
    property Moves[I: Integer]: TMove read GetMove; default;
    property Count: Integer read GetCount;

    property OnChange: TNotifyEvent read fOnChange write fOnChange;

    function GetEnumerator: TEnumerator;
  end;

implementation

{ TMoveList }

constructor TMoveList.Create(aName: string = '');
begin
  inherited Create;
  fItems := TList<TMove>.Create;
  fName := aName;
end;

destructor TMoveList.Destroy;
begin
  Clear;
  fItems.Free;
  inherited;
end;

procedure TMoveList.Add(aSource, aTarget: TStackId; aCount: Integer);
begin
  var m: TMove;
  m.Source := aSource;
  m.Target := aTarget;
  m.Count := aCount;
  Add(m);
end;

procedure TMoveList.BeginUpdate;
begin
  Inc(fUpdateCount);
end;

procedure TMoveList.EndUpdate;
begin
  if fUpdateCount > 0 then
    Dec(fUpdateCount);

  if (fUpdateCount = 0) and fChanged then
    Change;
end;

procedure TMoveList.Change;
begin
  fChanged := True;
  if fUpdateCount = 0 then
  begin
    fChanged := False;
    if Assigned(fOnChange) then
      fOnChange(Self);
  end;
end;

procedure TMoveList.Clear;
begin
  fItems.Clear;
  Change;
end;

function TMoveList.GetCount: Integer;
begin
  Result := fItems.Count;
end;

function TMoveList.GetMove(I: Integer): TMove;
begin
  Result := fItems[I];
end;

function TMoveList.IndexOfMove(aMove: TMove): Integer;

  function SameMove(aLeft, aRight: TMove): Boolean;
  begin
    Result := (aLeft.Source = aRight.Source) and (aLeft.Target = aRight.Target) and (aLeft.Count = aRight.Count);
  end;

begin
  Result := -1;

  for var i := 0 to fItems.Count - 1 do
  begin
    if SameMove(fItems[i], aMove) then
      Exit(i);

  end;

end;

procedure TMoveList.Add(aMove: TMove);
begin
  fItems.Add(aMove);
  Change;
end;

{ TMoveList.TEnumerator }

constructor TMoveList.TEnumerator.Create(aList: TMoveList);
begin
  inherited Create;
  fList := aList;
  fIndex := -1;
end;

function TMoveList.TEnumerator.GetCurrent: TMove;
begin
  Result := fList[fIndex];
end;

function TMoveList.TEnumerator.MoveNext: Boolean;
begin
  Result := fIndex < fList.Count - 1;
  if Result then
    Inc(fIndex);
end;

function TMoveList.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

end.
