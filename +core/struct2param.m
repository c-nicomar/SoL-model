function param = struct2param(structure)
    %% STRUCT2PARAM Converts a structure into a cell array of named parameters
    structureFields = fieldnames(structure);

    param(1:2:length(structureFields)*2) = structureFields';
    param(2:2:length(structureFields)*2) = struct2cell(structure)';

    for paramIx = 1:length(param)
        if(isnumeric(param{paramIx}))
            param{paramIx} = num2str(param{paramIx});
        end
    end
end