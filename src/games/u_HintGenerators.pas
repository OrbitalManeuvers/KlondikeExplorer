unit u_HintGenerators;

interface

uses u_Tables, u_MoveLists;

type
  THintGenerator = class
    class procedure GenerateHints(aTable: TTable; aMoveList: TMoveList);
  end;

implementation

uses u_Types, u_CardHelpers, u_MoveHelpers, u_MoveGenerators, u_MoveValidators,
  u_TableUtils;

{ THintGenerator }

(*
  - hint logic limited to face up cards

  - context aware on potentially cyclic moves
  - look-ahead considerations: king pressure on tableau
  - face up Ace uncovering moves


*)

class procedure THintGenerator.GenerateHints(aTable: TTable; aMoveList: TMoveList);
begin
  var scratch := TMoveList.Create;
  try
    TMoveGenerator.GenerateMoves(aTable, scratch);

    var info := TMoveInfo.Create(aTable);
    try
      // evaluate each move
      for var i := 0 to scratch.Count - 1 do
      begin

        var m := scratch.Moves[i];
        if TMoveValidator.IsValidMove(m, aTable) then
        begin
          var includeMove := m.Source <> siStock;
          if not includeMove then
            Continue;

          info.Load(m);

          var moveType := info.MoveType;
          case moveType of
            mtTableauToTableau:
              begin

                // see what's being uncovered by the move
                if (info.Source.Stack.FaceUpCount > info.MoveCount) then  // what's left still has face up cards
                begin
                  var s := info.Source.Stack;

                  //  0  1  2  3  4  5
                  //  ?? ?? 8H 7C 6D 5S
                  // stack.count = 6
                  // stack.faceUpCount = 4
                  // m.MoveCount = 3, new firstFaceUpIndex = 2, i.e. stack.Count - m.MoveCount - 1
                  // only safe when FaceUpCount > MoveCount
                  var uncoveredCard := s.Cards[s.Count - info.MoveCount - 1];

                  // see if the target has the twin on top
                  if info.Target.Stack.HasCards then
                  begin
                    var targetCard := info.Target.Stack.Last;
                    if targetCard.IsTwin(uncoveredCard) then
                    begin

                      // this only makes sense if the uncovered card is next for its foundation
                      includeMove := uncoveredCard.Value = info.NextFoundation[uncoveredCard.Suit];
                    end;
                  end;
                end;

                // moving an entire tableau stack to another tableau isn't really progress
                // unless there's a King waiting
                if includeMove and (info.MoveCount = info.Source.Stack.Count) then
                begin
                  var faceUpKing := aTable.Waste.HasCards and (aTable.Waste.Last.Value = cvKing);
                  if not faceUpKing then
                  begin
                    // search tableaus
                    for var stackId := siTableau1 to siTableau7 do
                    begin
                      if (stackId <> m.Source) and (aTable.Stacks[stackId].FaceUpCount > 0) then
                      begin
                        var stack := aTable.Stacks[stackId];
                        for var index := stack.Count - stack.FaceUpCount to stack.Count - 1 do
                        begin
                          if stack.Cards[index].Value = cvKing then
                          begin
                            includeMove := True;
                            Break;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;

              end;

          end;

          if includeMove then
            aMoveList.Add(m);

        end;
      end;
    finally
      info.Free;
    end;

  finally
    scratch.Free;
  end;

end;

end.
