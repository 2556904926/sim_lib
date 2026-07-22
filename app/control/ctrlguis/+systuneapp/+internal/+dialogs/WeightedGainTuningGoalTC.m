classdef (Hidden) WeightedGainTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Weighted Gain Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties (SetObservable)
        % WeightedGain Tuning Specification Parameters
        % see Parent class for additional parameters
        WL = 1;
        WR = 1;
        Stabilize = true;
        Models = NaN;
        Focus = [0 Inf];
        Type = 'WeightedGain'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelWeightedGain'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelWeightedGain'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelWeightedGain'));        
    end
    
    methods(Access = public)
        function this = WeightedGainTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.WeightedGainSpecTC(this);
            if this.Create % new tuning goal, give a name
                this.Name =  systuneapp.util.giveName('WeightedGainGoal',this.CDD.getTuningGoalName);
            end
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TuningGoalInputOutputTransferGC(this);
        end
    end
    
    methods(Access = public)
        function setTuningGoal(this)
            % collect information on the goal and create a new one
            try
                TempMetaData = this.TuningGoalSpecTC.getMetaData;                
                % capture error and return messages
                Goal = TuningGoal.WeightedGain(this.Input,this.Output,this.WL,this.WR);
                Goal.Openings = this.Openings;
                Goal.Stabilize = this.Stabilize;
                Goal.Name = this.Name;
                Goal.Models = this.Models;
                Goal.Focus = this.Focus;                                                
                                                               
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData); % create code
                delete(this.Listener);
                this.TuningGoalWrapper.setTuningGoal(Goal,TempMetaData)
                if this.Create
                    addTuningGoal(this.CDD,this.TuningGoalWrapper);
                    this.Create = false;
                end
            catch ME
                systuneapp.throwCSTunerError(ME);
            end
        end
        function syncData(this)
            % synchronize the outside changed tuning goal information to
            % tool component
            TuningGoal = this.TuningGoalWrapper.TuningGoal;
            this.Name = TuningGoal.Name;
            this.Input = TuningGoal.Input;
            this.Output = TuningGoal.Output;
            this.Openings = TuningGoal.Openings;
            this.WL = TuningGoal.WL;
            this.WR = TuningGoal.WR;
            this.Stabilize = TuningGoal.Stabilize;
            this.Models = reshape(TuningGoal.Models,1,[]);
            this.Focus = TuningGoal.Focus;
            if ~isempty(this.TuningGoalSpecTC)
                updateMetaData(this.TuningGoalSpecTC);
            end
            update(this);
        end
    end
    methods(Access = protected)
        function mUpdate(this)
            update(this.IOTransferTC);
            if ~isempty(this.TuningGoalSpecTC)
                update(this.TuningGoalSpecTC);
            end
        end
    end
    methods(Hidden=true)
        function Text = generateMATLABCode(this,MetaData)
            if nargin<2 || isempty(MetaData) % No MetaData information
                MetaData = this.TuningGoalSpecTC.getMetaData;
            end            
            GoalName = systuneapp.util.createVariableName(this.Name);
            Text = cell(0,1);
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'IO',this.Type,this.Input,this.Output);
            WLCode = ['WL = ' ...
                MetaData.WL '; % ' ...
                getString(message('Control:systunegui:CodegenLeftWeight'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,WLCode);
            WRCode = ['WR = ' ...
                MetaData.WR '; % ' ...
                getString(message('Control:systunegui:CodegenRightWeight'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,WRCode);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateWeightedGainGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            TGCreateCode = sprintf('%s = TuningGoal.WeightedGain(Inputs,Outputs,WL,WR);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldStabilize(Text,this.Stabilize,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);
        end
    end
end
