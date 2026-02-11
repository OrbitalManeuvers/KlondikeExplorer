object LogFrame: TLogFrame
  Left = 0
  Top = 0
  Width = 687
  Height = 135
  TabOrder = 0
  DesignSize = (
    687
    135)
  object btnCopyLog: TPngSpeedButton
    Left = 8
    Top = 8
    Width = 23
    Height = 22
    Hint = 'Copy log contents to clipboard'
  end
  object btnClear: TPngSpeedButton
    Left = 8
    Top = 40
    Width = 23
    Height = 22
    Hint = 'Clear contents of log window'
  end
  object LogMemo: TMemo
    Left = 45
    Top = 4
    Width = 628
    Height = 124
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Source Code Pro'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
    WordWrap = False
  end
end
