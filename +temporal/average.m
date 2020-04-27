function ad = average( time, data, getMatrix )

%% Extract year, month day and hour components of the datenum vector
dateVector = datevec(time);

%% Insert week number between month and day
weekVector = weeknum(time);
dateVector = [dateVector(:,1:2) [weekVector(:)] dateVector(:,3:6)];


%% Group by year
disp('Averaging by year...');
[~,~,ad.year.groups]=unique(dateVector(:,1),'rows');
ad.year.mean = accumarray(ad.year.groups, data, [], @nanmean);
ad.year.time = accumarray(ad.year.groups, time, [], @nanmean);


%% Group by month
disp('Averaging by month...');
[~,~,ad.month.groups]=unique(dateVector(:,1:2),'rows');
ad.month.mean = accumarray(ad.month.groups, data, [], @nanmean);
ad.month.time = accumarray(ad.month.groups, time, [], @nanmean);


%% Group by week
disp('Averaging by week...');
[~,~,ad.week.groups]=unique(dateVector(:,1:3),'rows');
ad.week.mean = accumarray(ad.week.groups, data, [], @nanmean);
ad.week.time = accumarray(ad.week.groups, time, [], @nanmean);


%% Group by day
disp('Averaging by day...');
[~,~,ad.day.groups]=unique(dateVector(:,1:4),'rows');
ad.day.mean = accumarray(ad.day.groups, data, [], @nanmean);
ad.day.time = accumarray(ad.day.groups, time, [], @nanmean);


%% Group by hour
disp('Averaging by hour...');
[~,~,ad.hour.groups]=unique(dateVector(:,1:5),'rows');
ad.hour.mean = accumarray(ad.hour.groups, data, [], @nanmean);
ad.hour.time = accumarray(ad.hour.groups, time, [], @nanmean);


%% Group by 30 minute
disp('Averaging by 30 minute...');
minute30Blocks = getMinuteBlocks(dateVector, 30);
[~,~,ad.minute30.groups]=unique([dateVector(:,1:5) minute30Blocks],'rows');
ad.minute30.mean = accumarray(ad.minute30.groups, data, [], @nanmean);
ad.minute30.time = accumarray(ad.minute30.groups, time, [], @nanmean);


%% Group by 10 minute
disp('Averaging by 10 minute...');
minute10Blocks = getMinuteBlocks(dateVector, 10);
[~,~,ad.minute10.groups]=unique([dateVector(:,1:5) minute10Blocks],'rows');
ad.minute10.mean = accumarray(ad.minute10.groups, data, [], @nanmean);
ad.minute10.time = accumarray(ad.minute10.groups, time, [], @nanmean);


%% Group by minute
disp('Averaging by minute...');
[~,~,ad.minute.groups]=unique(dateVector(:,1:6),'rows');
ad.minute.mean = accumarray(ad.minute.groups, data, [], @nanmean);
ad.minute.time = accumarray(ad.minute.groups, time, [], @nanmean);

if(getMatrix)
    ad.year.matrix = getGroupMatrix(data, ad.year.groups);
    ad.month.matrix = getGroupMatrix(data, ad.month.groups);
    ad.week.matrix = getGroupMatrix(data, ad.week.groups);
    ad.day.matrix = getGroupMatrix(data, ad.day.groups);
    ad.hour.matrix = getGroupMatrix(data, ad.hour.groups);
end


end

function minuteBlocks = getMinuteBlocks(dateVector, blockLength)
    % Get column of minute values to be grouped into blocks
    minuteBlocks = dateVector(:,6);
    
    for blockNum = 0:(60/blockLength)-1
        blockStart = blockNum*blockLength;
        blockEnd = (blockNum + 1)*blockLength; 
        
        %disp(blockStart);
        %disp(blockEnd);
        
        minuteBlocks(minuteBlocks >= blockStart & minuteBlocks < blockEnd) = blockNum;
    end
end


%% Group data into a set of matrix rows
function dataMatrix = getGroupMatrix(data, grouping)
    dataCells = accumarray(grouping, data, [], @(x){x})';

    maxSize = max(cellfun(@numel, dataCells)); 
    dataCellsPadded = cellfun(@(x) [nan(maxSize-numel(x),1); x],dataCells,'UniformOutput',false);

    dataMatrix = cell2mat(dataCellsPadded);
end




