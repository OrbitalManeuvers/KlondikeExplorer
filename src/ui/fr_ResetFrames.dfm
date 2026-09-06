inherited ResetFrame: TResetFrame
  Width = 301
  Height = 356
  ExplicitWidth = 301
  ExplicitHeight = 356
  inherited pnlBackground: TPanel
    Width = 301
    Height = 356
    BevelEdges = [beLeft, beTop, beRight, beBottom]
    ExplicitWidth = 301
    ExplicitHeight = 356
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
      Top = 312
      Width = 95
      Height = 30
      Caption = 'Reset'
      OnClick = btnResetClick
    end
    object Label1: TLabel
      Left = 40
      Top = 64
      Width = 116
      Height = 17
      Caption = 'Solvability unknown.'
    end
    object rbRandom: TRadioButton
      Left = 24
      Top = 41
      Width = 145
      Height = 17
      Caption = 'Random deal'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      TabStop = True
      OnClick = MethodClick
    end
    object cbSnapshots: TComboBox
      Left = 40
      Top = 259
      Width = 242
      Height = 25
      Style = csDropDownList
      TabOrder = 1
    end
    object rbSnapshot: TRadioButton
      Left = 24
      Top = 232
      Width = 86
      Height = 17
      Caption = 'Snapshot:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = MethodClick
    end
    object rgMethod: TRadioGroup
      Left = 40
      Top = 130
      Width = 242
      Height = 72
      Caption = ' Method '
      ItemIndex = 0
      Items.Strings = (
        'Foward'
        'Reverse')
      TabOrder = 4
    end
    object rbSolvable: TRadioButton
      Left = 24
      Top = 104
      Width = 241
      Height = 17
      Caption = 'Solvable deal'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      OnClick = MethodClick
    end
  end
end
