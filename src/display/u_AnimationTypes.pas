unit u_AnimationTypes;

interface

uses System.Skia;

type
  TAnimationState = (asRunning, asComplete);

  IAnimation = interface
    procedure Start;
    procedure Draw(aCanvas: ISkCanvas);
    function State: TAnimationState;
  end;

implementation

end.
