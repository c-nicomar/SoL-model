function eot = equationOfTime(time)
% EQUATION_OF_TIME Calculates the equation of time for the specified time vector

    % Calculate julian date corresponding to time vector 
    jd = juliandate(time);
    
    d = jd-2451543.5;
    
    % Keplerian Elements of the Sun
    
    % Eccentricity
    eccentricity = 0.016709 - (1.151e-9 * d);
    
    % Mean anomaly (degrees)
    meanAnomaly = mod(356.0470 + (0.9856002585 * d), 360);
    
    % Auxiliary angle
    auxiliaryAngle = meanAnomaly+(180/pi).*eccentricity.*sin(meanAnomaly.*(pi/180)).*(1+eccentricity.*cos(meanAnomaly.*(pi/180)));
    
    % Convert to rectangular coordinates
    x = cos(auxiliaryAngle.*(pi/180)) - eccentricity;
    y = sin(auxiliaryAngle.*(pi/180)) .* sqrt(1-eccentricity.^2);
    
    % Find the distance and true anomaly (degrees)
    trueAnomaly = atan2(y,x).*(180/pi);
    
	% Longitude of perihelion (degrees)
    perihelionLongitude = 282.9404 + (4.70935e-5 * d);
    
    % Ecliptic longitude of the sun
    eclipticLongitude = trueAnomaly + perihelionLongitude;
    
    % Calculate the equation of time in degrees
    eotDegrees = -1.91466647.*sind(meanAnomaly) - 0.019994643.*sind(2.*meanAnomaly) + 2.466.*sind(2.*eclipticLongitude) - 0.0053.*sind(4.*eclipticLongitude);
    
    % Convert from degrees to minutes (1 deg = 4 minutes)
    eot = eotDegrees .* 4;
end
