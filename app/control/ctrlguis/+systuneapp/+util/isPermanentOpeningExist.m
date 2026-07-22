function [isExist,Names] = isPermanentOpeningExist(ModelName)

Points = linearize.getModelIOPoints({ModelName});

isExist = false;
Names = {};
if isa(Points,'linearize.IOPoint')
    for ct = 1:numel(Points)
        if strcmp(linearize.IOPoint.getOpenLoopFromType(Points(ct).Type),'on')
            isExist = true;
            Names = vertcat(Names,Points(ct).Block);
        end
    end
end