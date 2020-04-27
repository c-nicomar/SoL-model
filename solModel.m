function netPVSystemPower = solModel( time, location, inverterRating, varargin )
%% 0.1) Parameter Parsing =================================================

p = inputParser;
p.addRequired('time',@(x) all(isstruct(x) & isfield(x,'daylightSavings') & isfield(x,'dayOfYear')));
p.addRequired('location',@(x) all(isstruct(x) & isfield(x,'elevation')));
p.addRequired('inverterRating',@(x) (isscalar(x) & isnumeric(x) & x>=0));
p.addOptional('ambientTemperature', 20, @isnumeric);
p.addOptional('clearnessIndex', [], @(x) (all(isnumeric(x) & x>=0 & x<=1)));
p.addOptional('oversizingRatio', 1.05, @(x) (isscalar(x) & isnumeric(x)));
p.addOptional('globalHorizontalIrradiance', [], @isnumeric);
%Irradiancia total
p.addOptional('globalIrradiance', [], @isnumeric);
p.addOptional('groundAlbedo', 0.2, @(x) (isscalar(x) & isnumeric(x) & x>=0));
p.addOptional('azimuthOffset', 0, @(x) (isscalar(x) & isnumeric(x)));
p.addOptional('linkeTurbidityPollution', 0, @(x) (isscalar(x) & isnumeric(x)));
p.addOptional('moduleAge', 0, @(x) (isscalar(x) & isnumeric(x)));
p.addOptional('powerFactor', 1, @(x) (isscalar(x) & isnumeric(x)));
p.addOptional('debug', NaN);
p.addOptional('tilt',[], @(x) (isscalar(x) & isnumeric(x)));
p.parse(time, location, inverterRating, varargin{:});


globalIrradiance=p.Results.globalIrradiance(:);
inverterRating = p.Results.inverterRating;
ambientTemperature = p.Results.ambientTemperature(:);
clearnessIndex = p.Results.clearnessIndex(:);
oversizingRatio = p.Results.oversizingRatio;
globalHorizontalIrradiance = p.Results.globalHorizontalIrradiance(:);
groundAlbedo = p.Results.groundAlbedo;
azimuthOffset = p.Results.azimuthOffset;
linkeTurbidityPollution = p.Results.linkeTurbidityPollution;
moduleAge = p.Results.moduleAge;
powerFactor = p.Results.powerFactor;
%debug = p.Results.debug;
tilt= p.Results.tilt;

%% 0.2) Definitions =======================================================

if(location.latitude > 0)
    % Northern hemisphere - Orient due south
    orientation.azimuth = 180 + azimuthOffset;
else
    % Southern hemisphere - Orient due north
    orientation.azimuth = 0 + azimuthOffset;
end

if(isempty(globalHorizontalIrradiance))
    % For clear-sky values the optimum tilt is approximately equal to the
    % absolute value of the site latitude, with minimal error in total annual
    % energy
    orientation.tilt = -0.004*abs(location.latitude)^2 + 1.13*abs(location.latitude);
elseif (~isempty(globalHorizontalIrradiance) & isempty(tilt))
    % For real irradiance values a quadratic equation is used based on the
    % fitting of real-data from 2000 global meteorological sites
    orientation.tilt = -0.004*abs(location.latitude)^2 + 0.92*abs(location.latitude) + 2;
else
    %Valor medido del ángulo de inclinación del panel
orientation.tilt=tilt;

end

MINUTES_IN_DAY = 24 * 60;

% Typical ground albedo value for dark surfaces (soil/grass)
% GROUND_ALBEDO = 0.2;

% Mean solar irradiance over a year on a surface 1 AU from the sun
% Informally referred to as the "solar constant"
% See http://lasp.colorado.edu/home/sorce/data/tsi-data/
TOTAL_SOLAR_IRRADIANCE = 1360.8;

% Approximate obliquity of the Earth for the period 2000 - 2050
EARTH_OBLIQUITY = 23.44;

% Latitudes of zones for computing Linke turbidity factors - Southern limit,
% Tropic of Capricorn, Tropic of Cancer, Northern limit
LINKE_TURBIDITY_ZONES = [-50 -23 23 60];

% Light induced degradation factors
INITIAL_LIGHT_INDUCED_DEGRADATION = 0.985;
YEARLY_LIGHT_INDUCED_DEGRADATION = 0.005;

% Typical derating factors
EFFECTIVE_IRRADIANCE_FACTOR = struct(...
    'SOILING', 0.98, ... 
    'SHADING', 1);

