function [ output_args ] = synthesiseMinutelyClearnessIndexes( indexGHI, indexDNI, stepsPerHour )
%SYNTHESISEMINUTELYCLEARNESSINDEXES Summary of this function goes here
%   Detailed explanation goes here


end



function minuteIndexesGHI = estimateMinuteIndexesGHI(indexGHI, indexDNI, stepsPerHour, sigmaGHI)

%% 0) Definitions =========================================================

CDF_STEPS = 40;

%% 1) Preallocation =======================================================

t_st = zeros(stepsPerHour,1);

t = zeros(CDF_STEPS,1);
cdf = zeros(CDF_STEPS,1);

orderedIndexesGHI = zeros(stepsPerHour,1);

%% 2) Calculation =========================================================

if(indexGHI <= 0.3)
    betaMin = -0.03;
    betaMax = 1.66;
elseif(indexGHI > 0.3 && indexGHI <= 0.6)
    betaMin = 0.20;
    betaMax = 4.26;
elseif(indexGHI > 0.6 && indexGHI <= 0.9)
    betaMin = 0.47;
    betaMax = 0.89;
elseif(indexGHI  > 0.9)
    betaMin = 2;
    betaMax = 0.38;
end

indexGHIMin = (indexGHI - 0.03) * exp(-11 * betaMin * (sigmaGHI^1.4)) - 0.09;
indexGHIMin(indexGHIMin < 0) = 0;

indexGHIMax = (indexGHI - 1.5) * exp(-9 * betaMax * (sigmaGHI^1.3)) + 1.5;

tobs = (indexGHI - indexGHIMin) / (indexGHIMax - indexGHIMin);

sigt = sigmaGHI / (indexGHIMax - indexGHIMin);

t1 = tobs * (0.01 + 0.98 * exp(-60 * (sigt ^ 3.3)));
t2 = (tobs - 1) * (0.01 + 0.98 * exp(-11 * sigt^2 )) + 1;
w = (t2 - tobs) / (t2 - t1);

tt11 = (t1^2) * (1 - t1) / (1 + t1);
tt22 = (t2^2) * (1 - t2) / (1 + t2);

ttt11 = t1 * (((1 - t1)^2) / (2 - t1));
ttt22 = t2 * (((1 - t2)^2) / (2 - t2));

% Calculate parameters for two incomplete beta functions
sigma11 = 0.014;
sigma22 = 0.006;

if(sigma11 >= tt11)
    sigma11 = tt11;
end
if(sigma22 >= tt22)
    sigma22 = tt22;
end
if(sigma11 >= ttt11)
    sigma11 = ttt11;
end
if(sigma22 >= ttt22)
    sigma22 = ttt22;
end

a1 = ((t1^2) * (1 - t1) / sigma11) - t1;
a1(a1 < 1) = 1;

a2 = ((t2^2) * (1 - t2) / sigma22) - t2;
a2(a2 < 1) = 1;

b1 = (t1 * (1 - t1) - sigma11) * (1 - t1) / sigma11;
b1(b1 < 1) = 1;

b2 = (t2 * (1 - t2) - sigma22) * (1 - t2) / sigma22;
b2(b2 < 1) = 1;

% Calculate discrete form of cumulated distribution (sum of two incomplete
% beta functions)
t(CDF_STEPS) = 1;
cdf(CDF_STEPS) = 1;

for cdfIx = 1:CDF_STEPS-1
    t(cdfIx) = cdfIx / CDF_STEPS;
    help1 = betainc(t(cdfIx), a1, b1);
    cdf1 = help1;
    help2 = betainc(t(cdfIx), a2, b2);
    cdf2 = help2;
    
    if(help1 > -98 && help2 > -98)
        cdf(cdfIx) = w * cdf1 + (1 - w) * cdf2;
    else
        cdf(cdfIx) = cdf(cdfIx - 1);
    end
end

randomNumbers = rand(stepsPerHour, 1);

