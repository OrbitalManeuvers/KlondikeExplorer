unit u_Games;

interface

uses System.Generics.Collections,
  u_Types, u_CardStacks, u_Tables, u_Snapshots, u_MoveLists,
  u_SnapshotTypes, u_SnapshotManagers;

type
  TUndoEntry = record
    Token: TSnapshotToken;
    Move: TMove;
  end;

  TKlondikeGame = class
  private
    fTable: TTable;
    fSnapshotManager: TSnapshotManager;
    fSnapshot: TSnapshot;
    fInitialState: TSnapshotToken;
    fUndoStack: TStack<TUndoEntry>;
    fRedoStack: TStack<TUndoEntry>;
    fHintMoves: TMoveList;
    fHintIndex: Integer;
    fMoveCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Initialize(aInitialState: TSnapshot);

    // Move execution with history
    function TryExecuteMove(const aMove: TMove): Boolean;
    procedure Undo;
    procedure Redo;
    function CanUndo: Boolean;
    function CanRedo: Boolean;

    // Auto-move (quick-click logic)
    function GetAutoMove(aSourceStack: TStackId; aCardIndex: Integer;
      out aMove: TMove): Boolean;

    // Hints
    procedure BuildHintList;
    function GetNextHint(out aMove: TMove): Boolean;
    procedure ResetHints;

    // Game state
    function IsWon: Boolean;
    function CanAutoComplete: Boolean;
    procedure Restart;
    procedure CopyTableTo(aTarget: TTable);

    property Table: TTable read fTable;
    property MoveCount: Integer read fMoveCount;

  end;

function NewUndoEntry(const aToken: TSnapshotToken; const aMove: TMove): TUndoEntry;

implementation

uses System.Math,
  u_CardHelpers, u_Utils, u_Dealers, u_MoveValidators, u_MoveExecutors,
  u_TableUtils, u_MoveGenerators, u_HintGenerators;

function NewUndoEntry(const aToken: TSnapshotToken; const aMove: TMove): TUndoEntry;
begin
  Result.Token := aToken;
  Result.Move := aMove;
end;

{ TKlondikeGame }
constructor TKlondikeGame.Create;
begin
  inherited;
  fTable := TTable.Create;
  fSnapshotManager := TSnapshotManager.Create;
  fSnapshot := TSnapshot.Create;
  fInitialState := NO_SNAPSHOT;

  fUndoStack := TStack<TUndoEntry>.Create;
  fRedoStack := TStack<TUndoEntry>.Create;

  fHintMoves := TMoveList.Create();
end;

destructor TKlondikeGame.Destroy;
begin
  fHintMoves.Free;
  fUndoStack.Free;
  fRedoStack.Free;

  fSnapshot.Free;

  if fInitialState <> NO_SNAPSHOT then
    fSnapshotManager.Delete(fInitialState);
  fSnapshotManager.Free;

  fTable.Free;
  inherited;
end;

procedure TKlondikeGame.Initialize(aInitialState: TSnapshot);
begin
  if fInitialState <> NO_SNAPSHOT then
    fSnapshotManager.Delete(fInitialState);
  fInitialState := fSnapshotManager.Save(aInitialState);

  Restart;
  BuildHintList;
end;

function TKlondikeGame.TryExecuteMove(const aMove: TMove): Boolean;
begin
  Result := False;
  if TMoveValidator.IsValidMove(aMove, fTable) then
  begin
    // capture undo state
    fSnapshot.Capture(fTable);
    var token := fSnapshotManager.Save(fSnapshot);
    fUndoStack.Push(NewUndoEntry(token, aMove));

    // new move invalidates redo history
    fRedoStack.Clear;

    // apply move
    TMoveExecutor.ExecuteMove(fTable, aMove);
    Inc(fMoveCount);
    Result := True;

    BuildHintList;
  end;
end;

procedure TKlondikeGame.BuildHintList;
begin
  fHintIndex := -1;
  fHintMoves.Clear;

  var scratch := TMoveList.Create();
  try

    // todo: implement THintGenerator.GenerateHints(Table, moveList);

    TMoveGenerator.GenerateMoves(fTable, scratch);

    // !! MS Solitaire has opinions here. tableau twins don't show as a move until
    // the covered twin can be moved to foundation.

    // my system generates a move to the twin as mechanically valid,
    // this used to get filtered out as cyclic. This needs design.

    for var m in scratch do
      if TMoveValidator.IsValidMove(m, fTable) then
      begin
        if m.Source <> siStock then
          fHintMoves.Add(m);
      end;
  finally
    scratch.Free;
  end;

  if fHintMoves.Count > 0 then
    fHintIndex := 0;
end;

function TKlondikeGame.GetNextHint(out aMove: TMove): Boolean;
begin
  Result := False;

  // fHintIndex points to the next one to use
  if (fHintIndex >= 0) and (fHintIndex < fHintMoves.Count) then
  begin
    aMove := fHintMoves.Moves[fHintIndex];
    Result := True;

    Inc(fHintIndex);
    if fHintIndex >= fHintMoves.Count then
      fHintIndex := 0;
  end;
end;

function TKlondikeGame.CanAutoComplete: Boolean;
begin
  Result := (fTable.Stock.Count = 0) and (fTable.Waste.Count = 0);
end;

