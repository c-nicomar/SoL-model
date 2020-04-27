function [ completeTime, completeData ] = complete(time, data)
%COMPLETE Generates a 'complete' version of the time series with no data
%holes. NaN values are generated for empty time points.
    
[time, sortedIx] = sort(time);
data = data(sortedIx);

% timeStep = diff(time);
% timeStep(timeStep == 0) = Inf;

% Round starting and ending datevalues to the nearest day start/end
dvStart = datevec(time(1));
dvStart(4:6) = 0;
dvEnd = datevec(time(end));
dvEnd(4) = 23;
dvEnd(5) = 50;
dvEnd(6) = 0;

completeTime = datenum(dvStart):600/86400:datenum(dvEnd);

% Converting to datevec effectively removes floating point noise at
% sub-millisecond level, ensuring valid floating point equality
% comparisons can be carried out
completeTime = datenum(datevec(completeTime));

% Generate an array with dummy NaN values for each data point and map
% across the actual data values
completeData = nan(length(completeTime), 1);
[~, ia, ib] = intersect(completeTime, time);
completeData(ia) = data(ib);

end

