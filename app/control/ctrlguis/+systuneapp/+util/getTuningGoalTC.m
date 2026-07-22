function TC = getTuningGoalTC(Type,cdd,TuningGoalWrapper)
% Utility function to get tuning goal's tool component
% TC = systuneapp.dialogs.[TuningGoalName]TuningGoalTC(cdd,TuningGoalWrapper);

% Copyright 2013-2021 The MathWorks, Inc.

switch Type
    case 'Looptune'
        TC = systuneapp.internal.dialogs.LooptuneTuningGoalTC(cdd,TuningGoalWrapper);
    case 'StepResp'
        TC = systuneapp.internal.dialogs.StepRespTuningGoalTC(cdd,TuningGoalWrapper);
    case 'StepRejection'
        TC = systuneapp.internal.dialogs.StepRejectionTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Transient'
        TC = systuneapp.internal.dialogs.TransientTuningGoalTC(cdd,TuningGoalWrapper);
    case 'LQG'
        TC = systuneapp.internal.dialogs.LQGTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Gain'
        TC = systuneapp.internal.dialogs.GainTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Variance'
        TC = systuneapp.internal.dialogs.VarianceTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Tracking'
        TC = systuneapp.internal.dialogs.TrackingTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Overshoot'
        TC = systuneapp.internal.dialogs.OvershootTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Rejection'
        TC = systuneapp.internal.dialogs.RejectionTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Sensitivity'
        TC = systuneapp.internal.dialogs.SensitivityTuningGoalTC(cdd,TuningGoalWrapper);
    case 'WeightedGain'
        TC = systuneapp.internal.dialogs.WeightedGainTuningGoalTC(cdd,TuningGoalWrapper);
    case 'WeightedVariance'
        TC = systuneapp.internal.dialogs.WeightedVarianceTuningGoalTC(cdd,TuningGoalWrapper);
    case 'MaxLoopGain'
        TC = systuneapp.internal.dialogs.MaxLoopGainTuningGoalTC(cdd,TuningGoalWrapper);
    case 'MinLoopGain'
        TC = systuneapp.internal.dialogs.MinLoopGainTuningGoalTC(cdd,TuningGoalWrapper);
    case 'LoopShape'
        TC = systuneapp.internal.dialogs.LoopShapeTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Margins'
        TC = systuneapp.internal.dialogs.MarginsTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Poles'
        TC = systuneapp.internal.dialogs.PolesTuningGoalTC(cdd,TuningGoalWrapper);
    case 'StableController'
        TC = systuneapp.internal.dialogs.StableControllerTuningGoalTC(cdd,TuningGoalWrapper);
    case 'Passivity'
        TC = systuneapp.internal.dialogs.PassivityTuningGoalTC(cdd,TuningGoalWrapper);
    case 'ConicSector'
        TC = systuneapp.internal.dialogs.ConicSectorTuningGoalTC(cdd,TuningGoalWrapper);
    case 'WeightedPassivity'
        TC = systuneapp.internal.dialogs.WeightedPassivityTuningGoalTC(cdd,TuningGoalWrapper);
    otherwise
        TC = [];
end