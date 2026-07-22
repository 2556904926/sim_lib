classdef (Hidden) StepRespTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for StepTracking Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties (SetObservable)
        % StepResp Tuning Specification Parameters
        % see Parent class for additional parameters
        ReferenceModel = tf(1,[1 2*0.707 1]);
        InputScaling = [];
        RelGap = 0.1;
        Models = NaN;
        Type = 'StepResp'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelStepResp'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelStepResp'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelStepResp'));
    end
    methods(Access = public)
        function this = StepRespTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.StepRespSpecTC(this);
            if this.Create % new tuning goal, give a name
                this.Name =  systuneapp.util.giveName('StepTrackingGoal', this.CDD.getTuningGoalName);
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
                switch TempMetaData.ResponseType
                    case 'ReferenceModel'
                        Goal = TuningGoal.StepTracking(this.Input,this.Output,this.ReferenceModel);
                    case 'FirstOrder'
                        Goal = TuningGoal.StepTracking(this.Input,this.Output,TempMetaData.Tau);
                    case 'SecondOrder'
                        Goal = TuningGoal.StepTracking(this.Input,this.Output,TempMetaData.Tau, TempMetaData.OS);
                end
                Goal.Openings = this.Openings;
                Goal.InputScaling = this.InputScaling;
                Goal.RelGap = this.RelGap;
                Goal.Name = this.Name;
                Goal.Models = this.Models;                 
                                                               
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData); % create code
                delete(this.Listener);
                this.TuningGoalWrapper.setTuningGoal(Goal,TempMetaData);
                if this.Create
                    addTuningGoal(this.CDD,this.TuningGoalWrapper);
                    this.Create = false;
                end
            catch ME
                % Throw a GUI specific error message
                if strcmp(ME.identifier, 'Control:tuning:StepTracking8') && ( strcmp(TempMetaData.ResponseType , 'FirstOrder') || strcmp(TempMetaData.ResponseType , 'SecondOrder'))
                    CurrentME = MException('Control:systunegui:StepRespSpecErrTau', getString(message('Control:systunegui:StepRespSpecErrTau')));
                elseif strcmp(ME.identifier, 'Control:tuning:StepTracking8') && strcmp(TempMetaData.ResponseType , 'ReferenceModel')
                    CurrentME = MException('Control:systunegui:StepRespSpecErrReferenceModel', getString(message('Control:systunegui:StepRespSpecErrReferenceModel')));
                else
                    CurrentME = ME;
                end
                systuneapp.throwCSTunerError(CurrentME);
            end
        end
        function syncData(this)
            % synchronize the outside changed tuning goal information to
            % tool component
            TuningGoal = this.TuningGoalWrapper.TuningGoal;
            this.Input = TuningGoal.Input;
            this.Output = TuningGoal.Output;
            this.Openings = TuningGoal.Openings;
            this.ReferenceModel = TuningGoal.ReferenceModel;
            this.InputScaling = reshape(TuningGoal.InputScaling,1,[]);
            this.RelGap = TuningGoal.RelGap;
            this.Name = TuningGoal.Name;
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
        function Text = generateMATLABCode(this,MetaData)
            if nargin<2 || isempty(MetaData) % No MetaData information
                MetaData = this.TuningGoalSpecTC.getMetaData;
            end            
            GoalName = systuneapp.util.createVariableName(this.Name);
            Text = cell(0,1);
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'IO',this.Type,this.Input,this.Output);
            TopCommentTGCreate = ['% ' getString(message('Control:systunegui:CodegenCreateStepRespGoal'))];
            VarNameTau = 'Tau';
            CommentTau = getString(message('Control:systunegui:StepRespSpecTau'));
            if nargin<2 || isempty(MetaData) || strcmp(MetaData.ResponseType,'ReferenceModel')
                RefModelCode = ['ReferenceModel = ' ...
                    controllib.internal.codegen.createExpressionForTFModel(MetaData.ReferenceModel) '; % ' ...
                    getString(message('Control:systunegui:CodegenRefModel'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,RefModelCode);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TopCommentTGCreate);
                CodeTGCreate = sprintf('%s = TuningGoal.StepTracking(Inputs,Outputs,ReferenceModel);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,CodeTGCreate);
            elseif strcmp(MetaData.ResponseType,'FirstOrder')
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.Tau,VarNameTau,CommentTau);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TopCommentTGCreate);
                TGCreateCode = sprintf('%s = TuningGoal.StepTracking(Inputs,Outputs,Tau);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            elseif strcmp(MetaData.ResponseType,'SecondOrder')
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.Tau,VarNameTau,CommentTau);
                VarNameOvershoot = 'Overshoot';
                CommentOvershoot = getString(message('Control:systunegui:StepRespSpecOS'));
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.OS,VarNameOvershoot,CommentOvershoot);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TopCommentTGCreate);
                TGCreateCode = sprintf('%s = TuningGoal.StepTracking(Inputs,Outputs,Tau,Overshoot);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            end
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Input',this.InputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalar(Text,'RelGap',this.RelGap,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName); 
        end
    end 
end
