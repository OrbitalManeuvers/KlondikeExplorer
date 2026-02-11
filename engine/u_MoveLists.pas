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
    procedure Add(aMove: TMove);

    property Name: string read fName write fName;
    property Moves[I: Integer]: TMove read GetMove; default;
    property Count: Integer read GetCount;


    // to-do
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
end;

function TMoveList.GetCount: Integer;
begin
  Result := fItems.Count;
end;

function TMoveList.GetMove(I: Integer): TMove;
begin
  Result := fItems[I];
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
