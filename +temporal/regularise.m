function [regularTime, regularMask] = regularise( time, step )
% REGULARISE Removes all time values that do not have the required step or
% do not exist for a complete period.
% Note that the resulting time series may still have gaps/holes - they just
% won't be in the middle of a time period.

%% 1) Processing ==========================================================

[yearVec, monthVec, dayVec, ~, ~, ~] = datevec(time);

% Get the complete, regular time series from the first date in the series
% to the last
startDay = datenum(yearVec(1), monthVec(1), dayVec(1));
endDay = datenum(yearVec(end), monthVec(end), dayVec(end));

timeVecFull = (startDay : step : endDay)';
timeVecFull = timeVecFull(1:end-1);

% Find all the days that have values missing (are present in one time series
% but not the other)
[missingTime, ~] = setxor(timeVecFull, time);

% Find all days with missing data and remove
[yearMissing, monthMissing, dayMissing, ~, ~, ~] = datevec(missingTime);

toRemove = ismember(datenum(yearVec, monthVec, dayVec), datenum(yearMissing, monthMissing, dayMissing));

% Ensure the final array contains only unique values
[~, uniqueIx, ~] = unique(time);

% Convert the unique index values into a logical array
uniqueMask = zeros(size(toRemove));
uniqueMask(uniqueIx) = 1;

% Return the mask used to regularise the time series so that it can be
% applied to corresponding datasets
regularMask = ~toRemove & uniqueMask;

% Return the regularised time series without NaN values and with all
% partial periods removed
regularTime = time(regularMask);

end

