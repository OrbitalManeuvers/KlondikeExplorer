unit u_UnitTests;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,

  u_Types,
  u_Cards,
  u_CardStacks,
  u_Tables,
  u_Tables.Render,
  u_Snapshots,
  u_SnapshotTokens
  ;

type
  TTestResult = (trNone, trPass, trFail, trExecuted);

  TUnitTest = class
  private
    fResults: TStrings;
    fTable: TTable;
    function GetStatus: string;
  protected
    TestResult: TTestResult;
    procedure Log(const S: string); overload;
    procedure Log(const aKey, aValue: string); overload;
    procedure LogBlank;
    procedure LogLine;
    procedure LogSection(const aName: string); overload;
    procedure LogSection(const aName, aValue: string); overload;

    class function GetName: string; virtual; abstract;

    procedure LogType(aName: string; aTable: TTable); overload;
//    procedure LogType(aName: string; aMoveList: TMoveList); overload;
//    procedure LogType(aName: string; aEvalList: TEvalList); overload;
//    procedure LogType(aName: string; aStack: TCardStack); overload;
//    procedure LogType(aName: string; aMove: TMove); overload;
//    function TableToStr(aTable: TTable): string;

    property Table: TTable read fTable;

  public
    constructor Create;
    destructor Destroy; override;
    procedure Run; virtual;

    class function TestName: string;
    property Results: TStrings read fResults;
    property Status: string read GetStatus;
  end;

  TUnitTestClass = class of TUnitTest;


  { TRenderTest }
  TRenderTest = class(TUnitTest)
  protected
    class function GetName: string; override;
  public
    procedure Run; override;
  end;

  { TMoveTest }
  TMoveTest = class(TUnitTest)
  protected
    class function GetName: string; override;
  public
    procedure Run; override;
  end;

  { TSnapshotTest }
  TSnapshotTest = class(TUnitTest)
  protected
    class function GetName: string; override;
  public
    procedure Run; override;
  end;

  { TSnapshotStorageTest }
  TSnapshotStorageTest = class(TUnitTest)
  protected
    class function GetName: string; override;
  public
    procedure Run; override;
  end;

  { TStorageStatsTest }
  TStorageStatsTest = class(TUnitTest)
  protected
    class function GetName: string; override;
  public
    procedure Run; override;
  end;


implementation

uses
  u_Dealers,
  u_Shufflers,
  u_SnapshotManagers,
  u_SnapshotStorage;

//function RandomSuit: TCardSuit;
//begin
//  Result := TCardSuit( Random(Ord(High(TCardSuit))) );
//end;
//
//function RandomValue: TCardValue;
//begin
//  Result := TCardValue( Random(Ord(High(TCardValue))) );
//end;
//
//function RandomCard: TCard;
//begin
//  Result := NewCard(RandomSuit(), RandomValue());
//end;


//type
//  TStatsHelper = record helper for TMemoryStats
//    function AsText: string;
//  end;
//
//function TStatsHelper.AsText: string;
//begin
//(*
//  TStats = record
//    History: record
//      Allocations: Cardinal;    // how many allocations have been done
//      Releases: Cardinal;       // how many allocations have been released
//      BlocksCreated: Cardinal;  // times a new block was created
//      BlocksCulled: Cardinal;   // excess blocks getting freed
//      RecycledUsed: Cardinal;   // pulled a block out of recycle list
//      PartialUsed: Cardinal;    // pulled a block out of partial list
//    end;
//    Lists: record
//      TotalBlocks: Cardinal;  // how many blocks exist
//      RecycleQueue: Cardinal; // available for recycle right now
//      PartialQueue: Cardinal;
//    end;
//  end;
//*)
//  var fmt := 'H:[A:%d R:%d BC:%d BX:%d RU:%d PU:%d] L:[TB:%d RQ:%d PQ:%d]';
//  Result := Format(fmt, [
//    History.Allocations,
//    History.Releases,
//    History.BlocksCreated,
//    History.BlocksCulled,
//    History.RecycledUsed,
//    History.PartialUsed,
//    Lists.TotalBlocks,
//    Lists.RecycleQueue,
//    Lists.PartialQueue
//  ]);
//end;


{ TUnitTest }
constructor TUnitTest.Create;
begin
  inherited Create;
  fResults := TStringList.Create;
  fTable := TTable.Create;
end;

destructor TUnitTest.Destroy;
begin
  fResults.Free;
  fTable.Free;
  inherited;
end;

function TUnitTest.GetStatus: string;
const
  codes: array[TTestResult] of string = (
    '',
    'Pass',
    'Fail',
    'Completed'
  );
