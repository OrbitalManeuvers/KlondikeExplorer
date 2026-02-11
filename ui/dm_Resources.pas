unit dm_Resources;

interface

uses System.SysUtils, System.Classes;

type
  TProgramResources = class(TDataModule)
  public
    { Public declarations }
  end;

var
  ProgramResources: TProgramResources;


implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
