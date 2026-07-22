classdef (Hidden) StepRejectionTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Step Rejection Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % StepRejection Tuning Specification Parameters
        % see Parent class for additional parameters
        ReferenceModel = zpk(0,[-6.8339 -6.8339],18.5765);
        InputScaling = [];
        OutputScaling = [];
        Models = NaN;
        Type = 'StepRejection'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelStepRejection'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelStepRejection'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelStepRejection'));        
    end
    methods(Access = public)
        function this = StepRejectionTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.StepRejectionSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('StepRejectionGoal',this.CDD.getTuningGoalName);
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
                        Goal = TuningGoal.StepRejection(this.Input,this.Output,this.ReferenceModel);
                    case 'ResponseCharacteristics'
                        Goal = TuningGoal.StepRejection(this.Input,this.Output, ...
                                                    TempMetaData.MaxAmplitude,TempMetaData.MaxSettlingTime,TempMetaData.MinDamping);
                end
                Goal.Openings = this.Openings;
                Goal.InputScaling = this.InputScaling;
                Goal.OutputScaling = this.OutputScaling;
                Goal.Name = this.Name;
                Goal.Models = this.Models;                  
                                                             
                % check the tuning goal is valid
                validateTuningGoal(this,Goal)
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData); % create code;
                delete(this.Listener);
                this.TuningGoalWrapper.setTuningGoal(Goal,TempMetaData);                
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
            this.Input = TuningGoal.Input;
            this.Output = TuningGoal.Output;
            this.Openings = TuningGoal.Openings;
            this.ReferenceModel = TuningGoal.ReferenceModel;
            this.InputScaling = reshape(TuningGoal.InputScaling,1,[]);
            this.OutputScaling = reshape(TuningGoal.OutputScaling,1,[]);
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
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateStepRejectionGoal'))];
            if nargin<2 || isempty(MetaData) || strcmp(MetaData.ResponseType,'ReferenceModel')           
                RefModelCode = ['ReferenceModel = ' ...
                    controllib.internal.codegen.createExpressionForTFModel(MetaData.ReferenceModel) '; % ' ...
                    getString(message('Control:systunegui:CodegenRefModel'))];                                                
                Text = controllib.internal.codegen.appendMATLABCode(Text,RefModelCode);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.StepRejection(Inputs,Outputs,ReferenceModel);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            elseif strcmp(MetaData.ResponseType,'ResponseCharacteristics')               
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.MaxAmplitude,'MaxAmplitude');
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.MaxSettlingTime,'MaxSettlingTime');                       
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.MinDamping,'MinDamping');
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.StepRejection(Inputs,Outputs,MaxAmplitude,MaxSettlingTime,MinDamping);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            end
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Input',this.InputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Output',this.OutputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);                 
        end
    end     
end
