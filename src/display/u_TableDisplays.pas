unit u_TableDisplays;

interface

uses System.Skia, System.Types,
  u_Types, u_Tables, u_Snapshots;

type
  TTableDisplay = class
  private
    fTable: TTable;
    fSnapshot: TSnapshot;
    fPreviewMode: Boolean;
    procedure AdoptState(aTable: TTable);
  protected
    property PreviewMode: Boolean read fPreviewMode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ClearTable;
    procedure PreviewTable(aTable: TTable);
    procedure UpdateTable(aTable: TTable);

    procedure Draw(aCanvas: ISkCanvas; aSize: TSize); virtual;
  end;

implementation


{ TTableDisplay }

constructor TTableDisplay.Create;
begin
  inherited Create;
  fTable := TTable.Create;
  fSnapshot := TSnapshot.Create;
end;

destructor TTableDisplay.Destroy;
begin
  fTable.Free;
  fSnapshot.Free;
  inherited;
end;

procedure TTableDisplay.Draw(aCanvas: ISkCanvas; aSize: TSize);
begin
  //
end;

procedure TTableDisplay.AdoptState(aTable: TTable);
begin
  // just adopt the contents and next update will show new state
  fSnapshot.Capture(aTable);
  fSnapshot.Restore(fTable);
end;

procedure TTableDisplay.ClearTable;
begin
  fTable.Clear;
end;

procedure TTableDisplay.PreviewTable(aTable: TTable);
begin
  if Assigned(aTable) then
  begin
    AdoptState(aTable);
    fPreviewMode := True;
  end
  else
  begin
    ClearTable;
    fPreviewMode := False;
  end;
end;

procedure TTableDisplay.UpdateTable(aTable: TTable);
begin
  fPreviewMode := False;
  AdoptState(aTable);
end;

end.
