unit fr_StateFrames;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrames, Vcl.ExtCtrls,
  VirtualTrees, Vcl.StdCtrls,

  u_Types, u_StateManagers;

type
  TStateFrame = class(TContentFrame)
    lblTitle: TLabel;
    Tree: TVirtualStringTree;
    procedure TreeInitNode(Sender: TBaseVirtualTree; ParentNode, Node: PVirtualNode;
      var InitialStates: TVirtualNodeInitStates);
    procedure TreeInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode;
      var ChildCount: Cardinal);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType; var CellText: string);
    procedure TreeNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
  private
    fStateManager: TStateManager;
    procedure SetStateManager(const Value: TStateManager);
    procedure HandleStateChange(Sender: TObject; ParentNode, ChildNode: TStateNode);
  public
    procedure InitContent; override;
    procedure HandleMoveExecuted(Sender: TObject; aMove: TMove);

    property StateManager: TStateManager read fStateManager write SetStateManager;
  end;


implementation

{$R *.dfm}

type
  TStateNodeData = record
    state: TStateNode;
  end;


{ TStateFrame }

procedure TStateFrame.InitContent;
begin
  inherited;
  Tree.NodeDataSize := SizeOf(TStateNodeData);

end;

procedure TStateFrame.SetStateManager(const Value: TStateManager);
begin
  fStateManager := Value;
  fStateManager.OnStateChange := HandleStateChange;
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
    Tree.RootNodeCount := 1;
    Tree.Invalidate;
  end
  else
  begin
    // otherwise the parent had a change in its children
    var treeParent := Tree.IterateSubtree(nil,
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
      Tree.ReinitNode(treeParent, True);
      Tree.InvalidateNode(treeParent);
    end;
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
  //
end;

end.
