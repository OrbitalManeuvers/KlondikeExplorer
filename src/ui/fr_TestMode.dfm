inherited TestFrame: TTestFrame
  Width = 711
  Height = 524
  Font.Height = -13
  ParentFont = False
  ExplicitWidth = 711
  ExplicitHeight = 524
  object ControlPanel: TPanel
    Left = 0
    Top = 0
    Width = 241
    Height = 524
    Align = alLeft
    ShowCaption = False
    TabOrder = 0
    object SpeedButton1: TSpeedButton
      Left = 24
      Top = 232
      Width = 81
      Height = 33
    end
    object CheckListBox1: TCheckListBox
      Left = 8
      Top = 48
      Width = 217
      Height = 161
      ItemHeight = 17
      TabOrder = 0
    end
  end
  object LogView: TControlList
    Left = 241
    Top = 0
    Width = 470
    Height = 524
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ItemHeight = 28
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    ParentFont = False
    TabOrder = 1
    StyleElements = [seClient, seBorder]
    OnBeforeDrawItem = LogViewBeforeDrawItem
    object lblEntryType: TLabel
      AlignWithMargins = True
      Left = 8
      Top = 0
      Width = 73
      Height = 28
      Margins.Left = 8
      Margins.Top = 0
      Margins.Bottom = 0
      Align = alLeft
      AutoSize = False
      Caption = 'lblEntryType'
      Layout = tlCenter
    end
    object lblEntryText: TLabel
      AlignWithMargins = True
      Left = 88
      Top = 0
      Width = 374
      Height = 28
      Margins.Left = 4
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alClient
      AutoSize = False
      Caption = 'lblEntryText'
      Layout = tlCenter
      ExplicitLeft = 176
      ExplicitTop = 8
      ExplicitWidth = 66
      ExplicitHeight = 17
    end
  end
end
