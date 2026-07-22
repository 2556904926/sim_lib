function Text = appendMATLABCodeForFieldScalar(Text,FieldName,Value,GoalName,Comment)
% Low level utility function to add MATLAB Code for Tolerance Fields in
% TuningGoals to Text, i.e., Type = 'RelGap

% Copyright 2014 The MathWorks, Inc.

if nargin<5
    Comment = '';
end

VarName = sprintf('%s.%s',GoalName,FieldName);

switch FieldName
    case 'RelGap'
        if ~isequal(Value,0.1)
            Comment = getString(message('Control:systunegui:CodegenRelGap'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,Value,VarName,Comment);
        end
    case 'CrossTol'
        if ~isequal(Value,0.1)
            Comment= getString(message('Control:systunegui:CodegenCrossTol'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,Value,VarName,Comment);
        end
    case 'MinDecay' % Poles or StableController
        Text = controllib.internal.codegen.appendMATLABCode(Text,Value,VarName,Comment);
    case 'MinDamping' % Poles or StableController
        Text = controllib.internal.codegen.appendMATLABCode(Text,Value,VarName,Comment);
    case 'MaxFrequency' % Poles or StableController
        Text = controllib.internal.codegen.appendMATLABCode(Text,Value,VarName,Comment);
end
