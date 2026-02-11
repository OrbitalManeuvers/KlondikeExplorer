object TableFrame: TTableFrame
  Left = 0
  Top = 0
  Width = 505
  Height = 364
  DoubleBuffered = True
  ParentDoubleBuffered = False
  TabOrder = 0
  DesignSize = (
    505
    364)
  object lblTable: TLabel
    Left = 8
    Top = 2
    Width = 38
    Height = 21
    Caption = 'Table'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 4227327
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
    StyleElements = [seClient, seBorder]
  end
  object shpPlaceholder: TShape
    Left = 8
    Top = 60
    Width = 481
    Height = 293
    Anchors = [akLeft, akTop, akRight, akBottom]
    Brush.Style = bsClear
    Pen.Color = clTeal
  end
  object btnTableMode: TSpeedButton
    Left = 8
    Top = 24
    Width = 65
    Height = 30
    AllowAllUp = True
    GroupIndex = 1
    Caption = 'Normal'
    OnClick = btnTableModeClick
  end
  object btnSaveSnapshot: TSpeedButton
    Left = 88
    Top = 24
    Width = 105
    Height = 30
    AllowAllUp = True
    Caption = 'Save Snapshot'
  end
  object lblHValue: TLabel
    Left = 224
    Top = 31
    Width = 12
    Height = 15
    Caption = 'H:'
    FocusControl = edtHValue
  end
  object edtHValue: TEdit
    Left = 248
    Top = 28
    Width = 121
    Height = 23
    ReadOnly = True
    TabOrder = 0
    Text = '0'
  end
end
