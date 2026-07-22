classdef (Hidden) MaxLoopGainTuningGoalTC < systuneapp.internal.dialogs.TuningGoalLoopTransferTC
    % Tool component for Maximum Loop Gain Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
        
    properties (SetObservable)
        % MaxLoopGain Tuning Specification Parameters       
        % see Parent class for additional parameters
        Gain = 1;
        LoopScaling = 'on';
        Stabilize = true;
        Models = NaN;
        Focus = [0 Inf];
        Type = 'MaxLoopGain'
        % Dialog labels for signals
        LocationSignalLabel = getString(message('Control:systunegui:SignalListLocationLabelMaxLoopGain'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelMaxLoopGain'));        
    end
    
    methods(Access = public)
        function this = MaxLoopGainTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty           
            this = this@systuneapp.internal.dialogs.TuningGoalLoopTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.MinMaxLoopGainSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('MaxLoopGainGoal',this.CDD.getTuningGoalName);
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
                % capture error and return messages
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                switch TempMetaData.EnableGain
                    case true
                        Goal = TuningGoal.MaxLoopGain(this.Location,this.Gain);
                    case false
                        Goal = TuningGoal.MaxLoopGain(this.Location,TempMetaData.F, TempMetaData.G);
                end
                Goal.Openings = this.Openings;
                Goal.Stabilize = this.Stabilize;
                Goal.LoopScaling = this.LoopScaling;
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
            this.Location = TuningGoal.Location;
            this.Openings = TuningGoal.Openings;
            this.Gain = TuningGoal.MaxGain;
            this.LoopScaling = TuningGoal.LoopScaling;
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
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateMaxLoopGainGoal'))];
            if nargin<2 || isempty(MetaData) || MetaData.EnableGain
                GainCode = ['LoopGain = ' ...
                    controllib.internal.codegen.createExpressionForTFModel(MetaData.Gain) '; % ' ...
                    getString(message('Control:systunegui:CodegenMaxLoopGainLoopGain'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,GainCode);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.MaxLoopGain(Locations,LoopGain);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            else
                CommentFGmax = ['% ' getString(message('Control:systunegui:CodegenMaxLoopGainFGmax'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,CommentFGmax);              
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.F,'FMax');
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.G,'GMax');
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.MaxLoopGain(Locations,FMax,GMax);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            end         
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldStabilize(Text,this.Stabilize,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Loop',this.LoopScaling,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);             
        end
    end          
end
