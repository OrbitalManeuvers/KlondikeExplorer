unit u_Animations;

interface

uses System.Diagnostics, System.TimeSpan, System.Skia,
  u_AnimationTypes;

type
  TAnimation = class(TInterfacedObject, IAnimation)
  private
    fState: TAnimationState;
    fStopwatch: TStopwatch;
  protected
    function GetDuration: Cardinal; virtual; abstract;  // ms, each descendant defines
    function Progress: Double;
    procedure Draw(aCanvas: ISkCanvas); virtual; abstract;
  public
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

function TAnimation.Progress: Double;
begin
  if fState = asComplete then
    Exit(1.0);

  Result := fStopwatch.ElapsedMilliseconds / GetDuration;
  if Result >= 1.0 then
  begin
    Result := 1.0;
    fState := asComplete;
  end;
end;

end.
