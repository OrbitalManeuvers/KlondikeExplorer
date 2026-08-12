inherited GameFrame: TGameFrame
  Width = 1050
  Height = 632
  Font.Height = -13
  ParentFont = False
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
      ActivePage = tsGame
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
            Caption = 'Regenerate'
            OnClick = btnGenerateDealsClick
          end
          object btnPlay: TSpeedButton
            Left = 8
            Top = 478
            Width = 113
            Height = 33
            Anchors = [akLeft, akBottom]
            Caption = 'Play'
            OnClick = btnPlayClick
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
            object lblDealTitle: TLabel
              AlignWithMargins = True
              Left = 8
              Top = 3
              Width = -16
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
              Width = -11
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
      end
      object tsGame: TTabSheet
        Caption = 'Game'
        ImageIndex = 1
        TabVisible = False
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
end
