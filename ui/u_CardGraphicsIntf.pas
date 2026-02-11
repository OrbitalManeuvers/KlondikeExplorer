unit u_CardGraphicsIntf;

interface

uses Vcl.Graphics, System.Types,
  u_Types;


type
  ICardGraphics = interface
  ['{756B50AA-FBC6-4180-9A5B-BD8375AA5CCD}']
    function GetCardSize: TSize;
    procedure Draw(c: TCard; faceUp: Boolean; where: TPoint; target: TCanvas; debugMode: Boolean);

  end;


implementation

end.
