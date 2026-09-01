object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Klondike Explorer'
  ClientHeight = 787
  ClientWidth = 1279
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  StyleElements = [seFont, seBorder]
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object LeftColumnBorderShape: TShape
    Left = 329
    Top = 25
    Width = 6
    Height = 743
    Margins.Left = 0
    Margins.Top = 6
    Margins.Bottom = 6
    Align = alLeft
    Brush.Color = clBtnShadow
    Pen.Style = psClear
    ExplicitLeft = 306
    ExplicitTop = 31
    ExplicitHeight = 731
  end
  object VSplitter: TSplitter
    Left = 672
    Top = 25
    Width = 6
    Height = 743
    ResizeStyle = rsUpdate
  end
  object MainMenu: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 1279
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
  object StatusBar: TStatusBar
    Left = 0
    Top = 768
    Width = 1279
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = 'Simple text example'
  end
  object LeftColumn: TPanel
    AlignWithMargins = True
    Left = 6
    Top = 31
    Width = 320
    Height = 731
    Margins.Left = 6
    Margins.Top = 6
    Margins.Bottom = 6
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 4
    Padding.Top = 4
    Padding.Right = 4
    Padding.Bottom = 4
    ParentBackground = False
    ShowCaption = False
    TabOrder = 2
    object LeftColumnSplitShape: TShape
      Left = 40
      Top = 48
      Width = 65
      Height = 6
      Brush.Color = clBtnShadow
      Pen.Style = psClear
    end
  end
  object CenterColumn: TPanel
    AlignWithMargins = True
    Left = 338
    Top = 31
    Width = 331
    Height = 731
    Margins.Top = 6
    Margins.Bottom = 6
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 4
    Padding.Top = 4
    Padding.Right = 4
    Padding.Bottom = 4
    ParentBackground = False
    ShowCaption = False
    TabOrder = 3
    object HSplitter: TSplitter
      Left = 4
      Top = 4
      Width = 323
      Height = 8
      Cursor = crVSplit
      Align = alTop
      Color = clBlack
      ParentColor = False
      ResizeStyle = rsUpdate
    end
  end
  object RightColumn: TPanel
    AlignWithMargins = True
    Left = 681
    Top = 31
    Width = 592
    Height = 731
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 4
    Padding.Top = 4
    Padding.Right = 4
    Padding.Bottom = 4
    ParentBackground = False
    ShowCaption = False
    TabOrder = 4
    object RightColumnSplitShape: TShape
      Left = 48
      Top = 56
      Width = 65
      Height = 6
      Brush.Color = clBtnShadow
      Pen.Style = psClear
    end
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
    object actNewGame: TAction
      Category = 'File'
      Caption = 'New Game'
      ShortCut = 16462
      OnExecute = actNewGameExecute
    end
  end
end
