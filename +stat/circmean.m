function meanAngle = circmean( angles )

angles = deg2rad(angles(~isnan(angles)));

r = sum(exp(1i*angles(:)));

meanAngle = rad2deg(angle(r));

end

