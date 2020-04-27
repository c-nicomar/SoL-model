classdef Constants
    %CONSTANTS Temporal constants
    
    properties(Constant)
        DAYS_IN_LEAP_YEAR = 366;
        DAYS_IN_YEAR = 365;
        HOURS_IN_DAY = 24;
        MINUTES_IN_HOUR = 60;
        SECONDS_IN_MINUTE = 60;
    end
    
    methods(Static)
        function dayFraction = stepToDay(step, units)
            switch(units)
                case 'day'
                    conversionFactor = 1;
                case 'hour'
                    conversionFactor = temporal.Constants.HOURS_IN_DAY;
                case 'minute'
                    conversionFactor = temporal.Constants.HOURS_IN_DAY * temporal.Constants.MINUTES_IN_HOUR;
                case 'second'
                    conversionFactor = temporal.Constants.HOURS_IN_DAY * temporal.Constants.MINUTES_IN_HOUR * temporal.Constants.SECONDS_IN_MINUTE;
            end
            
            dayFraction = step ./ conversionFactor;
        end
        
        function seconds = asSeconds(value, units)
            switch(units)
                case 'day'
                    conversionFactor = temporal.Constants.HOURS_IN_DAY * temporal.Constants.MINUTES_IN_HOUR * temporal.Constants.SECONDS_IN_MINUTE;
                case 'hour'
                    conversionFactor = temporal.Constants.MINUTES_IN_HOUR * temporal.Constants.SECONDS_IN_MINUTE;
                case 'minute'
                    conversionFactor = temporal.Constants.SECONDS_IN_MINUTE;
                case 'second'
                    conversionFactor = 1;
            end
            
            seconds = value * conversionFactor;
        end
    end
end

