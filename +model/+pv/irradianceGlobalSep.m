function ds = irradianceGlobalSep( inputGHI, time, location )
%IRRADIANCEGLOBALSEP Separate global horizontal irradiance into its direct
%normal and direct horizontal irradiance components

import model.pv.*;

%% Data Correction ========================================================
disp('Correcting and restructuring data...');

dataMask = ~isnan(inputGHI);

ds.GHI = inputGHI(dataMask);

ds.time = time(dataMask);

ds.ts = maketimestruct(ds.time, 12);
doy = date2doy(ds.ts.year, ds.ts.month, ds.ts.day); 

%% Data Import ============================================================
% Obtain corresponding VCSN pressure data for correcting irradiance values
disp('Generating local pressure data...');

ggd = GGD('ggd.db', 'data'); 

vcsnData = ggd.getNearestDataFromTable(location.longitude, location.latitude, 'vcsn');

dayTimes = round(ds.time);

[~, ia, ib] = intersect(dayTimes, vcsnData.time);

pressure = nan(length(ds.GHI),1);
pressure(ia) = vcsnData.pressure(ib);

pressureIx = ~isnan(pressure);
idx = cumsum(pressureIx);
idx(~idx) = 1;
a = pressure(pressureIx);
pressure = a(idx);

ds.pressure = pressure.*100;


%% Solar Position =========================================================
disp('Calculating solar position...');

[ds.sunAzimuth, ds.sunElevation, ds.apparentSunElevation, ~] = solarPositionEphemeris(ds.ts, location);
ds.apparentSunZenith = 90-ds.apparentSunElevation;
ds.sunZenith = 90 - ds.sunElevation;

% ds.eConstant = 1.041.*(ds.sunZenith*pi/180).^3;
% ds.cosSunZenith = cosd(ds.sunZenith);
% ds.sinSunZenith = sind(ds.sunZenith);

% Only need zenith so save some memory
clear ds.sunElevation;
clear ds.apparentSunElevation;


%% Airmass ================================================================
disp('Generating local airmass data...');
ds.relativeAirmass = airmassRelative(ds.sunZenith);

ds.absoluteAirmass = airmassAbsolute(ds.relativeAirmass, ds.pressure);

ds.outerIrradiance = irradianceSun(date2doy(ds.ts.year, ds.ts.month, ds.ts.day));



%% ods.GHI Decomposition ======================================================
disp('Decomposing GHI...');

ds.DNI = irradianceDirectDIRINT(ds.GHI, ds.sunZenith, doy, pressure);
ds.DHI = ds.GHI - cosd(ds.apparentSunZenith).*ds.DNI;

% CHECK!s
ds.DHI(ds.DHI < 0) = 0;

ds.location = location;

end