begin
  Result := codes[TestResult];
end;

procedure TUnitTest.Log(const S: string);
begin
  fResults.Add(S);
end;

procedure TUnitTest.Log(const aKey, aValue: string);
begin
  fResults.Add(aKey + ': ' + aValue);
end;

procedure TUnitTest.LogBlank;
begin
  Log('');
end;

procedure TUnitTest.LogLine;
begin
  Log('-----------------------------------------');
end;

procedure TUnitTest.LogSection(const aName, aValue: string);
begin
  LogSection(aName);
  Log(aValue);
end;

procedure TUnitTest.Run;
begin
  LogSection(TestName);
  TestResult := trExecuted;
end;

class function TUnitTest.TestName: string;
begin
  Result := GetName();
end;

procedure TUnitTest.LogSection(const aName: string);
begin
  if fResults.Count <> 0 then
    Logblank;
  Log(aName);
  Logline;
end;

procedure TUnitTest.LogType(aName: string; aTable: TTable);
begin
  Log(aName, Table.AsCompact);
end;


{ TRenderTest }

class function TRenderTest.GetName: string;
begin
  Result := 'Basic Render Tests';
end;

procedure TRenderTest.Run;
begin
  inherited;
end;

{ TMoveTest }

class function TMoveTest.GetName: string;
begin
  Result := 'Basic Move Tests';
end;

procedure TMoveTest.Run;
begin
  inherited;
end;

{ TSnapshotTest }

class function TSnapshotTest.GetName: string;
begin
  Result := 'Snapshot Tests';
end;

procedure TSnapshotTest.Run;
const
  k_orig_table = 'orig-tab';
  k_orig_sn = 'orig-sn';
  k_changed_table = 'changed-tab';
  k_restored_table = 'restored-tab';
  k_stored_sn = 'stored-sn';
  k_stored_table = 'stored-tab';
var
  values: TStrings;
begin
  inherited;

  TestResult := trFail;

  var deck := TCardStack.Create;
  try

    values := TStringList.Create(dupAccept, False, False);
    try

      // set up and log table
      TDealer.PopulateNewDeck(deck);
      TShuffler.Shuffle(deck);
      TDealer.Deal(deck, Table);
      values.Values[k_orig_table] := Table.AsCompact;

      // save original as snapshot
      var sn := TSnapshot.Create;
      try
        sn.Capture(Table);

        // log snapshot contents
        values.Values[k_orig_sn] := sn.AsText;

        // re-populate and re-shuffle deck
        TDealer.PopulateNewDeck(deck);
        TShuffler.Shuffle(deck);
        TDealer.Deal(deck, Table);

        // log changed table
        values.Values[k_changed_table] := Table.AsCompact;

        // confrim the table has changed
        if values.Values[k_changed_table] = values.Values[k_orig_table] then
        begin
          Log('Changed table has not changed.');
          Exit;
        end
        else log('Table change confirmed');

        // now restore/log the table using the snapshot
        sn.Restore(Table);
        values.Values[k_restored_table] := Table.AsCompact;

        // check restored table
        if values.Values[k_orig_table] <> values.Values[k_restored_table] then
        begin
          values.Add('Restored table does not compare');
          Exit;
        end;

// --
(*
        // test snapshot manager service
        if not Assigned(Self.SnapshotManager) then
        begin
          Log('** No SnapshotManager instance **');
          Exit;
        end;

        // put the snapshot into storage
        var snapshotToken := SnapshotManager.SaveSnapshot(sn);
        if snapshotToken = INVALID_SNAPSHOT then
        begin
          Log('Failed to store snapshot');
          Exit;
        end
        else Log('Stored snapshot.');

        // clear the table and try to restore from a new snapshot
        Table.Clear;

        var newSN := TSnapshot.Create;
        try
          SnapshotManager.LoadSnapshot(snapshotToken, newSN);
          Log('Loaded new snapshot');

          // the snapshot should come back the same as the original
          stream.Init(newSN.Buffer);
          values.Values[k_stored_sn] := stream.BufferAsText;

          if values.Values[k_orig_sn] <> values.Values[k_stored_sn] then
          begin
            Log('Failed to retrieve snapshot from storage');
            Exit;
          end;

          // put this back into the table and log
          newSN.Restore(Table);
          values.Values[k_stored_table] := Table.AsCompact;

          if values.Values[k_orig_table] <> values.Values[k_stored_table] then
          begin
            Log('Restored table failed to compare');
            Exit;
          end;

        finally
          newSN.Free;
        end;
*)
// --

      finally
        sn.Free;
      end;

    finally
      fResults.AddStrings(values);
      values.Free;
    end;
  finally
    deck.Free;
  end;

  TestResult := trPass;