function TKlondikeGame.CanRedo: Boolean;
begin
  Result := not fRedoStack.IsEmpty;
end;

function TKlondikeGame.CanUndo: Boolean;
begin
  Result := not fUndoStack.IsEmpty;
end;

procedure TKlondikeGame.CopyTableTo(aTarget: TTable);
begin
  fSnapshot.Capture(fTable);
  fSnapshot.Restore(aTarget);
end;

function TKlondikeGame.GetAutoMove(aSourceStack: TStackId; aCardIndex: Integer;
  out aMove: TMove): Boolean;
begin
  Result := False;

  var category := StackIdToCategory(aSourceStack);
  case category of

    // Stock - if cards: flip to waste, if empty: recycle waste to stock
    scStock:
      begin
        if fTable.Stock.HasCards then
        begin
          // do mtDraw
          aMove.Source := siStock;
          aMove.Target := siWaste;
          aMove.Count := Min(3, fTable.Stock.Count);
          Exit(True);
        end
        else if fTable.Waste.HasCards then
        begin
          // do mtRecycle
          aMove.Source := siWaste;
          aMove.Target := siStock;
          aMove.Count := fTable.Waste.Count;
          Exit(True);
        end;
      end;

    // Waste - only moves topmost card. try foundation first, tableaus next
    scWaste:
      begin
        if fTable.Waste.HasCards then
        begin
          var c := fTable.Waste.Last;

          // immediate move to foundation?
          if IsNextFoundationCard(c, fTable) then
          begin
            aMove.Source := siWaste;
            aMove.Target := SuitToStackId(c.Suit);
            aMove.Count := 1;
            Exit(True);
          end;

          // check tableau stacks.
          var targetId: TStackId;
          if FindTableauTarget(c, fTable, targetId) then
          begin
            aMove.Source := siWaste;
            aMove.Target := targetId;
            aMove.Count := 1;
            Exit(True);
          end;
        end;
      end;

    // Tableau
    // - topmost card: check foundation first, then other tableaus
    // - buried face up: can only move full run to other tableau
    scTableau:
      begin
        var c := fTable.Stacks[aSourceStack].Cards[aCardIndex];

        // if this is the topmost card ...
        if aCardIndex = fTable.Stacks[aSourceStack].Count - 1 then
        begin
          if IsNextFoundationCard(c, fTable) then
          begin
            aMove.Source := aSourceStack;
            aMove.Target := SuitToStackId(c.Suit);
            aMove.Count := 1;
            Exit(True);
          end;
        end;

        // otherwise, regardless of its position it has to move to a valid spot
        var target: TStackId;
        if FindTableauTarget(c, fTable, target) then
        begin
          aMove.Source := aSourceStack;
          aMove.Target := target;
          aMove.Count := fTable.Stacks[aSourceStack].Count - aCardIndex; // !! verify
          Exit(True);
        end;
      end;

    // Foundation - only moves single card, only to tableau.
    scFoundation:
      begin
        if fTable.Stacks[aSourceStack].HasCards then
        begin
          var c := fTable.Stacks[aSourceStack].Last;
          var target: TStackId;
          if FindTableauTarget(c, fTable, target) then
          begin
            aMove.Source := aSourceStack;
            aMove.Target := target;
            aMove.Count := 1;
            Exit(True);
          end;
        end;
      end;

  end;

end;

function TKlondikeGame.IsWon: Boolean;
begin
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if (not fTable.Foundation[suit].HasCards) or (fTable.Foundation[suit].Last.Value <> cvKing) then
      Exit(False);

  Result := True;
end;

procedure TKlondikeGame.Redo;
begin
  if CanRedo then
  begin
    // capture current state for undo
    fSnapshot.Capture(fTable);
    var undoToken := fSnapshotManager.Save(fSnapshot);

    var entry := fRedoStack.Pop;
    fUndoStack.Push(NewUndoEntry(undoToken, entry.Move));

    // restore forward state
    fSnapshotManager.Load(entry.Token, fSnapshot);
    fSnapshot.Restore(fTable);

    Inc(fMoveCount);
  end;
end;

procedure TKlondikeGame.Undo;
begin
  if CanUndo then
  begin
    // capture current state for redo
    fSnapshot.Capture(fTable);
    var redoToken := fSnapshotManager.Save(fSnapshot);

    var entry := fUndoStack.Pop;
    fRedoStack.Push(NewUndoEntry(redoToken, entry.Move));

    // restore previous state
    fSnapshotManager.Load(entry.Token, fSnapshot);
    fSnapshot.Restore(fTable);

    Dec(fMoveCount);
  end;
end;

procedure TKlondikeGame.ResetHints;
begin
  fHintMoves.Clear;
  fHintIndex := -1;
end;

procedure TKlondikeGame.Restart;
begin
  Assert(fInitialState <> NO_SNAPSHOT);

  ResetHints;

  for var ue in fUndoStack do
    fSnapshotManager.Delete(ue.Token);
  fUndoStack.Clear;

  for var re in fRedoStack do
    fSnapshotManager.Delete(re.Token);
  fRedoStack.Clear;

  fMoveCount := 0;

  fTable.BeginUpdate;
  try
    fTable.Clear;

    fSnapshotManager.Load(fInitialState, fSnapshot);
    fSnapshot.Restore(fTable);
  finally
    fTable.EndUpdate;
  end;
end;

end.
