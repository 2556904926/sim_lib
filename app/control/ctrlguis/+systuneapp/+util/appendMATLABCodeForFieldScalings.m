function Text = appendMATLABCodeForFieldScalings(Text,Type,Scaling,GoalName)
% Low level utility function to add MATLAB Code for Scaling Fields in
% TuningGoals to Text, i.e., InputScaling, OutputScaling, LoopScaling

% Copyright 2014 The MathWorks, Inc.

switch Type
    case 'Input'
        if ~isempty(Scaling)
            VarName = sprintf('%s.InputScaling',GoalName);
            Comment = getString(message('Control:systunegui:CodegenInputScaling'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,Scaling,VarName,Comment);
        end
    case 'Output'
        if ~isempty(Scaling)
            VarName = sprintf('%s.OutputScaling',GoalName);
            Comment = getString(message('Control:systunegui:CodegenOutputScaling'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,Scaling,VarName,Comment);
        end
    case 'Loop'
        if ~isequal(Scaling,'on')
            VarName = sprintf('%s.LoopScaling',GoalName);            
            Comment = getString(message('Control:systunegui:CodegenLoopScaling'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,Scaling,VarName,Comment);
        end
    case 'Order'
        if Scaling ~= 0
            VarName = sprintf('%s.ScalingOrder',GoalName);
            Comment = getString(message('Control:systunegui:CodegenScalingOrder'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,Scaling,VarName,Comment);
        end        
end
