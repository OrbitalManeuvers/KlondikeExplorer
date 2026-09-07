object AboutBox: TAboutBox
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'About Klondike Explorer'
  ClientHeight = 136
  ClientWidth = 271
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 17
  object btnOK: TButton
    Left = 93
    Top = 88
    Width = 75
    Height = 35
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 182
    Top = 88
    Width = 75
    Height = 35
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
end
