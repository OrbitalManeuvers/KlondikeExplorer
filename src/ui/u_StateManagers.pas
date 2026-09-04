unit u_StateManagers;

interface

uses System.Generics.Collections,
  u_Types, u_SnapshotTypes, u_Snapshots, u_SnapshotManagers, u_MoveLists,
  u_Tables;

type
  TStateNode = class
  private
    fName: string;
    fParent: TStateNode;
    fParentMoveIndex: Integer;
    fChildren: TList<TStateNode>;
    function GetChild(aIndex: Integer): TStateNode;
    function GetChildCount: Integer;
    procedure AddChild(aNode: TStateNode);

  public
    Token: TSnapshotToken;
    HValue: Single;
    Moves: TMoveList;

    constructor Create(aParent: TStateNode; aParentMoveIndex: Integer; const aName: string);
    destructor Destroy; override;

    property Name: string read fName;
    property Parent: TStateNode read fParent;
    property ParentMoveIndex: Integer read fParentMoveIndex;

    function HasChild(aMoveIndex: Integer): Boolean; // do we already have this state?
    property ChildCount: Integer read GetChildCount;
    property ChildNodes[aIndex: Integer]: TStateNode read GetChild;
  end;


  TStateChangeEvent = procedure(Sender: TObject; ParentNode, ChildNode: TStateNode) of object;

  TStateManager = class
  private
    fLocalSnapshot: TSnapshot;
    fLocalTable: TTable;

    fRootNode: TStateNode;
    fNodes: TObjectList<TStateNode>;

    fSnapshotManager: TSnapshotManager;
    fOnStateChange: TStateChangeEvent;
    function GetStateCount: Integer;
    procedure PopulateNode(aNode: TStateNode);
  public
    constructor Create(aSnapshotManager: TSnapshotManager);
    destructor Destroy; override;

    property RootNode: TStateNode read fRootNode;

    procedure Clear;
    procedure CreateInitialState(aSnapshot: TSnapshot);
    procedure CreateNewState(aParent: TStateNode; aMoveIndex: Integer; const aCaption: string);

    procedure ApplyState(aSource: TStateNode; aTarget: TTable);

    property OnStateChange: TStateChangeEvent read fOnStateChange write fOnStateChange;
    property StateCount: Integer read GetStateCount;

  end;

implementation

uses u_MoveGenerators, u_MoveValidators, u_Heuristics, u_MoveExecutors;

{ TStateNode }

constructor TStateNode.Create(aParent: TStateNode; aParentMoveIndex: Integer; const aName: string);
begin
  inherited Create;
  fName := aName;
  fParent := aParent;
  fParentMoveIndex := aParentMoveIndex;
  Moves := TMoveList.Create;
  HValue := 0.0;
  fChildren := nil;
end;

destructor TStateNode.Destroy;
begin
  Moves.Free;

  fChildren.Free;
  inherited;
end;

procedure TStateNode.AddChild(aNode: TStateNode);
begin
  if not Assigned(fChildren) then
    fChildren := TList<TStateNode>.Create;
  fChildren.Add(aNode);
end;

function TStateNode.GetChild(aIndex: Integer): TStateNode;
begin
  Result := fChildren[aIndex];
end;

function TStateNode.GetChildCount: Integer;
begin
  if Assigned(fChildren) then
    Result := fChildren.Count
  else
    Result := 0;
end;

function TStateNode.HasChild(aMoveIndex: Integer): Boolean;
begin
  Result := False;
  if ChildCount > 0 then
  begin
    for var i := 0 to fChildren.Count - 1 do
      if fChildren[i].ParentMoveIndex = aMoveIndex then
        Exit(True);
  end;
end;

{ TStateManager }

constructor TStateManager.Create(aSnapshotManager: TSnapshotManager);
begin
  inherited Create;
  fSnapshotManager := aSnapshotManager;
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

procedure TStateManager.CreateInitialState(aSnapshot: TSnapshot);
begin
  Assert(fNodes.Count = 0);

  // create root node
  fRootNode := TStateNode.Create(nil, 0, 'Initial State');
  fNodes.Add(fRootNode);

  // save the snapshot
  aSnapshot.Restore(fLocalTable);
  fLocalSnapshot.Capture(fLocalTable);

  // the local snapshot serves as the root node's starting state
  fRootNode.Token := fSnapshotManager.Save(fLocalSnapshot);

  // use LocalTable to generate moves
  PopulateNode(fRootNode);

  // notify
  if Assigned(fOnStateChange) then
    fOnStateChange(Self, nil, fRootNode);

end;

procedure TStateManager.CreateNewState(aParent: TStateNode; aMoveIndex: Integer; const aCaption: string);
var
  child: TStateNode;
begin
  // create new node
  child := TStateNode.Create(aParent, aMoveIndex, aCaption);
  fNodes.Add(child);
  aParent.AddChild(child);

  // local table gets populated from parent node
  fSnapshotManager.Load(aParent.Token, fLocalSnapshot);
  fLocalSnapshot.Restore(fLocalTable);

  // execute the move on the local table
  var m := aParent.Moves[aMoveIndex];
  TMoveExecutor.ExecuteMove(fLocalTable, m);

  // take a snapshot of the new table state for the new node
  fLocalSnapshot.Capture(fLocalTable);
  child.Token := fSnapshotManager.Save(fLocalSnapshot);

  // uses LocalTable to populate moves
  PopulateNode(child);

  // notify
  if Assigned(fOnStateChange) then
    fOnStateChange(Self, aParent, child);
end;

procedure TStateManager.ApplyState(aSource: TStateNode; aTarget: TTable);
begin
  fSnapshotManager.Load(aSource.Token, fLocalSnapshot);
  fLocalSnapshot.Restore(aTarget);
end;

procedure TStateManager.Clear;
begin
  // remove our items from the snapshot manager ???
  for var node in fNodes do
    fSnapshotManager.Delete(node.Token);

  fNodes.Clear;
  fRootNode := nil;
end;

function TStateManager.GetStateCount: Integer;
begin
  Result := fNodes.Count;
end;

procedure TStateManager.PopulateNode(aNode: TStateNode);
begin
  // generate moves
  var firstMoves := TMoveList.Create();
  try
    TMoveGenerator.GenerateMoves(fLocalTable, firstMoves);

      // separate the invalid moves
      for var m in firstMoves do
      begin
        if TMoveValidator.IsValidMove(m, fLocalTable) then
          aNode.Moves.Add(m);
      end;

    // measure heuristic at this state
    aNode.HValue := THeuristic.Score(fLocalTable);

  finally
    firstMoves.Free;
  end;

end;

end.
