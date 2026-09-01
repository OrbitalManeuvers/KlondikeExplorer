object SaveSnapshotDlg: TSaveSnapshotDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Save Snapshot'
  ClientHeight = 145
  ClientWidth = 267
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 17
  object Label1: TLabel
    Left = 16
    Top = 15
    Width = 38
    Height = 17
    Caption = 'Name:'
  end
  object Label3: TLabel
    Left = 16
    Top = 47
    Width = 54
    Height = 17
    Caption = 'Contents:'
  end
  object rbInitialState: TRadioButton
    Left = 91
    Top = 47
    Width = 113
    Height = 17
    Caption = 'Initial state'
    Checked = True
    TabOrder = 1
    TabStop = True
  end
  object rbCurrentState: TRadioButton
    Left = 91
    Top = 73
    Width = 113
    Height = 17
    Caption = 'Current state'
    TabOrder = 2
  end
  object edtName: TEdit
    Left = 91
    Top = 12
    Width = 163
    Height = 25
    TabOrder = 0
    OnChange = edtNameChange
  end
  object btnOK: TButton
    Left = 83
    Top = 112
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 179
    Top = 112
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
