unit fr_Table;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Types, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,

  u_Tables,
  u_TableViewers,
  dm_CardImages,
  u_CardGraphicsIntf,
  u_Types;

type
  TTableFrame = class(TFrame)
    lblTable: TLabel;
    shpPlaceholder: TShape;
    btnTableMode: TSpeedButton;
    btnSaveSnapshot: TSpeedButton;
    edtHValue: TEdit;
    lblHValue: TLabel;
    procedure btnTableModeClick(Sender: TObject);
  private
    Images: TdmCardImages;
    Viewer: TTableViewer;
    Table: TTable;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFrom(aTable: TTable; aMoveCount: Integer);
    procedure HighlightMove(aMove: TMove);
    procedure ResetHighlight;
    procedure Clear;

  end;

implementation

uses System.IOUtils, System.UITypes, System.StrUtils,

  u_Heuristics;

{$R *.dfm}

constructor TTableFrame.Create(AOwner: TComponent);
begin
  inherited;
  Images := TdmCardImages.Create(AOwner);

  shpPlaceholder.Visible := False;
  Viewer := TTableViewer.Create(Self, Images);
  Viewer.Parent := Self;
  Viewer.BoundsRect := shpPlaceholder.BoundsRect;
  Viewer.Anchors := shpPlaceholder.Anchors;
end;

procedure TTableFrame.btnTableModeClick(Sender: TObject);
begin
  Viewer.DebugMode := not Viewer.DebugMode;
  btnTableMode.Caption := IfThen(Viewer.DebugMode, 'Debug', 'Normal');
end;

procedure TTableFrame.Clear;
begin
  ResetHighlight;
end;

procedure TTableFrame.HighlightMove(aMove: TMove);
begin
  Viewer.HighlightMove(aMove);
end;

procedure TTableFrame.ResetHighlight;
begin
  Viewer.ClearMove;
end;

procedure TTableFrame.LoadFrom(aTable: TTable; aMoveCount: Integer);
begin
  Table := ATable;

  var HValue := THeuristic.Calculate(Table, aMoveCount);
  edtHValue.Text := HValue.ToString;

  Viewer.LoadFrom(Table);
end;


end.
