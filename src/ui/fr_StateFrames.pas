unit fr_StateFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  VirtualTrees, Vcl.StdCtrls,

  u_Types, u_StateManagers, u_Authors, VirtualTrees.DrawTree;

type
  TNodeNavigateEvent = procedure(Sender: TObject; aNode: TStateNode) of object;

  TStateFrame = class(TContentFrame)
    lblTitle: TLabel;
    StateTree: TVirtualDrawTree;
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode;
      var InitialStates: TVirtualNodeInitStates);
    procedure TreeInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode;
      var ChildCount: Cardinal);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType; var CellText: string);
    procedure TreeNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
    procedure TreeBeforeCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
      Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode;
      CellRect: TRect; var ContentRect: TRect);
    procedure StateTreeDrawNode(Sender: TBaseVirtualTree; const PaintInfo: TVTPaintInfo);
    procedure StateTreeMeasureItem(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
      Node: PVirtualNode; var NodeHeight: Integer);
    procedure StateTreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
  private
    fStateManager: TStateManager;
    fOnNavigate: TNodeNavigateEvent;
    fUpdatingTree: Boolean;
    procedure SetStateManager(const Value: TStateManager);
    procedure HandleStateChange(Sender: TObject; ParentNode, ChildNode: TStateNode);
    function FindTreeNode(aState: TStateNode): PVirtualNode;
  public
    procedure InitContent; override;
    procedure HandleMoveExecuted(Sender: TObject; aMove: TMove);
    procedure HandleCursorChange(aNode: TStateNode); override;

    property StateManager: TStateManager read fStateManager write SetStateManager;
    property OnNavigate: TNodeNavigateEvent read fOnNavigate write fOnNavigate;
  end;


implementation

{$R *.dfm}

uses Vcl.Themes;

type
  TStateNodeData = record
    state: TStateNode;
  end;


{ TStateFrame }

procedure TStateFrame.InitContent;
begin
  inherited;
  StateTree.NodeDataSize := SizeOf(TStateNodeData);

end;

procedure TStateFrame.SetStateManager(const Value: TStateManager);
begin
  fStateManager := Value;
//  fStateManager.OnStateChange := HandleStateChange; { !! removed in 3.4; reworked to OnCursorChange in Task 5 }
end;

procedure TStateFrame.HandleMoveExecuted(Sender: TObject; aMove: TMove);
begin
  //
end;

procedure TStateFrame.HandleStateChange(Sender: TObject; ParentNode, ChildNode: TStateNode);
begin
  if ParentNode = nil then
  begin
    // new root node
    StateTree.RootNodeCount := 1;
    StateTree.Invalidate;
  end
  else
  begin
    // otherwise the parent had a change in its children
    var treeParent := StateTree.IterateSubtree(nil,
      procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean)
      var
        nodeData: TStateNodeData;
      begin
        nodeData := Node.GetData<TStateNodeData>;
        if nodeData.state = Data then
        begin
          Abort := True;
        end;
      end,
      ParentNode, []);

    if Assigned(treeParent) then
    begin
      StateTree.ReinitNode(treeParent, True);
      StateTree.InvalidateNode(treeParent);
    end;
  end;
end;

function TStateFrame.FindTreeNode(aState: TStateNode): PVirtualNode;
begin
  Result := StateTree.IterateSubtree(nil,
    procedure(Sender: TBaseVirtualTree; Node: PVirtualNode; Data: Pointer; var Abort: Boolean)
    var
      nodeData: TStateNodeData;
    begin
      nodeData := Node.GetData<TStateNodeData>;
      if nodeData.state = Data then
        Abort := True;
    end,
    aState, []);
end;

procedure TStateFrame.HandleCursorChange(aNode: TStateNode);
begin
  if not Assigned(aNode) then
  begin
    StateTree.ClearSelection;
    StateTree.FocusedNode := nil;
    Exit;
  end;

  fUpdatingTree := True;
  try
    // make sure the root is present the first time through
    if StateTree.RootNodeCount = 0 then
      StateTree.RootNodeCount := 1;

    // refresh the affected subtree so displayed structure matches the manager exactly
    // (a follow-or-create may have sprouted a new child under the parent)
    if Assigned(aNode.Parent) then
    begin
      var treeParent := FindTreeNode(aNode.Parent);
      if Assigned(treeParent) then
        StateTree.ReinitNode(treeParent, True);
    end
    else
      StateTree.ReinitNode(nil, True);

    // select the cursor node
    var treeNode := FindTreeNode(aNode);
    if Assigned(treeNode) then
    begin
      StateTree.ClearSelection;
      StateTree.Selected[treeNode] := True;
      StateTree.FocusedNode := treeNode;
      StateTree.InvalidateNode(treeNode);
    end;
  finally
    fUpdatingTree := False;
  end;
