function Text = appendMATLABCodeForFieldName(Text,Name,GoalName)
% Low level utility function to add MATLAB Code for Name Field in
% TuningGoals to Text.

% Copyright 2014 The MathWorks, Inc.

if ~isempty(Name)
    VarNameName = sprintf('%s.Name',GoalName);
    CommentName = getString(message('Control:systunegui:CodegenName'));
    Text = controllib.internal.codegen.appendMATLABCode(Text,GoalName,VarNameName,CommentName);
end
