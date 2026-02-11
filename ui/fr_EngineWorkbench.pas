unit fr_EngineWorkbench;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,

  fr_ContentFrame,
  u_Types,
  u_Tables,
  u_SnapshotManagers,
  u_StateManagers,
  u_SeedLibraries,
  u_SnapshotLibraries,
  u_SnapshotTokens,

  fr_States,
  fr_Moves,
  fr_Table;

type
  TEngineWorkbench = class(TContentFrame)
    GridPanel: TGridPanel;
  private
    StateManager: TStateManager;
    Table: TTable;

    StateFrame: TStateFrame;
    MovesFrame: TMovesFrame;
    TableFrame: TTableFrame;

//    procedure Log(const aMsg: string);

    { state handling }
    procedure HandleStateSelected(Sender: TObject);
    procedure HandleExpandState(Sender: TObject);
    procedure HandleMoveSelected(Sender: TObject);
    procedure HandleSaveSnapshot(Sender: TObject);
    procedure ClearState;
    procedure CreateInitialState;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InitContent; override;
    procedure DoneContent; override;

    procedure SessionReset(aSnapshot: TSnapshotToken); override;
  end;

implementation

{$R *.dfm}

uses System.IOUtils, System.JSON,

  u_Shufflers,
  u_Dealers,
  u_CardStacks,
  u_Snapshots,
  u_Moves.Render;

{ TEngineWorkbench }

{$region 'CreateDestroy'}
constructor TEngineWorkbench.Create(AOwner: TComponent);
begin
  inherited;

end;

procedure TEngineWorkbench.InitContent;
begin
  inherited;

  Table := TTable.Create;
  StateManager := TStateManager.Create(SnapshotServices);

  // create views
  GridPanel.DisableAlign;
  try
    StateFrame := TStateFrame.Create(Self);
    GridPanel.ColumnCollection[0].Value := StateFrame.Width + 2;
    StateFrame.Align := alClient;
    StateFrame.Parent := GridPanel;
    StateFrame.StateManager := StateManager;
    StateFrame.OnStateSelected := HandleStateSelected;
    StateFrame.OnExpandState := HandleExpandState;

    MovesFrame := TMovesFrame.Create(Self);
    GridPanel.ColumnCollection[1].Value := MovesFrame.Width;
    MovesFrame.Align := alClient;
    MovesFrame.Parent := GridPanel;
    MovesFrame.OnSelectionChange := HandleMoveSelected;

    TableFrame := TTableFrame.Create(Self);
    TableFrame.Align := alClient;
    TableFrame.Parent := GridPanel;
    TableFrame.btnSaveSnapshot.OnClick := HandleSaveSnapshot;

  finally
    GridPanel.EnableAlign;
  end;
end;

procedure TEngineWorkbench.DoneContent;
begin
  StateManager.Free;
  Table.Free;
  inherited;
end;

destructor TEngineWorkbench.Destroy;
begin
  inherited;
end;

//procedure TEngineWorkbench.Log(const aMsg: string);
//begin
//  if Assigned(fOnLog) then
//    fOnLog(Self, aMsg);
//end;

procedure TEngineWorkbench.SessionReset(aSnapshot: TSnapshotToken);
begin
  inherited;

  ClearState;

  // now we populate the initial table, either from a snapshot, or shuffle

  if aSnapshot <> NO_SNAPSHOT then
  begin
    // fetch and restore to table
    var s := TSnapshot.Create;
    try
      SnapshotServices.Load(aSnapshot, s);
      Table.BeginUpdate;
      try
        s.Restore(Table);
      finally
        Table.EndUpdate;
      end;
    finally
      S.Free;
    end;
  end
  else
  begin
    // start a new deal
    var deck := TCardStack.Create;
    try
      TDealer.PopulateNewDeck(deck);

      // shuffle
      TShuffler.Shuffle(deck);

      // deal
      Table.BeginUpdate;
      try
        Table.Clear;
        TDealer.Deal(deck, Table);
      finally
        Table.EndUpdate;
      end;

    finally
      deck.Free;
    end;

  end;

  CreateInitialState;
end;

{$endregion}

{$region 'StateHandling'}

procedure TEngineWorkbench.ClearState;
begin
  StateFrame.Clear;
  StateManager.Clear;
  MovesFrame.Clear;
  TableFrame.Clear;
  Log('State cleared');
end;

procedure TEngineWorkbench.CreateInitialState;
begin
  StateManager.CreateInitialState(Table);
  StateFrame.SelectRoot;
  Log('New initial state');
end;

procedure TEngineWorkbench.HandleSaveSnapshot(Sender: TObject);
var
  snapshotName: string;
begin
  if not Assigned(StateFrame.ActiveState) then
    Exit;

  snapshotName := StateFrame.ActiveState.Name;
  if SnapshotServices.GetLibrarySaveName(snapshotName) then
  begin

    var token: TSnapshotToken;
    var s := TSnapshot.Create;
    try
      s.Capture(Table);
      token := SnapshotServices.Save(s);
    finally
      s.Free;
    end;

    SnapshotServices.SaveToLibrary(snapshotName, token);
  end;

end;

procedure TEngineWorkbench.HandleStateSelected(Sender: TObject);
begin

  var state := StateFrame.ActiveState;
  if Assigned(state) then
  begin

    // the state of the active node goes into the viewers
    Table.BeginUpdate;
    try
      StateManager.ApplyState(state, Table);
    finally
      Table.EndUpdate;
    end;

    // update the views
    MovesFrame.LoadFrom(state.Evaluations);
    TableFrame.LoadFrom(Table, state.Evaluations.ValidMoveCount);
  end;
end;

procedure TEngineWorkbench.HandleExpandState(Sender: TObject);
begin
  Assert(Assigned(StateFrame.ActiveState));

  // spawn child states from active state
  var node := StateFrame.ActiveState;
  for var i := 0 to node.Evaluations.Count - 1 do
  begin
    if not node.HasChild(i) then
    begin
      var desc := node.Evaluations[i].Move.Description;
      StateManager.CreateNewState(node, i, desc);
    end;
  end;
end;

procedure TEngineWorkbench.HandleMoveSelected(Sender: TObject);
begin
  if (MovesFrame.SelectedIndex <> -1) and Assigned(StateFrame.ActiveState) then
  begin
    var m := StateFrame.ActiveState.Evaluations[MovesFrame.SelectedIndex].Move;
    if m.Count > -1 then
      TableFrame.HighlightMove(m);
  end
  else
  begin
    TableFrame.ResetHighlight;
  end;
end;

{$endregion}



end.
