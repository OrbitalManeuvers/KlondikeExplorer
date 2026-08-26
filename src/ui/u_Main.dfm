object MainForm: TMainForm
  Left = 0
  Top = 0
  OnAlignPosition = FormAlignPosition
  Caption = 'Klondike Explorer'
  ClientHeight = 787
  ClientWidth = 1150
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  StyleElements = [seFont, seBorder]
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object MainMenu: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 1150
    Height = 25
    UseSystemFont = False
    ActionManager = MainActions
    Color = clMenuBar
    ColorMap.DisabledFontColor = 10461087
    ColorMap.HighlightColor = clWhite
    ColorMap.BtnSelectedFont = clBlack
    ColorMap.UnusedColor = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    Spacing = 0
  end
  object LeftPanel: TPanel
    AlignWithMargins = True
    Left = 6
    Top = 31
    Width = 300
    Height = 750
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alLeft
    ParentBackground = False
    ShowCaption = False
    TabOrder = 1
    object GroupBox1: TGroupBox
      AlignWithMargins = True
      Left = 5
      Top = 4
      Width = 290
      Height = 145
      Margins.Left = 4
      Margins.Right = 4
      Align = alTop
      Caption = ' Reset '
      TabOrder = 0
      object btnReset: TSpeedButton
        Left = 16
        Top = 104
        Width = 81
        Height = 33
        Caption = 'Reset'
        OnClick = btnResetClick
      end
      object rbRandom: TRadioButton
        Left = 16
        Top = 24
        Width = 113
        Height = 17
        Caption = 'Random'
        TabOrder = 0
      end
      object rbSolvable: TRadioButton
        Left = 16
        Top = 48
        Width = 113
        Height = 17
        Caption = 'Solvable'
        TabOrder = 1
      end
      object rbSnapshot: TRadioButton
        Left = 16
        Top = 72
        Width = 81
        Height = 17
        Caption = 'Snapshot:'
        TabOrder = 2
      end
      object cbSnapshots: TComboBox
        Left = 104
        Top = 68
        Width = 172
        Height = 25
        Style = csDropDownList
        TabOrder = 3
      end
    end
  end
  object TablePanel: TPanel
    Left = 318
    Top = 46
    Width = 815
    Height = 347
    Margins.Left = 6
    Margins.Top = 0
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alCustom
    ParentBackground = False
    ShowCaption = False
    TabOrder = 2
  end
  object GraphPanel: TPanel
    Left = 384
    Top = 416
    Width = 693
    Height = 183
    Margins.Left = 6
    Margins.Top = 0
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alCustom
    ParentBackground = False
    ShowCaption = False
    TabOrder = 3
  end
  object MainActions: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = actOpenGame
                ImageIndex = 7
                ShortCut = 16463
              end
              item
                Caption = '-'
              end
              item
                Action = actSaveGame
                Caption = '&Save Game'
                ShortCut = 16467
              end
              item
                Action = actSaveGameAs
                ImageIndex = 30
              end
              item
                Caption = '-'
              end
              item
                Action = actFileExit
                ImageIndex = 43
                ShortCut = 32856
              end>
            Caption = '&File'
          end
          item
            Items = <
              item
                Action = actTests
                Caption = '&Regression Tests...'
              end
              item
                Caption = '-'
              end
              item
                Action = actAbout
                Caption = '&About...'
              end>
            Caption = '&Help'
          end>
        ActionBar = MainMenu
      end>
    Left = 512
    Top = 96
    StyleName = 'Platform Default'
    object actFileExit: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
      ShortCut = 32856
    end
    object actOpenGame: TFileOpen
      Category = 'File'
      Caption = '&Open Game...'
      Dialog.DefaultExt = '.json'
      Dialog.Filter = 'JSON Files (*.json)|*.json|Any file (*.*)|*.*'
      Dialog.Options = [ofHideReadOnly, ofNoChangeDir, ofFileMustExist, ofEnableSizing]
      Dialog.Title = 'Open Saved Game'
      Hint = 'Open|Opens an existing file'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = actOpenGameAccept
    end
    object actSaveGameAs: TFileSaveAs
      Category = 'File'
      Caption = 'Save Game &As...'
      Dialog.Title = 'Save Game'
      Hint = 'Save As|Saves the active file with a new name'
      ImageIndex = 30
      OnAccept = actSaveGameAsAccept
    end
    object actSaveGame: TAction
      Category = 'File'
      Caption = 'Save Game'
      ShortCut = 16467
      OnExecute = actSaveGameExecute
    end
    object actTests: TAction
      Category = 'Help'
      Caption = 'Regression Tests...'
      OnExecute = actTestsExecute
    end
    object actAbout: TAction
      Category = 'Help'
      Caption = 'About...'
      OnExecute = actAboutExecute
    end
  end
end
