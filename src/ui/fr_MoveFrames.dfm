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
        Left = 45
        Top = 3
        Width = 162
        Height = 24
        Margins.Left = 8
        Align = alClient
        AutoSize = False
        Caption = 'move name'
        Layout = tlCenter
        ExplicitLeft = 80
        ExplicitWidth = 127
      end
      object lblHValue: TLabel
        AlignWithMargins = True
        Left = 213
        Top = 3
        Width = 24
        Height = 24
        Margins.Right = 8
        Align = alRight
        Caption = '0.00'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        Layout = tlCenter
        StyleElements = [seClient, seBorder]
        ExplicitHeight = 17
      end
      object shHintStatus: TShape
        AlignWithMargins = True
        Left = 6
        Top = 6
        Width = 25
        Height = 18
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Align = alLeft
        Brush.Color = clMoneyGreen
        Shape = stCircle
        ExplicitLeft = 8
        ExplicitTop = 0
        ExplicitHeight = 25
      end
    end
  end
end
