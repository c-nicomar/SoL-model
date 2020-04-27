function powerDC = modelModuleSL( irradiance, ambientTemperature, modelCoeff )
%MODELMODULESL Santos-Lemon simplified solar module model

irradianceNorm = irradiance ./ 800;
ambientTemperatureNorm = ambientTemperature ./ 20;

a = modelCoeff(1);
b = modelCoeff(2);
c = modelCoeff(3);

powerDC = modelCoeff.a.*irradianceNorm.^2 + modelCoeff.b.*irradianceNorm.*ambientTemperatureNorm + modelCoeff.c.*irradianceNorm;

end

