classdef (Hidden) PolesTuningGoalTC < systuneapp.internal.dialogs.AbstractTuningGoalDialogTC
    % Tool component for Poles Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % Generic Parameters
        Location = {}
        LocationInLocationList = {};
        Openings = {}
        LocationListTC
        OpeningListTC
        % Poles Tuning Specification Parameters       
        MinDecay = 0
        MinDamping = 0 
        MaxFrequency = Inf
        Models = NaN
        Focus = [0 Inf]
        Type = 'Poles'
        % Dialog labels for signals
        LocationSignalLabel = '';
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelPoles'));           
    end
       
    methods(Access = public)
        function this = PolesTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty 
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogTC(CDD,varargin{:});
            this.Create = false;
            this.CDD = CDD;            
 
            if isempty(varargin) || isempty(varargin{1}) % when creating new tuning goal
                this.Create = true;
                NewTuningGoalWrapper = systuneapp.data.TuningGoalWrapper;
                this.TuningGoalWrapper = NewTuningGoalWrapper;
                this.Name =  systuneapp.util.giveName('PolesGoal',this.CDD.getTuningGoalName);
            else % when editing existing tuning goal
                this.TuningGoalWrapper=varargin{1}; %TuningGoalWrapper;
                syncData(this);
                this.Listener = addlistener(this.TuningGoalWrapper,'TuningGoal','PostSet',@(es,ed) syncData(this));
            end              
            
            this.LocationListTC =  controllib.widget.internal.signallist.SignalListPanel(this,...
                'Location','Location',this.LocationSignalLabel);
            this.OpeningListTC =  controllib.widget.internal.signallist.SignalListPanel(this,...
                'Openings','Openings',this.OpeningSignalLabel);             
            this.TuningGoalSpecTC = systuneapp.internal.panels.PolesSpecTC(this);              
        end
    end
        
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.PolesTuningGoalGC(this);
        end
        
        function delete(this)
            delete(this.LocationListTC);
            delete(this.OpeningListTC);
            delete(this.TuningGoalSpecTC);
            delete(this.Listener);     
        end           

        function setTuningGoal(this)
            % collect information on the goal and create a new one
            try
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                % capture error and return messages
                if ~isempty(this.Location)
                    Goal = TuningGoal.Poles(this.Location);
                else
                    Goal = TuningGoal.Poles();
                end
                Goal.Name = this.Name;
                Goal.Openings = this.Openings;
                Goal.MinDecay = this.MinDecay;
                Goal.MinDamping = this.MinDamping;
                Goal.MaxFrequency = this.MaxFrequency;                
                Goal.Models = this.Models;
                Goal.Focus = this.Focus;                                
                                                               
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData); % create code
                delete(this.Listener);
                this.TuningGoalWrapper.setTuningGoal(Goal,TempMetaData);                
                if this.Create
                    addTuningGoal(this.CDD,this.TuningGoalWrapper);
                    this.Create=false;
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
            this.MinDecay = TuningGoal.MinDecay;
            this.MinDamping = TuningGoal.MinDamping;
            this.MaxFrequency = TuningGoal.MaxFrequency;            
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
            if ~isempty(this.LocationListTC)
                update(this.LocationListTC);
            end
            if ~isempty(this.OpeningListTC)
                update(this.OpeningListTC);
            end
            if ~isempty(this.TuningGoalSpecTC)
                update(this.TuningGoalSpecTC);
            end
        end
    end
    methods(Hidden=true)
        function Text = generateMATLABCode(this,~) 
            GoalName = systuneapp.util.createVariableName(this.Name);
            Text = cell(0,1);
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'Loop',this.Type,this.Location);
            Comment = getString(message('Control:systunegui:CodegenPolesMinDecay'));          
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MinDecay,'MinDecay',Comment);            
            Comment = getString(message('Control:systunegui:CodegenPolesMinDamping'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MinDamping,'MinDamping',Comment);   
            Comment = getString(message('Control:systunegui:CodegenPolesMaxFrequency'));            
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MaxFrequency,'MaxFrequency',Comment);            
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreatePolesGoal'))];                                   
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            if ~isempty(this.Location)
                TGCreateCode = sprintf('%s = TuningGoal.Poles(Locations,MinDecay,MinDamping,MaxFrequency);',GoalName);
            else
                TGCreateCode = sprintf('%s = TuningGoal.Poles(MinDecay,MinDamping,MaxFrequency);',GoalName);
            end           
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode); 
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);                        
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);                                 
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);                          
        end
    end        
end
