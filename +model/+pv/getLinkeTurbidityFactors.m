function linkeTurbidity = getLinkeTurbidityFactors( time, location )
%GETLINKETURBIDITYFACTORS Lookup simplified Linke turbidity factors
%corresponding to time and location of site

%% 0) Definitions =========================================================

LINKE_TURBIDITY_ZONES = [-50 -23 23 60];

if(location.latitude < min(LINKE_TURBIDITY_ZONES) || location.latitude > max(LINKE_TURBIDITY_ZONES))
    linkeTurbidity = 1.9; % Poles
elseif(location.latitude > LINKE_TURBIDITY_ZONES(2) && location.latitude < LINKE_TURBIDITY_ZONES(3));
    linkeTurbidity = 3.8; % Tropics
else
    halfYearMask = time.dayOfYear <= max(time.dayOfYear)/2;
    
    linkeTurbidity(halfYearMask,1) = 0.0067*time.dayOfYear(halfYearMask) + 2.28;
    linkeTurbidity(~halfYearMask,1) = -0.0071*time.dayOfYear(~halfYearMask) + 4.9521;
    
    if(location.latitude < 0)
        % In Southern hemisphere so shift Linke Turbidity values by 6 months
        linkeTurbidity = circshift(linkeTurbidity, round(length(linkeTurbidity)/2));
    end
end