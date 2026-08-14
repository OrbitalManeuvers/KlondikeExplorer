unit u_AnimationTypes;

interface

uses System.Skia;

type
  TAnimationState = (asRunning, asComplete);
  TCompletionAction = (caUpdateDisplay);
  TCompletionActions = set of TCompletionAction;

  IAnimation = interface
    procedure Start;
    procedure Draw(aCanvas: ISkCanvas);
    function State: TAnimationState;
    function GetCompletionActions: TCompletionActions;
  end;

implementation

end.