DERATING_FACTOR = struct(...
    'MISMATCH', 0.98, ...
    'WIRING', 0.98, ...
    'CONNECTIONS', 0.995, ...
    'LIGHT_INDUCED_DEGRADATION', INITIAL_LIGHT_INDUCED_DEGRADATION - (YEARLY_LIGHT_INDUCED_DEGRADATION * moduleAge), ...
    'NAMEPLATE_RATING', 0.99);

% Median oversizing ratio of fitted systems
BASE_OVERSIZING_RATIO = 1.05;

%% 1) Solar Position ======================================================
%  Calculate solar position using ASCE algorithm

% ASCE (4)
eclipticLongitude = (360/365.25)*(time.dayOfYear - 81);

% Declination angle [Sproul]
declination = asind(sind(eclipticLongitude) .* sind(EARTH_OBLIQUITY));

%Equation of time [Custom fitting]
EOT = 9.9*sind(2*eclipticLongitude) - 7.1*cosd(eclipticLongitude) - 1.9*sind(eclipticLongitude) - 4*cosd(2*eclipticLongitude);

% Standard merdian in arcminutes
standardMeridian = time.UTCOffset(1)*15;

% Calculate the sample offset required so that the solar time is positioned
% around the MIDDLE of the period
%timeValues = datenum(time.year, time.month, time.day, time.hour, time.minute, time.second);
sampleOffset = (time.timeValues(2) - time.timeValues(1)) * MINUTES_IN_DAY / 2;

% Solar time ASCE (7)
solarTime = (time.hour*60 + time.daylightSavings*60 + time.minute + sampleOffset + 4*(location.longitude - standardMeridian) + EOT)/60;

% Alternativa a solarTime

%[SunAz, SunEl, ApparentSunEl, solarTime] = pvl_ephemeris(time, location);
%%Por mejorar!

% Hour angle ASCE (9)
hourAngle = 15*(solarTime - 12);

% The true zenith angle for the site
cosSunZenith = cosd(location.latitude)*cosd(declination).*cosd(hourAngle) + sind(location.latitude)*sind(declination);
sunZenith = acosd(cosSunZenith);

sunZenith = circshift(sunZenith, -1);

sunElevation = 90 - sunZenith;

% Sun azimuth for the site
sunAzimuth = acosd(((sind(declination) .* cosd(location.latitude)) - (cosd(declination) .* sind(location.latitude) .* cosd(hourAngle)))./cosd(sunElevation));
sunAzimuth(hourAngle > 0) = 360 - sunAzimuth(hourAngle > 0);

% Extraterrestrial irradiance
extraterrestrialIrradiance = TOTAL_SOLAR_IRRADIANCE*(1 + 0.033*cos((2*pi/365)*time.dayOfYear));


%% 2) Angle of Incidence ==================================================

angleOfIncidence = acosd(max(min(cosd(sunZenith) .* cosd(orientation.tilt) + sind(orientation.tilt) .* sind(sunZenith) .* cosd(sunAzimuth - orientation.azimuth), 1),-1)); 

%% 3) Atmosphere ==========================================================

% Linke turbidity factor estimation
if(location.latitude < min(LINKE_TURBIDITY_ZONES) || location.latitude > max(LINKE_TURBIDITY_ZONES))
    % Poles
    linkeTurbidity = 1.8;
elseif(location.latitude > LINKE_TURBIDITY_ZONES(2) && location.latitude < LINKE_TURBIDITY_ZONES(3))
    % Tropics
    if(location.latitude < 0)
        linkeTurbidity = 3.8 + 0.56*cosd(1.13*time.dayOfYear);
    else
        linkeTurbidity = 4.25 - 0.46*cosd(0.94*time.dayOfYear);
    end
else
    if(location.latitude < 0)
        linkeTurbidity = 3.2 + 0.36*cosd(0.94*time.dayOfYear);
    else
        linkeTurbidity = 3 - 0.84*cosd(0.94*time.dayOfYear);
    end
end

% Include localised air pollution factors in overall Linke turbidity
linkeTurbidity = linkeTurbidity + linkeTurbidityPollution;

% Absolute airmass computed using the Kasten-Young formulae
sunZenith(sunZenith > 90) = NaN;

pressure = 100* ((44331.514 - location.elevation)/11880.516).^(1/0.1902632);
airmassRelative = 1 ./ (cosd(sunZenith) + 0.50572 .* ((6.07995+(90-sunZenith)) .^ -1.6364));
airmassAbsolute = airmassRelative.*pressure/101325;

