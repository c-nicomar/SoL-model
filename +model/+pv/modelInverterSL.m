function powerAC = modelInverterSL( powerDC, voltageDC, modelCoeff )
%MODEL_INVERTER_SL Santos-Lemon simplified inverter model

powerAC = modelCoeff.a.*powerDC.^2 + modelCoeff.b.*powerDC + modelCoeff.c.*voltageDC;

end

