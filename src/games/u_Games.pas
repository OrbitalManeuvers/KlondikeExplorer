unit u_Games;

interface

uses System.Classes, System.Generics.Collections,
  u_Types, u_CardStacks, u_Tables, u_Snapshots, u_MoveLists,
  u_SnapshotTypes, u_SnapshotManagers;

type
  TGameMove = record
    Token: TSnapshotToken;
    Move: TMove;
  end;

//  TMoveExecutedEvent = procedure (Sender: TObject; aMove: TMove) of object;

  TKlondikeGame = class
  private
    fTable: TTable;
    fSnapshotManager: TSnapshotManager;
    fOwnsSnapshotManager: Boolean;
    fSnapshot: TSnapshot;
    fMoveHistory: TList<TGameMove>;
    fHistoryIndex: Integer;
    fHintMoves: TMoveList;
    fHintIndex: Integer;
    fOnStateChanged: TNotifyEvent;
//    fMoveEvent: TMulticastEvent<TMoveExecutedEvent>;
    function GetMoveHistory(aIndex: Integer): TGameMove;
    function GetMoveCount: Integer;
    procedure StateChanged;
  public
    constructor Create(ASnapshotManager: TSnapshotManager = nil);
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
    procedure CopyTableTo(aTarget: TTable);

    property Table: TTable read fTable;
    property MoveCount: Integer read GetMoveCount;
    property MoveHistory[aIndex: Integer]: TGameMove read GetMoveHistory;

    property OnStateChanged: TNotifyEvent read fOnStateChanged write fOnStateChanged;
  end;

function NewGameMove(const aToken: TSnapshotToken; const aMove: TMove): TGameMove;

implementation

uses System.Math,
  u_CardHelpers, u_Utils, u_Dealers, u_MoveValidators, u_MoveExecutors,
  u_TableUtils, u_MoveGenerators, u_HintGenerators;

function NewGameMove(const aToken: TSnapshotToken; const aMove: TMove): TGameMove;
begin
  Result.Token := aToken;
  Result.Move := aMove;
end;

function TKlondikeGame.GetMoveHistory(aIndex: Integer): TGameMove;
begin
  Result := fMoveHistory[aIndex];
end;

function TKlondikeGame.GetMoveCount: Integer;
begin
  Result := fHistoryIndex + 1;
end;

{ TKlondikeGame }
constructor TKlondikeGame.Create(ASnapshotManager: TSnapshotManager = nil);
begin
  inherited Create;
  fTable := TTable.Create;
//  fMoveEvent := TMulticastEvent<TMoveExecutedEvent>.Create;

  if ASnapshotManager <> nil then
  begin
    fSnapshotManager := ASnapshotManager;
    fOwnsSnapshotManager := False;
  end
  else
  begin
    fSnapshotManager := TSnapshotManager.Create;
    fOwnsSnapshotManager := True;
  end;
  fSnapshot := TSnapshot.Create;

  fMoveHistory := TList<TGameMove>.Create;
  fHistoryIndex := -1;

  fHintMoves := TMoveList.Create();
end;

destructor TKlondikeGame.Destroy;
begin
  fHintMoves.Free;

  // free all snapshot tokens held in history
  for var i := 0 to fMoveHistory.Count - 1 do
    fSnapshotManager.Delete(fMoveHistory[i].Token);
  fMoveHistory.Free;

  fSnapshot.Free;

  if fOwnsSnapshotManager then
    fSnapshotManager.Free;

  fTable.Free;

  inherited;
end;

procedure TKlondikeGame.Initialize(aInitialState: TSnapshot);
begin
  ResetHints;

  for var i := 0 to fMoveHistory.Count - 1 do
    fSnapshotManager.Delete(fMoveHistory[i].Token);
  fMoveHistory.Clear;
  fHistoryIndex := -1;

  fTable.BeginUpdate;
  try
    fTable.Clear;
    aInitialState.Restore(fTable);
  finally
    fTable.EndUpdate;
  end;

  StateChanged;
end;

function TKlondikeGame.TryExecuteMove(const aMove: TMove): Boolean;
begin
  Result := False;
  if TMoveValidator.IsValidMove(aMove, fTable) then
  begin
    // capture pre-move state
    fSnapshot.Capture(fTable);
    var token := fSnapshotManager.Save(fSnapshot);

    // truncate any redo entries beyond current position
    for var i := fMoveHistory.Count - 1 downto fHistoryIndex + 1 do
    begin
      fSnapshotManager.Delete(fMoveHistory[i].Token);
      fMoveHistory.Delete(i);
    end;

    // append new entry
    fMoveHistory.Add(NewGameMove(token, aMove));
    Inc(fHistoryIndex);

    // apply move
    TMoveExecutor.ExecuteMove(fTable, aMove);
    Result := True;

//    fMoveEvent.Notify(
//      procedure(Handler: TMoveExecutedEvent)
//      begin
//        Handler(Self, aMove);
//      end
//    );

    StateChanged;
  end;
end;

procedure TKlondikeGame.Undo;
begin
  if CanUndo then
  begin
    // restore state stored at current history index
    var entry := fMoveHistory[fHistoryIndex];
    fSnapshotManager.Load(entry.Token, fSnapshot);
    fSnapshot.Restore(fTable);

    Dec(fHistoryIndex);

    StateChanged;
  end;
end;

procedure TKlondikeGame.Redo;
begin
  if CanRedo then
  begin
    // advance index, then re-execute that move
    Inc(fHistoryIndex);
    var entry := fMoveHistory[fHistoryIndex];
    TMoveExecutor.ExecuteMove(fTable, entry.Move);

    StateChanged;
  end;
end;

function TKlondikeGame.CanUndo: Boolean;
begin
  Result := fHistoryIndex >= 0;
end;

function TKlondikeGame.CanRedo: Boolean;
begin
  Result := fHistoryIndex < fMoveHistory.Count - 1;
end;

procedure TKlondikeGame.BuildHintList;
begin
  fHintIndex := -1;
  fHintMoves.Clear;
  THintGenerator.GenerateHints(fTable, fHintMoves);

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
          aMove.Count := fTable.Stacks[aSourceStack].Count - aCardIndex;
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
    if (not fTable.Foundation[suit].HasCards)
      or (fTable.Foundation[suit].Last.Value <> cvKing) then
      Exit(False);

  Result := True;
end;

procedure TKlondikeGame.ResetHints;
begin
  fHintMoves.Clear;
  fHintIndex := -1;
end;

procedure TKlondikeGame.StateChanged;
begin
  BuildHintList;
  if Assigned(fOnStateChanged) then
    fOnStateChanged(Self);
end;

end.
