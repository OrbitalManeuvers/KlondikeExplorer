object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Klondike Explorer'
  ClientHeight = 950
  ClientWidth = 1338
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object phLog: TShape
    Left = 0
    Top = 815
    Width = 1338
    Height = 113
    Align = alBottom
    Brush.Color = 7358844
    Pen.Style = psClear
    ExplicitLeft = 8
    ExplicitTop = 434
    ExplicitWidth = 921
  end
  object phSession: TShape
    Left = 0
    Top = 0
    Width = 313
    Height = 805
    Align = alLeft
    Brush.Color = 6913097
    Pen.Style = psClear
  end
  object shpSpacerH: TShape
    Left = 0
    Top = 805
    Width = 1338
    Height = 10
    Align = alBottom
    Brush.Color = clGray
    Pen.Style = psClear
    ExplicitTop = 435
    ExplicitWidth = 966
  end
  object shpSpacerV: TShape
    Left = 313
    Top = 0
    Width = 10
    Height = 805
    Align = alLeft
    Brush.Color = clGray
    Pen.Style = psClear
    ExplicitLeft = 500
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 928
    Width = 1338
    Height = 22
    Panels = <
      item
        Style = psOwnerDraw
        Text = '(Mem Status)'
        Width = 150
      end>
    ParentFont = True
    UseSystemFont = False
    OnDrawPanel = StatusBarDrawPanel
  end
  object PageControl: TPageControl
    Left = 323
    Top = 0
    Width = 1015
    Height = 805
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    ActivePage = tsEngineWorkbench
    Align = alClient
    TabOrder = 1
    OnChange = PageControlChange
    object tsEngineWorkbench: TTabSheet
      Caption = 'Engine Workbench'
    end
    object tsSolverWorkbench: TTabSheet
      Caption = 'Solver Workbench'
      ImageIndex = 1
    end
    object tsAutomatedTests: TTabSheet
      Caption = 'Automated Tests'
      ImageIndex = 2
    end
  end
  object AppEvents: TApplicationEvents
    OnIdle = AppEventsIdle
    Left = 824
    Top = 472
  end
end
