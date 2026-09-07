inherited StateFrame: TStateFrame
  Width = 317
  Height = 474
  ExplicitWidth = 317
  ExplicitHeight = 474
  inherited pnlBackground: TPanel
    Width = 317
    Height = 474
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
    object btnShelve: TSpeedButton
      Left = 12
      Top = 33
      Width = 69
      Height = 27
      Caption = 'Shelve'
      OnClick = btnShelveClick
    end
    object btnUnshelve: TSpeedButton
      Left = 84
      Top = 33
      Width = 68
      Height = 27
      Caption = 'Unshelve'
      OnClick = btnUnshelveClick
    end
    object btnPlayerView: TSpeedButton
      Left = 168
      Top = 33
      Width = 30
      Height = 27
      AllowAllUp = True
      GroupIndex = 1
      Down = True
      Caption = 'P'
      OnClick = ViewClick
    end
    object btnDFSView: TSpeedButton
      Left = 196
      Top = 33
      Width = 30
      Height = 27
      AllowAllUp = True
      GroupIndex = 2
      Caption = 'D'
      OnClick = ViewClick
    end
    object btnAStarView: TSpeedButton
      Left = 224
      Top = 33
      Width = 30
      Height = 27
      AllowAllUp = True
      GroupIndex = 3
      Caption = 'A*'
      OnClick = ViewClick
    end
    object btnBeamView: TSpeedButton
      Left = 252
      Top = 33
      Width = 30
      Height = 27
      AllowAllUp = True
      GroupIndex = 4
      Caption = 'B'
      OnClick = ViewClick
    end
    object Label1: TLabel
      Left = 8
      Top = 445
      Width = 102
      Height = 17
      Anchors = [akLeft, akBottom]
      Caption = 'Invoke from here:'
    end
    object btnDFSInvoke: TSpeedButton
      Tag = 2
      Left = 116
      Top = 440
      Width = 53
      Height = 27
      Anchors = [akLeft, akBottom]
      Caption = 'DFS'
      OnClick = InvokeClick
    end
    object btnAStarInvoke: TSpeedButton
      Tag = 3
      Left = 175
      Top = 440
      Width = 53
      Height = 27
      Anchors = [akLeft, akBottom]
      Caption = 'A*'
      OnClick = InvokeClick
    end
    object btnBeamInvoke: TSpeedButton
      Tag = 4
      Left = 234
      Top = 440
      Width = 53
      Height = 27
      Anchors = [akLeft, akBottom]
      Caption = 'Beam'
      OnClick = InvokeClick
    end
    object StateTree: TVirtualDrawTree
      Left = 12
      Top = 64
      Width = 291
      Height = 370
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
      OnDrawNode = StateTreeDrawNode
      OnFocusChanged = StateTreeFocusChanged
      OnInitChildren = TreeInitChildren
      OnInitNode = TreeInitNode
      OnMeasureItem = StateTreeMeasureItem
      OnNodeClick = TreeNodeClick
      Touch.InteractiveGestures = [igPan, igPressAndTap]
      Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
      Columns = <>
    end
  end
end
