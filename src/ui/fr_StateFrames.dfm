inherited StateFrame: TStateFrame
  Width = 284
  ExplicitWidth = 284
  inherited pnlBackground: TPanel
    Width = 284
    ExplicitTop = 0
    ExplicitWidth = 284
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 61
      Height = 17
      Caption = 'State Tree'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Tree: TVirtualStringTree
      Left = 8
      Top = 31
      Width = 265
      Height = 439
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
      OnGetText = TreeGetText
      OnInitChildren = TreeInitChildren
      OnInitNode = TreeInitNode
      OnNodeClick = TreeNodeClick
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <>
    end
  end
end
