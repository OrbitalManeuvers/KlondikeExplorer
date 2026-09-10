object SnapshotComposerDlg: TSnapshotComposerDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Snapshot Composer'
  ClientHeight = 280
  ClientWidth = 448
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 17
  object Label1: TLabel
    Left = 6
    Top = 16
    Width = 93
    Height = 17
    Caption = 'Snapshot name:'
  end
  object Label2: TLabel
    Left = 6
    Top = 48
    Width = 76
    Height = 17
    Caption = 'Specification:'
  end
  object edtSnapshotName: TEdit
    Left = 104
    Top = 16
    Width = 329
    Height = 25
    TabOrder = 0
    OnChange = edtSnapshotNameChange
  end
  object mmoInstructions: TMemo
    Left = 104
    Top = 45
    Width = 329
    Height = 188
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    Lines.Strings = (
      'T1: - - 4D')
    ParentFont = False
    TabOrder = 1
  end
  object btnOK: TButton
    Left = 264
    Top = 247
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 2
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 358
    Top = 247
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
