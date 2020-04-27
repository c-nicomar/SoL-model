function dailyClearnessIndexes = synthesiseDailyClearnessIndexes( years, monthlyClearnessIndexes, varargin )
% SYNTHESISE_DAILY_CLEARNESS_INDEXES Synthesises a sequence of daily clearness 
% indices (Kt) using the mean monthly clearness index and a set of empirically
% determined Markov transition matrices from the original Aguiar work, the 
% updated Meteonorm work or provided by the user
% Parameters:
%   (required)
%   - years: A scalar or vector of years [2011, 2012]
%   - monthlyClearnessIndexes: A vector containing 12 mean clearness indexes
%     corresponding to each month of the year [Jan, Feb, Mar, ..., Dec]
%   (optional)
%   - model (default: meteonorm): The set of Markov transition matrices to
%     use for the model. Either the original 'aguiar' set or the more
%     recent and updated Meteonorm set
%   - initialClearnessIndex (default: mean clearness index of last month):
%     The clearness index to use for computing the first value of the data
%     series

%% 0.1 Parameter Parsing ==================================================

p = inputParser;
p.addRequired('years', @isnumeric);
p.addRequired('monthlyClearnessIndexes', @(x) ((length(x) == 12) && all(isnumeric(x) & (x >0) & (x <= 1))));
p.addOptional('initialDailyClearnessIndex', monthlyClearnessIndexes(end), @(x) (isscalar(x) & (x > 0) & ( x<= 1)));
p.addOptional('model', 'meteonorm', @ischar);
p.parse(years, monthlyClearnessIndexes, varargin{:});

model = p.Results.model;
years = p.Results.years;
monthlyClearnessIndexes = p.Results.monthlyClearnessIndexes;
lastDailyClearnessIndex = p.Results.initialDailyClearnessIndex;

%% 0.2) Definitions =======================================================

MONTHS_IN_YEAR = 12;

CLEARNESS_INDEX_BINS = 0:0.1:1.0;

MAX_ITERATIONS = 50;

%% 2) Transition Indexing =================================================

% Calculate the number of days covering the vector of years given (from
% start of first year specified, to end of last year specified)
numberOfDays = daysact(datenum(min(years), 1, 1), datenum(max(years) + 1, 1, 1));
currentDayIx = 1;

dailyClearnessIndexes = nan(numberOfDays, 1);

% Get a set of random numbers for the entirety of the current time series
% - more computationally efficient than calling this function every
% time a random number is needed
%randomNumbers = rand(numberOfDays, 1);

for yearIx = 1:length(years)
    for month = 1:MONTHS_IN_YEAR
        %% 1) Makov Matrix Selection ______________________________________
        %  Select the Markov transition matrix corresponding to the
        %  clearness index of the current month
        currentMarkovTransitionMatrix = getMarkovTransitionMatrix(model, monthlyClearnessIndexes(month));
        
        daysInMonth = eomday(years(yearIx), month);
        
        clearnessIndexError = 100;
        iterationCount = 0;
        % Save variables for each iteration
        startDayIx = currentDayIx;
        startDailyClearnessIndex = lastDailyClearnessIndex;
        
        % Repeat random process until the error between the mean monthly
        % clearness index of the actual and estimated values is less than
        % 1%, or the number of iterations has exceeded the maximum allowed
        while((iterationCount < MAX_ITERATIONS) && (clearnessIndexError > 1))
            % Ensure same starting values are maintained for each iteration
            currentDayIx = startDayIx;
            lastDailyClearnessIndex = startDailyClearnessIndex;
            
            for dayIx = 1:daysInMonth

                [~, ~, currentRowIx] = histcounts(lastDailyClearnessIndex, CLEARNESS_INDEX_BINS);
                if(currentRowIx == 0)
                    currentRowIx = 10;
                end
                
                cumulativeSum = cumsum(currentMarkovTransitionMatrix(currentRowIx,:));
                
                uniformRandomNumber = rand;
                
                currentTransitionIx = find(cumulativeSum > uniformRandomNumber, 1);
                % Unable to find value greater so cap to end
                if(isempty(currentTransitionIx))
                    currentTransitionIx = 10;
                end
                
                
                currentCumulativeSum = cumulativeSum(currentTransitionIx);

                if(currentTransitionIx == 1)
                    lastCumulativeSum = 0;
                else
                    lastCumulativeSum = cumulativeSum(currentTransitionIx - 1);
                end
                
                lastDailyClearnessIndex = (0.1/(currentCumulativeSum - lastCumulativeSum))*(uniformRandomNumber - lastCumulativeSum) + CLEARNESS_INDEX_BINS(currentTransitionIx);
                    
                dailyClearnessIndexes(currentDayIx, 1) = lastDailyClearnessIndex;

                currentDayIx = currentDayIx + 1;
            end

            clearnessIndexError = 100 * abs(monthlyClearnessIndexes(month) - mean(dailyClearnessIndexes(startDayIx:currentDayIx - 1)))/monthlyClearnessIndexes(month);
        end
    end
end

end

%% Get the corresponding Markov Transition Matrix
%  Loads and returns the Markov Transition Matrix corresponding to the
%  specified model for the given month
%
%  Note that due to the overhead of loading the matrix datasets from a .mat
%  file, the transition matrix sets are persisted in memory and will only be
%  reloaded if the specified model is changed
function markovTransitionMatrix = getMarkovTransitionMatrix(model, monthlyClearnessIndex)
    persistent markovTransitionMatrices;
    persistent currentModel;
    persistent monthlyClearnessIndexBins;
    
    % If a model has not currently been executed, force execution
    if(isempty(currentModel))
        currentModel = 'null';
    end
    
    % If model has been executed, but does not match the current model
    % request then execute
    if(~strcmp(currentModel, model))
        switch(model)
            case 'meteonorm'
                monthlyClearnessIndexBins = 0.1:0.1:1;
                
                % Load the set of all Markov Transition matrices for this
                % model and upack the internal variable
                markovTransitionMatrices = load('..\library\synthesis\daily\meteonorm.mat');
                markovTransitionMatrices = markovTransitionMatrices.markovTransitionMatrices;
            case 'aguiar'
                monthlyClearnessIndexBins = [-Inf 0.3:0.05:0.7 Inf];
                
                markovTransitionMatrices = load('..\library\synthesis\daily\aguiar.mat');
                markovTransitionMatrices = markovTransitionMatrices.markovTransitionMatrices;
        end
        currentModel = model;
    end
    
    % Get the matrix bin corresponding to the given monthly clearness index, and
    % the select the corresponding matrix
    [~, ~, markovTransitionMatrixIx] = histcounts(monthlyClearnessIndex, monthlyClearnessIndexBins);

    markovTransitionMatrix = squeeze(markovTransitionMatrices(markovTransitionMatrixIx, :, :));
end

