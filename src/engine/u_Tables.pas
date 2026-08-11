unit u_Tables;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_CardStacks;

  { The table's own methods should not call Begin/EndUpdate, it should just
    perform its operations and leave state to owning objects }

type
  TTable = class
  private
    fChanged: Boolean;
    fUpdateCount: Integer;

    fStacks: array[TStackId] of TCardStack;
    fOnChange: TNotifyEvent;
    fRecycleCount: Integer;

    function GetTableau(TableauIndex: TTableauIndex): TCardStack;
    function GetFoundation(ASuit: TCardSuit): TCardStack;
    function GetStack(Id: TStackId): TCardStack;

    procedure Change;
    procedure HandleStackChange(Sender: TObject);
    procedure SetRecycleCount(const Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    procedure BeginUpdate;
    procedure EndUpdate;

    // remove all cards from table
    procedure Clear;

    // stacks by name
    property Stock: TCardStack read fStacks[siStock];
    property Waste: TCardStack read fStacks[siWaste];
    property Foundation[ASuit: TCardSuit]: TCardStack read GetFoundation;
    property Tableau[TableauIndex: TTableauIndex]: TCardStack read GetTableau;

    // stacks as an array
    property Stacks[Id: TStackId]: TCardStack read GetStack;

    property RecycleCount: Integer read fRecycleCount write SetRecycleCount;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  end;

implementation


{ TTable }

constructor TTable.Create();
begin
  inherited Create;
  for var id := Low(TStackId) to High(TStackId) do
  begin
    fStacks[id] := TCardStack.Create;
    fStacks[id].OnChange := Self.HandleStackChange;
  end;
end;

destructor TTable.Destroy;
begin
  for var id := Low(TStackId) to High(TStackId) do
    fStacks[id].Free;
  inherited;
end;

procedure TTable.BeginUpdate;
begin
  if fUpdateCount = 0 then
  begin
    for var id := Low(TStackId) to High(TStackId) do
      fStacks[id].BeginUpdate;
  end;

  Inc(fUpdateCount);
end;

procedure TTable.EndUpdate;
begin
  if fUpdateCount > 0 then
    Dec(fUpdateCount);

  if fUpdateCount = 0 then
  begin
    for var id := Low(TStackId) to High(TStackId) do
    begin
      fStacks[id].Change;
      fStacks[id].EndUpdate;
    end;
    Change;
  end;
end;

function TTable.GetFoundation(ASuit: TCardSuit): TCardStack;
var
  idx: Integer;
begin
  idx := Ord(siFoundation1) + Ord(ASuit);
  Result := fStacks[ TStackId(idx) ];
end;

function TTable.GetStack(Id: TStackId): TCardStack;
begin
  Result := fStacks[Id];
end;

function TTable.GetTableau(TableauIndex: TTableauIndex): TCardStack;
var
  idx: Integer;
begin
  idx := Ord(siTableau1) + (Ord(TableauIndex) - 1);
  Result := fStacks[ TStackId(idx) ];
end;

procedure TTable.HandleStackChange(Sender: TObject);
begin
  Change;
end;

procedure TTable.SetRecycleCount(const Value: Integer);
begin
  fRecycleCount := Value;
end;

procedure TTable.Change;
begin
  fChanged := True;
  if fUpdateCount = 0 then
  begin
    if Assigned(fOnChange) then
      fOnChange(Self);
    fChanged := False;
  end;
end;

procedure TTable.Clear;
begin
  for var id := Low(TStackId) to High(TStackId) do
    fStacks[id].Clear;
  Change;
end;

end.
