function effectiveIrradiance = irradianceTranspose( data, tilt, azimuth)
% IRRADIANCE_TRANPOSE Full irradiance transposition using Perez model

import model.pv.*;

%% 0) Definitions =========================================================

ALBEDO = 0.2;


%% Transposition ==========================================================
AOI = solarIncidentAngle(tilt, azimuth, data.apparentSunZenith, data.sunAzimuth);

effectiveIrradiance.beam = data.DNI.*cosd(AOI);
effectiveIrradiance.beam(AOI >= 90) = 0;

effectiveIrradiance.diffuseSky = irradianceDiffusePerez(tilt, azimuth, data.DHI, data.DNI, data.extraterrestrialIrradiance, data.apparentSunZenith, data.sunAzimuth, data.relativeAirmass);
%effectiveIrradiance.diffuseSky = data.DHI * (1+ cosd(tilt)) * 0.5;

effectiveIrradiance.diffuseGround = irradianceGroundDiffuse(tilt, data.GHI, ALBEDO);

effectiveIrradiance.total = effectiveIrradiance.beam + effectiveIrradiance.diffuseSky + effectiveIrradiance.diffuseGround;

end

