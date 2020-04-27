function fullArray = repeatArray( array, count )
%REPEATARRAY Repeats the elements in an array a specified number of times
% Example: repeatArray([1 2 3], 2) -> [1 1 2 2 3 3]

matrix = repmat(array, count,1);
fullArray = matrix(:);

end

