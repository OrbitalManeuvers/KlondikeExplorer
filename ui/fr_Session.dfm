object SessionFrame: TSessionFrame
  Left = 0
  Top = 0
  Width = 317
  Height = 829
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  DesignSize = (
    317
    829)
  object lblSession: TLabel
    Left = 8
    Top = 2
    Width = 55
    Height = 21
    Caption = 'Session'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 4227327
    Font.Height = -16
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
    StyleElements = [seClient, seBorder]
  end
  object lblSelectedConfig: TLabel
    Left = 8
    Top = 65
    Width = 113
    Height = 17
    Caption = 'Active restart point:'
    FocusControl = edtRestartMethod
  end
  object bvlRight: TBevel
    Left = 313
    Top = 0
    Width = 4
    Height = 829
    Align = alRight
    Shape = bsLeftLine
    Visible = False
    ExplicitLeft = 280
    ExplicitHeight = 144
  end
  object btnActivateRandom: TSpeedButton
    Left = 8
    Top = 167
    Width = 188
    Height = 30
    Caption = 'Activate Random Seed Mode'
    OnClick = btnActivateRandomClick
  end
  object btnReset: TSpeedButton
    Left = 8
    Top = 29
    Width = 299
    Height = 30
    Caption = 'Reset'
    Layout = blGlyphTop
    OnClick = btnResetClick
  end
  object btnSaveSeed: TSpeedButton
    Left = 224
    Top = 206
    Width = 80
    Height = 25
    Caption = 'Save...'
    Layout = blGlyphTop
    OnClick = btnSaveSeedClick
  end
  object btnActivateSeed: TSpeedButton
    Left = 224
    Top = 284
    Width = 80
    Height = 25
    Caption = 'Activate'
    OnClick = btnActivateSeedClick
  end
  object btnEditSeed: TSpeedButton
    Left = 224
    Top = 332
    Width = 80
    Height = 25
    Caption = 'Edit'
    Layout = blGlyphTop
    OnClick = btnEditSeedClick
  end
  object btnDeleteSeed: TSpeedButton
    Left = 224
    Top = 364
    Width = 80
    Height = 25
    Caption = 'Delete'
    Layout = blGlyphTop
    OnClick = btnDeleteSeedClick
  end
  object btnActivateSnapshot: TSpeedButton
    Left = 224
    Top = 496
    Width = 80
    Height = 25
    Caption = 'Activate'
    Layout = blGlyphTop
    OnClick = btnActivateSnapshotClick
  end
  object btnEditSnapshot: TSpeedButton
    Left = 224
    Top = 540
    Width = 80
    Height = 25
    Caption = 'Edit'
    Layout = blGlyphTop
    OnClick = btnEditSnapshotClick
  end
  object btnDeleteSnapshot: TSpeedButton
    Left = 224
    Top = 579
    Width = 80
    Height = 25
    Caption = 'Delete'
    Layout = blGlyphTop
    OnClick = btnDeleteSnapshotClick
  end
  object pbDivider1: TPaintBox
    Left = 0
    Top = 128
    Width = 320
    Height = 3
    OnPaint = DividerPaint
  end
  object lblRandSeeds: TLabel
    Left = 8
    Top = 134
    Width = 100
    Height = 20
    Caption = 'Random Seeds'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 8
    Top = 209
    Width = 90
    Height = 17
    Caption = 'Last generated:'
  end
  object pbDivider2: TPaintBox
    Left = 0
    Top = 248
    Width = 320
    Height = 3
    OnPaint = DividerPaint
  end
  object lblPredefinedSeeds: TLabel
    Left = 9
    Top = 254
    Width = 124
    Height = 20
    Caption = 'Pre-defined Seeds'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object pbDivider3: TPaintBox
    Left = 0
    Top = 464
    Width = 320
    Height = 3
    OnPaint = DividerPaint
  end
  object lblSnapshots: TLabel
    Left = 9
    Top = 470
    Width = 69
    Height = 20
    Caption = 'Snapshots'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Segoe UI Semibold'
    Font.Style = []
    ParentFont = False
  end
  object edtRestartMethod: TEdit
    Left = 8
    Top = 88
    Width = 296
    Height = 25
    ReadOnly = True
    TabOrder = 0
  end
  object SeedList: TControlList
    Left = 8
    Top = 284
    Width = 210
    Height = 167
    ItemHeight = 18
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ParentColor = False
    TabOrder = 1
    OnBeforeDrawItem = SeedListBeforeDrawItem
    OnItemClick = SeedListItemClick
    object lblSeedNameDisplay: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 0
      Width = 198
      Height = 18
      Margins.Left = 4
      Margins.Top = 0
      Margins.Right = 4
      Margins.Bottom = 0
      Align = alClient
      AutoSize = False
      Caption = '(none)'
      Layout = tlCenter
      ExplicitLeft = 16
      ExplicitWidth = 120
      ExplicitHeight = 17
    end
  end
  object SnapshotList: TControlList
    Left = 8
    Top = 496
    Width = 210
    Height = 315
    Anchors = [akLeft, akTop, akBottom]
    ItemHeight = 18
    ItemMargins.Left = 0
    ItemMargins.Top = 0
    ItemMargins.Right = 0
    ItemMargins.Bottom = 0
    ItemSelectionOptions.SelectedColorAlpha = 240
    ItemSelectionOptions.FocusedColorAlpha = 255
    ItemSelectionOptions.SelectedFontColor = clHighlightText
    ItemSelectionOptions.FocusedFontColor = clHighlightText
    ItemSelectionOptions.UseFontColorForLabels = True
    ParentColor = False
    TabOrder = 2
    OnBeforeDrawItem = SnapshotListBeforeDrawItem
    OnClick = SnapshotListClick
    object lblSnapshotNameDisplay: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 3
      Width = 79
      Height = 13
      Margins.Left = 4
      Align = alClient
      Caption = 'Single line text 1'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      Transparent = True
      Layout = tlCenter
    end
  end
  object edtLastGeneratedSeed: TEdit
    Left = 110
    Top = 206
    Width = 110
    Height = 25
    ReadOnly = True
    TabOrder = 3
  end
end
