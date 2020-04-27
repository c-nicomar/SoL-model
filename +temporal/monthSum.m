function sd = monthSum(time, data)

%% Extract year, month day and hour components of the datenum vector
dateVector = datevec(time);

[~,~,groups]=unique(dateVector(:,1:2),'rows');
sd.sum = accumarray(groups, data, [], @sum);
sd.time = accumarray(groups, time, [], @nanmean);

end

