object MovesFrame: TMovesFrame
  Left = 0
  Top = 0
  Width = 304
  Height = 781
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    304
    781)
  object lblMoves: TLabel
    Left = 8
    Top = 2
    Width = 49
    Height = 21
    Caption = 'Moves'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 4227327
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
    StyleElements = [seClient, seBorder]
  end
  object MoveList: TControlList
    Left = 8
    Top = 29
    Width = 281
    Height = 140
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 24
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 0
    OnBeforeDrawItem = MoveListBeforeDrawItem
    OnItemClick = MoveListItemClick
    object lblCaption: TLabel
      Left = 49
      Top = 0
      Width = 228
      Height = 24
      Align = alClient
      AutoSize = False
      Caption = '000'
      Color = clWindowText
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      ExplicitLeft = 32
      ExplicitTop = 8
      ExplicitWidth = 49
      ExplicitHeight = 20
    end
    object lblScore: TLabel
      Left = 0
      Top = 0
      Width = 49
      Height = 24
      Align = alLeft
      Alignment = taCenter
      AutoSize = False
      Caption = '000'
      Color = 4259584
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      Layout = tlCenter
      StyleElements = [seClient, seBorder]
      ExplicitLeft = 32
      ExplicitTop = 8
      ExplicitHeight = 20
    end
  end
  object FactorList: TControlList
    Left = 10
    Top = 184
    Width = 277
    Height = 233
    Anchors = [akLeft, akTop, akRight]
    ItemHeight = 20
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ItemSelectionOptions.HotColor = clWindow
    ItemSelectionOptions.SelectedColor = clWindow
    ItemSelectionOptions.FocusedColor = clWindow
    ParentColor = False
    TabOrder = 1
    OnBeforeDrawItem = FactorListBeforeDrawItem
    object lblScoreFactor: TLabel
      Left = 4
      Top = 0
      Width = 83
      Height = 17
      Caption = 'lblScoreFactor'
      StyleElements = [seClient, seBorder]
    end
  end
  object FeatureList: TValueListEditor
    Left = 16
    Top = 423
    Width = 271
    Height = 346
    Anchors = [akLeft, akTop, akBottom]
    DefaultDrawing = False
    DisplayOptions = [doAutoColResize, doKeyColFixed]
    Enabled = False
    FixedCols = 1
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goThumbTracking]
    Strings.Strings = (
      'KingPressure=4'
      'Somethilg=Eles')
    TabOrder = 2
    TitleCaptions.Strings = (
      'Feature'
      'Value')
    OnDrawCell = FeatureListDrawCell
    ColWidths = (
      150
      115)
  end
end
