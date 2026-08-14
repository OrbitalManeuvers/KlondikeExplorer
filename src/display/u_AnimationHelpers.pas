unit u_AnimationHelpers;

interface

uses System.Diagnostics, System.Math;

type
  TCycler = record
  private
    fStopwatch: TStopwatch;
    fRangeLow: Single;
    fRangeHigh: Single;
    fPeriodMS: Int64;

  public
    procedure Init(aPeriodMS: Int64; aRangeLow, aRangeHigh: Single; aStopwatch: TStopwatch);
    procedure InitHz(aHertz: Integer; aRangeLow, aRangeHigh: Single; aStopwatch: TStopwatch);
    function Value: Single;
  end;

implementation

uses System.SysUtils;

{ TCycler }

procedure TCycler.Init(aPeriodMS: Int64; aRangeLow, aRangeHigh: Single; aStopwatch: TStopwatch);
begin
  Assert(aPeriodMS > 0);

  fStopwatch := aStopwatch;
  fPeriodMS := aPeriodMS;
  fRangeLow := aRangeLow;
  fRangeHigh := aRangeHigh;
end;

procedure TCycler.InitHz(aHertz: Integer; aRangeLow, aRangeHigh: Single; aStopwatch: TStopwatch);
begin
  Assert(aHertz > 0);
  Init(Round(1000 / aHertz), aRangeLow, aRangeHigh, aStopwatch);
end;

function TCycler.Value: Single;
begin
  if fPeriodMS <= 0 then
    Exit(fRangeLow);

  var cyclePhase := (fStopwatch.ElapsedMilliseconds mod fPeriodMS) / fPeriodMS;
  var wave := (1.0 + Sin(2.0 * PI * cyclePhase - PI / 2.0)) / 2.0;
  Result := fRangeLow + (fRangeHigh - fRangeLow) * wave;
end;

end.
