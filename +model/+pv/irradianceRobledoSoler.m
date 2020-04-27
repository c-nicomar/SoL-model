function clearSkyGHI = irradianceRobledoSoler(zenithAngle)

clearSkyGHI = 1159.24.*(cosd(zenithAngle).^1.179) .* exp(-0.0019.*(90-zenithAngle));
clearSkyGHI(clearSkyGHI<0)=0;

end

