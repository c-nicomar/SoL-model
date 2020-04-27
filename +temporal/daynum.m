function doy = daynum(dateval) 
    dateval = datenum(dateval); 
    prevYear = datenum(year(dateval)-1, 12,31); 
    doy = dateval-prevYear; 
end