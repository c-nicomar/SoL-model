function dg = decompose( time, data, discardMissing )
%DECOMPOSE Summary of this function goes here
%   Detailed explanation goes here

%% Data Padding ===========================================================
disp('Padding NaN values...');

[completeTime, completeData] = temporal.complete(time, data);

%% Daily Grouping =========================================================
disp('Grouping by day...');
dg.data = reshape(completeData, 144, length(completeData)/144);
dg.time = reshape(completeTime, 144, length(completeTime)/144);

%% Cleaning ===============================================================
disp('Zeroing tail NaNs...');
% Get index of all rows that should always be zero and set to zero if NaN
zeroIx = nansum(dg.data, 2) == 0;
dg.data(zeroIx, :) = 0;

if(discardMissing)
    disp('Discarding days with missing data...');
    % User has elected to discard any days with missing values so find all
    % the valid columns, i.e. the columns that do not contain any NaN
    % values
    validColumn = ~any(isnan(dg.data));
    
    % Create a new array keeping all rows from just the valid columns -
    % discard everything else
    dg.data = dg.data(:, validColumn);
    dg.time = dg.time(:, validColumn);
end

disp('Grouping by day...');
[dg.timeDay, dg.dataDay] = temporal.matrixGroup(dg.time, dg.data, 144, 1);

disp('Grouping by half day...');
[dg.timeHalfDay, dg.dataHalfDay] = temporal.matrixGroup(dg.time, dg.data, 144, 2);

disp('Grouping by hour...');
[dg.timeHour, dg.dataHour] = temporal.matrixGroup(dg.time, dg.data, 144, 24);


% [~, ~, ~, hourGroup, ~, ~] = datevec(dg.time(:,1));
% 
% dg.meanHour = accumarray(hourGroup, dg.data, [], @mean);
% dg.timeHour = accumarray(hourGroup, dg.time, [], @mean);

end

