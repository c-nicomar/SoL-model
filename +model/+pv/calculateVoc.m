function Voc = calculateVoc( module )
%CALCULATEVOC Summary of this function goes here
%   Detailed explanation goes here

%% 0) Constants ===========================================================

% Reference temperature (25 deg C)
REFERENCE_TEMPERATURE = 25;
REFERENCE_IRRADIANCE = 1;

% Elementary charge (1.60218E-19 coulombs
Q = 1.60218E-19;

%Boltzmann's constant (1.38066E-23 J/K)
K = 1.38066E-23;  

% Efective irradiance in suns
EFFECTIVE_IRRADIANCE = 1;

%% 1) Calculation =========================================================

% Typical value for mBetaVoc according to Sandia "Array Performance Model" pp 17
moduleMBetaVoc = 0;

% Typical value for empricial diode factor according Sandia's "Array Performance Model" pp 11
%moduleDiodeFactor = 1;

cellTemperature = -10;

moduleDiodeFactor = Q*module.a_ref / (module.Ns * K * (cellTemperature + 273.15));

betaVoc = module.beta_oc + moduleMBetaVoc .* (1 - EFFECTIVE_IRRADIANCE);
delta = moduleDiodeFactor .* K .* (cellTemperature + 273.15) ./ Q;
Voc = (module.v_oc_ref + module.Ns .* delta .* log(REFERENCE_IRRADIANCE) + betaVoc .* (cellTemperature - REFERENCE_TEMPERATURE));


end

