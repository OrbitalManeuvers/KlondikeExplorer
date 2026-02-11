inherited TestFrame: TTestFrame
  Height = 393
  Anchors = [akLeft, akTop, akRight, akBottom]
  ExplicitHeight = 393
  object btnCheckAll: TSpeedButton
    Left = 8
    Top = 280
    Width = 23
    Height = 22
    OnClick = btnCheckAllClick
  end
  object btnClearAll: TSpeedButton
    Left = 48
    Top = 280
    Width = 23
    Height = 22
    OnClick = btnClearAllClick
  end
  object Log: TMemo
    Left = 328
    Top = 40
    Width = 721
    Height = 345
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Source Code Pro'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object btnRun: TButton
    Left = 3
    Top = 353
    Width = 75
    Height = 25
    Caption = 'Run Tests'
    TabOrder = 1
    OnClick = btnRunClick
  end
  object cbStopOnFailure: TCheckBox
    Left = 3
    Top = 330
    Width = 129
    Height = 17
    Caption = 'Stop on failure'
    TabOrder = 2
  end
  object ListView: TListView
    Left = 8
    Top = 40
    Width = 305
    Height = 225
    Checkboxes = True
    Columns = <
      item
        Caption = 'Test Name'
        Width = 150
      end
      item
        Caption = 'Status'
        Width = 80
      end
      item
        AutoSize = True
        Caption = 'Lines'
      end>
    ColumnClick = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 3
    ViewStyle = vsReport
    OnSelectItem = ListViewSelectItem
    OnItemChecked = ListViewItemChecked
  end
end
