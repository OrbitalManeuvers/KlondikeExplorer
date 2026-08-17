unit u_BasicSolvers;

interface

uses System.Generics.Collections,
  u_Types, u_Tables, u_Snapshots, u_SnapshotManagers, u_SolverTypes, u_Solvers,
  u_MoveLists, u_CardStacks;

type
  TBasicSolver = class(TSolver)
  private
    fTable: TTable;
    fVisited: THashSet<string>;
    fSnapshots: TSnapshotManager;
    fSnapshot: TSnapshot;
    fNodesExplored: Cardinal;
    fMaxDepth: Integer;
    fDepth: Integer;
    fMoveStack: TList<TMove>;
    fSolution: TArray<TMove>;
    function DoSearch(aTable: TTable): Boolean;
    function IsSolved(aTable: TTable): Boolean;
    procedure SortMoves(aTable: TTable; aMoveList: TMoveList; var Sorted: TArray<TMove>);
  public
    constructor Create;
    destructor Destroy; override;
    function Solve(aDeck: TCardStack): TSolverOutcome; override;
  end;

implementation

uses System.Generics.Defaults,
  u_Dealers, u_Heuristics, u_MoveGenerators, u_MoveValidators,
  u_MoveExecutors;

{ TBasicSolver }

constructor TBasicSolver.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fVisited := THashSet<string>.Create;
  fSnapshot := TSnapshot.Create;
  fSnapshots := TSnapshotManager.Create;
  fMoveStack := TList<TMove>.Create;
end;

destructor TBasicSolver.Destroy;
begin
  fMoveStack.Free;
  fVisited.Free;
  fTable.Free;
  fSnapshot.Free;
  fSnapshots.Free;
  inherited;
end;

function TBasicSolver.Solve(aDeck: TCardStack): TSolverOutcome;
begin
  Result := Default(TSolverOutcome);

  fNodesExplored := 0;
  fMaxDepth := 0;
  fDepth := 0;
  fMoveStack.Clear;
  fVisited.Clear;
  fSnapshots.Clear;
  fSolution := nil;

  TDealer.Deal(aDeck, fTable);
  try
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
  finally
    TDealer.Repack(fTable, aDeck);
  end;
end;

function TBasicSolver.IsSolved(aTable: TTable): Boolean;
begin
  Result := True;
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if aTable.Foundation[suit].Count <> 13 then
      Exit(False);
end;

function TBasicSolver.DoSearch(aTable: TTable): Boolean;
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
    fSolution := fMoveStack.ToArray;
    Exit(True);
  end;

  fSnapshot.Capture(aTable);
  var snap := fSnapshot.AsText;
  if fVisited.Contains(snap) then
    Exit(False);

  fVisited.Add(snap);

  var sortedMoves: TArray<TMove> := [];

  var moveList := TMoveList.Create;
  try
    TMoveGenerator.GenerateMoves(aTable, moveList);
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

    TMoveExecutor.ExecuteMove(aTable, sortedMoves[i]);
    if DoSearch(aTable) then
      Exit(True);

    // restore state and release token
    Dec(fDepth);
    fMoveStack.Delete(fMoveStack.Count - 1);
    fSnapshots.Load(token, fSnapshot);
    fSnapshot.Restore(aTable);
    fSnapshots.Delete(token);
  end;

  Result := False;
end;

procedure TBasicSolver.SortMoves(aTable: TTable; aMoveList: TMoveList; var Sorted: TArray<TMove>);
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
      // test and score moves
      for var i := 0 to aMoveList.Count - 1 do
      begin
        if TMoveValidator.IsValidMove(aMoveList[i], aTable) then
        begin

          // start from saved state, apply move and score
          fSnapshot.Restore(scratch);
          TMoveExecutor.ExecuteMove(scratch, aMoveList[i]);
          var score := THeuristic.Score(scratch);

          // save
          var scored := Default(TScoredMove);
          scored.MoveIndex := i;
          scored.Score := score;
          scoredMoves.Add(scored);
        end;
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

      //
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
