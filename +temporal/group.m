function gd = group( time, period )

%% Extract year, month, day and hour components of the datenum vector
dateVector = datevec(time);

switch(period)
    % Group by year
    case 'year'
        [gd.value,~,gd.group]=unique(dateVector(:,1),'rows');
    % Group by month
    case 'month'
        [gd.value,~,gd.group]=unique(dateVector(:,1:2),'rows');
    % Group by week
    case 'week'
        weekVector = weeknum(time);
        weekVector = reshape(weekVector, [numel(weekVector), 1]);
        dateVector = [dateVector(:,1) weekVector];
        [gd.value,~,gd.group]=unique(dateVector(:,1:2),'rows');
	% Group by day
    case 'day'
        weekVector = weeknum(time);
        weekVector = reshape(weekVector, [numel(weekVector), 1]);
        dateVector = [dateVector(:,1:2) weekVector dateVector(:,3)];
        [gd.value,~,gd.group]=unique(dateVector(:,1:4),'rows');
end

end
