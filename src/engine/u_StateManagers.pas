unit u_StateManagers;

interface

uses System.Generics.Collections,
  u_Types, u_SnapshotTypes, u_Snapshots, u_SnapshotManagers, u_MoveLists,
  u_Tables, u_Authors;

type
  TStateNode = class
  private
    fName: string;
    fAuthor: TAuthor;
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

    constructor Create(aParent: TStateNode; aParentMoveIndex: Integer; const aName: string; aAuthor: TAuthor);
    destructor Destroy; override;

    property Name: string read fName;
    property Author: TAuthor read fAuthor;
    property Parent: TStateNode read fParent;
    property ParentMoveIndex: Integer read fParentMoveIndex;
    function ChildForMove(aMoveIndex: Integer): TStateNode;
    property ChildCount: Integer read GetChildCount;
    property ChildNodes[aIndex: Integer]: TStateNode read GetChild;
  end;


  TCursorChangeEvent = procedure(Sender: TObject; aNode: TStateNode; aIsStep: Boolean) of object;

  TStateManager = class
  private
    fLocalSnapshot: TSnapshot;
    fLocalTable: TTable;

    fRootNode: TStateNode;
    fNodes: TObjectList<TStateNode>;

    fCursor: TStateNode;

    fSnapshotManager: TSnapshotManager;
    fOnCursorChange: TCursorChangeEvent;
    function GetStateCount: Integer;
    procedure PopulateNode(aNode: TStateNode);
    procedure SetCursorInternal(aNode: TStateNode; aIsStep: Boolean);
    function CreateChild(aParent: TStateNode; aMoveIndex: Integer; aAuthor: TAuthor): TStateNode;
  public
    constructor Create(aSnapshotManager: TSnapshotManager);
    destructor Destroy; override;

    property RootNode: TStateNode read fRootNode;

    procedure Clear;
    procedure CreateInitialState(aSnapshot: TSnapshot);

    procedure ApplyState(aSource: TStateNode; aTarget: TTable);
    procedure LoadState(aNode: TStateNode; aTarget: TSnapshot);

    procedure SetCursor(aNode: TStateNode);
    procedure ExecuteMoveAtCursor(aMoveIndex: Integer; aAuthor: TAuthor; aIsStep: Boolean = True);
    function FindAutoMoveAtCursor(aStackId: TStackId; aCardIndex: Integer;
      out aMove: TMove): Boolean;

    property StateCount: Integer read GetStateCount;

    property Cursor: TStateNode read fCursor;
    property OnCursorChange: TCursorChangeEvent read fOnCursorChange write fOnCursorChange;

  end;

implementation

uses u_MoveGenerators, u_MoveValidators, u_Heuristics, u_MoveExecutors, u_MoveHelpers, u_AutoMovers;

{ TStateNode }

constructor TStateNode.Create(aParent: TStateNode; aParentMoveIndex: Integer; const aName: string; aAuthor: TAuthor);
begin
  inherited Create;
  fName := aName;
  fAuthor := aAuthor;
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

function TStateNode.ChildForMove(aMoveIndex: Integer): TStateNode;
begin
  Result := nil;
  if Assigned(fChildren) then
  begin
    for var answer in fChildren do
      if answer.ParentMoveIndex = aMoveIndex then
        Exit(answer);
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

  // create root node — authored by the player
  fRootNode := TStateNode.Create(nil, 0, 'Initial State', auPlayer);
  fNodes.Add(fRootNode);

  // save the snapshot
  aSnapshot.Restore(fLocalTable);
  fLocalSnapshot.Capture(fLocalTable);

  // the local snapshot serves as the root node's starting state
  fRootNode.Token := fSnapshotManager.Save(fLocalSnapshot);

  // use LocalTable to generate moves
  PopulateNode(fRootNode);

  // seed the cursor at the root (also fires OnCursorChange once)
  SetCursorInternal(fRootNode, False);
end;

function TStateManager.CreateChild(aParent: TStateNode; aMoveIndex: Integer; aAuthor: TAuthor): TStateNode;
begin
  // local table gets populated from parent node
  fSnapshotManager.Load(aParent.Token, fLocalSnapshot);
  fLocalSnapshot.Restore(fLocalTable);

  // execute the move on the local table
  var m := aParent.Moves[aMoveIndex];

  // create new node, named after the move that produced it, authored once
  Result := TStateNode.Create(aParent, aMoveIndex, m.AsText, aAuthor);
  fNodes.Add(Result);
  aParent.AddChild(Result);

  TMoveExecutor.ExecuteMove(fLocalTable, m);

  // take a snapshot of the new table state for the new node
  fLocalSnapshot.Capture(fLocalTable);
  Result.Token := fSnapshotManager.Save(fLocalSnapshot);

  // uses LocalTable to populate moves
  PopulateNode(Result);
end;

procedure TStateManager.ExecuteMoveAtCursor(aMoveIndex: Integer; aAuthor: TAuthor; aIsStep: Boolean);
begin
  var existing := fCursor.ChildForMove(aMoveIndex);
  if Assigned(existing) then
    SetCursorInternal(existing, aIsStep)  // follow — no creation, no re-author
  else
    SetCursorInternal(CreateChild(fCursor, aMoveIndex, aAuthor), aIsStep);  // authored once
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

procedure TStateManager.SetCursor(aNode: TStateNode);
begin
  if aNode <> fCursor then
    SetCursorInternal(aNode, False);
end;

procedure TStateManager.SetCursorInternal(aNode: TStateNode; aIsStep: Boolean);
begin
  fCursor := aNode;
  if Assigned(fOnCursorChange) then
    fOnCursorChange(Self, aNode, aIsStep);
end;

function TStateManager.GetStateCount: Integer;
begin
  Result := fNodes.Count;
end;

procedure TStateManager.LoadState(aNode: TStateNode; aTarget: TSnapshot);
begin
  fSnapshotManager.Load(aNode.Token, aTarget);
end;

function TStateManager.FindAutoMoveAtCursor(aStackId: TStackId; aCardIndex: Integer;
  out aMove: TMove): Boolean;
begin
  // reconstruct the cursor's table into our scratch table, then let the rules decide
  ApplyState(fCursor, fLocalTable);
  Result := TAutoMover.FindAutoMove(fLocalTable, aStackId, aCardIndex, aMove);
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
