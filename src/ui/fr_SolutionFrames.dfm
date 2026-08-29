inherited SolutionFrame: TSolutionFrame
  Width = 313
  Height = 519
  ExplicitWidth = 313
  ExplicitHeight = 519
  inherited pnlBackground: TPanel
    Width = 313
    Height = 519
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
    object Placeholder: TShape
      Left = 8
      Top = 31
      Width = 297
      Height = 34
      Brush.Color = clBlack
    end
    object pcSolutionPages: TPageControl
      Left = 8
      Top = 67
      Width = 297
      Height = 446
      ActivePage = tsPlayer
      Anchors = [akLeft, akTop, akBottom]
      TabOrder = 0
      object tsPlayer: TTabSheet
        Caption = 'tsPlayer'
        TabVisible = False
        object ControlList1: TControlList
          Left = 0
          Top = 0
          Width = 289
          Height = 436
          Align = alClient
          ItemMargins.Left = 0
          ItemMargins.Top = 0
          ItemMargins.Right = 0
          ItemMargins.Bottom = 0
          ParentColor = False
          TabOrder = 0
          ExplicitLeft = 56
          ExplicitTop = 72
          ExplicitWidth = 200
          ExplicitHeight = 200
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
