classdef (Hidden) OvershootTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Overshoot Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % Overshoot Tuning Specification Parameters
        % see Parent class for additional parameters
        MaxOvershoot = 5;
        InputScaling = [];
        Models = NaN;
        Type = 'Overshoot'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelOvershoot'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelOvershoot'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelOvershoot'));        
    end
    
    methods(Access = public)
        function this = OvershootTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.OvershootSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('OvershootGoal',this.CDD.getTuningGoalName);
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
                Goal = TuningGoal.Overshoot(this.Input,this.Output,this.MaxOvershoot);
                Goal.Openings = this.Openings;
                Goal.Name = this.Name;
                Goal.InputScaling = this.InputScaling;
                Goal.Models = this.Models;                
                                                               
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
            this.MaxOvershoot = TuningGoal.MaxOvershoot;
            this.InputScaling = reshape(TuningGoal.InputScaling,1,[]);
            this.Models = reshape(TuningGoal.Models,1,[]);
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
        function Text = generateMATLABCode(this,~) 
            GoalName = systuneapp.util.createVariableName(this.Name);
            Text = cell(0,1);
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'IO',this.Type,this.Input,this.Output);
            CommentMaxOvershoot = getString(message('Control:systunegui:CodegenMaxOvershoot'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MaxOvershoot,'MaxOvershoot',CommentMaxOvershoot);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateOvershootGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            TGCreateCode = sprintf('%s = TuningGoal.Overshoot(Inputs,Outputs,MaxOvershoot);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Input',this.InputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);
        end
    end     
end
