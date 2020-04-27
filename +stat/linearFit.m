function [rsq, p] = rSquared( baseData, data )
%RSQUARED Summary of this function goes here
%   Detailed explanation goes here

% Fit a first degree (linear) polynomial that fits the baseData to the
% comparison data
p = polyfit(baseData, data, 1);

% Get fitted data corresponding to the base data using the linear model
yfit = polyval(p, baseData);

% Measure how good this fit actually is by find the residuals - the
% difference between the actual data and the linear model
yresid = data - yfit;
SSresid = sum(yresid.^2);
SStotal = (length(data)-1) * var(data);
rsq = 1 - SSresid/SStotal;

end

