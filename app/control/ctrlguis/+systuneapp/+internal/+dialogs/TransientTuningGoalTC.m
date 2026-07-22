classdef (Hidden) TransientTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Transient Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % StepRejection Tuning Specification Parameters
        % see Parent class for additional parameters
        ReferenceModel = tf(1,[1 1]);
        OtherInputShaping = tf(1,[1 1]);
        InputScaling = [];
        OutputScaling = [];
        RelGap = 0.1;
        Models = NaN;
        Type = 'Transient'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelTransient'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelTransient'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelTransient'));
    end
    methods(Access = public)
        function this = TransientTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.TransientSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('TransientGoal',this.CDD.getTuningGoalName);
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
                % create tuning goal
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                if strcmp(TempMetaData.InputSignalString, getString(message('Control:systunegui:TransientTuningGoalSpecOther')))
                    Goal = TuningGoal.Transient(this.Input,this.Output,this.ReferenceModel,this.OtherInputShaping);
                else % impulse, step and ramp selections
                    Goal = TuningGoal.Transient(this.Input,this.Output,this.ReferenceModel, ...
                                                convertInputSignalStringToEnglish(TempMetaData.InputSignalString));
                end                
                % capture error and return messages
                Goal.Openings = this.Openings;
                Goal.InputScaling = this.InputScaling;
                Goal.OutputScaling = this.OutputScaling;
                Goal.RelGap = this.RelGap;
                Goal.Name = this.Name;
                Goal.Models = this.Models;                  
                                                               
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData);
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
            this.OtherInputShaping = TuningGoal.InputShaping;
            this.InputScaling = reshape(TuningGoal.InputScaling,1,[]);
            this.OutputScaling = reshape(TuningGoal.OutputScaling,1,[]);
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
            RefModelCode = ['ReferenceModel = ' ...
                            controllib.internal.codegen.createExpressionForTFModel(MetaData.ReferenceModel) '; % ' ...
                            getString(message('Control:systunegui:CodegenRefModel'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,RefModelCode);
            if strcmp(MetaData.InputSignalString,getString(message('Control:systunegui:TransientTuningGoalSpecOther')))
                OtherSignalCode = ['InputSignal = ' ...
                    controllib.internal.codegen.createExpressionForTFModel(MetaData.OtherInputShaping) '; % ' ...
                    getString(message('Control:systunegui:CodegenTransientInputShaping'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,OtherSignalCode);
            else % impulse, step and ramp selections
                InputSignalString = lower(convertInputSignalStringToEnglish(MetaData.InputSignalString));
                InputSignalString = ['InputSignal = ''' InputSignalString '''; % ' getString(message('Control:systunegui:CodegenTransientInputShaping'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,InputSignalString);
            end            
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateTransientGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            TGCreateCode = sprintf('%s = TuningGoal.Transient(Inputs,Outputs,ReferenceModel,InputSignal);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Input',this.InputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Output',this.OutputScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalar(Text,'RelGap',this.RelGap,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);             
        end
    end     
end

function estr = convertInputSignalStringToEnglish(str)
switch str
    case getString(message('Control:systunegui:TransientTuningGoalSpecImpulse'))
        estr = 'impulse';
    case getString(message('Control:systunegui:TransientTuningGoalSpecStep'))
        estr = 'step';
    case getString(message('Control:systunegui:TransientTuningGoalSpecRamp'))
        estr = 'ramp';
    otherwise
        estr = '';
end        
end