%% 3) Temporal Averaging __________________________________________________

if(~isempty(globalHorizontalIrradiance))
    timeResolutionRatio = length(time.minute) / length(globalHorizontalIrradiance);

    averageData = @(x) mean(reshape(x, timeResolutionRatio, []))';

    % If a higher time resolution time series has been passed then average
    % calculated values so that the have the same period
    if(timeResolutionRatio > 1)
        solarTime = averageData(solarTime);
        cosSunZenith = averageData(cosSunZenith);
        sunZenith = averageData(sunZenith);
        sunElevation = averageData(sunElevation);

        %sunAzimuth = averageData(sunAzimuth);

        extraterrestrialIrradiance = averageData(extraterrestrialIrradiance);

        angleOfIncidence = averageData(angleOfIncidence);

        airmassAbsolute = averageData(airmassAbsolute);
    end
end



%% 3) Horizontal Irradiance ===============================================

%% Irradiance Decomposition
%  If no global horizontal irradiance data has been passed then calculate
%  clear-sky irradiance values using the Ineichen model
if(isempty(globalHorizontalIrradiance) && isempty(clearnessIndex))
    fh1=exp(location.elevation.*(-1/8000));
    fh2=exp(location.elevation.*(-1/1250));

    % GHI
    cg1=(0.0000509.*location.elevation+0.868);
    cg2=0.0000392.*location.elevation+0.0387;
    globalHorizontalIrradiance = cg1.*extraterrestrialIrradiance.*cosSunZenith.*exp(-cg2.*airmassAbsolute.*(fh1+fh2.*(linkeTurbidity-1))).*exp(0.01.*(airmassAbsolute).^(1.8));

    globalHorizontalIrradiance(globalHorizontalIrradiance<0)=0;
    
    % DNI
    b = 0.664 + 0.163 ./ fh1;
    BncI = b .* extraterrestrialIrradiance .* exp(-0.09 .* airmassAbsolute .* (linkeTurbidity-1)); 

    % For very low turbidity conditions (linkeTurbidity < 2), apply an
    % empirical correction factor
    directNormalIrradiance = min(BncI, globalHorizontalIrradiance .* (1-(0.1 - 0.2 .* exp(-1*linkeTurbidity)) ./ (0.1 + 0.882 ./ fh1)) ./ cosSunZenith);
    
    % DHI
    diffuseHorizontalIrradiance = globalHorizontalIrradiance - (directNormalIrradiance .* cosSunZenith);
else
    % BRL Model ___________________________________________________________
    % Bayesian coefficients are used from "Derivation of a solar diffuse
    % fraction model in a Bayesian framework (Lauret, Boland, Ridley) [2010]"
    
    % Calculate extraterrestrial irradiance on a horizontal plane
    % Ensure this never goes negative or to invalid values, even outside
    % daylight hours, to prevent incorrect daily value
    horizontalExtraterrestrialIrradiance = extraterrestrialIrradiance .* cosd(sunZenith);
    horizontalExtraterrestrialIrradiance(isnan(horizontalExtraterrestrialIrradiance)) = 0;
    horizontalExtraterrestrialIrradiance(horizontalExtraterrestrialIrradiance < 0) = 0;
    
    if(isempty(clearnessIndex))
        % Calculate clearness index, setting any values at very low or negative
        % sun elevations to 0
        clearnessIndex = globalHorizontalIrradiance ./ horizontalExtraterrestrialIrradiance;
        clearnessIndex(sunElevation < 5) = 0;
    else
        globalHorizontalIrradiance = clearnessIndex .* horizontalExtraterrestrialIrradiance;
    end
    
    % Calculate daily clearness index
    daysInYear = max(time.dayOfYear);
    samplesInDay = numel(globalHorizontalIrradiance) / daysInYear;
    
    dailyGlobalHorizontalIrradiance = sum(reshape(globalHorizontalIrradiance, [samplesInDay daysInYear]));
    dailyHorizontalExtraterrestrialIrradiance = sum(reshape(horizontalExtraterrestrialIrradiance, [samplesInDay daysInYear]));
    dailyClearnessIndex = core.repeatArray(dailyGlobalHorizontalIrradiance ./ dailyHorizontalExtraterrestrialIrradiance, samplesInDay);
    
    persistenceFactor = (circshift(clearnessIndex, -1) + circshift(clearnessIndex, 1)) / 2;
    
    % Calculate diffuse fraction
    d = 1 ./ (1 + exp(-5.323 + 7.279*clearnessIndex - 0.030*solarTime - 0.005*sunElevation + 1.719*dailyClearnessIndex + 1.082*persistenceFactor));
    d((sunElevation < 5) | (d < 0) | isnan(d)) = 1;
    
    % Calculate DHI
    diffuseHorizontalIrradiance = globalHorizontalIrradiance .* d;
    
    % Calculate DNI
    directNormalIrradiance = (globalHorizontalIrradiance - diffuseHorizontalIrradiance) ./ sind(sunElevation);
