unit fr_TestFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, fr_ContentFrame, Vcl.StdCtrls,
  Vcl.CheckLst,
  System.Generics.Collections, Vcl.Buttons, Vcl.ComCtrls,

  u_UnitTests
  ;

type
  TTestFrame = class(TContentFrame)
    Log: TMemo;
    btnRun: TButton;
    cbStopOnFailure: TCheckBox;
    btnCheckAll: TSpeedButton;
    btnClearAll: TSpeedButton;
    ListView: TListView;
    procedure btnRunClick(Sender: TObject);
    procedure btnCheckAllClick(Sender: TObject);
    procedure btnClearAllClick(Sender: TObject);
    procedure ListViewItemChecked(Sender: TObject; Item: TListItem);
    procedure ListViewSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    type
      TTestCase = class
        Name: string;
        Status: string;
        Log: TStrings;
        TestClass: TUnitTestClass;
        ListItem: TListItem;
        constructor Create(aTestClass: TUnitTestClass);
        destructor Destroy; override;
      end;
  private
    Tests: TObjectList<TTestCase>;
    CheckedCount: Integer;
    procedure UpdateControls;
    procedure CheckAll(Checked: Boolean);
    procedure UpdateListItems;
    procedure UpdateListItem(AItem: TListItem);
  public
    procedure InitContent; override;
    procedure DoneContent; override;
  end;


implementation

{$R *.dfm}

uses
  u_Types,
  u_Cards,
  u_Snapshots,
  u_Dealers,
  u_CardStacks,
  u_Tables,

  u_Tables.Render;

{ TTestFrame }

procedure TTestFrame.InitContent;
begin
  inherited;
  Tests := TObjectList<TTestCase>.Create(True);

  // load known test cases
  Tests.Add(TTestCase.Create(TRenderTest));
  Tests.Add(TTestCase.Create(TMoveTest));
  Tests.Add(TTestCase.Create(TSnapshotTest));
  Tests.Add(TTestCase.Create(TSnapshotStorageTest));
  Tests.Add(TTestCase.Create(TStorageStatsTest));

  for var testCase in Tests do
  begin
    var item := ListView.Items.Add;
    item.Data := testCase;
    testCase.ListItem := item;
  end;

  UpdateListItems;

  CheckedCount := 0;
  UpdateControls;
end;

procedure TTestFrame.ListViewItemChecked(Sender: TObject; Item: TListItem);
begin
  inherited;
  if Item.Checked then
    Inc(CheckedCount)
  else
    Dec(CheckedCount);
  UpdateControls;
end;

procedure TTestFrame.ListViewSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  var testCase := TTestCase(Item.Data);
  Log.Lines.Assign(testCase.Log);
end;

procedure TTestFrame.DoneContent;
begin
  inherited;
  Tests.Free;
end;

procedure TTestFrame.btnCheckAllClick(Sender: TObject);
begin
  CheckAll(True);
end;

procedure TTestFrame.btnClearAllClick(Sender: TObject);
begin
  CheckAll(False);
end;

procedure TTestFrame.CheckAll(Checked: Boolean);
begin
  ListView.Items.BeginUpdate;
  try
    for var i := 0 to ListView.Items.Count - 1 do
      ListView.Items[i].Checked := Checked;
  finally
    ListView.Items.EndUpdate;
  end;
end;

procedure TTestFrame.UpdateControls;
begin
  btnRun.Enabled := CheckedCount > 0;
end;

procedure TTestFrame.UpdateListItem(AItem: TListItem);
begin
  var testCase := TTestCase(AItem.Data);
  AItem.Caption := testCase.TestClass.TestName;
  AItem.SubItems.Clear;
  AItem.SubItems.Add(testCase.Status);
  AItem.SubItems.Add(testCase.Log.Count.ToString);
end;

procedure TTestFrame.UpdateListItems;
begin
  ListView.Items.BeginUpdate;
  try
    for var item in ListView.Items do
      UpdateListItem(item);
  finally
    ListView.Items.EndUpdate;
  end;
end;

procedure TTestFrame.btnRunClick(Sender: TObject);

  procedure _log(const msg: string);
  begin
    var line := Format('[%s] %s', [FormatDateTime('hh:mm:ss', Now), msg]);
    Log.Lines.Add(line);
  end;

begin
  Log.Lines.Clear;
  _log('Begin Test Run');

  // get rid of selection
  ListView.ItemIndex := -1;

  for var item in ListView.Items do
  begin
    if item.Checked then
    begin
      var testCase := TTestCase(item.Data);
      var tester := testCase.TestClass.Create;
      try
//        tester._SnapshotManager := Self.SnapshotManager;
        tester.Run;
        _log('Executed: ' + tester.TestName);

        // put results into test case and update ui
        testCase.Log.Assign(tester.Results);
        testCase.Status := tester.Status;
        UpdateListItem(item);
      finally
        tester.Free;
      end;
    end;
  end;

  _log('Completed.');
  _log('Select test to view log.');

end;



{ TTestFrame.TTestEntry }

constructor TTestFrame.TTestCase.Create(aTestClass: TUnitTestClass);
begin
  inherited Create;
  Log := TStringList.Create;
  Name := aTestClass.TestName;
  TestClass := aTestClass;
end;

destructor TTestFrame.TTestCase.Destroy;
begin
  Log.Free;
  inherited;
end;

end.
