function stats = statisticsGeneric(time, data, depth, functionSet)
%% 1) Temporal Grouping ===================================================

% Extract year, month day and hour components of the datenum vector
dateVector = datevec(time);

% Get week corresponding to each data point
weekVector = weeknum(time);


[~,~,temporal.year.groups]=unique(dateVector(:,1),'rows');
[~,~,temporal.month.groups]=unique(dateVector(:,1:2),'rows');
[~,~,temporal.week.groups]=unique(weekVector,'rows');
[~,~,temporal.day.groups]=unique(dateVector(:,1:3),'rows');
[~,~,temporal.hour.groups]=unique(dateVector(:,1:4),'rows');

temporalNames = fieldnames(temporal);

functionNames = fieldnames(functionSet);

%% 2) Calculation =========================================================

for temporalIx = 1:length(temporalNames)
    
    currentTemporal = temporalNames{temporalIx};
    
    for functionIx = 1:length(functionNames)
        currentStat = functionNames{functionIx};
        
        if(functionSet.(currentStat).returnsMultiple)
            stats.(currentTemporal).(currentStat) = accumarray(temporal.(currentTemporal).groups, data, [], @(x) {functionSet.(currentStat).handle(x)});
        else
            stats.(currentTemporal).(currentStat) = accumarray(temporal.(currentTemporal).groups, data, [], functionSet.(currentStat).handle);
        end
        
    end
    
    if(strcmp(currentTemporal, depth))
        return;
    end
end



end