end;



{ TSnapshotStorageTest }

class function TSnapshotStorageTest.GetName: string;
begin
  Result := 'Storage Tests';
end;

procedure TSnapshotStorageTest.Run;
var
  mgr: TSnapshotManager;
  tokens: TList<TSnapshotToken>;

  procedure _randomDeal(aTable: TTable);
  begin
    var deck := TCardStack.Create;
    try
      TDealer.PopulateNewDeck(deck);
      TShuffler.Shuffle(deck);
      TDealer.Deal(deck, aTable); // clears first
    finally
      deck.Free;
    end;
  end;

  procedure _stats(s: TStrings);
  begin
    s.add('mem: ' + mgr.Storage.Stats.AsText);
  end;

begin
  inherited;
  TestResult := trFail;

  // all allocated tokens
  tokens := TList<TSnapshotToken>.Create;
  try
    // snapshot manager
    mgr := TSnapshotManager.Create;
    try
      // list to keep track of snapshot textified images
      var strings := TStringList.Create(dupAccept, False, False);
      try

{$region 'Capture and Restore'}

        // Capture and restore a table using snapshots
        LogSection('Basic capture and restore');

        strings.Clear;
        begin
          var table := TTable.Create;
          try
            _randomDeal(table);

            // save the table as a simple, easy to compare string
            strings.Values['t-before'] := table.AsCompact;

            var token: TSnapshotToken;

            // capture the table
            var capture := TSnapshot.Create;
            try
              capture.Capture(table);

              _stats(strings);
              token := mgr.Save(capture);
              _stats(strings);

              // supposedly this snapshot captured the table
              strings.Values['s-captured'] := capture.AsText;
            finally
              capture.Free;
            end;

            // now we can clear the table and retrieve the snapshot to restore the table
            table.Clear;

            var restore := TSnapshot.Create;
            try
              mgr.Load(token, restore);
              strings.Values['s-restored'] := restore.AsText;
              restore.Restore(table);
              strings.Values['t-after'] := table.AsCompact;
            finally
              restore.Free;
            end;

            // sum up the results
            if strings.Values['t-before'] = strings.Values['t-after'] then
              strings.add('>> tables match')
            else
            begin
              strings.Add('>> tables DO NOT match');
              TestResult := trFail;
            end;

            if strings.Values['s-captured'] = strings.Values['s-restored'] then
              strings.Add('>> snapshots match')
            else
            begin
              strings.add('>> snapshot DID NOT store or load correctly');
              TestResult := trFail;
            end;

            mgr.Delete(token);
            strings.add('after deleting snapshot:');
            _stats(strings);

            Log(strings.Text);

          finally
            table.Free;
          end;
        end;
{$endregion}

        begin

        end;

      finally
        strings.Free;
      end;

    finally
      mgr.Free;
    end;
  finally
    tokens.Free;
  end;

  TestResult := trPass;
end;



{ TStorageStatsTest }

class function TStorageStatsTest.GetName: string;
begin
  Result := 'Storage Stress/Stats';
end;

procedure TStorageStatsTest.Run;
const
  TARGET_COUNT = 100;
var
  store: TSnapshotStorage;
  tokens: TList<TSnapshotToken>;

  procedure stats(where: string);
  begin
    log(where, store.Stats.AsText);
  end;

  procedure allocate(acount: Integer);
  begin
    //
  end;

  procedure select_sequential(var into: array of integer; aCount: Integer);
  begin
    // pick a random index and generate that many numbers
    var startIndex := Random(tokens.count - 1);
    while (startIndex <= tokens.Count - 1) and (aCount > 0) do
    begin
      into[aCount -1] := startIndex;
    end;

  end;

  procedure deallocate(aCount: Integer; sequential: Boolean);
  begin
    var indicies: array of Integer;
    SetLength(indicies, aCount);

    if sequential then
      select_sequential(indicies, aCount);


  end;

begin
  inherited;

  LogSection('Storage Tests');

  store := TSnapshotStorage.Create;
  try
    tokens := TList<TSnapshotToken>.Create;
    try

      stats('start');

(*
  This test allocates TARGET_COUNT units, but does so in a staggered and slightly
  random sequence of allocations/deallocations
*)




    finally
      tokens.Free;
    end;
  finally
    store.Free;
  end;
end;

end.
