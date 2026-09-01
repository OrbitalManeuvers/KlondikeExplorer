inherited MoveFrame: TMoveFrame
  Width = 270
  Height = 249
  ExplicitWidth = 270
  ExplicitHeight = 249
  inherited pnlBackground: TPanel
    Width = 270
    Height = 249
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 100
      Height = 17
      Caption = 'Potential Moves'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object ControlList1: TControlList
      Left = 8
      Top = 31
      Width = 249
      Height = 200
      Anchors = [akLeft, akTop, akRight, akBottom]
      ItemMargins.Left = 0
      ItemMargins.Top = 0
      ItemMargins.Right = 0
      ItemMargins.Bottom = 0
      ParentColor = False
      TabOrder = 0
    end
  end
end
