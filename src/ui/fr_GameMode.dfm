inherited GameFrame: TGameFrame
  Width = 1050
  Height = 632
  Color = clBlack
  Font.Height = -13
  ParentBackground = False
  ParentColor = False
  ParentFont = False
  StyleElements = [seFont, seBorder]
  ExplicitWidth = 1050
  ExplicitHeight = 632
  object pnlGameControls: TPanel
    Left = 0
    Top = 0
    Width = 313
    Height = 632
    Align = alLeft
    BevelOuter = bvNone
    Padding.Left = 4
    Padding.Right = 4
    ShowCaption = False
    TabOrder = 0
    object pcControlPages: TPageControl
      Left = 4
      Top = 0
      Width = 305
      Height = 632
      ActivePage = tsLiveMode
      Align = alClient
      Style = tsFlatButtons
      TabOrder = 0
      object tsSetupMode: TTabSheet
        Caption = 'Setup'
        TabVisible = False
        DesignSize = (
          297
          622)
        object Label2: TLabel
          Left = 3
          Top = 9
          Width = 117
          Height = 17
          Caption = 'Select starting state:'
        end
        object btnGenerateDeals: TSpeedButton
          Left = 3
          Top = 579
          Width = 86
          Height = 33
          Action = actRegen
          Anchors = [akLeft, akBottom]
        end
        object btnStartLiveMode: TSpeedButton
          Left = 136
          Top = 579
          Width = 150
          Height = 33
          Action = actStartLiveMode
          Anchors = [akLeft, akBottom]
        end
        object btnNewDeals: TSpeedButton
          Left = 3
          Top = 39
          Width = 140
          Height = 33
          GroupIndex = 1
          Down = True
          Caption = 'New Deals'
          OnClick = StartStateChange
        end
        object btnSnapshots: TSpeedButton
          Left = 151
          Top = 39
          Width = 140
          Height = 33
          GroupIndex = 1
          Caption = 'Snapshots'
          OnClick = StartStateChange
        end
        object StateList: TControlList
          Left = 3
          Top = 79
          Width = 288
          Height = 486
          Anchors = [akLeft, akTop, akRight, akBottom]
          ItemHeight = 58
          ItemMargins.Left = 0
          ItemMargins.Top = 0
          ItemMargins.Right = 0
          ItemMargins.Bottom = 0
          ParentColor = False
          TabOrder = 0
          OnBeforeDrawItem = StateListBeforeDrawItem
          OnClick = StateListClick
          OnItemDblClick = StateListItemDblClick
          object lblDealTitle: TLabel
            AlignWithMargins = True
            Left = 8
            Top = 3
            Width = 268
            Height = 25
            Margins.Left = 8
            Margins.Right = 8
            Margins.Bottom = 0
            Align = alTop
            Caption = 'Title'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWhite
            Font.Height = -19
            Font.Name = 'Segoe UI Semibold'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
            ExplicitWidth = 37
          end
          object lblDealDescription: TLabel
            AlignWithMargins = True
            Left = 8
            Top = 28
            Width = 273
            Height = 17
            Margins.Left = 8
            Margins.Top = 0
            Align = alTop
            Caption = 'Description'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWhite
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            StyleElements = [seClient, seBorder]
            ExplicitWidth = 66
          end
        end
      end
      object tsLiveMode: TTabSheet
        Caption = 'LiveMode'
        ImageIndex = 1
        TabVisible = False
        object btnUndo: TPngSpeedButton
          Left = 17
          Top = 40
          Width = 80
          Height = 33
          Action = actUndo
        end
        object btnRedo: TPngSpeedButton
          Left = 104
          Top = 40
          Width = 80
          Height = 33
          Action = actRedo
        end
        object btnHint: TPngSpeedButton
          Left = 191
          Top = 40
          Width = 80
          Height = 33
          Action = actHint
        end
        object btnRestart: TPngSpeedButton
          Left = 17
          Top = 96
          Width = 80
          Height = 33
          Action = actRestart
        end
        object btnEndGame: TPngSpeedButton
          Left = 104
          Top = 96
          Width = 80
          Height = 33
          Action = actEndLiveMode
        end
        object btnAutoComplete: TPngSpeedButton
          Left = 191
          Top = 96
          Width = 80
          Height = 33
          Action = actAutoComplete
        end
        object GroupBox1: TGroupBox
          Left = 3
          Top = 152
          Width = 290
          Height = 145
          Caption = ' Save Snapshot'
          TabOrder = 0
          object Label1: TLabel
            Left = 16
            Top = 35
            Width = 38
            Height = 17
            Caption = 'Name:'
          end
          object btnSaveSnapshot: TPngSpeedButton
            Left = 16
            Top = 95
            Width = 80
            Height = 33
            Action = actRestart
            Caption = 'Save'
            OnClick = btnSaveSnapshotClick
          end
          object edtSnapshotName: TEdit
            Left = 72
            Top = 32
            Width = 200
            Height = 25
            TabOrder = 0
            OnChange = edtSnapshotNameChange
          end
          object rbStarting: TRadioButton
            Left = 16
            Top = 64
            Width = 113
            Height = 17
            Caption = 'Starting state'
            TabOrder = 1
          end
          object rbCurrentState: TRadioButton
            Left = 160
            Top = 64
            Width = 113
            Height = 17
            Caption = 'Current state'
            Checked = True
            TabOrder = 2
            TabStop = True
          end
        end
      end
    end
  end
  object skTable: TSkAnimatedPaintBox
    Left = 313
    Top = 0
    Width = 737
    Height = 632
    Align = alClient
    OnMouseDown = skTableMouseDown
    OnMouseMove = skTableMouseMove
    OnMouseUp = skTableMouseUp
    OnResize = skTableResize
    BackgroundColor = claSeagreen
    OnAnimationDraw = skTableAnimationDraw
  end
  object GameActions: TActionList
    Left = 512
    Top = 304
    object actRegen: TAction
      Caption = 'Regenerate'
      OnExecute = actRegenExecute
    end
    object actStartLiveMode: TAction
      Caption = 'Start Selected'
      OnExecute = actStartLiveModeExecute
    end
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
    object actEndLiveMode: TAction
      Caption = 'End Game'
      OnExecute = actEndLiveModeExecute
    end
    object actAutoComplete: TAction
      Caption = 'Complete'
      OnExecute = actAutoCompleteExecute
    end
  end
end
