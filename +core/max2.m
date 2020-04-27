function [value, rowIx, colIx] = max2( matrix )
%MAX2 Get the 2D max (row and column) for a 2D matrix

[maxRow, rowIxs] = nanmax(matrix);

[value, colIx] = nanmax(maxRow);

rowIx = rowIxs(colIx);

end

