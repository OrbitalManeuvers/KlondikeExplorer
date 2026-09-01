inherited SolutionFrame: TSolutionFrame
  Width = 313
  Height = 519
  ExplicitWidth = 313
  ExplicitHeight = 519
  inherited pnlBackground: TPanel
    Width = 313
    Height = 519
    ExplicitTop = 0
    ExplicitWidth = 313
    ExplicitHeight = 519
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 58
      Height = 17
      Caption = 'Solutions'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object btnPlayer: TSpeedButton
      Left = 14
      Top = 30
      Width = 72
      Height = 30
      GroupIndex = 1
      Caption = 'Player'
      OnClick = SolutionTypeClick
    end
    object btnDFS: TSpeedButton
      Left = 84
      Top = 30
      Width = 72
      Height = 30
      GroupIndex = 1
      Caption = 'DFS'
      OnClick = SolutionTypeClick
    end
    object btnBeam: TSpeedButton
      Left = 154
      Top = 30
      Width = 72
      Height = 30
      GroupIndex = 1
      Caption = 'Beam'
      OnClick = SolutionTypeClick
    end
    object btnAStar: TSpeedButton
      Left = 224
      Top = 30
      Width = 72
      Height = 30
      GroupIndex = 1
      Caption = 'A*'
      OnClick = SolutionTypeClick
    end
    object pcSolutionPages: TPageControl
      Left = 8
      Top = 59
      Width = 297
      Height = 454
      ActivePage = tsPlayer
      Anchors = [akLeft, akTop, akBottom]
      TabOrder = 0
      object tsPlayer: TTabSheet
        Caption = 'tsPlayer'
        TabVisible = False
        object PlayerMoveList: TControlList
          Left = 0
          Top = 0
          Width = 289
          Height = 444
          Align = alClient
          ItemMargins.Left = 0
          ItemMargins.Top = 0
          ItemMargins.Right = 0
          ItemMargins.Bottom = 0
          ParentColor = False
          TabOrder = 0
          ExplicitHeight = 436
        end
      end
      object tsSolver: TTabSheet
        Caption = 'tsSolver'
        ImageIndex = 1
        TabVisible = False
      end
    end
  end
end
