function ad = yearAverage(time, data)

%% Extract year, month day and hour components of the datenum vector
dateVector = datevec(time);

[~,~,groups]=unique(dateVector(:,1),'rows');
ad.mean = accumarray(groups, data, [], @nanmean);
ad.time = accumarray(groups, time, [], @nanmean);

end

