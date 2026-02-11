unit u_EvalLists;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections, System.Generics.Defaults,

  u_Types,
  u_Moves.Analysis;


type
  TEvalList = class
  private
    fName: string;
    fItems: TList<TEvaluation>;

    fUpdateCount: Integer;
    fChanged: Boolean;
    fOnChange: TNotifyEvent;

    function GeTEvaluation(I: Integer): TEvaluation;
    function GetCount: Integer;
    procedure Change;
    procedure SetCapacity(const Value: NativeInt);
    procedure SetEvaluation(I: Integer; const Value: TEvaluation);
    function GetValidMoveCount: Integer;

    type
      TEnumerator = class
      private
        fList: TEvalList;
        fIndex: Integer;
      public
        constructor Create(aList: TEvalList);
        function GetCurrent: TEvaluation;
        function MoveNext: Boolean;
        property Current: TEvaluation read GetCurrent;
      end;

  public
    constructor Create(aName: string = '');
    destructor Destroy; override;
    procedure Clear;
    procedure Sort;

    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Add(aMove: TEvaluation);

    property Name: string read fName write fName;
    property Evals[I: Integer]: TEvaluation read GetEvaluation write SetEvaluation; default;
    property Count: Integer read GetCount;

    property Capacity: NativeInt write SetCapacity;
    property ValidMoveCount: Integer read GetValidMoveCount;


    // to-do
    property OnChange: TNotifyEvent read fOnChange write fOnChange;


    function GetEnumerator: TEnumerator;
  end;

implementation

{ TEvalList }

constructor TEvalList.Create(aName: string = '');
begin
  inherited Create;
  fItems := TList<TEvaluation>.Create;
  fName := aName;
end;

destructor TEvalList.Destroy;
begin
  Clear;
  fItems.Free;

  inherited;
end;

procedure TEvalList.BeginUpdate;
begin
  Inc(fUpdateCount);
end;

procedure TEvalList.EndUpdate;
begin
  if fUpdateCount > 0 then
    Dec(fUpdateCount);

  if (fUpdateCount = 0) and fChanged then
    Change;
end;

procedure TEvalList.Change;
begin
  fChanged := True;
  if fUpdateCount = 0 then
  begin
    fChanged := False;
    if Assigned(fOnChange) then
      fOnChange(Self);
  end;
end;

procedure TEvalList.Clear;
begin
  fItems.Clear;
end;

function TEvalList.GetCount: Integer;
begin
  Result := fItems.Count;
end;

function TEvalList.GeTEvaluation(I: Integer): TEvaluation;
begin
  Result := fItems[I];
end;

function TEvalList.GetValidMoveCount: Integer;
begin
  Result := 0;
  for var item in fItems do
    if item.Score >= 0 then
      Inc(Result);
end;

procedure TEvalList.SetCapacity(const Value: NativeInt);
begin
  fItems.Capacity := Value;
end;

procedure TEvalList.SetEvaluation(I: Integer; const Value: TEvaluation);
begin
  fItems[I] := Value;
end;

procedure TEvalList.Sort;
begin
  var comparer: IComparer<TEvaluation> := TEvalComparer.Create;
  fItems.Sort(comparer);
end;

procedure TEvalList.Add(aMove: TEvaluation);
begin
  fItems.Add(aMove);
  Change;
end;

{ TEvalList.TEnumerator }

constructor TEvalList.TEnumerator.Create(aList: TEvalList);
begin
  inherited Create;
  fList := aList;
  fIndex := -1;
end;

function TEvalList.TEnumerator.GetCurrent: TEvaluation;
begin
  Result := fList[fIndex];
end;

function TEvalList.TEnumerator.MoveNext: Boolean;
begin
  Result := fIndex < fList.Count - 1;
  if Result then
    Inc(fIndex);
end;

function TEvalList.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(Self);
end;

end.
