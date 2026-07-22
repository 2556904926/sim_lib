classdef (Hidden) SensitivityTuningGoalTC < systuneapp.internal.dialogs.TuningGoalLoopTransferTC
    % Tool component for Sensitivity Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % Sensitivity Tuning Specification Parameters       
        % see Parent class for additional parameters
        MaxSensitivity = zpk(0,-1,1);
        LoopScaling = 'on';
        Models = NaN;
        Focus = [0 Inf];
        Type = 'Sensitivity'
        % Dialog labels for signals
        LocationSignalLabel = getString(message('Control:systunegui:SignalListLocationLabelSensitivity'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelSensitivity'));         
    end
    
    methods(Access = public)
        function this = SensitivityTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty           
            this = this@systuneapp.internal.dialogs.TuningGoalLoopTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.SensitivitySpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('SensitivityGoal',this.CDD.getTuningGoalName);
            end                   
        end
    end
        
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TuningGoalLoopTransferGC(this);
        end
    end
    
    methods(Access = public)
        function setTuningGoal(this)
            % collect information on the goal and create a new one
            try
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                % capture error and return messages
                Goal = TuningGoal.Sensitivity(this.Location,this.MaxSensitivity);
                Goal.Openings = this.Openings;
                Goal.LoopScaling = this.LoopScaling;
                Goal.Name = this.Name;
                Goal.Models = this.Models;
                Goal.Focus = this.Focus;    
                
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode =  generateMATLABCode(this,TempMetaData); % create code
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
            this.Name = TuningGoal.Name;
            this.Location = TuningGoal.Location;
            this.Openings = TuningGoal.Openings;
            this.MaxSensitivity = TuningGoal.MaxSensitivity;
            this.LoopScaling = TuningGoal.LoopScaling;
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
             update(this.LoopTransferTC);
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
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'Loop',this.Type,this.Location);
            SensitivityCode = ['MaxSensitivity = ' MetaData.MaxSensitivity '; % ' getString(message('Control:systunegui:CodegenSensitivityMaxSensitivity'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,SensitivityCode);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateSensitivityGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            TGCreateCode = sprintf('%s = TuningGoal.Sensitivity(Locations,MaxSensitivity);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode); 
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Loop',this.LoopScaling,GoalName); 
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);                          
        end
    end      
end
