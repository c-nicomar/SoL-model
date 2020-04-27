function av = averagePeriod( time, data, varargin )

%% Extract year, month day and hour components of the datenum vector
dateVector = datevec(time);

%% Insert week number between month and day
weekVector = weeknum(time)';
dateVector = [dateVector(:,1:2) weekVector dateVector(:,3:6)];

% By default the length of each period is 1 unit
period = 1;

if(nargin <= 2)
    units = 'day';
end

if(nargin >= 3)
    period = varargin{1};
end

if(nargin >= 4)
    units = varargin{2};
end

switch(units)
    case 'year'
        %% Group by year
        disp('Averaging by year...');
        [~,~,ad.year.groups]=unique(dateVector(:,1),'rows');
        av.data = accumarray(ad.year.groups, data, [], @nanmean);
        av.time = accumarray(ad.year.groups, time, [], @nanmean);
        
    case 'month'
        %% Group by month
        disp('Averaging by month...');
        [~,~,ad.month.groups]=unique(dateVector(:,1:2),'rows');
        av.data = accumarray(ad.month.groups, data, [], @nanmean);
        av.time = accumarray(ad.month.groups, time, [], @nanmean);
        
    case 'week'
        %% Group by week
        disp('Averaging by week...');
        [~,~,ad.week.groups]=unique(dateVector(:,1:3),'rows');
        av.data = accumarray(ad.week.groups, data, [], @nanmean);
        av.time = accumarray(ad.week.groups, time, [], @nanmean);

    case 'day'

        %% Group by day
        disp('Averaging by day...');
        [~,~,ad.day.groups]=unique(dateVector(:,1:4),'rows');
        av.data = accumarray(ad.day.groups, data, [], @nanmean);
        av.time = accumarray(ad.day.groups, time, [], @nanmean);
        
    case 'hour'
        %% Group by hour
        disp('Averaging by hour...');
        if(period == 1)
            [~,~,ad.hour.groups]=unique(dateVector(:,1:5),'rows');
        else
            hourBlocks = getHourBlocks(dateVector, period);
            [~,~,ad.hour.groups]=unique([dateVector(:,1:4) hourBlocks],'rows');
        end
        av.data = accumarray(ad.hour.groups, data, [], @nanmean);
        av.time = accumarray(ad.hour.groups, time, [], @nanmean);

    case 'minute'
        %% Group by minute
        disp('Averaging by minute...');
        if(period == 1)
            [~,~,ad.minute.groups]=unique(dateVector(:,1:6),'rows');
        else
            minuteBlocks = getMinuteBlocks(dateVector, period);
            [~,~,ad.minute.groups]=unique([dateVector(:,1:5) minuteBlocks],'rows');
        end
        av.data = accumarray(ad.minute.groups, data, [], @nanmean);
        av.time = accumarray(ad.minute.groups, time, [], @nanmean);
	
    case 'second'
        %% Group by minute
        disp('Averaging by second...');
        if(period == 1)
            [~,~,ad.second.groups]=unique(dateVector(:,1:7),'rows');
        else
            secondBlocks = getSecondBlocks(dateVector, period);
            [~,~,ad.second.groups]=unique([dateVector(:,1:6) secondBlocks],'rows');
        end
        
        av.data = accumarray(ad.second.groups, data, [], @nanmean);
        av.time = accumarray(ad.second.groups, time, [], @nanmean);
end

end

function hourBlocks = getHourBlocks(dateVector, blockLength)
    % Get column of hour values to be grouped into blocks
    hourBlocks = dateVector(:,5);
    
    for blockNum = 0:(24/blockLength)-1
        blockStart = blockNum*blockLength;
        blockEnd = (blockNum + 1)*blockLength; 
        
        hourBlocks(hourBlocks >= blockStart & hourBlocks < blockEnd) = blockNum;
    end
end

function minuteBlocks = getMinuteBlocks(dateVector, blockLength)
    % Get column of minute values to be grouped into blocks
    minuteBlocks = dateVector(:,6);
    
    for blockNum = 0:(60/blockLength)-1
        blockStart = blockNum*blockLength;
        blockEnd = (blockNum + 1)*blockLength; 
        
        minuteBlocks(minuteBlocks >= blockStart & minuteBlocks < blockEnd) = blockNum;
    end
end

function secondBlocks = getSecondBlocks(dateVector, blockLength)
    secondBlocks = dateVector(:, 7);

    for blockNum = 0:(60/blockLength)-1
        blockStart = blockNum*blockLength;
        blockEnd = (blockNum + 1)*blockLength; 
        
        secondBlocks(secondBlocks >= blockStart & secondBlocks < blockEnd) = blockNum;
    end
end
    





