classdef (Hidden) TrackingTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Tracking Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % Tracking Tuning Specification Parameters
        % see Parent class for additional parameters
        MaxError = zpk(-0.02,-2,1);
        InputScaling = [];
        Models = NaN;
        Focus = [0 Inf];
        Type = 'Tracking'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelTracking'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelTracking'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelTracking'));
    end
    
    methods(Access = public)
        function this = TrackingTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.TrackingSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('TrackingGoal',this.CDD.getTuningGoalName);
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
                % capture error and return messages
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                switch TempMetaData.EnableFreqDomainSpec
                    case true
                        Goal = TuningGoal.Tracking(this.Input,this.Output,this.MaxError);
                    case false
                        Goal = TuningGoal.Tracking(this.Input,this.Output, TempMetaData.ResponseTime,...
                                                                TempMetaData.DCError, TempMetaData.PeakError);
                end                
                Goal.Openings = this.Openings;
                Goal.Name = this.Name;
                Goal.InputScaling = this.InputScaling;
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
                if strcmp(ME.identifier,'Control:tuning:TrackingReq2') && isequal(TempMetaData.EnableFreqDomainSpec,false)
                    CurrentME = MException('Control:tuning:TrackingReq3', getString(message('Control:tuning:TrackingReq3')));
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
            this.Name = TuningGoal.Name;
            this.Input = TuningGoal.Input;
            this.Output = TuningGoal.Output;
            this.Openings = TuningGoal.Openings;
            this.MaxError = TuningGoal.MaxError;
            this.InputScaling = reshape(TuningGoal.InputScaling,1,[]);
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
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateTrackingGoal'))];
            if nargin<2 || isempty(MetaData) || MetaData.EnableFreqDomainSpec
                MaxErrorCode = ['MaxError = ' ...
                    controllib.internal.codegen.createExpressionForTFModel(MetaData.MaxError) '; % ' ...
                    getString(message('Control:systunegui:CodegenTrackingMaxError'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,MaxErrorCode);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.Tracking(Inputs,Outputs,MaxError);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            else
                ResponseTimeComment = getString(message('Control:systunegui:CodegenTrackingResponseTime'));
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.ResponseTime,'ResponseTime',ResponseTimeComment);                
                DCErrorComment = getString(message('Control:systunegui:CodegenTrackingDCError'));
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.DCError,'DCError',DCErrorComment);
                PeakErrorComment = getString(message('Control:systunegui:CodegenTrackingPeakError'));
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.PeakError,'PeakError',PeakErrorComment);                
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.Tracking(Inputs,Outputs,ResponseTime,DCError,PeakError);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            end
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Input',this.InputScaling,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);            
        end
    end    
end
