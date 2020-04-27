function stats = statistics(time, data, depth)

%% Extract year, month day and hour components of the datenum vector
dateVector = datevec(time);

%% Get week corresponding to each data point
weekVector = weeknum(time);


%% Group by year
disp('Averaging by year...');
[~,~,stats.year.groups]=unique(dateVector(:,1),'rows');
stats.year.quantile = accumarray(stats.year.groups, data, [], @(x) {quantile(x, [0.05 0.25 0.50 0.75 0.95])});
stats.year.max = accumarray(stats.year.groups, data, [], @nanmax);
stats.year.mean = accumarray(stats.year.groups, data, [], @nanmean);
stats.year.time = accumarray(stats.year.groups, time, [], @nanmean);

if(strcmp(depth, 'year'))
    return;
end


%% Group by month
disp('Averaging by month...');
[~,~,stats.month.groups]=unique(dateVector(:,1:2),'rows');
stats.month.quantile = accumarray(stats.month.groups, data, [], @(x) {quantile(x, [0.05 0.25 0.50 0.75 0.95])});
stats.month.max = accumarray(stats.month.groups, data, [], @nanmax);
stats.month.mean = accumarray(stats.month.groups, data, [], @nanmean);
stats.month.time = accumarray(stats.month.groups, time, [], @nanmean);

if(strcmp(depth, 'month'))
    return;
end

%% Group by week
disp('Averaging by week...');
[~,~,stats.week.groups]=unique(weekVector,'rows');
stats.week.quantile = accumarray(stats.week.groups, data, [], @(x) {quantile(x, [0.05 0.25 0.50 0.75 0.95])});
stats.week.mean = accumarray(stats.week.groups, data, [], @nanmean);
stats.week.mean = accumarray(stats.week.groups, data, [], @nanmean);
stats.week.time = accumarray(stats.week.groups, time, [], @nanmean);

if(strcmp(depth, 'week'))
    return;
end

%% Group by day
disp('Averaging by day...');
[~,~,stats.day.groups]=unique(dateVector(:,1:3),'rows');
stats.day.quantile = accumarray(stats.day.groups, data, [], @(x) {quantile(x, [0.05 0.25 0.50 0.75 0.95])});
stats.day.mean = accumarray(stats.day.groups, data, [], @nanmean);
stats.day.time = accumarray(stats.day.groups, time, [], @nanmean);

if(strcmp(depth, 'day'))
    return;
end

%% Group by hour
disp('Averaging by hour...');
[~,~,stats.hour.groups]=unique(dateVector(:,1:4),'rows');
stats.hour.quantile = accumarray(stats.hour.groups, data, [], @(x) {quantile(x, [0.05 0.25 0.50 0.75 0.95])});
stats.hour.mean = accumarray(stats.hour.groups, data, [], @nanmean);
stats.hour.time = accumarray(stats.hour.groups, time, [], @nanmean);

if(strcmp(depth, 'hour'))
    return;
end

end