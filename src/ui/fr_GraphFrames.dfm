inherited GraphFrame: TGraphFrame
  Height = 109
  ExplicitHeight = 109
  inherited pnlBackground: TPanel
    Height = 109
    ExplicitTop = 0
    ExplicitHeight = 109
    object btnPlayer: TSpeedButton
      Left = 8
      Top = 4
      Width = 65
      Height = 27
      AllowAllUp = True
      GroupIndex = 1
      Caption = 'Player'
    end
    object btnDFS: TSpeedButton
      Left = 8
      Top = 28
      Width = 65
      Height = 27
      AllowAllUp = True
      GroupIndex = 2
      Caption = 'DFS'
    end
    object btnBeam: TSpeedButton
      Left = 8
      Top = 52
      Width = 65
      Height = 27
      AllowAllUp = True
      GroupIndex = 3
      Caption = 'Beam'
    end
    object btnAStar: TSpeedButton
      Left = 8
      Top = 76
      Width = 65
      Height = 27
      AllowAllUp = True
      GroupIndex = 4
      Caption = 'A*'
    end
  end
end
