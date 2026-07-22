function Text = appendMATLABCodeForFieldModels(Text,Models,GoalName)
% Low level utility function to add MATLAB Code for Models Field in
% TuningGoals to Text.

% Copyright 2014 The MathWorks, Inc.

if ~isnan(Models)
    VarNameModels = sprintf('%s.Models',GoalName);
    CommentModels = getString(message('Control:systunegui:CodegenModels'));
    Text = controllib.internal.codegen.appendMATLABCode(Text,Models,VarNameModels,CommentModels);
end
