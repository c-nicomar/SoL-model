% =========================================================================
% equationOfTime.m
%
% Compare the accuracy of different equation of time approximations
% =========================================================================

%% 0.1) Definitions =======================================================

time = datenum(2015, 1, 1):datenum(2016,1,1);
time = time(1:end-1);

[year, month, day] = datevec(time);

dayOfYear = temporal.date2doy(year, month, day);

QUANTILE_BINS = 0:0.05:1;

%% 0.2) Preallocation =====================================================

eot = nan(length(dayOfYear), 4);
errorQuantiles = nan(length(QUANTILE_BINS), 4);

%% 1) Full EOT ============================================================

eot(:,1) = temporal.equationOfTime(time);


%% 2) Simplified EOT ======================================================

eclipticLongitude = (360/365)*(dayOfYear - 81);
eot(:,2) = 9.87*sind(2*eclipticLongitude) - 7.53*cosd(eclipticLongitude) - 1.5*sind(eclipticLongitude);


%% 3) Spencer EOT =========================================================

B = (dayOfYear - 1)*(360 / 365);

eot(:,3) = 229.2*(0.000075 + 0.001868*cosd(B) - 0.032077*sind(B) - 0.014615*cosd(2*B) - 0.04089*sind(2*B));


%% 4) Custom Fitted EOT ===================================================

eot(:,4) = 9.9*sind(2*eclipticLongitude) - 7.1*cosd(eclipticLongitude) - 1.9*sind(eclipticLongitude) - 0.4*cosd(2*eclipticLongitude);


%% 4) Error ===============================================================

for modelIx = 1:size(eot, 2)
    RMSE(modelIx) = sqrt(mean((eot(:,1) - eot(:,modelIx)).^2));
end

for modelIx = 1:size(eot, 2)
    errorQuantiles(:,modelIx) = quantile((eot(:,1) - eot(:,modelIx)), QUANTILE_BINS);
    
end

figure;
plot(QUANTILE_BINS*100, errorQuantiles(:, 2:end));

xlabel('Percentiles');
ylabel('Error (minutes)');

grid on;

%% 4) Visualisation =======================================================

%figure;
%plot(eot);