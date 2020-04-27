function y = interpNan( x )
% INTERP_NAN Linearly interpolates gaps in a time series
% YOUT=INTERPNAN(YIN) linearly interpolates over NaN
% in the input time series (may be complex), but ignores
% trailing and leading NaN.
%

y=x;

bd=isnan(x);
gd=find(~bd);

bd([1:(min(gd)-1) (max(gd)+1):end])=0;


y(bd)=interp1(gd,x(gd),find(bd));


end

