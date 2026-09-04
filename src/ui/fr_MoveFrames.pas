unit fr_MoveFrames;

interface

uses System.Generics.Collections,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  Vcl.ControlList, Vcl.StdCtrls,

  u_Types, u_StateManagers;

type
  TMoveSelectedEvent = procedure(Sender: TObject; aMoveIndex: Integer) of object;

  TMoveFrame = class(TContentFrame)
    lblTitle: TLabel;
    MovesList: TControlList;
    lblMoveName: TLabel;
    lblHValue: TLabel;
    procedure MovesListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas; ARect: TRect;
      AState: TOwnerDrawState);
    procedure MovesListItemClick(Sender: TObject);
  private type
    TMoveRow = record
      Caption: string;
      Executed: Boolean;
      hValue: Single;
    end;
  private
    fRows: TList<TMoveRow>;
    fOnMoveSelected: TMoveSelectedEvent;
    procedure Clear;
  public
    procedure InitContent; override;
    procedure DoneContent; override;
    procedure HandleCursorChange(aNode: TStateNode); override;

    property OnMoveSelected: TMoveSelectedEvent read fOnMoveSelected write fOnMoveSelected;
  end;


implementation

{$R *.dfm}

uses u_MoveHelpers;

{ TMoveFrame }

procedure TMoveFrame.InitContent;
begin
  inherited;
  fRows := TList<TMoveRow>.Create;
  Clear;
end;

procedure TMoveFrame.DoneContent;
begin
  MovesList.ItemCount := 0;
  fRows.Free;
  inherited;
end;

procedure TMoveFrame.MovesListBeforeDrawItem(AIndex: Integer; ACanvas: TCanvas; ARect: TRect;
  AState: TOwnerDrawState);
begin
  // todo: color

  if (AIndex >= 0) and (AIndex < fRows.Count) then
  begin
    var row := fRows[AIndex];
    lblMoveName.Caption := row.Caption;
    if row.Executed then
      lblHValue.Caption := Format('%f', [row.hValue])
    else
      lblHValue.Caption := '';
  end;
end;

procedure TMoveFrame.MovesListItemClick(Sender: TObject);
begin
  if (MovesList.ItemCount > 0) and (MovesList.ItemIndex >= 0) and Assigned(fOnMoveSelected) then
    fOnMoveSelected(Self, MovesList.ItemIndex);
end;

procedure TMoveFrame.Clear;
begin
  fRows.Clear;
  MovesList.ItemIndex := -1;
  MovesList.ItemCount := 0;
end;

procedure TMoveFrame.HandleCursorChange(aNode: TStateNode);
begin
  inherited;
  Clear;

  for var moveIndex := 0 to aNode.Moves.Count - 1 do
  begin
    var m := aNode.Moves[moveIndex];
    var row := Default(TMoveRow);
    row.Caption := m.AsText;

    var childNode := aNode.ChildForMove(moveIndex);
    row.Executed := Assigned(childNode);
    if row.Executed then
      row.hValue := childNode.HValue - aNode.HValue;

    fRows.Add(row);
  end;

  MovesList.ItemCount := fRows.Count;
end;

end.
