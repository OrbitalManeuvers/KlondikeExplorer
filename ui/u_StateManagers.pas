unit u_StateManagers;

interface

uses System.Classes, System.SysUtils, System.Generics.Collections, System.Generics.Defaults,

  u_Types,
  u_Snapshots,
  u_SnapshotTokens,
  u_SnapshotServices.Intf,
  u_MoveLists,
  u_EvalLists,
  u_Moves.Generators,
  u_Moves.Validators,
  u_Moves.Evaluators,
  u_Moves.Analysis,
  u_Moves.Executors,
  u_Moves.Scorers,
  u_Tables;

type
  TStateNode = class
  private
    fOrigin: TStateNode;
    fChildNodes: TList<TStateNode>;
    fName: string;
    fOriginMoveIndex: Integer;
    function GetChild(aIndex: Integer): TStateNode;
    function GetChildCount: Integer;
    procedure AddChild(aNode: TStateNode);

  public
    // to-do: make properties
    Token: TSnapshotToken;
    HValue: Double;
    Evaluations: TEvalList;

    constructor Create(aOrigin: TStateNode; aOriginMoveIndex: Integer; const aName: string);
    destructor Destroy; override;

    property Origin: TStateNode read fOrigin;
    property OriginMoveIndex: Integer read fOriginMoveIndex;
    property Name: string read fName;

    function HasChild(aMoveIndex: Integer): Boolean; // do we already have this state?
    property ChildCount: Integer read GetChildCount;
    property ChildNodes[aIndex: Integer]: TStateNode read GetChild;
  end;

  TStateChangeEvent = procedure (Sender: TObject; ParentNode, ChildNode: TStateNode) of object;

  TStateManager = class
  private
    fLocalSnapshot: TSnapshot;
    fLocalTable: TTable;

    fRootNode: TStateNode;
    fNodes: TObjectList<TStateNode>;

    fSnapshotServices: ISnapshotServices;
    fOnStateChange: TStateChangeEvent;
    procedure PopulateNode(aNode: TStateNode);
    function GetStateCount: Cardinal;
  public
    constructor Create(const aSnapshotServices: ISnapshotServices);
    destructor Destroy; override;

    property RootNode: TStateNode read fRootNode;

    procedure Clear;
    procedure CreateInitialState(aTable: TTable);
    procedure CreateNewState(aOrigin: TStateNode; aMoveIndex: Integer; const aCaption: string);

    procedure ApplyState(aSource: TStateNode; aTarget: TTable);

    property OnStateChange: TStateChangeEvent read fOnStateChange write fOnStateChange;
    property StateCount: Cardinal read GetStateCount;

  end;

implementation

uses
  u_Heuristics;

{ TStateManager }

constructor TStateManager.Create(const aSnapshotServices: ISnapshotServices);
begin
  inherited Create;
  fSnapshotServices := aSnapshotServices;
  fNodes := TObjectList<TStateNode>.Create(True);
  fRootNode := nil;

  fLocalSnapshot := TSnapshot.Create;
  fLocalTable := TTable.Create;
end;

destructor TStateManager.Destroy;
begin
  fLocalSnapshot.Free;
  fLocalTable.Free;
  fNodes.Free;

  inherited;
end;

function TStateManager.GetStateCount: Cardinal;
begin
  Result := fNodes.Count;
end;

procedure TStateManager.ApplyState(aSource: TStateNode; aTarget: TTable);
begin
  fSnapshotServices.Load(aSource.Token, fLocalSnapshot);
  fLocalSnapshot.Restore(aTarget);
end;

procedure TStateManager.Clear;
begin
  // remove our items from the snapshot manager ???
  for var node in fNodes do
  begin
    fSnapshotServices.Delete(node.Token);
  end;

  fNodes.Clear;
  fRootNode := nil;
end;

procedure TStateManager.CreateInitialState(aTable: TTable);
begin
  Assert(FNodes.Count = 0);

  // create root node
  fRootNode := TStateNode.Create(nil, 0, 'Initial State');
  fNodes.Add(fRootNode);

  // capture the current table state
  fLocalSnapshot.Capture(aTable);
  fLocalSnapshot.Restore(fLocalTable);

  // the local snapshot serves as the root node's starting state
  fRootNode.Token := fSnapshotServices.Save(fLocalSnapshot);

  // use LocalTable to generate moves
  PopulateNode(fRootNode);

  // notify
  if Assigned(fOnStateChange) then
    fOnStateChange(Self, nil, fRootNode);
end;

procedure TStateManager.CreateNewState(aOrigin: TStateNode; aMoveIndex: Integer; const aCaption: string);
var
  child: TStateNode;
begin

  // create new node
  child := TStateNode.Create(aOrigin, aMoveIndex, aCaption);
  fNodes.Add(child);
  aOrigin.AddChild(child);

  // local table gets populated from parent node
  fSnapshotServices.Load(aOrigin.Token, fLocalSnapshot);
  fLocalSnapshot.Restore(fLocalTable);

  // execute the move on the local table
  var m := aOrigin.Evaluations[aMoveIndex].Move;
  TExecutor.ExecuteMove(fLocalTable, m);

  // take a snapshot of the new table state for the new node
  fLocalSnapshot.Capture(fLocalTable);
  child.Token := fSnapshotServices.Save(fLocalSnapshot);

  // uses LocalTable to populate moves
  PopulateNode(child);

  // notify
  if Assigned(fOnStateChange) then
    fOnStateChange(Self, aOrigin, child);
end;

procedure TStateManager.PopulateNode(aNode: TStateNode);
begin
  // generate moves
  var firstMoves := TMoveList.Create();
  try
    TGenerator.GenerateMoves(fLocalTable, firstMoves);

    var candidates := TMoveList.Create;
    try
      // separate the invalid moves
      for var m in firstMoves do
      begin
        if TValidator.IsValidMove(m, fLocalTable) then
          candidates.add(m);
      end;

      // measure heuristic at this state
      aNode.HValue := THeuristic.Calculate(fLocalTable, candidates.Count);

      // create evaluations
      TEvaluator.Evaluate(candidates, fLocalTable, aNode.Evaluations);

      // assign scores/sort
      TScorer.AssignScores(aNode.Evaluations);


    finally
      candidates.Free;
    end;

  finally
    firstMoves.Free;
  end;
end;



{ TStateNode }

constructor TStateNode.Create(aOrigin: TStateNode; aOriginMoveIndex: Integer; const aName: string);
begin
  inherited Create;
  fOrigin := aOrigin;
  fOriginMoveIndex := aOriginMoveIndex;
  fName := aName;

  Evaluations := TEvalList.Create;
  HValue := 0;
  fChildNodes := nil;
end;

destructor TStateNode.Destroy;
begin
  Evaluations.Free;
  fChildNodes.Free;
  inherited;
end;

function TStateNode.HasChild(aMoveIndex: Integer): Boolean;
begin
  Result := False;
  if ChildCount > 0 then
  begin
    for var i := 0 to fChildNodes.Count - 1 do
      if fChildNodes[i].OriginMoveIndex = aMoveIndex then
        Exit(True);
  end;
end;

procedure TStateNode.AddChild(aNode: TStateNode);
begin
  if not Assigned(fChildNodes) then
    fChildNodes := TList<TStateNode>.Create;
  fChildNodes.Add(aNode);
end;

function TStateNode.GetChild(aIndex: Integer): TStateNode;
begin
  Result := fChildNodes[aIndex];
end;

function TStateNode.GetChildCount: Integer;
begin
  if Assigned(fChildNodes) then
    Result := fChildNodes.Count
  else
    Result := 0;
end;


end.

