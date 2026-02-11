object StateFrame: TStateFrame
  Left = 0
  Top = 0
  Width = 259
  Height = 358
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentDoubleBuffered = False
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    259
    358)
  object lblState: TLabel
    Left = 8
    Top = 2
    Width = 45
    Height = 21
    Caption = 'States'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 4227327
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
    StyleElements = [seClient, seBorder]
  end
  object btnExpand: TSpeedButton
    Left = 8
    Top = 32
    Width = 70
    Height = 25
    Caption = 'Expand'
    OnClick = btnExpandClick
  end
  object btnShelve: TSpeedButton
    Left = 87
    Top = 32
    Width = 70
    Height = 25
    Caption = 'Shelve'
    OnClick = btnShelveClick
  end
  object StateTree: TVirtualStringTree
    Left = 8
    Top = 72
    Width = 240
    Height = 273
    Anchors = [akLeft, akTop, akRight, akBottom]
    Colors.BorderColor = 2697513
    Colors.DisabledColor = clGray
    Colors.DropMarkColor = 14581296
    Colors.DropTargetColor = 14581296
    Colors.DropTargetBorderColor = 14581296
    Colors.FocusedSelectionColor = 14581296
    Colors.FocusedSelectionBorderColor = 14581296
    Colors.GridLineColor = 2697513
    Colors.HeaderHotColor = clWhite
    Colors.HotColor = clWhite
    Colors.SelectionRectangleBlendColor = 14581296
    Colors.SelectionRectangleBorderColor = 14581296
    Colors.SelectionTextColor = clWhite
    Colors.TreeLineColor = 9471874
    Colors.UnfocusedColor = clGray
    Colors.UnfocusedSelectionColor = 2368548
    Colors.UnfocusedSelectionBorderColor = 2368548
    Header.AutoSizeIndex = 0
    Header.MainColumn = -1
    TabOrder = 0
    OnGetText = StateTreeGetText
    OnInitChildren = StateTreeInitChildren
    OnInitNode = StateTreeInitNode
    OnNodeClick = StateTreeNodeClick
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
end
