unit u_AStarSolvers;

interface

uses System.Generics.Collections,
  u_Types, u_Tables, u_Snapshots, u_SnapshotManagers, u_SnapshotTypes,
  u_SolverTypes, u_Solvers, u_MoveLists, u_CardStacks;

type
  TAStarSolver = class(TSolver)
  private
    fTable: TTable;
    fClosed: THashSet<string>;
    fSnapshots: TSnapshotManager;
    fSnapshot: TSnapshot;
    fNodesExplored: Cardinal;
    fMaxDepth: Integer;
    function IsSolved(aTable: TTable): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Solve(InitialState: TSnapshot): TSolverOutcome; override;
  end;

implementation

uses System.Generics.Defaults,
  u_Dealers, u_Heuristics, u_MoveGenerators, u_MoveValidators,
  u_MoveExecutors;

type
  TAStarNode = record
    Token: TSnapshotToken;  // pooled state storage
    G: Integer;             // cost so far (move count)
    F: Single;              // g + h
    Moves: TArray<TMove>;   // path from start
  end;


{ TAStarSolver }

constructor TAStarSolver.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fClosed := THashSet<string>.Create;
  fSnapshot := TSnapshot.Create;
  fSnapshots := TSnapshotManager.Create;
end;

destructor TAStarSolver.Destroy;
begin
  fClosed.Free;
  fTable.Free;
  fSnapshot.Free;
  fSnapshots.Free;
  inherited;
end;

function TAStarSolver.IsSolved(aTable: TTable): Boolean;
begin
  Result := True;
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if aTable.Foundation[suit].Count <> 13 then
      Exit(False);
end;

function TAStarSolver.Solve(InitialState: TSnapshot): TSolverOutcome;
var
  openList: TList<TAStarNode>;

  function ExtractMin: TAStarNode;
  var
    bestIdx: Integer;
  begin
    bestIdx := 0;
    for var i := 1 to openList.Count - 1 do
      if openList[i].F < openList[bestIdx].F then
        bestIdx := i;
    Result := openList[bestIdx];
    openList.Delete(bestIdx);
  end;

begin
  Result := Default(TSolverOutcome);
  fNodesExplored := 0;
  fMaxDepth := 0;
  fClosed.Clear;
  fSnapshots.Clear;

  InitialState.Restore(fTable);

  // seed the open list with the initial state
  fSnapshot.Capture(fTable);
  var startHash := fSnapshot.AsText;
  fClosed.Add(startHash);

  var startNode: TAStarNode;
  startNode.Token := fSnapshots.Save(fSnapshot);
  startNode.G := 0;
  startNode.F := THeuristic.Score(fTable);
  startNode.Moves := [];

  openList := TList<TAStarNode>.Create;
  try
    openList.Add(startNode);

    while openList.Count > 0 do
    begin
      // check cancellation
      if IsCancelled then
        Break;

      // check node limit
      if (Limits.MaxNodes > 0) and (fNodesExplored >= Limits.MaxNodes) then
        Break;

      var current := ExtractMin;
      Inc(fNodesExplored);

      if current.G > fMaxDepth then
        fMaxDepth := current.G;

      // restore state from the node's token
      fSnapshots.Load(current.Token, fSnapshot);
      fSnapshot.Restore(fTable);
      fSnapshots.Delete(current.Token);

      // check for goal
      if IsSolved(fTable) then
      begin
        Result.Result := srSolved;
        Result.Moves := current.Moves;
        Result.NodesExplored := fNodesExplored;
        Result.MaxDepthReached := fMaxDepth;

        // clean up remaining open-list tokens
        for var i := 0 to openList.Count - 1 do
          fSnapshots.Delete(openList[i].Token);
        Exit;
      end;

      // check depth limit
      if (Limits.MaxDepth > 0) and (current.G >= Limits.MaxDepth) then
        Continue;

      // notify observer periodically
      if (fNodesExplored mod 1000) = 0 then
        NotifyProgress(fNodesExplored);

      // expand successors
      var moveList := TMoveList.Create;
      try
        TMoveGenerator.GenerateMoves(fTable, moveList);

        for var i := 0 to moveList.Count - 1 do
        begin
          if not TMoveValidator.IsValidMove(moveList[i], fTable) then
            Continue;

          // apply move on a scratch copy
          fSnapshot.Capture(fTable);
          var scratchToken := fSnapshots.Save(fSnapshot);

          TMoveExecutor.ExecuteMove(fTable, moveList[i]);

          // check closed set
          fSnapshot.Capture(fTable);
          var hash := fSnapshot.AsText;

          if not fClosed.Contains(hash) then
          begin
            fClosed.Add(hash);

            var childNode: TAStarNode;
            childNode.Token := fSnapshots.Save(fSnapshot);
            childNode.G := current.G + 1;
            childNode.F := childNode.G + THeuristic.Score(fTable);
            childNode.Moves := Copy(current.Moves);
            SetLength(childNode.Moves, Length(childNode.Moves) + 1);
            childNode.Moves[High(childNode.Moves)] := moveList[i];

            openList.Add(childNode);
          end;

          // restore parent state
          fSnapshots.Load(scratchToken, fSnapshot);
          fSnapshot.Restore(fTable);
          fSnapshots.Delete(scratchToken);
        end;
      finally
        moveList.Free;
      end;
    end;

    // search ended without solution — clean up remaining tokens
    for var i := 0 to openList.Count - 1 do
      fSnapshots.Delete(openList[i].Token);

  finally
    openList.Free;
  end;

  // determine outcome
  if Result.Result <> srSolved then
  begin
    if IsCancelled then
      Result.Result := srCancelled
    else if (Limits.MaxNodes > 0) and (fNodesExplored >= Limits.MaxNodes) then
      Result.Result := srLimitReached
    else
      Result.Result := srUnsolved;
  end;

  Result.NodesExplored := fNodesExplored;
  Result.MaxDepthReached := fMaxDepth;


end;

end.
