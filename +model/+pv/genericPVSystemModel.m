function netPVSystemPower = genericPVSystemModel( incidentIrradianceTotal, inverterRating, varargin )
%GENERIC_PV_SYSTEM_MODEL Calculate the net output power of a PV system
%given incident irradiance on the PV modules

%% 0.1) Parameter Parsing =================================================

p = inputParser;
p.addRequired('incidentIrradianceTotal',@(x) (isnumeric(x) & all(x>=0)));
p.addRequired('inverterRating',@(x) (isscalar(x) & isnumeric(x) & x>=0));
p.addOptional('ambientTemperature', 20, @isnumeric);
p.addOptional('oversizingRatio', 1, @(x) (isscalar(x) & isnumeric(x)));
p.parse(incidentIrradianceTotal, inverterRating, varargin{:});

incidentIrradianceTotal = p.Results.incidentIrradianceTotal;
inverterRating = p.Results.inverterRating;
ambientTemperature = p.Results.ambientTemperature;
oversizingRatio = p.Results.oversizingRatio;


%% 0.2) Definitions =======================================================

% Typical derating factors
DERATING_FACTOR = struct(...
    'SOILING', 0.98, ... 
    'SHADING', 0.97, ...
    'MISMATCH', 0.98, ...
    'WIRING', 0.98, ...
    'CONNECTIONS', 0.995, ...
    'LIGHT_INDUCED_DEGRADATION', 0.985, ...
    'NAMEPLATE_RATING', 0.99);

% Coefficients for the PV model a*Enorm^2 + b*Enorm*Tnorm + c*Enorm for a
% generic mono- or polycrystalline silicon module
PV_MODEL_COEFFICIENTS = [-0.104, -0.0754, 0.917];

% Reference values under NOCT conditions for normalising irradiance and
% temperature data
REF_IRRADIANCE_NOCT = 800;
REF_TEMPERATURE_NOCT = 20;


%% 1) Effective Irradiance ================================================
% Apply derating factors to calculate incident irradiance on the modules
% that is actually usable for electricity generation

%effectiveIrradiance = incidentIrradiance.total .* DERATING_FACTOR.SOILING .* DERATING_FACTOR.SHADING;
effectiveIrradiance = incidentIrradianceTotal;

% Apply an overcapacity factor to emulate oversizing of the PV array
effectiveIrradiance = effectiveIrradiance * oversizingRatio;


%% 2) System Power ========================================================
% Calculate system output using simplified PV system model, and convert
% from normalised values to actual power values

irradianceNorm = effectiveIrradiance ./ REF_IRRADIANCE_NOCT;
ambientTemperatureNorm = ambientTemperature ./ REF_TEMPERATURE_NOCT;

grossPVSystemPower = inverterRating * (PV_MODEL_COEFFICIENTS(1)*irradianceNorm.^2 + PV_MODEL_COEFFICIENTS(2).*irradianceNorm.*ambientTemperatureNorm + PV_MODEL_COEFFICIENTS(3)*irradianceNorm);


%% 3) Losses/Derating =====================================================
% Multiply gross PV system output power by all derating factors

% Calculate product of all derating factors
totalDeratingFactor = prod(cell2mat(struct2cell(DERATING_FACTOR)));

netPVSystemPower = totalDeratingFactor * grossPVSystemPower;


%% 4) Inverter Clipping ===================================================
%  Clip output power values that exceed the inverter rating
netPVSystemPower(netPVSystemPower > inverterRating) = inverterRating;




end