end

%Para lo de los NaNs en la potencia a la salida habrá que toquetear aquí 
% Convert any NaN elements to zero
globalHorizontalIrradiance(isnan(globalHorizontalIrradiance)) = 0;
directNormalIrradiance(isnan(directNormalIrradiance)) = 0;
diffuseHorizontalIrradiance(isnan(diffuseHorizontalIrradiance)) = 0;


%% 4) Incident Irradiance =================================================
%  Transpose irradiance onto the plane using isotropic sky model

% Beam
incidentIrradiance.beam = directNormalIrradiance .* cosd(angleOfIncidence);
incidentIrradiance.beam(angleOfIncidence >= 90) = 0;

% Diffuse sky - Hay-Davies model
%incidentIrradiance.diffuseSky = diffuseHorizontalIrradiance;
A = directNormalIrradiance ./ extraterrestrialIrradiance;
R_b = max(cosd(angleOfIncidence),0)./max(cosd(sunZenith),0.01745);
incidentIrradiance.diffuseSky = diffuseHorizontalIrradiance .* (A .* R_b + (1-A) .* 0.5 .* (1 + cosd(orientation.tilt)));

% Ground
incidentIrradiance.diffuseGround = globalHorizontalIrradiance .* groundAlbedo .* (1-cosd(orientation.tilt)) .* 0.5;

 % Total incident irradiance
 
 if (isempty(globalIrradiance))
     
 incidentIrradiance.total = incidentIrradiance.beam + incidentIrradiance.diffuseSky + incidentIrradiance.diffuseGround;

 else
 
%Alternativa de irrradiancia total

incidentIrradiance.total=globalIrradiance;

 end

incidentIrradiance.total(sunElevation < 5) = 0;


%% 5) Effective Irradiance ================================================
% Apply derating factors to calculate incident irradiance on the modules
% that is actually usable for electricity generation

effectiveIrradiance = incidentIrradiance.total .* EFFECTIVE_IRRADIANCE_FACTOR.SOILING .* EFFECTIVE_IRRADIANCE_FACTOR.SHADING;

normalisedEffectiveIrradiance = effectiveIrradiance ./ 800;

%% 6) Array Design ========================================================
% Apply an overcapacity factor to emulate oversizing of the PV array
normalisedOversizingRatio = oversizingRatio / BASE_OVERSIZING_RATIO;

normalisedArrayIrradiance = normalisedEffectiveIrradiance * normalisedOversizingRatio;


%% 7) System Power ========================================================
% Calculate system output using simplified PV system model, and convert
% from normalised values to actual power values

% Coefficients for the PV model a*Enorm^2 + b*Enorm*Tnorm + c*Enorm
%PV_MODEL_COEFFICIENTS = [-0.104, -0.0754, 0.917]; % T/20
%normalisedAmbientTemperature = ambientTemperature ./ 20;

PV_MODEL_COEFFICIENTS = [-0.106, -0.00368, 0.846]; % T - 20
normalisedAmbientTemperature = ambientTemperature - 20;

%PV_MODEL_COEFFICIENTS = [-0.106, -1.08, 1.93]; % (T + 273.15)/(293.15)
%normalisedAmbientTemperature = (ambientTemperature + 273.15) / (293.15);

grossPVSystemPower = inverterRating * (PV_MODEL_COEFFICIENTS(1)*normalisedArrayIrradiance.^2 + PV_MODEL_COEFFICIENTS(2).*normalisedArrayIrradiance.*normalisedAmbientTemperature + PV_MODEL_COEFFICIENTS(3)*normalisedArrayIrradiance);


%% 8) Losses/Derating =====================================================
% Multiply gross PV system output power by all derating factors

totalDeratingFactor = prod(cell2mat(struct2cell(DERATING_FACTOR)));

netPVSystemPower = totalDeratingFactor * grossPVSystemPower;

%% 9) Inverter Clipping ===================================================
%  Clip output power values that exceed the inverter rating

netPVSystemPower(netPVSystemPower > (inverterRating * powerFactor)) = inverterRating * powerFactor;

% save datasol;
end