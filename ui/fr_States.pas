unit fr_States;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  VirtualTrees, System.Generics.Collections,

  u_StateManagers;

type
  TStateFrame = class(TFrame)
    lblState: TLabel;
    btnExpand: TSpeedButton;
    btnShelve: TSpeedButton;
    StateTree: TVirtualStringTree;
    procedure StateTreeInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure StateTreeInitChildren(Sender: TBaseVirtualTree;
      Node: PVirtualNode; var ChildCount: Cardinal);
    procedure StateTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure StateTreeNodeClick(Sender: TBaseVirtualTree;
      const HitInfo: THitInfo);
    procedure btnExpandClick(Sender: TObject);
    procedure btnShelveClick(Sender: TObject);
  strict private
    fStateManager: TStateManager;
    procedure SetStateManager(const Value: TStateManager);
  private
    Shelves: TStack<TStateNode>;
    fOnStateSelected: TNotifyEvent;
    fOnExpandClick: TNotifyEvent;
    fActiveState: TStateNode;
    procedure HandleStateChange(Sender: TObject; ParentNode, ChildNode: TStateNode);
    procedure UpdateControls;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure SelectRoot;

    property ActiveState: TStateNode read fActiveState;

    property StateManager: TStateManager read fStateManager write SetStateManager;
    property OnStateSelected: TNotifyEvent read fOnStateSelected write fOnStateSelected;
    property OnExpandState: TNotifyEvent read fOnExpandClick write fOnExpandClick;
  end;


implementation

{$R *.dfm}

type
  TStateNodeData = record
    state: TStateNode;
  end;
  PStateNodeData = ^TStateNodeData;


{ TStateFrame }

constructor TStateFrame.Create(AOwner: TComponent);
begin
  inherited;
  Shelves := TStack<TStateNode>.Create;

  StateTree.NodeDataSize := SizeOf(TStateNodeData);
  Clear;
  UpdateControls;
end;

destructor TStateFrame.Destroy;
begin
  Shelves.Free;
  inherited;
end;

procedure TStateFrame.Clear;
begin
  StateTree.RootNodeCount := 0;
end;

procedure TStateFrame.HandleStateChange(Sender: TObject; ParentNode, ChildNode: TStateNode);
begin
  if ParentNode = nil then
  begin
    // new root node
    StateTree.RootNodeCount := 1;
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

procedure TStateFrame.SelectRoot;
begin
  var vNode := StateTree.GetFirst();
  if Assigned(vNode) then
  begin
    StateTree.Selected[vNode] := True;

    var nodeData := vNode.GetData<TStateNodeData>;
    if Assigned(nodeData.state) then
    begin
      fActiveState := nodeData.state;
      if Assigned(fOnStateSelected) then
        fOnStateSelected(Self);
    end;
  end;
end;

procedure TStateFrame.SetStateManager(const Value: TStateManager);
begin
  fStateManager := Value;
  fStateManager.OnStateChange := HandleStateChange;
  StateTree.RootNodeCount := 0;
end;

procedure TStateFrame.StateTreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
begin
  var nodeData := Node.GetData<TStateNodeData>;
  if Assigned(nodeData.state) then
  begin
    const fmt = '%s [ %g, %d ]';
    CellText := Format(fmt, [
      nodeData.state.Name,
      nodeData.state.HValue,
      nodeData.state.Evaluations.Count
    ]);
  end;
end;

procedure TStateFrame.StateTreeInitChildren(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var ChildCount: Cardinal);
begin
  var nodeData := Node.GetData<TStateNodeData>;
  if Assigned(nodeData.state) then
    ChildCount := nodeData.state.ChildCount;
end;

procedure TStateFrame.StateTreeInitNode(Sender: TBaseVirtualTree; ParentNode,
  Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  nodeData: TStateNodeData;
begin
  nodeData := Node.GetData<TStateNodeData>;
  InitialStates := [];

  if ParentNode = nil then
  begin
    if Shelves.Count > 0 then
      nodeData.state := Shelves.Peek
    else
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

procedure TStateFrame.StateTreeNodeClick(Sender: TBaseVirtualTree;
  const HitInfo: THitInfo);
var
  nodeData: TStateNodeData;
begin
  if (hiOnItem in HitInfo.HitPositions) and (not (hiOnItemButton in HitInfo.HitPositions)) then
  begin
    nodeData := HitInfo.HitNode.GetData<TStateNodeData>;
    fActiveState := nodeData.state;
    UpdateControls;

    if Assigned(fOnStateSelected) then
      fOnStateSelected(Self);
  end;
end;

procedure TStateFrame.UpdateControls;
begin
  btnExpand.Enabled := False;
  btnShelve.Enabled := False;

  if Assigned(ActiveState) then
  begin
    btnExpand.Enabled := ActiveState.ChildCount = 0;

    // if the active state is at the top of the shelves, it can unshelve
    if (Shelves.Count > 0) and (Shelves.Peek = ActiveState) then
    begin
      btnShelve.Caption := 'Unshelve';
      btnShelve.Enabled := True;
    end;

    // if the selected state is not the topmost (either root or shelve), then
    // it can shelve
    var rootState := fStateManager.RootNode;
    if Shelves.Count > 0 then
      rootState := Shelves.Peek;

    if ActiveState <> rootState then
    begin
      btnShelve.Caption := 'Shelve';
      btnShelve.Enabled := True;
    end;

    // and when not enabled, show shelve
    if not btnShelve.Enabled then
      btnShelve.Caption := 'Shelve';
  end;
end;

procedure TStateFrame.btnExpandClick(Sender: TObject);
begin
  if Assigned(fOnExpandClick) then
  begin
    fOnExpandClick(Self);
    UpdateControls;
  end;
end;

procedure TStateFrame.btnShelveClick(Sender: TObject);
begin
  Assert(Assigned(ActiveState));

  // we're either unshelving or shelving ...
  if (Shelves.Count > 0) and (Shelves.Peek = ActiveState) then
  begin
    // unshelve from here
    Shelves.Pop;
  end
  else
  begin
    // otherwise
    Shelves.Push(ActiveState);
  end;

  // update the view
  var vNode := StateTree.GetFirst();
  StateTree.ReinitNode(vNode, True);
  SelectRoot;
  UpdateControls;
end;


end.
