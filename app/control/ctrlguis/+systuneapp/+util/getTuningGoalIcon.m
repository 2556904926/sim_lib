function TuningGoalIcon = getTuningGoalIcon(TuningGoalName)
% Utility function returning tuning goal icon

% Copyright 2023 The MathWorks,

switch TuningGoalName
    case 'Looptune'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('quickLoopTune');
    case 'StepResp'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalStepTracking');
    case 'StepRejection'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalStepRejection');
    case 'Transient'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalTransient');
    case 'LQG'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalLqg');
    case 'Gain'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalGain');
    case 'Variance'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalVariance');
    case 'Tracking'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalTracking');
    case 'Overshoot'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalOvershoot');
    case 'Rejection'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalRejection');
    case 'Sensitivity'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalSensitivity');
    case 'WeightedGain'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalGain');
    case 'WeightedVariance'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalVariance');
    case 'MinLoopGain'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalMinLoopGain');
    case 'MaxLoopGain'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalMaxLoopGain');
    case 'LoopShape'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalLoopShape');
    case 'Margins'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalMargins');
    case 'Passivity'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalPassivity');
    case 'ConicSector'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalConicSector');
    case 'WeightedPassivity'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalPassivity');
    case 'Poles'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalPoles');
    case 'StableController'
        TuningGoalIcon = matlab.ui.internal.toolstrip.Icon('tuningGoalControllerPoles');
end
