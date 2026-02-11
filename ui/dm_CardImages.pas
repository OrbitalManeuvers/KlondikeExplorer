unit dm_CardImages;

interface

uses
  System.SysUtils, System.Classes, System.ImageList, Vcl.ImgList, Vcl.Controls,
  Vcl.Graphics, System.Types,
  PngImageList,

  u_Types,
  u_CardGraphicsIntf;

type
  TdmCardImages = class(TDataModule, ICardGraphics)
    imgBlackCardValues: TPngImageList;
    imgRedCardValues: TPngImageList;
    imgSuitFaces: TPngImageList;
    imgBlackCardValues2: TPngImageList;
    imgRedCardValues2: TPngImageList;
    imgSuitFaces2: TPngImageList;
  private
    { interface methods }
    procedure Draw(c: TCard; faceUp: Boolean; where: TPoint; target: TCanvas; debugMode: Boolean);
    function GetCardSize: TSize;
  private
  public
    destructor Destroy; override;
    procedure DrawCard(C: TCard; X, Y: Integer; aTarget: TCanvas);
    procedure DrawBack(X, Y: Integer; aTarget: TCanvas);
    property CardSize: TSize read GetCardSize;
  end;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

uses
  u_Cards;

const
  VALUE_OFFSET: TPoint = (X: 3; Y: 2);


{ TdmCardImages }

destructor TdmCardImages.Destroy;
begin

  inherited;
end;

procedure TdmCardImages.Draw(c: TCard; faceUp: Boolean; where: TPoint; target: TCanvas; debugMode: Boolean);
begin
  if (not faceUp) and (not debugMode) then
    DrawBack(where.x, where.Y, target)
  else
    DrawCard(c, where.x, where.y, target);
end;

procedure TdmCardImages.DrawBack(X, Y: Integer; aTarget: TCanvas);
begin
  imgSuitFaces2.Draw(aTarget, X, Y, 4);
end;

procedure TdmCardImages.DrawCard(C: TCard; X, Y: Integer; aTarget: TCanvas);
begin
  // first draw the card suit
  var i := Ord(C.Suit);
  imgSuitFaces2.Draw(aTarget, X, Y, i);

  // then the value
  var list: TPNGImageList;
  if C.Color = ccBlack then list := imgBlackCardValues2
  else list := imgRedCardValues2;
  list.Draw(aTarget, X + VALUE_OFFSET.X, Y + VALUE_OFFSET.Y, Ord(C.Value));
end;

function TdmCardImages.GetCardSize: TSize;
begin
  Result.cx := imgSuitFaces2.Width;
  Result.cy := imgSuitFaces2.Height;
end;

end.
