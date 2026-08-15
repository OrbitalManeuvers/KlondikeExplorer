unit u_IconResources;

interface

uses System.Types, System.Skia,
  u_Types;

type
  TIconResources = class
  public
    procedure DrawIcon(aCanvas: ISkCanvas; aSuit: TCardSuit; aLocation: TRectF;
      aGhosted: Boolean = False); virtual; abstract;
  end;

implementation

end.
