unit u_HitTesters;

interface

uses System.Types,
  u_Types, u_Layouts, u_Tables;

type
  THitInfo = record
    Valid: Boolean;
    StackId: TStackId;
    CardIndex: Integer;      // index within the stack (-1 for empty stack click)
    IsFaceUp: Boolean;
  end;

  THitTester = class
    class function GetHitInfo(const Layout: TLayout; Table: TTable; MousePos: TPointF): THitInfo;
  end;

implementation

{ THitTester }

class function THitTester.GetHitInfo(const Layout: TLayout; Table: TTable; MousePos: TPointF): THitInfo;
begin
  //

end;

end.
