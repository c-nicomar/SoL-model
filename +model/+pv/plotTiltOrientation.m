function [irradiances, summerIrradiances, winterIrradiances] = plotTiltOrientation( longitude, latitude, varargin )
%% 0) Definitions =========================================================

pvTilts = 0:5:90;
pvOrientations = mod(270:10:360+90,360);
pvDisplayOrientations = -90:10:90;

location.longitude = longitude;
location.latitude = latitude;
location.elevation = spatial.getElevationData( longitude, latitude );

if(nargin < 3)
    % Evaluate solar characteristics over one year - Use current year as
    % representative year
    ds.time = datenum(2013,1,1):1/24:datenum(2014,1,1);
    ds.time = ds.time(1:end-1);
    
else
    ds = varargin{1};
end



%% 1) Data Import =========================================================

months = month(ds.time);
summerMask = ismember(months, [10 11 12 1 2 3]);
winterMask = ismember(months, [4 5 6 7 8 9]);


%% 2) Solar Position ======================================================

%ts = model.pv.maketimestruct(ds.time, 12.584);
ts = model.pv.maketimestruct(ds.time, 12);

[sunAzimuth, sunElevation, apparentSunElevation] = model.pv.solarPositionSPA(ts, location);
apparentSunZenith = 90 - apparentSunElevation;
sunZenith = 90 - sunElevation;

%% 3) Clear Sky Model =====================================================
%  Do not have actual irradiance data so use clear-sky data
if(nargin < 3)
    [clearSkyGHI, clearSkyDNI, clearSkyDHI] = model.pv.irradianceIneichen(ts, location);

    clearSkyGHI(isnan(clearSkyGHI)) = 0;
    clearSkyDNI(isnan(clearSkyDNI)) = 0;
    clearSkyDHI(isnan(clearSkyDHI)) = 0;

    ds.GHI = clearSkyGHI;
    ds.DNI = clearSkyDNI;
    ds.DHI = clearSkyDHI;
else
    if(~isfield(ds, 'DNI'))
        ds.DNI = model.pv.irradianceDirectDIRINT(ds.GHI, sunZenith, model.pv.date2doy(ts.year, ts.month, ts.day), model.pv.alt2pres(location.elevation));
    end
    
    if(~isfield(ds, 'DHI'))
        ds.DHI = ds.GHI(:) - cosd(apparentSunZenith).*ds.DNI(:);
    end
end


%% 4) Irradiance Components ===============================================

irradiances = zeros(length(pvTilts),length(pvOrientations));
summerIrradiances = zeros(length(pvTilts),length(pvOrientations));
winterIrradiances = zeros(length(pvTilts),length(pvOrientations));

for orientationIx = 1:length(pvOrientations)
    % Get current PV panel orientation
    orientation = pvOrientations(orientationIx);
    
    fprintf('Analysing tilts for orientation %d...\n', pvDisplayOrientations(orientationIx));
    
    for tiltIx = 1:length(pvTilts)
        % get current PV tilt
        tilt = pvTilts(tiltIx);
        
        AOI = model.pv.solarIncidentAngle(tilt, orientation, apparentSunZenith, sunAzimuth);

        % Determine the beam component of irradiance
        effectiveIrradianceBeam = 0*AOI;
        effectiveIrradianceBeam(AOI<90) = ds.DNI(AOI<90).*cosd(AOI(AOI<90));
        
        % Determine the diffuse component of irradiance
        %Ed = model.pv.irradianceDiffuseKing(pvTilts(tiltIx), ds.DHI, ds.GHI, sunZenith);
        extraterrestrialIrradiance = model.pv.extraterrestrialIrradiance(model.pv.date2doy(ts.year, ts.month, ts.day));
        effectiveIrradianceDiffuseSky = model.pv.irradianceDiffusePerez(tilt, orientation, ds.DHI, ds.DNI, extraterrestrialIrradiance, apparentSunZenith, sunAzimuth, model.pv.airmassRelative(apparentSunZenith));
        
        % Determine the ground reflected component of irradiance
        albedo = 0.2;
        effectiveIrradianceDiffuseGround = model.pv.irradianceGroundDiffuse(tilt, ds.GHI, albedo);

        effectiveIrradiance = effectiveIrradianceBeam + effectiveIrradianceDiffuseSky + effectiveIrradianceDiffuseGround;
        %E = Eb;

        % Storage
        irradiances(tiltIx, orientationIx) = sum(effectiveIrradiance);
        summerIrradiances(tiltIx, orientationIx) = sum(effectiveIrradiance(summerMask));
        winterIrradiances(tiltIx, orientationIx) = sum(effectiveIrradiance(winterMask));
    end
end

% Calculate transposition factor as ratio of tilted irradiance to
% horizontal irradiance
%transpositionFactor = irradiances./irradiances(find(pvTilts == 0), find(pvOrientations == 0));

% Display heatmap of % irradiance of tilt vs. orientation
figure;
clabel = arrayfun(@(x){sprintf('%0.0f',x)}, 100*irradiances./max(max(irradiances)));
disp.heatmap(irradiances, pvDisplayOrientations, pvTilts, clabel);
set(gca,'YDir','normal');

figure; 
clabelSummer = arrayfun(@(x){sprintf('%0.0f',x)}, 100*summerIrradiances/max(max(summerIrradiances)));
disp.heatmap(summerIrradiances, pvDisplayOrientations, pvTilts, clabelSummer);
set(gca,'YDir','normal');

figure;
clabelWinter =  arrayfun(@(x){sprintf('%0.0f',x)}, 100*winterIrradiances/max(max(winterIrradiances)));
disp.heatmap(winterIrradiances, pvDisplayOrientations, pvTilts, clabelWinter);
set(gca,'YDir','normal');


end

