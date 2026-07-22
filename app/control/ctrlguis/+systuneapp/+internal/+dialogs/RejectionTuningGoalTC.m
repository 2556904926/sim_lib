classdef (Hidden) RejectionTuningGoalTC < systuneapp.internal.dialogs.AbstractTuningGoalDialogTC
    % Tool component for Rejection Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % Generic Parameters
        Openings = {}
        DisturbanceInput = {}
        DisturbanceInputListPanel
        OpeningListPanel
        % Rejection Tuning Specification Parameters       
        MinAttenuation = zpk(-1,0,1);
        LoopScaling = 'on' 
        Models = NaN
        Focus = [0 Inf]
        Type = 'Rejection'
        % Dialog labels for signals 
        DisturbanceInputSignalLabel = getString(message('Control:systunegui:SignalListDisturbanceInputLabelRejection'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelRejection'));          
    end
    
    methods(Access = public)
        function this = RejectionTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty           
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogTC(CDD,varargin{:});
            this.Create = false;
            this.CDD = CDD;            
                        
            if isempty(varargin) || isempty(varargin{1}) % when creating new tuning goal
                this.Create = true;
                NewTuningGoalWrapper = systuneapp.data.TuningGoalWrapper;
                this.TuningGoalWrapper = NewTuningGoalWrapper;
                this.Name =  systuneapp.util.giveName('RejectionGoal',this.CDD.getTuningGoalName);
            else % when editing existing tuning goal
                this.TuningGoalWrapper=varargin{1}; %TuningGoalWrapper;
                syncData(this);
                this.Listener = addlistener(this.TuningGoalWrapper,'TuningGoal','PostSet',@(es,ed) syncData(this));
            end              
            
            this.OpeningListPanel = controllib.widget.internal.signallist.SignalListPanel(...
                this,'Openings','Openings',this.OpeningSignalLabel);   
            this.DisturbanceInputListPanel = controllib.widget.internal.signallist.SignalListPanel(...
                this,'DisturbanceInput','DisturbanceInput',this.DisturbanceInputSignalLabel);
            this.TuningGoalSpecTC = systuneapp.internal.panels.RejectionSpecTC(this);
            
            registerDataListeners(this.OpeningListPanel, ...
                addlistener(this,'Openings','PostSet', ...
                @(src,data)createFlatContextMenu(this.OpeningListPanel)));
            registerDataListeners(this.DisturbanceInputListPanel, ...
                addlistener(this,'DisturbanceInput','PostSet', ...
                @(src,data)createFlatContextMenu(this.DisturbanceInputListPanel)));
        end
    end
        
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.RejectionTuningGoalGC(this);
        end
        
        function delete(this)
            delete(this.DisturbanceInputListPanel);
            delete(this.OpeningListPanel);
            delete(this.TuningGoalSpecTC);
            delete(this.Listener);     
        end        

        function setTuningGoal(this)
            % collect information on the goal and create a new one
            try
                TempMetaData = this.TuningGoalSpecTC.getMetaData; 
                % capture error and return messages
                Goal = TuningGoal.Rejection(this.DisturbanceInput,this.MinAttenuation);
                Goal.Openings = this.Openings;
                Goal.Name = this.Name;
                Goal.Models = this.Models;
                Goal.Focus = this.Focus;
                Goal.LoopScaling = this.LoopScaling;                                                         
                                                               
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
                systuneapp.throwCSTunerError(ME);
            end
        end        
        function syncData(this)
            % synchronize the outside changed tuning goal information to
            % tool component            
            TuningGoal = this.TuningGoalWrapper.TuningGoal;
            this.DisturbanceInput = TuningGoal.DisturbanceInput;
            this.MinAttenuation = TuningGoal.MinAttenuation;
            this.Openings = TuningGoal.Openings;
            this.Name = TuningGoal.Name;
            this.Models = reshape(TuningGoal.Models,1,[]);
            this.Focus = TuningGoal.Focus;
            this.LoopScaling = TuningGoal.LoopScaling;
            if ~isempty(this.TuningGoalSpecTC)
                updateMetaData(this.TuningGoalSpecTC);
            end             
            update(this);           
        end
    end    
    methods(Access = protected)
        function mUpdate(this)
            if ~isempty(this.OpeningListPanel)
                updateUI(this.OpeningListPanel);
            end
            if ~isempty(this.DisturbanceInputListPanel)
                updateUI(this.DisturbanceInputListPanel);
            end            
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
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'Loop',this.Type,this.DisturbanceInput);
            MinAttenuationCode = ['MinAttenuation = ' MetaData.MinAttenuation '; % ' getString(message('Control:systunegui:CodegenRejectionMinAttenuation'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,MinAttenuationCode);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateRejectionGoal'))];            
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);                        
            TGCreateCode = sprintf('%s = TuningGoal.Rejection(Locations,MinAttenuation);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldScalings(Text,'Loop',this.LoopScaling,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);                        
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                                 
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);                          
        end
    end

    %% QE Methods
    methods(Hidden)
        function qeAddDisturbanceInput(this,input)
            % qeAddLocation(dialogTC, location)
            arguments
                this
                input char
            end
            this.DisturbanceInput = [this.DisturbanceInput; {input}];
        end
        
        function qeAddOpening(this,opening)
            % qeAddOpening(dialogTC, opening)
            arguments
                this
                opening char
            end
            this.Openings = [this.Openings; {opening}];
        end
    end
end
