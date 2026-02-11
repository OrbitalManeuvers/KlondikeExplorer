unit u_Shufflers;

interface

uses System.Classes,

  u_Types,
  u_CardStacks;

type
  { standard randomize shuffle }
  TShuffler = class
  public
    class procedure Shuffle(aStack: TCardStack);
  end;

implementation

uses System.SysUtils;

{ TShuffler }

class procedure TShuffler.Shuffle(aStack: TCardStack);
var
  shuffles: Integer;
  loopIndex: Integer;
  randomIndex: Integer;
  temp: TCard;
begin
  shuffles := 1 + Random(3);

  aStack.BeginUpdate;
  try
    while shuffles > 0 do
    begin
      // for each position
      for loopIndex := aStack.Count - 1 downto 0 do
      begin
        randomIndex := Random(loopIndex + 1);
        if randomIndex <> loopIndex then
        begin
          temp := aStack.Cards[randomIndex];
          aStack.Cards[randomIndex] := aStack.Cards[loopIndex];
          aStack.Cards[loopIndex] := temp;
        end;
      end;
      Dec(shuffles);
    end;
  finally
    aStack.EndUpdate;
  end;
end;


end.
