function [Variables,Blocks] = getModelVariablesUsedInTunedBlocks(CDD)
    % Returns model variable used in Tuned Blocks of Control System Tuner App
    
    % Copyright 2013 The MathWorks, Inc.

Variables=cell(0,1);
Blocks=cell(0,1);
%Get list of all model variables
vars = Simulink.findVars(getName(CDD));
%Filter list to only contain model workspace, data dictionary, and base workspace variables.
srcType = {vars.SourceType};
idx     = strncmp(srcType,'base',4) | strncmp(srcType,'model',5) | strncmp(srcType,'data', 4);
vars    = vars(idx);

for id=1:length(vars)
    TBList = arrayfun(@(x)x.Name, getTunedBlocks(CDD), 'UniformOutput', false);
    TunedBlocks = intersect(vars(id).Users,TBList);
    if length(TunedBlocks)>1
        Variables=vertcat(Variables,vars(id).Name);
        Blocks=vertcat(Blocks,TunedBlocks);
    end
end
end