% TODO: Fix array bounds
for sampleIx = 1:stepsPerHour
    for cdfIx = 1:CDF_STEPS
        if(randomNumbers(sampleIx) >= cdf(cdfIx - 1) && randomNumbers(sampleIx) <= cdfIx)
            t_st(sampleIx) = t(cdfIx-1) + (randomNumbers(sampleIx) - cdf(cdfIx-1)) * (t(cdfIx) - t(cdfIx-1)) / (cdf(cdfIx) - cdf(cdfIx-1));
            break;
        end
    end
end

% In-place sort t_st in ascending order
t_st = sort(t_st);

for indexIx = 1:stepsPerHour
    orderedIndexesGHI(indexIx) = indexGHIMin + ((indexGHIMax - indexGHIMin) * t_st(indexIx));
end

% Temporally rearrange the ordered short-term indexes
if(lastHourlyIndexGHI <= orderedIndexesGHI(1))
    rankLastHourlyIndexGHI = 1;
end



end



%% ========================================================================
%  Estimate GHI and DNI sigma values
%% ========================================================================
function [sigmaGHI, sigmaDNI] = estimateSigma(indexesGHI, indexDNI, stepsPerHour)

%% 0) Definitions =========================================================

MINUTES_IN_HOUR = 60;
MAX_TIME_STEP = 5;


%% 1) Calculation =========================================================
sigmaDNIX = indexDNI * (1 - indexDNI);

if(indexDNI < 1)
    sigmaDNIX = sqrt(sigmaDNIX);
end

sigma3 = ((1/2) * ((indexesGHI(2) - indexesGHI(1))^2 + (indexesGHI(3) - indexesGHI(2))^2)) ^ (1/2);

if(indexesGHI(2) <= 0.3)
    betaSigma = 1.3;    
elseif(indexesGHI(2) > 0.3 && indexesGHI(2) <= 0.6)
    betaSigma = 1.3;
elseif(indexesGHI(2) > 0.6 && indexesGHI(2) <= 0.9)
    betaSigma = 1.0;
elseif(indexesGHI(2) > 0.9)
    betaSigma = 0.7;
else
    betaSigma = 1.0;
end

sigmaStar = betaSigma * ((0.87 * (indexesGHI(2)^2) * (1 - indexesGHI(2))) + (0.39 * (indexesGHI(2)^(1/2)) * sigma3));
sigmaStar(sigmaStar < 0) = 0;

gam = 0.88 + 42 * sigmaStar^2;
alpha = gamma(gam);

% Generate uniform random number
ran = rand;

s = (1/alpha) * exp((1/gam) * log(log(1/(1 - ran))));

sigmaGHI5 = s * sigmaStar;
sigmaDNI5 = sigmaGHI5 * (15 * exp(-0.15 * (indexesGHI(2) - 0.65)^2) - 14.08 + 1.85 * (sigmaGHI5 - 0.42) * sin(1.5 * pi * indexesGHI(2)));
sigmaDNI5(sigmaDNI5 < 0) = 0;

% Calculate the time between samples (minutes), limiting to a maximum
timeStep = MINUTES_IN_HOUR / stepsPerHour;
timeStep(timeStep > MAX_TIME_STEP) = MAX_TIME_STEP;


deltaGHI = (0.6 - 1.3 * sigmaGHI5) * (indexesGHI(2) - 0.2);
sigmaGHI = sigmaGHI5 * (1 + ((5 - timeStep)/5)^1.5 * deltaGHI);

deltaDNI = 0.18 + (0.2 - sigmaDNI5) * (0.6 + 2.5 * (indexDNI - 0.5)^2);
sigmaDNI = sigmaDNI5 * (1 + ((5 - timeStep)/5)^1.5 * deltaDNI);\

sigmaDNIDiff = sigmaDNIX - sigmaDNI;


if(sigmaGHI < sigmaGHI5)
    sigmaGHI = sigmaGHI5;
end

if(sigmaDNI < sigmaDNI5)
    sigmaDNI = sigmaDNI5;
end
if(sigmaDNI > sigmaDNIX || sigmaDNIDiff < 0.01)
    sigmaDNI = sigmaDNIX - 0.01;
end
if(sigmaDNI < 0)
    sigmaDNI = 0.0001;
end


end

