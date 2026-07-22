classdef (Hidden) GainTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Gain Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.    
    
    properties (SetObservable)
        % Gain Tuning Specification Parameters
        % see Parent class for additional parameters
        Gain = 1;
        Stabilize = true;
        InputScaling = [];
        OutputScaling = [];
        Models = NaN;
        Focus = [0 Inf];
        Type = 'Gain'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelGain'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelGain'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelGain'));
    end
    
    methods(Access = public)
        function this = GainTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.GainSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('GainGoal',this.CDD.getTuningGoalName);
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
                Goal = TuningGoal.Gain(this.Input,this.Output,this.Gain);
                Goal.Openings = this.Openings;
                Goal.Stabilize = this.Stabilize;
                Goal.Name = this.Name;
                Goal.InputScaling = this.InputScaling;
                Goal.OutputScaling = this.OutputScaling;
                Goal.Models = this.Models;
                Goal.Focus = this.Focus;                
                                                               
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData); % create code;
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
            this.Gain = TuningGoal.MaxGain;
            this.InputScaling = reshape(TuningGoal.InputScaling,1,[]);
            this.OutputScaling = reshape(TuningGoal.OutputScaling,1,[]);
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
            MaxGainCode = ['MaxGain = ' ...
                controllib.internal.codegen.createExpressionForTFModel(MetaData.Gain) '; % ' ...
                getString(message('Control:systunegui:CodegenMaxGain'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,MaxGainCode);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateGainGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            TGCreateCode = sprintf('%s = TuningGoal.Gain(Inputs,Outputs,MaxGain);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldStabilize(Text,this.Stabilize,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Input',this.InputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Output',this.OutputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);    
        end
    end           
end
