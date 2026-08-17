object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Klondike Explorer'
  ClientHeight = 787
  ClientWidth = 939
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object MainMenu: TActionMainMenuBar
    Left = 0
    Top = 0
    Width = 939
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
  object MainPages: TPageControl
    Left = 0
    Top = 25
    Width = 939
    Height = 762
    ActivePage = tsGame
    Align = alClient
    Style = tsFlatButtons
    TabOrder = 1
    OnChange = MainPagesChange
    object tsGame: TTabSheet
      Caption = 'Game Mode'
    end
    object tsExplore: TTabSheet
      Caption = 'Explore Mode'
      ImageIndex = 1
    end
    object tsTests: TTabSheet
      Caption = 'Engine Tests'
      ImageIndex = 2
    end
  end
  object MainActions: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = actFileExit
                ImageIndex = 43
                ShortCut = 32856
              end>
            Caption = '&File'
          end>
        ActionBar = MainMenu
      end>
    Left = 96
    Top = 216
    StyleName = 'Platform Default'
    object actFileExit: TFileExit
      Category = 'File'
      Caption = 'E&xit'
      Hint = 'Exit|Quits the application'
      ImageIndex = 43
      ShortCut = 32856
    end
  end
end
