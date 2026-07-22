classdef (Hidden) StableControllerTuningGoalTC < systuneapp.internal.dialogs.AbstractTuningGoalDialogTC
    % Tool component for Stable Controller Tuning Goal.
    
    % Copyright 2013 The MathWorks, Inc.     
    
    properties (SetObservable)
        % Generic Parameters
        Block = {}
        % StableController Tuning Specification Parameters       
        MinDecay = 0;
        MinDamping = 0;
        MaxFrequency = Inf;
        Type = 'StableController'
    end
    
    methods(Access = public)
        function this = StableControllerTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty           
            this = this@systuneapp.internal.dialogs.AbstractTuningGoalDialogTC(CDD,varargin{:});
            this.Create = false;
            this.CDD = CDD;            
                        
            if isempty(varargin) || isempty(varargin{1}) % when creating new tuning goal
                this.Create = true;
                NewTuningGoalWrapper = systuneapp.data.TuningGoalWrapper;
                this.TuningGoalWrapper = NewTuningGoalWrapper;
                this.Name =  systuneapp.util.giveName('ControllerPolesGoal',this.CDD.getTuningGoalName);
            else % when editing existing tuning goal
                this.TuningGoalWrapper=varargin{1}; %TuningGoalWrapper;
                syncData(this);
                this.Listener = addlistener(this.TuningGoalWrapper,'TuningGoal','PostSet',@(es,ed) syncData(this));                
            end                                      
            this.TuningGoalSpecTC = systuneapp.internal.panels.StableControllerSpecTC(this);
        end
    end
        
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.StableControllerTuningGoalGC(this);
        end
        
        function delete(this)
            delete(this.TuningGoalSpecTC);
            delete(this.Listener);     
        end           
    
        function setTuningGoal(this)
            % collect information on the goal and create a new one
            try
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                % capture error and return messages
                Goal = TuningGoal.ControllerPoles(this.Block, ...
                    this.MinDecay,this.MinDamping,this.MaxFrequency);                
                Goal.Name = this.Name;
                                                               
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
            this.Name = TuningGoal.Name;
            this.Block = TuningGoal.Block;
            this.MinDecay = TuningGoal.MinDecay;
            this.MinDamping = TuningGoal.MinDamping;
            this.MaxFrequency = TuningGoal.MaxFrequency;
            if ~isempty(this.TuningGoalSpecTC)
                updateMetaData(this.TuningGoalSpecTC);
            end                   
            update(this);     
        end
    end    
    methods(Access = protected)
        function mUpdate(this) 
            if ~isempty(this.TuningGoalSpecTC)
                update(this.TuningGoalSpecTC);
            end
        end
    end
    methods(Hidden=true)
        function Text = generateMATLABCode(this,~) 
            GoalName = systuneapp.util.createVariableName(this.Name);
            Text = cell(0,1);
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'Block',this.Type,this.Block);            
            Comment = getString(message('Control:systunegui:CodegenStableControllerMinDecay'));          
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MinDecay,'MinDecay',Comment);            
            Comment = getString(message('Control:systunegui:CodegenStableControllerMinDamping'));
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MinDamping,'MinDamping',Comment);   
            Comment = getString(message('Control:systunegui:CodegenStableControllerMaxFrequency'));            
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.MaxFrequency,'MaxFrequency',Comment);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateStableControllerGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            TGCreateCode = sprintf('%s = TuningGoal.ControllerPoles(Block,MinDecay,MinDamping,MaxFrequency);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);                               
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);                          
        end
    end      
end










