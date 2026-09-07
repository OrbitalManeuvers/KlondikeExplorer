unit u_SnapshotTests;

interface

uses
  DUnitX.TestFramework;

type
  TSnapshotTests = class
  private
  public
    [Test]
    procedure TestAsText;
  end;

implementation

uses System.Classes, System.SysUtils,
  u_Snapshots, u_Types, u_CardStacks, u_Dealers, u_Shufflers, u_Tables;

{ TSnapshotTests }

procedure TSnapshotTests.TestAsText;
begin

  var table := TTable.Create;
  try

    var deck := TCardStack.Create;
    try
      TDealer.PopulateNewDeck(deck);

      // first deal
      TShuffler.Shuffle(deck);
      TDealer.Deal(deck, Table);

      // capture the first snapshot
      var originalState := TSnapshot.Create;
      try
        originalState.Capture(table);
        var originalState_AsText := originalState.AsText;

        // mutate the table
        Assert.IsTrue(table.Tableau[7].Count = 7);
        table.Tableau[7]._Cards.Exchange(1, 2);
        table.RecycleCount := 1;

        // capture the changed state
        var changedState := TSnapshot.Create;
        try
          changedState.Capture(table);
          var changedState_AsText := changedState.AsText;

          // these two cannot be the same
          Assert.AreNotEqual(originalState_AsText, changedState_AsText);

          // but, if we restore the original ...
          originalState.Restore(table);

          // and recapture it
          changedState.Capture(table);

          // then they must be the same
          changedState_AsText := changedState.AsText;
          Assert.AreEqual(originalState_AsText, changedState_AsText);

        finally
          changedState.Free;
        end;

      finally
        originalState.Free;
      end;

    finally
      deck.Free;
    end;

  finally
    table.Free;
  end;

end;


initialization
  TDUnitX.RegisterTestFixture(TSnapshotTests);


end.
