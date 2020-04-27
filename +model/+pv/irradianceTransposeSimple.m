function ds = irradianceTranspose( data, tilt, orientation)

import model.pv.*;

%% Transposition ==========================================================
%disp('Transposing irradiance...');
AOI = solarIncidentAngle(tilt, orientation, data.apparentSunZenith, data.sunAzimuth);

ds.Eb = data.DNI.*cosd(AOI);
ds.Eb(AOI >= 90) = 0;
%ds.Eb = 0*AOI;
%ds.Eb(AOI<90) = data.DNI(AOI<90).*cosd(AOI(AOI<90));

ds.Ed = irradianceDiffuseIsotropic(tilt, data.DHI);
%ds.Ed = irradianceDiffusePerez(tilt, orientation, data.DHI, data.DNI, data.outerIrradiance, data.sunZenith, data.sunAzimuth, data.relativeAirmass);
%ds.Ed = irradianceDiffuseKing(tilt, data.DHI, data.GHI, data.sunZenith);

albedo = 0.2;
ds.Eg = irradianceGroundDiffuse(tilt, data.GHI, albedo);

ds.E = ds.Eb + ds.Ed + ds.Eg;

end

