function Text = appendMATLABCodeForFieldOpenings(Text,Openings,GoalName)
% Low level utility function to add MATLAB Code for Openings Field in
% TuningGoals to Text.

% Copyright 2014 The MathWorks, Inc.

if ~isempty(Openings)
    VarNameOpening = sprintf('%s.Openings',GoalName);
    CommentOpening = getString(message('Control:systunegui:CodegenOpenings'));
    Text = controllib.internal.codegen.appendMATLABCode(Text,Openings,VarNameOpening,CommentOpening);
end
