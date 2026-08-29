object TableView: TTableView
  AlignWithMargins = True
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentColor = False
  ParentFont = False
  TabOrder = 0
  StyleElements = [seFont, seBorder]
  object skTable: TSkAnimatedPaintBox
    Left = 0
    Top = 41
    Width = 640
    Height = 439
    Align = alClient
    OnMouseDown = skTableMouseDown
    OnMouseMove = skTableMouseMove
    OnMouseUp = skTableMouseUp
    OnResize = skTableResize
    BackgroundColor = xFF27774A
    OnAnimationDraw = skTableAnimationDraw
  end
  object Toolbar: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    Color = 2236962
    ParentBackground = False
    ShowCaption = False
    TabOrder = 1
    StyleElements = [seFont, seBorder]
    object btnHint: TSpeedButton
      Left = 8
      Top = 8
      Width = 50
      Height = 25
      Action = actHint
    end
    object btnUndo: TSpeedButton
      Left = 65
      Top = 8
      Width = 50
      Height = 25
      Action = actUndo
    end
    object btnRedo: TSpeedButton
      Left = 115
      Top = 8
      Width = 50
      Height = 25
      Action = actRedo
    end
    object btnSnapshot: TSpeedButton
      Left = 320
      Top = 8
      Width = 72
      Height = 25
      Action = actSnapshot
    end
    object btnRestart: TSpeedButton
      Left = 243
      Top = 8
      Width = 57
      Height = 25
      Action = actRestart
    end
    object btnComplete: TSpeedButton
      Left = 171
      Top = 8
      Width = 68
      Height = 25
      Action = actAutoComplete
    end
    object lblHScore: TLabel
      AlignWithMargins = True
      Left = 628
      Top = 3
      Width = 4
      Height = 35
      Margins.Right = 8
      Align = alRight
      Layout = tlCenter
      ExplicitLeft = 615
      ExplicitHeight = 17
    end
  end
  object GameActions: TActionList
    Left = 48
    Top = 56
    object actUndo: TAction
      Caption = 'Undo'
      OnExecute = actUndoExecute
    end
    object actRedo: TAction
      Caption = 'Redo'
      OnExecute = actRedoExecute
    end
    object actHint: TAction
      Caption = 'Hint'
      OnExecute = actHintExecute
    end
    object actRestart: TAction
      Caption = 'Restart'
      OnExecute = actRestartExecute
    end
    object actAutoComplete: TAction
      Caption = 'Complete'
      OnExecute = actAutoCompleteExecute
    end
    object actSnapshot: TAction
      Caption = 'Snapshot'
      OnExecute = actSnapshotExecute
    end
  end
end
