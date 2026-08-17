unit u_SnapshotTests;

interface

uses u_TestUnits;

type
  TSnapshotTests = class(TTestUnit)
  protected
    function TestId: string; override;
    procedure ExecuteTest; override;
  end;

implementation

uses System.SysUtils,
  u_Types, u_CardStacks, u_Dealers, u_Shufflers;

{ TSnapshotTests }

procedure TSnapshotTests.ExecuteTest;
begin
  var deck := TCardStack.Create;
  try

    TDealer.PopulateNewDeck(deck);

    // first deal
    TShuffler.Shuffle(deck);
    TDealer.Deal(deck, Table);

    // save and log first
    Snapshot.Capture(Table);
    var beforeToken := SnapshotManager.Save(Snapshot);
    try
      var before := Snapshot.AsText;
      Log('before', before);

      // mutate
      TDealer.PopulateNewDeck(deck);
      TShuffler.Shuffle(deck);
      TDealer.Deal(deck, Table);

      Snapshot.Capture(Table);
      var during := Snapshot.AsText;

      if not SameStr(before, during) then
      begin
        Log('during', 'changed');
        // restore the saved snapshot
        SnapshotManager.Load(beforeToken, Snapshot);
        Snapshot.Restore(Table);

        Snapshot.Capture(Table);
        var after := Snapshot.AsText;
        if SameStr(before, after) then
          Log('after', after)
        else
          LogError('after_err: ' + after);


      end
      else
      begin
        LogError('Table mutation failure');
      end;


    finally
      SnapshotManager.Delete(beforeToken);
    end;



    // log changed



  finally
    deck.Free;
  end;
end;

function TSnapshotTests.TestId: string;
begin
  Result := 'Snapshots';
end;


end.
