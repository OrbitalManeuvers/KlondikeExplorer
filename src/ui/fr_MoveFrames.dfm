inherited MoveFrame: TMoveFrame
  Width = 270
  Height = 249
  ExplicitWidth = 270
  ExplicitHeight = 249
  inherited pnlBackground: TPanel
    Width = 270
    Height = 249
    ExplicitWidth = 270
    ExplicitHeight = 249
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 77
      Height = 17
      Caption = 'Legal Moves'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object MovesList: TControlList
      Left = 8
      Top = 31
      Width = 249
      Height = 200
      Anchors = [akLeft, akTop, akRight, akBottom]
      ItemHeight = 30
      ItemMargins.Left = 0
      ItemMargins.Top = 0
      ItemMargins.Right = 0
      ItemMargins.Bottom = 0
      ParentColor = False
      TabOrder = 0
      OnBeforeDrawItem = MovesListBeforeDrawItem
      OnItemClick = MovesListItemClick
      object lblMoveName: TLabel
        AlignWithMargins = True
        Left = 8
        Top = 3
        Width = 199
        Height = -6
        Margins.Left = 8
        Align = alClient
        AutoSize = False
        Caption = 'move name'
        Layout = tlCenter
        ExplicitWidth = 122
        ExplicitHeight = 24
      end
      object lblHValue: TLabel
        AlignWithMargins = True
        Left = -32
        Top = 3
        Width = 24
        Height = -6
        Margins.Right = 8
        Align = alRight
        Caption = '0.00'
        Layout = tlCenter
        ExplicitLeft = 213
        ExplicitHeight = 17
      end
    end
  end
end
