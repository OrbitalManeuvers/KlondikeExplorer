inherited ResetFrame: TResetFrame
  Width = 280
  Height = 186
  ExplicitWidth = 280
  ExplicitHeight = 186
  inherited pnlBackground: TPanel
    Width = 280
    Height = 186
    BevelEdges = [beLeft, beTop, beRight, beBottom]
    ExplicitTop = 0
    ExplicitWidth = 280
    ExplicitHeight = 186
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 108
      Height = 17
      Caption = 'Reset Initial State'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnReset: TSpeedButton
      Left = 24
      Top = 144
      Width = 95
      Height = 26
      Caption = 'Reset'
      OnClick = btnResetClick
    end
    object rbRandom: TRadioButton
      Left = 24
      Top = 41
      Width = 241
      Height = 17
      Caption = 'Random deal, solvability unknown'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = MethodClick
    end
    object cbSnapshots: TComboBox
      Left = 118
      Top = 100
      Width = 147
      Height = 25
      Style = csDropDownList
      TabOrder = 1
    end
    object rbSnapshot: TRadioButton
      Left = 24
      Top = 104
      Width = 86
      Height = 17
      Caption = 'Snapshot:'
      TabOrder = 2
      OnClick = MethodClick
    end
    object rbSolvable: TRadioButton
      Left = 24
      Top = 72
      Width = 241
      Height = 17
      Caption = 'Solvable deal, complexity undefined'
      TabOrder = 3
      OnClick = MethodClick
    end
  end
end
