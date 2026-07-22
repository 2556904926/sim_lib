function Text = appendMATLABCodeForTuningGoalTitleAndSignals(Text,SignalType,TuningGoalType,varargin)
% Low level utility function to add MATLAB Code for Title and Signals of
% Tuning Goals to Text.
% SignalType = 'IO', 'Loop'

% Copyright 2014 The MathWorks, Inc.

Title = ['%% ' getString(message(['Control:systunegui:Codegen' TuningGoalType 'Title']))];
Text = controllib.internal.codegen.appendMATLABCode(Text,Title);

switch SignalType
    case 'IO'
        IOsTitle  = ['% ' getString(message('Control:systunegui:CodegenIOs'))];
        Text = controllib.internal.codegen.appendMATLABCode(Text,IOsTitle);
        Text = controllib.internal.codegen.appendMATLABCode(Text,varargin{1},'Inputs');
        Text = controllib.internal.codegen.appendMATLABCode(Text,varargin{2},'Outputs');
        SpecTitle = ['% ' getString(message('Control:systunegui:CodegenSpecifications'))];
        Text = controllib.internal.codegen.appendMATLABCode(Text,SpecTitle);
    case 'Loop'
        if ~strcmp(TuningGoalType,'Poles') || (strcmp(TuningGoalType,'Poles') && ~isempty(varargin{1}))
            LocationComment  =   getString(message('Control:systunegui:CodegenLocations'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,varargin{1},'Locations',LocationComment);
        end        
        SpecTitle = ['% ' getString(message('Control:systunegui:CodegenSpecifications'))];
        Text = controllib.internal.codegen.appendMATLABCode(Text,SpecTitle);
    case 'Block'
        switch TuningGoalType
            case 'StableController'
                Text = controllib.internal.codegen.appendMATLABCode(Text,varargin{1},'Block');
        end
        SpecTitle = ['% ' getString(message('Control:systunegui:CodegenSpecifications'))];
        Text = controllib.internal.codegen.appendMATLABCode(Text,SpecTitle);
end
