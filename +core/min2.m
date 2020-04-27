function [value, rowIx, colIx] = min2( matrix )
%MAX2 Get the 2D max (row and column) for a 2D matrix

[maxRow, rowIxs] = nanmin(matrix);

[value, colIx] = nanmin(maxRow);

rowIx = rowIxs(colIx);

end

