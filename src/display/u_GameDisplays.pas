unit u_GameDisplays;

interface

uses u_TableDisplays, u_AnimationTypes;

type
  TGameDisplay = class(TTableDisplay)
  private
    fAnimation: IAnimation;

  public
    property Animation: IAnimation read fAnimation write fAnimation;
  end;

implementation

end.
