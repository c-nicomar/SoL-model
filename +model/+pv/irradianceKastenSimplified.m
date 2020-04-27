function [ClearSkyGHI, ClearSkyDNI, ClearSkyDHI]= irradianceKastenSimplified(time, location, varargin)
% irradianceIneichen Determine clear sky GHI, DNI, and DHI from Ineichen/Perez model
%
% Syntax
%   [ClearSkyGHI, ClearSkyDNI, ClearSkyDHI]= irradianceIneichen(time, location)
%   [ClearSkyGHI, ClearSkyDNI, ClearSkyDHI]= irradianceIneichen(time, location, linkeTurbidityData)
%   
% Description
%   Implements the Ineichen and Perez clear sky model for global horizontal
%   irradiance (GHI), direct normal irradiance (DNI), and calculates
%   the clear-sky diffuse horizontal (DHI) component as the difference
%   between GHI and DNI*cos(zenith) as presented in [1, 2]. A report on clear
%   sky models found the Ineichen/Perez model to have excellent performance
%   with a minimal input data set [3]. Default values for Linke turbidity
%   provided by SoDa [4, 5].
%
% Input Parameters:
%   time - a struct with the following elements, note that all elements
%       can be column vectors, but they must all be the same length.
%       pvl_maketimestruct may be used to generate the time input.
%   time.year = The year in the gregorian calendar
%   time.month = the month of the year (January = 1 to December = 12)
%   time.day = the day of the month
%   time.hour = the hour of the day
%   time.minute = the minute of the hour
%   time.second = the second of the minute
%   time.UTCOffset = the UTC offset code, using the convention
%      that a positive UTC offset is for time zones east of the prime meridian
%      (e.g. EST = -5)
% 
%   location - a struct with the following elements, note that all
%      elements may scalars or column vectors, but they must all be the same 
%      length (e.g. time.hour(i) must correspond to location.latitude(i)).
%      pvl_makelocationstruct may be used to make scalar (stationary)
%      location files.
%   location.latitude = vector or scalar latitude in decimal degrees (positive is
%      northern hemisphere)
%   location.longitude = vector or scalar longitude in decimal degrees (positive is 
%      east of prime meridian)
%   location.elevation = vector or scalar height above sea level in meters.
%      While elevation is optional in many uses, it is required in this
%      model implmentation.
%
% Output:   
%   ClearSkyGHI - the modeled global horizonal irradiance in W/m^2 provided
%      by the Ineichen clear-sky model.
%   ClearSkyDNI - the modeled direct normal irradiance in W/m^2 provided
%      by the Ineichen clear-sky model.
%   ClearSkyDHI - the calculated diffuse horizonal irradiance in W/m^2 
%      provided by the Ineichen clear-sky model.
%
% Sources:
%
% [1] P. Ineichen and R. Perez, "A New airmass independent formulation for
%     the Linke turbidity coefficient", Solar Energy, vol 73, pp. 151-157, 2002.
%
% [2] R. Perez et. al., "A New Operational Model for Satellite-Derived
%     Irradiances: Description and Validation", Solar Energy, vol 73, pp.
%     307-317, 2002.
%
% [3] M. Reno, C. Hansen, and J. Stein, "Global Horizontal Irradiance Clear
%     Sky Models: Implementation and Analysis", Sandia National
%     Laboratories, SAND2012-2389, 2012.
%
% [4] http://www.soda-is.com/eng/services/climat_free_eng.php#c5 (obtained
%     July 17, 2012).
%
% [5] J. Remund, et. al., "Worldwide Linke Turbidity Information", Proc.
%     ISES Solar World Congress, June 2003. Goteborg, Sweden.
%
%
% See also
%   PVL_MAKETIMESTRUCT    PVL_MAKELOCATIONSTRUCT   solarPositionEphemeris
%   PVL_HAURWITZ

import model.pv.*;

%% 0) Input Parsing =======================================================

% Require the field location.elevation
p = inputParser;
p.addRequired('time',@isstruct);
p.addRequired('location',@(x) all(isstruct(x) & isfield(x,'elevation')));
p.addOptional('apparentSunZenith', @(x) (all(isnumeric(x) & x<=180 & x>=0 & isvector(x))));
p.parse(time, location, varargin{:});


%% 0.1) Definitions =======================================================

% Average of the Sandia Linke Turbidity data set across all data points
% (across location and all 12 months)
TL = getLinkeTurbidityFactors(time, location);


%% 1) Input Processing ====================================================

% Determine day of year and extraterrestrial normal radiation for each time
% instant in time.
I0 = irradianceSun(time.dayOfYear);

% Assumptions made in this step: 
% 1. Pressure is local standard pressure (per alt2pres)
% 2. Temperature is 12C (default for solarPositionEphemeris)
if(any(strcmp({'apparentSunZenith'}, p.UsingDefaults)))
    % Apparent sun zenith has not been specified so calculated using solar
    % position ephemeris algorithm
    [~, ~, ApparentSunElevation, ~] = solarPositionEphemeris(time, location, alt2pres(location.elevation));
    apparentSunZenith = 90-ApparentSunElevation;
else
    apparentSunZenith = p.Results.apparentSunZenith;
end



%% 2) Calculation =========================================================

% Get the absolute airmass assuming standard local pressure (per
% alt2pres) using Kasten and Young's 1989 formula for airmass.
AMabsolute = airmassAbsolute(airmassRelative(apparentSunZenith, 'kastenyoung1989'), alt2pres(location.elevation));

fh1=exp(location.elevation.*(-1/8000));
fh2=exp(location.elevation.*(-1/1250));

%apparentSunZenith(apparentSunZenith < 0) = 0;
cosApparentSunZenith = cosd(apparentSunZenith);
%cosapparentSunZenith(cosapparentSunZenith < 0) = 0;

% This equation is found in Solar Energy 73, pg 311. It is slightly
% different than the equation given in Solar Energy 73, pg 156. We used the
% equation from pg 311 because of the existence of known typos in the pg 156
% publication (notably the fh2-(TL-1) should be fh2 * (TL-1)).

ClearSkyGHI = 0.84.*I0.*cosApparentSunZenith.*exp(-0.027.*AMabsolute.*(fh1+fh2.*(TL-ones(size(TL)))));
ClearSkyGHI(ClearSkyGHI<0)=0;

b = 0.664 + 0.163 ./ fh1;
BncI = b .* I0 .* exp(-0.09 .* AMabsolute .* (TL-ones(size(TL)))); 

% Take the minimum of BncI and the equation given 
ClearSkyDNI = min(BncI, ClearSkyGHI .* (1-(0.1 - 0.2 .* exp(-1*TL)) ./ (0.1 + 0.882 ./ fh1)) ./ cosApparentSunZenith);

ClearSkyDHI = ClearSkyGHI - (ClearSkyDNI .* cosApparentSunZenith);

% Convert any NaN elements to zero
ClearSkyGHI(isnan(ClearSkyGHI)) = 0;
ClearSkyDNI(isnan(ClearSkyDNI)) = 0;
ClearSkyDHI(isnan(ClearSkyDHI)) = 0;

end