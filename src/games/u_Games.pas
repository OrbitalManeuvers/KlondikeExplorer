unit u_Games;

interface

uses System.Generics.Collections,
  u_Types, u_CardStacks, u_Tables, u_Snapshots, u_MoveLists,
  u_SnapshotTypes, u_SnapshotManagers;

type
  // base class just owns a table
  TGame = class
  protected
    fTable: TTable;
    fStartingDeck: TCardStack; // save for Reset
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure InitializeGame(aDeck: TCardStack); virtual;
    property Table: TTable read fTable;
  end;

  TKlondikeGame = class(TGame)
  private
    fSnapshotManager: TSnapshotManager;
    fSnapshot: TSnapshot;
    fUndoStack: TStack<TSnapshotToken>;
    fRedoStack: TStack<TSnapshotToken>;
    fMoveHistory: TList<TMove>;
    fHintMoves: TMoveList;
    fHintIndex: Integer;
    fMoveCount: Integer;    //
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure InitializeGame(aDeck: TCardStack); override;

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
    function GetNextHint(out aMove: TMove): Boolean;
    procedure ResetHints;

    // Game state
    function IsWon: Boolean;
    function CanAutoComplete: Boolean;
    procedure Restart;

    property MoveCount: Integer read fMoveCount;

  end;


implementation

uses u_CardHelpers, u_Utils, u_Dealers, u_MoveValidators, u_MoveExecutors,
  u_TableUtils;

{ TGame }

constructor TGame.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fStartingDeck := TCardStack.Create;
end;

destructor TGame.Destroy;
begin
  fStartingDeck.Free;
  fTable.Free;
  inherited;
end;

procedure TGame.InitializeGame(aDeck: TCardStack);
begin
  fStartingDeck.Clear;
  fStartingDeck.AddFrom(aDeck);
end;


{ TKlondikeGame }
constructor TKlondikeGame.Create;
begin
  inherited;
  fSnapshotManager := TSnapshotManager.Create;
  fSnapshot := TSnapshot.Create;

  fUndoStack := TStack<TSnapshotToken>.Create;
  fRedoStack := TStack<TSnapshotToken>.Create;
  fMoveHistory := TList<TMove>.Create;

  fHintMoves := TMoveList.Create();
end;

destructor TKlondikeGame.Destroy;
begin
  fMoveHistory.Free;
  fHintMoves.Free;
  fUndoStack.Free;
  fRedoStack.Free;

  fSnapshot.Free;
  fSnapshotManager.Free;

  inherited;
end;

function TKlondikeGame.TryExecuteMove(const aMove: TMove): Boolean;
begin
  Result := False;
  if TValidator.IsValidMove(aMove, fTable) then
  begin
    // capture undo state
    fSnapshot.Capture(Table);
    var t := fSnapshotManager.Save(fSnapshot);
    fUndoStack.Push(t);

    // apply move
    TMoveExecutor.ExecuteMove(Table, aMove);
    fMoveHistory.Add(aMove);
  end;

end;

function TKlondikeGame.CanAutoComplete: Boolean;
begin
  Result := False;
end;

function TKlondikeGame.CanRedo: Boolean;
begin
  Result := not fRedoStack.IsEmpty;
end;

function TKlondikeGame.CanUndo: Boolean;
begin
  Result := not fUndoStack.IsEmpty;
end;

function TKlondikeGame.GetAutoMove(aSourceStack: TStackId; aCardIndex: Integer;
  out aMove: TMove): Boolean;
begin
  Result := False;

  var category := u_Utils.IdToCategory(aSourceStack);
  case category of

    // Stock - if cards: flip to waste, if empty: recycle waste to stock
    scStock:
      begin
        if Table.Stock.HasCards then
        begin
          // do mtDraw
          aMove.Source := siStock;
          aMove.Target := siWaste;
          aMove.Count := 3;
          Exit(True);
        end
        else if Table.Waste.HasCards then
        begin
          // do mtRecycle
          aMove.Source := siWaste;
          aMove.Target := siStock;
          aMove.Count := Table.Waste.Count;
          Exit(True);
        end;
      end;

    // Waste - only moves topmost card. try foundation first, tableaus next
    scWaste:
      begin
        if Table.Waste.HasCards then
        begin
          var c := Table.Waste.Last;

          // immediate move to foundation?
          if IsNextFoundationCard(c, Table) then
          begin
            aMove.Source := siWaste;
            aMove.Target := SuitToStackId(c.Suit);
            aMove.Count := 1;
            Exit(True);
          end;

          // check tableau stacks.
          var targetId: TStackId;
          if FindTableauTarget(c, Table, targetId) then
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
        var c := Table.Stacks[aSourceStack].Cards[aCardIndex];

        // if this is the topmost card ...
        if aCardIndex = Table.Stacks[aSourceStack].Count - 1 then
        begin
          if IsNextFoundationCard(c, Table) then
          begin
            aMove.Source := aSourceStack;
            aMove.Target := SuitToStackId(c.Suit);
            aMove.Count := 1;
            Exit(True);
          end;
        end;

        // otherwise, regardless of its position it has to move to a valid spot
        var target: TStackId;
        if FindTableauTarget(c, Table, target) then
        begin
          aMove.Source := aSourceStack;
          aMove.Target := target;
          aMove.Count := Table.Stacks[aSourceStack].Count - aCardIndex; // !! verify
          Exit(True);
        end;
      end;

    // Foundation - only moves single card, only to tableau.
    scFoundation:
      begin
        if Table.Stacks[aSourceStack].HasCards then
        begin
          var c := Table.Stacks[aSourceStack].Last;
          var target: TStackId;
          if FindTableauTarget(c, Table, target) then
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

function TKlondikeGame.GetNextHint(out aMove: TMove): Boolean;
begin
  Result := False;
end;

procedure TKlondikeGame.InitializeGame(aDeck: TCardStack);
begin
  inherited;
  Restart;
end;

function TKlondikeGame.IsWon: Boolean;
begin
  for var suit := Low(TCardSuit) to High(TCardSuit) do
    if (not Table.Foundation[suit].HasCards) or (Table.Foundation[suit].Last.Value <> cvKing) then
      Exit(False);

  Result := True;
end;

procedure TKlondikeGame.Redo;
begin
  //
end;

procedure TKlondikeGame.Undo;
begin
  //
end;

procedure TKlondikeGame.ResetHints;
begin
  fHintMoves.Clear;
  fHintIndex := -1;
end;

procedure TKlondikeGame.Restart;
begin
  ResetHints;

  fSnapshotManager.Clear;
  fUndoStack.Clear;
  fRedoStack.Clear;
  fMoveCount := 0;

  Table.BeginUpdate;
  try
    TDealer.Deal(fStartingDeck, Table);
  finally
    Table.EndUpdate;
  end;
end;

end.
