classdef (Hidden) LoopShapeTuningGoalTC < systuneapp.internal.dialogs.TuningGoalLoopTransferTC
    % Tool component for Loop Shape Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % LoopShape Tuning Specification Parameters       
        % see Parent class for additional parameters
        LoopGain = tf(1,[1 0]);
        CrossTol = 0.1;
        Stabilize = true;
        LoopScaling = 'on';
        Models = NaN
        Focus = [0 Inf];
        Type = 'LoopShape'
        % Dialog labels for signals
        LocationSignalLabel = getString(message('Control:systunegui:SignalListLocationLabelLoopShape'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelLoopShape'));        
    end
    
    methods(Access = public)
        function this = LoopShapeTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty           
            this = this@systuneapp.internal.dialogs.TuningGoalLoopTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.LoopShapeSpecTC(this);
            if this.Create % new tuning goal, give a name
               this.Name =  systuneapp.util.giveName('LoopShapeGoal',this.CDD.getTuningGoalName);
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
                switch TempMetaData.EnableLoopGain
                    case true
                        Goal = TuningGoal.LoopShape(this.Location,this.LoopGain);
                    case false
                        Goal = TuningGoal.LoopShape(this.Location,TempMetaData.Wc);
                end
                Goal.CrossTol = this.CrossTol;
                Goal.Openings = this.Openings;
                Goal.Stabilize = this.Stabilize;
                Goal.LoopScaling = this.LoopScaling;
                Goal.Name = this.Name;
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
            this.Location = TuningGoal.Location;
            this.Openings = TuningGoal.Openings;
            this.LoopGain = TuningGoal.LoopGain;
            this.CrossTol = TuningGoal.CrossTol;
            this.Stabilize = TuningGoal.Stabilize;
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
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateLoopShapeGoal'))];
            if nargin<2 || isempty(MetaData) || MetaData.EnableLoopGain
                LoopGainCode = ['LoopGain = ' ...
                    controllib.internal.codegen.createExpressionForTFModel(MetaData.LoopGain) '; % ' ...
                    getString(message('Control:systunegui:CodegenLoopShapeLoopGain'))];
                Text = controllib.internal.codegen.appendMATLABCode(Text,LoopGainCode);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.LoopShape(Locations,LoopGain);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            else
                CommentWc = getString(message('Control:systunegui:CodegenLoopShapeWc'));
                Text = controllib.internal.codegen.appendMATLABCode(Text,MetaData.Wc,'Wc',CommentWc);                
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
                TGCreateCode = sprintf('%s = TuningGoal.LoopShape(Locations,Wc);',GoalName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            end
            Text = systuneapp.util.appendMATLABCodeForFieldScalar(Text,'CrossTol',this.CrossTol,GoalName);           
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldStabilize(Text,this.Stabilize,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Loop',this.LoopScaling,GoalName); 
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);            
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                      
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);                          
        end
    end                 
end
