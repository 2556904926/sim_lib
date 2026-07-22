function Text = appendMATLABCodeForFieldFocus(Text,Focus,GoalName)
% Low level utility function to add MATLAB Code for Focus Field in
% TuningGoals to Text.

% Copyright 2014 The MathWorks, Inc.

if ~isequal(Focus,[0 Inf])
    VarNameFocus = sprintf('%s.Focus',GoalName);
    CommentFocus = getString(message('Control:systunegui:CodegenFocus'));
    Text = controllib.internal.codegen.appendMATLABCode(Text,Focus,VarNameFocus,CommentFocus);
end
