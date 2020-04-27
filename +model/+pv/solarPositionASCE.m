function [sunZenith, sunAzimuth] = solarPositionASCE(time, location)

%% 1) Calculation =========================================================

% ASCE (4)
x = (360/365)*(time.dayOfYear - 81);

% Declination angle ASCE (3)
declination = 23.45*sind(x);

% Equation of time ASCE (8)
EOT = 9.87*sind(2*x) - 7.53*cosd(x) - 1.5*sind(x);

% Standard merdian in arcminutes
standardMeridian = time.UTCOffset(1)*15;

% Solar time ASCE (7)
solarTime = (time.hour*60 + time.minute + 4*(standardMeridian - -1*location.longitude) + EOT)/60;

% Hour angle ASCE (9)
% Angle between the line pointing directly to the sun and the line pointing
% directly to the sun at solar noon
% Hour angle is just an angular representation of solar time
hourAngle = 15*(solarTime - 12);

% The true zenith angle for the site
cosZenith = cosd(location.latitude)*cosd(declination).*cosd(hourAngle) + sind(location.latitude)*sind(declination);

sunZenith = acosd(cosZenith);

sunAzimuth = atan2d(-1 * sind(hourAngle), cosd(location.latitude) .* tand(declination) - sind(location.latitude) .* cosd(hourAngle));
sunAzimuth = sunAzimuth + (sunAzimuth < 0) * 360; %shift from range of [-180,180] to [0,360]


end