unit u_Authors;

interface

uses Vcl.Graphics;

type
  TAuthor = (auPlayer, auDFS, auAStar, auBeam);

  TAuthorHelper = record helper for TAuthor
    function AsText: string;
    function AsColor: TColor;
  end;

implementation

const
  author_colors: array[TAuthor] of TColor = (clWhite, clRed, clGreen, clBlue); { !! }
  author_names: array[TAuthor] of string = ('Player', 'DFS', 'A*', 'Beam');

{ TAuthorHelper }

function TAuthorHelper.AsColor: TColor;
begin
  Result := author_colors[Self];
end;

function TAuthorHelper.AsText: string;
begin
  Result := author_names[Self];
end;

end.
