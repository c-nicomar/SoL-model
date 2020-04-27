function [groupedTime, groupedData] = matrixGroup( time, data, inPoints, outPoints )
%MATRIXGROUP Summary of this function goes here
%   Detailed explanation goes here

pointRatio = inPoints / outPoints;

groupedData = mean(reshape(data, pointRatio, numel(data)/pointRatio));
groupedTime = mean(reshape(time, pointRatio, numel(data)/pointRatio));

groupedData = reshape(groupedData, outPoints, numel(groupedData)/outPoints);
groupedTime = reshape(groupedTime, outPoints, numel(groupedTime)/outPoints);

end

