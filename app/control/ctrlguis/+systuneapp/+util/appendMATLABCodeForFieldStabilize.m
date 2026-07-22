function Text = appendMATLABCodeForFieldStabilize(Text,Stabilize,GoalName)
% Low level utility function to add MATLAB Code for Stabilize Field in
% TuningGoals to Text.

% Copyright 2014 The MathWorks, Inc.

if ~Stabilize
    VarNameStabilize = sprintf('%s.Stabilize',GoalName);
    CommentStabilize = getString(message('Control:systunegui:CodegenStabilize'));
    Text = controllib.internal.codegen.appendMATLABCode(Text,Stabilize,VarNameStabilize,CommentStabilize);
end
