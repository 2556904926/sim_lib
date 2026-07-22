function TuningGoalData = getTuningGoalData(TuningGoalNames)
% Utility function returning tuning goal data as struct array.
% TuningGoalData(n) has the follwoing fields
%   .Name       : received from input
%   .Title      : received from message catalog systungui.xml
%                    Control:systunegui:TuningGoalType[TuningGoalName]
%   .Description: received from message catalog systungui.xml
%                    Control:systunegui:TuningGoalDescription[TuningGoalName]
%   .Icon       : received from resources directory, 'TuningGoal.' is
%                 identifier, TuningGoalName is used to identify file name
%                    and files names Plot_[TuningGoalName]_60x40.png

% Copyright 2013-2023 The MathWorks, Inc.

TuningGoalData = struct;

switch TuningGoalNames % if names are groupnames, get tuning goal names
    case {'quickstart','time','frequency','openloop','passivity','systemdynamics'}
        TuningGoalNames = systuneapp.util.getTuningGoalName(TuningGoalNames);
end

for ct=1:length(TuningGoalNames)
    TuningGoalData(ct,1).Name = TuningGoalNames{ct};
    TuningGoalData(ct,1).Description = ...
        getString(message(['Control:systunegui:TuningGoalDescription' TuningGoalNames{ct}]));
    TuningGoalData(ct,1).Icon = systuneapp.util.getTuningGoalIcon(TuningGoalNames{ct});
end
