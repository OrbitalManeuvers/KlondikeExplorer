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
    Width = 337
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
      Width = 329
      Height = 632
      ActivePage = tsSetup
      Align = alClient
      Style = tsFlatButtons
      TabOrder = 0
      object tsSetup: TTabSheet
        Caption = 'Setup'
        TabVisible = False
        object gbSeedControl: TGroupBox
          AlignWithMargins = True
          Left = 4
          Top = 4
          Width = 313
          Height = 81
          Margins.Left = 4
          Margins.Top = 4
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alTop
          Caption = ' Seeds '
          TabOrder = 0
        end
        object gbDeals: TGroupBox
          AlignWithMargins = True
          Left = 4
          Top = 97
          Width = 313
          Height = 521
          Margins.Left = 4
          Margins.Top = 8
          Margins.Right = 4
          Margins.Bottom = 4
          Align = alClient
          Caption = ' Deals '
          TabOrder = 1
          DesignSize = (
            313
            521)
          object btnGenerateDeals: TSpeedButton
            Left = 8
            Top = 24
            Width = 105
            Height = 33
            Action = actRegen
          end
          object btnStartGame: TSpeedButton
            Left = 8
            Top = 478
            Width = 113
            Height = 33
            Action = actStartGame
            Anchors = [akLeft, akBottom]
            ExplicitTop = 456
          end
          object clDeals: TControlList
            Left = 8
            Top = 63
            Width = 298
            Height = 404
            Anchors = [akLeft, akTop, akRight, akBottom]
            ItemHeight = 58
            ItemMargins.Left = 0
            ItemMargins.Top = 0
            ItemMargins.Right = 0
            ItemMargins.Bottom = 0
            ParentColor = False
            TabOrder = 0
            OnBeforeDrawItem = clDealsBeforeDrawItem
            OnClick = clDealsClick
            OnItemDblClick = clDealsItemDblClick
            object lblDealTitle: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 3
              Width = 37
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
            end
            object lblDealDescription: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 28
              Width = 66
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
            end
          end
        end
      end
      object tsGame: TTabSheet
        Caption = 'Game'
        ImageIndex = 1
        TabVisible = False
        object btnUndo: TPngSpeedButton
          Left = 16
          Top = 40
          Width = 65
          Height = 33
          Action = actUndo
        end
        object btnRedo: TPngSpeedButton
          Left = 88
          Top = 40
          Width = 65
          Height = 33
          Action = actRedo
        end
        object btnHint: TPngSpeedButton
          Left = 159
          Top = 40
          Width = 65
          Height = 33
          Action = actHint
        end
        object btnRestart: TPngSpeedButton
          Left = 231
          Top = 40
          Width = 65
          Height = 33
          Action = actRestart
        end
        object btnEndGame: TPngSpeedButton
          Left = 87
          Top = 575
          Width = 137
          Height = 33
          Action = actEndGame
        end
      end
    end
  end
  object skTable: TSkAnimatedPaintBox
    Left = 337
    Top = 0
    Width = 713
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
    object actStartGame: TAction
      Caption = 'Start Selected'
      OnExecute = actStartGameExecute
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
    object actEndGame: TAction
      Caption = 'End Game'
      OnExecute = actEndGameExecute
    end
  end
end
