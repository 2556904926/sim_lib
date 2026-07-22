function Type = getTuningGoalType(TuningGoal)
% Utility function to get tuning goal type

% Copyright 2013 The MathWorks, Inc.

% delete TuningGoal. part and gets tuning goal type
Type = strrep(class(TuningGoal),'TuningGoal.','');

switch Type
    case 'StepTracking'
        Type = 'StepResp';
    case 'ControllerPoles'
        Type = 'StableController';
end