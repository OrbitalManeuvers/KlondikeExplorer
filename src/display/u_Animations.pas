unit u_Animations;

interface

uses System.Diagnostics, System.TimeSpan, System.Skia,
  u_AnimationTypes;

type
  TAnimation = class(TInterfacedObject, IAnimation)
  private
    fState: TAnimationState;
    fStopwatch: TStopwatch;
    procedure CheckComplete;
  protected
    function GetDuration: Cardinal; virtual; abstract;  // ms, each descendant defines
    function Progress: Double;
    function Elapsed: Int64;
    procedure Draw(aCanvas: ISkCanvas); virtual; abstract;
    function GetCompletionActions: TCompletionActions;
  public
    CompletionActions: TCompletionActions;
    procedure Start;
    function State: TAnimationState;
  end;

implementation


{ TAnimation }

procedure TAnimation.Start;
begin
  fState := asRunning;
  fStopwatch := TStopwatch.StartNew;
end;

function TAnimation.State: TAnimationState;
begin
  Result := fState;
end;

function TAnimation.Elapsed: Int64;
begin
  Result := fStopWatch.ElapsedMilliseconds;
  CheckComplete;
end;

function TAnimation.GetCompletionActions: TCompletionActions;
begin
  Result := Self.CompletionActions;
end;

function TAnimation.Progress: Double;
begin
  if fState = asComplete then
    Exit(1.0);

  Result := fStopwatch.ElapsedMilliseconds / GetDuration;
  if Result >= 1.0 then
    Result := 1.0;
  CheckComplete;
end;

procedure TAnimation.CheckComplete;
begin
  if (fState = asRunning) and (fStopwatch.ElapsedMilliseconds >= GetDuration) then
    fState := asComplete;
end;

end.
