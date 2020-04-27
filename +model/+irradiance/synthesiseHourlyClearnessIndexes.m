function hourlyClearnessIndexes = synthesiseHourlyClearnessIndexes(time, location, dailyClearnessIndexes, varargin )
% SYNTHESISE_HOURLY_CLEARNESS_INDEXES Synthesises a sequence of hourly clearness
% indices (Kt) using the mean daily clearness index and the time-dependent,
% autoregressive, Gaussian (TAG) model [1]
% Parameters:
%   (required)
%   - years: A scalar or vector of years [2011, 2012]
%   - dailyClearnessIndexes: A vector containing a set of mean clearness indexes
%     corresponding to each day for which hourly values are to be
%     synthesised
%   (optional)
%
% References:
% [1] TAG: a time-dependent, autoregressive Guassian model for generating
% synthetic hourly radiation (Aguair, Collares-Pereira) [1992]
% [2] Meteonorm - Handbook Part II: Theory (Version 7.1) [2014]

%% 0.1 Parameter Parsing ==================================================

p = inputParser;
p.addRequired('time', @isstruct);
p.addRequired('location', @isstruct);
p.addRequired('dailyClearnessIndexes', @(x) (all(isnumeric(x) & (x >0))));
p.addOptional('model', 'meteonorm', @ischar);
p.parse(time, location, dailyClearnessIndexes, varargin{:});

time = p.Results.time;
location = p.Results.location;
dailyClearnessIndexes = p.Results.dailyClearnessIndexes;
model = p.Results.model;

%% 0.2) Definitions =======================================================

HOURS_IN_DAY = 24;

MAX_ITERATIONS = 50;

% The Meteonorm model allows an overshoot of 10% in the calculated
% clear-sky index
CLEAR_SKY_OVERSHOOT = 1.05;

%% 1) Solar Position ======================================================

declinationAngle = -asin(0.39779 * cos(deg2rad(0.98565 * (time.dayOfYear + 10) + 1.914 * sin(deg2rad(0.98565 * (time.dayOfYear - 2))))));

sunriseAngle = acos(-1*tan(declinationAngle) * tan(deg2rad(location.latitude)));

% Algorithm expects hours from 1-24, MATLAB uses hours from 0-23
hours = time.hour + 1;

% Start/centre/end of hour angles
startOfHourAngle = (hours - 13) * pi / 12;
endOfHourAngle = (hours - 12) * pi / 12;
centreOfHourAngle = (hours - 12.5) * pi / 12;

isDaylight = (startOfHourAngle > -1*sunriseAngle) & (endOfHourAngle < sunriseAngle);

% Clear-sky clearness index
clearSkyClearnessIndex = 0.88 * cos(pi * (hours - 12.5) / 30);

solarElevationAngle = asin(cos(centreOfHourAngle) .* cos(declinationAngle) .* cos(deg2rad(location.latitude)) + sin(declinationAngle) .* sin(deg2rad(location.latitude)));

%% 2) Statistical Parameters ==============================================

switch(model)
    case 'meteonorm'
        autocorrelationCorrectionFactor = 2;
        
        phi = core.repeatArray(0.148 + 2.356 * dailyClearnessIndexes - (5.195 * dailyClearnessIndexes.^2) + (3.758 * dailyClearnessIndexes.^3), HOURS_IN_DAY);
        phi(phi > 1) = 1;
        
        standardDeviationPerturbations = core.repeatArray(0.32 * exp(-50 * (dailyClearnessIndexes - 0.4).^2) + 0.002, HOURS_IN_DAY);
	case 'aguiar'
        autocorrelationCorrectionFactor = 1;
        
        % Autocorrelation coefficient
        phi = core.repeatArray(0.38 + (0.06 * cos(7.4 * dailyClearnessIndexes - 2.5)), HOURS_IN_DAY);
        
        A = core.repeatArray(0.14 * exp(-20 * (dailyClearnessIndexes - 0.35).^2), HOURS_IN_DAY);
        B = core.repeatArray(3 * (dailyClearnessIndexes - 0.45).^2 + (16 * dailyClearnessIndexes.^5), HOURS_IN_DAY);

        standardDeviationPerturbations = A .* exp(B .* (1 - sin(solarElevationAngle)));
end

% Algorithm constants
lambda = core.repeatArray(-0.19 + (1.12 * dailyClearnessIndexes) + (0.24 * exp(-8 * dailyClearnessIndexes)), HOURS_IN_DAY);
eta = core.repeatArray(0.32 - (1.6 * (dailyClearnessIndexes - 0.5).^2), HOURS_IN_DAY);
kappa = core.repeatArray(0.19 + (2.27 * dailyClearnessIndexes.^2) - (2.51 * dailyClearnessIndexes.^3), HOURS_IN_DAY);
averageClearnessIndex = lambda + eta .* exp(-1*kappa ./ sin(solarElevationAngle));

% Meteonorm limits any clearness index values to a max of 0.8 for solar
% elevations below 10 degrees
averageClearnessIndex(solarElevationAngle <= deg2rad(10) & averageClearnessIndex > 0.8) = 0.8;
averageClearnessIndex(averageClearnessIndex > CLEAR_SKY_OVERSHOOT) = CLEAR_SKY_OVERSHOOT;
averageClearnessIndex(averageClearnessIndex < 0) = 0;

standardDeviation = standardDeviationPerturbations .* (1 - phi.^2).^0.5;



%% 3) Preallocation =======================================================

hourlyClearnessIndexes = -1*ones(length(hours), 1);
normalisedVariable = zeros(length(hours), 1);

%% 4) Calculation =========================================================


for hourIx = 1:length(hours)
    if(isDaylight(hourIx))
        iterationCount = 0;
        
        while((hourlyClearnessIndexes(hourIx, 1) < 0) || (hourlyClearnessIndexes(hourIx, 1) > clearSkyClearnessIndex(hourIx, 1)))
            gaussianRandomNumber = normrnd(0, standardDeviation(hourIx, 1));
            normalisedVariable(hourIx, 1) = (autocorrelationCorrectionFactor * phi(hourIx, 1) * normalisedVariable(hourIx - 1)) + gaussianRandomNumber;
            
            hourlyClearnessIndexes(hourIx, 1) = averageClearnessIndex(hourIx, 1) + (standardDeviation(hourIx, 1) * normalisedVariable(hourIx, 1));
            
            iterationCount = iterationCount + 1;
            
            if(iterationCount > MAX_ITERATIONS)
                break;
            end
        end
    end
    
end

hourlyClearnessIndexes(hourlyClearnessIndexes < 0) = 0;
hourlyClearnessIndexes(hourlyClearnessIndexes > clearSkyClearnessIndex) = clearSkyClearnessIndex(hourlyClearnessIndexes > clearSkyClearnessIndex);

hourlyClearnessIndexes = CLEAR_SKY_OVERSHOOT * (hourlyClearnessIndexes ./ max(hourlyClearnessIndexes));

end





