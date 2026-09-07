unit u_BasicSolvers;

interface

uses System.Generics.Collections,
  u_Types, u_Tables, u_Snapshots, u_SnapshotManagers, u_SolverTypes, u_Solvers;

type
  TDFSSolver = class(TSolver)
  private
    fTable: TTable;
    fVisited: THashSet<string>;
    fSnapshots: TSnapshotManager;
    fSnapshot: TSnapshot;
    fNodesExplored: Cardinal;
    fMaxDepth: Integer;
    fDepth: Integer;
    fMoveStack: TList<TSolverMove>;
    fSolution: TArray<TMove>;
    function DoSearch(aTable: TTable): Boolean;
    function IsSolved(aTable: TTable): Boolean;
    function FlattenMoveStack: TArray<TMove>;
    procedure SortMoves(aTable: TTable; aMoveList: TList<TSolverMove>;
      var Sorted: TArray<TSolverMove>);
  public
    constructor Create;
    destructor Destroy; override;
    function Solve(InitialState: TSnapshot): TSolverOutcome; override;
  end;

(*
todo: simple move sort:

Foundation moves (Always prioritize clearing cards)
Tableau flips (Exposing a face-down card reveals new information)
King to empty column (Unlocks a buried pile)
Tableau-to-tableau moves (Rearranging the board)
Draw from stock / Reset waste (Usually the lowest priority unless stuck)

*)


implementation

uses System.Generics.Defaults,
  u_Dealers, u_Heuristics, u_MoveGenerators,
  u_MoveExecutors;

{ TDFSSolver }

constructor TDFSSolver.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fVisited := THashSet<string>.Create;
  fSnapshot := TSnapshot.Create;
  fSnapshots := TSnapshotManager.Create;
  fMoveStack := TList<TSolverMove>.Create;
end;

destructor TDFSSolver.Destroy;
begin
  fMoveStack.Free;
  fVisited.Free;
  fTable.Free;
  fSnapshot.Free;
  fSnapshots.Free;
  inherited;
end;

function TDFSSolver.Solve(InitialState: TSnapshot): TSolverOutcome;
begin
  Result := Default(TSolverOutcome);

  fNodesExplored := 0;
  fMaxDepth := 0;
  fDepth := 0;
  fMoveStack.Clear;
  fVisited.Clear;
  fSnapshots.Clear;
  fSolution := nil;

  InitialState.Restore(fTable);

  if DoSearch(fTable) then
  begin
    Result.Result := srSolved;
    Result.Moves := fSolution;
  end
  else if IsCancelled then
    Result.Result := srCancelled
  else if (Limits.MaxNodes > 0) and (fNodesExplored >= Limits.MaxNodes) then
    Result.Result := srLimitReached
  else if (Limits.MaxDepth > 0) and (fMaxDepth >= Limits.MaxDepth) then
    Result.Result := srLimitReached
  else
    Result.Result := srUnsolved;

  Result.NodesExplored := fNodesExplored;
  Result.MaxDepthReached := fMaxDepth;
end;

function TDFSSolver.IsSolved(aTable: TTable): Boolean;
begin
  Result := True;
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if aTable.Foundation[suit].Count <> 13 then
      Exit(False);
end;

function TDFSSolver.FlattenMoveStack: TArray<TMove>;
var
  moves: TList<TMove>;
  unrolled: TArray<TMove>;
begin
  moves := TList<TMove>.Create;
  try
    for var i := 0 to fMoveStack.Count - 1 do
    begin
      unrolled := fMoveStack[i].Unroll;
      for var j := 0 to High(unrolled) do
        moves.Add(unrolled[j]);
    end;
    Result := moves.ToArray;
  finally
    moves.Free;
  end;
end;

function TDFSSolver.DoSearch(aTable: TTable): Boolean;
begin
  Inc(fNodesExplored);
  if fDepth > fMaxDepth then
    fMaxDepth := fDepth;

  // check limits and cancellation
  if IsCancelled then
    Exit(False);
  if (Limits.MaxNodes > 0) and (fNodesExplored >= Limits.MaxNodes) then
    Exit(False);
  if (Limits.MaxDepth > 0) and (fDepth >= Limits.MaxDepth) then
    Exit(False);

  if IsSolved(aTable) then
  begin
    fSolution := FlattenMoveStack;
    Exit(True);
  end;

  fSnapshot.Capture(aTable);
  var snap := fSnapshot.AsText;
  if fVisited.Contains(snap) then
    Exit(False);

  fVisited.Add(snap);

  // notify observer of the new state being explored
  NotifyStateVisited(fDepth);
  if (fNodesExplored mod 1000) = 0 then
    NotifyProgress(fNodesExplored);

  var sortedMoves: TArray<TSolverMove> := [];

  var moveList := TList<TSolverMove>.Create;
  try
    TMoveGenerator.GenerateSolverMoves(aTable, moveList);
    SortMoves(aTable, moveList, sortedMoves);
  finally
    moveList.Free;
  end;

  if Length(sortedMoves) = 0 then
    Exit(False);

  for var i := 0 to High(sortedMoves) do
  begin
    var token := fSnapshots.Save(fSnapshot);  // save current state
    fMoveStack.Add(sortedMoves[i]);
    Inc(fDepth);

    TMoveExecutor.ExecuteSolverMove(aTable, sortedMoves[i]);
    if DoSearch(aTable) then
      Exit(True);

    // restore state and release token
    Dec(fDepth);
    fMoveStack.Delete(fMoveStack.Count - 1);
    fSnapshots.Load(token, fSnapshot);
    fSnapshot.Restore(aTable);
    fSnapshots.Delete(token);
    NotifyBacktrack(fDepth);
  end;

  Result := False;
end;

procedure TDFSSolver.SortMoves(aTable: TTable; aMoveList: TList<TSolverMove>;
  var Sorted: TArray<TSolverMove>);
type
  TScoredMove = record
    MoveIndex: Integer;
    Score: Single;
  end;

begin
  SetLength(Sorted, 0);
  if aMoveList.Count = 0 then
    Exit;

  // save a snapshot of the starting state
  fSnapshot.Capture(aTable);

  var scratch := TTable.Create;
  try

    var scoredMoves := TList<TScoredMove>.Create();
    try
      // apply and score complete solver moves
      for var i := 0 to aMoveList.Count - 1 do
      begin
        fSnapshot.Restore(scratch);
        TMoveExecutor.ExecuteSolverMove(scratch, aMoveList[i]);
        var score := THeuristic.Score(scratch);

        var scored := Default(TScoredMove);
        scored.MoveIndex := i;
        scored.Score := score;
        scoredMoves.Add(scored);
      end;

      // sort by score ascending (lowest = closest to goal = try first)
      scoredMoves.Sort(TComparer<TScoredMove>.Construct(
        function(const A, B: TScoredMove): Integer
        begin
          if A.Score < B.Score then
            Result := -1
          else if A.Score > B.Score then
            Result := 1
          else
            Result := 0;
        end
      ));

      SetLength(Sorted, scoredMoves.Count);
      for var i := 0 to scoredMoves.Count - 1 do
        Sorted[i] := aMoveList[scoredMoves[i].MoveIndex];

    finally
      scoredMoves.Free;
    end;

  finally
    scratch.Free;

  end;

end;




end.