end;

procedure TStateFrame.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  var nodeData := Node.GetData<TStateNodeData>;
  if Assigned(nodeData.state) then
  begin
    const fmt = '%s [ %g ]';
    CellText := Format(fmt, [
      nodeData.state.Name,
      nodeData.state.HValue
    ]);
  end;
end;

procedure TStateFrame.TreeInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode;
  var ChildCount: Cardinal);
begin
  var nodeData := Node.GetData<TStateNodeData>;
  if Assigned(nodeData.state) then
    ChildCount := nodeData.state.ChildCount;
end;

procedure TStateFrame.TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode;
  var InitialStates: TVirtualNodeInitStates);
var
  nodeData: TStateNodeData;
begin
  nodeData := Node.GetData<TStateNodeData>;
  InitialStates := [];

  if ParentNode = nil then
  begin
//    if Shelves.Count > 0 then
//      nodeData.state := Shelves.Peek
//    else
      nodeData.state := StateManager.RootNode;
  end
  else
  begin
    var parentData := ParentNode.GetData<TStateNodeData>;
    nodeData.state := parentData.state.ChildNodes[node.Index];
  end;
  node.SetData(nodeData);

  if nodeData.state.ChildCount > 0 then
  begin
    Include(InitialStates, ivsHasChildren);
    if not (vsExpanded in node.States) then
      Include(InitialStates, ivsExpanded);
  end;
end;

procedure TStateFrame.TreeNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
begin
  if not Assigned(HitInfo.HitNode) then
    Exit;

  var nodeData := HitInfo.HitNode.GetData<TStateNodeData>;
  if Assigned(fOnNavigate) then
    fOnNavigate(Self, nodeData.state);   // report only; the manager owns the cursor move
end;

procedure TStateFrame.StateTreeDrawNode(Sender: TBaseVirtualTree; const PaintInfo: TVTPaintInfo);
var
  nodeData: TStateNodeData;
  canvas: TCanvas;
  r, authorRect, textRect: TRect;
  isSelected: Boolean;
  nodeText: string;
begin
  nodeData := PaintInfo.Node.GetData<TStateNodeData>;
  if not Assigned(nodeData.state) then
    Exit;

  canvas := PaintInfo.Canvas;
  r := PaintInfo.ContentRect;
  isSelected := vsSelected in PaintInfo.Node.States;

  // Background
  if isSelected then
  begin
    if StateTree.Focused then
      canvas.Brush.Color := StateTree.Colors.FocusedSelectionColor
    else
      canvas.Brush.Color := StateTree.Colors.UnfocusedSelectionColor;
    canvas.Font.Color := StateTree.Colors.SelectionTextColor;
  end
  else
  begin
    canvas.Brush.Color := StyleServices.GetSystemColor(clWindow);
    canvas.Font.Color := StyleServices.GetSystemColor(clWindowText);
  end;

  canvas.FillRect(PaintInfo.CellRect);

  // Author color bar indicator on the left
  authorRect := Rect(r.Left, r.Top + 4, r.Left + 5, r.Bottom - 4);
  canvas.Brush.Color := nodeData.state.Author.AsColor;
  canvas.FillRect(authorRect);

  // Node text
  textRect := r;
  textRect.Left := authorRect.Right + 8;
  nodeText := Format('%s [ %g ]', [nodeData.state.Name, nodeData.state.HValue]);

  canvas.Brush.Style := bsClear;
  DrawText(canvas.Handle, PChar(nodeText), Length(nodeText), textRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

procedure TStateFrame.StateTreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex);
begin
  if fUpdatingTree or (not Assigned(Node)) then
    Exit;

  var nodeData := Node.GetData<TStateNodeData>;
  if Assigned(nodeData.state) and Assigned(fOnNavigate) then
    fOnNavigate(Self, nodeData.state);
end;

procedure TStateFrame.StateTreeMeasureItem(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
  Node: PVirtualNode; var NodeHeight: Integer);
begin
  NodeHeight := 30; // !!

end;

procedure TStateFrame.TreeBeforeCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas;
  Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode;
  CellRect: TRect; var ContentRect: TRect);
begin
  if CellPaintMode <> cpmPaint then
    Exit;

  var nodeData := Node.GetData<TStateNodeData>;
  if Assigned(nodeData.state) then
  begin
    TargetCanvas.Brush.Color := nodeData.state.Author.AsColor;
    TargetCanvas.FillRect(CellRect);
  end;
end;

end.
