classdef (Hidden) LooptuneTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Quick Loop Tuning Goal.
    
    % Copyright 2014 The MathWorks, Inc.        
    
    properties (SetObservable)      
        % Loop Tuning Specification Parameters
        % see Parent class for additional parameters                       
        Wc = 0.1;
        GainMargin = 7.6;
        PhaseMargin = 45;
        MinDecay = 0;
        MaxFrequency = Inf;        
        Models = NaN;
        Type = 'Looptune'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelLooptune'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelLooptune'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelLooptune'));        
    end
    
    methods(Access = public)
        function this = LooptuneTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            
            % check whether loop tuning is used before and give a different name
            NameExtensions = { ...
                '_LoopShapeGoal', ...
                '_MarginsGoal', '_InputMarginsGoal', '_OutputMarginsGoal', ...
                '_PolesGoal' };
            TuningGoalNames = this.CDD.getTuningGoalName;
            for ct=1:length(NameExtensions)
                TuningGoalNames = strrep(TuningGoalNames,NameExtensions{ct},'');
            end            
            this.Name =  systuneapp.util.giveName('LoopTuning',TuningGoalNames);                      
            
            this.IOTransferTC = systuneapp.internal.panels.IOTransferTC(this.CDD,this); 
            this.TuningGoalSpecTC = systuneapp.internal.panels.LooptuneSpecTC(this);              
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
                %% Create Looptune requirements
                LooptuneOptions = looptuneOptions;
                LooptuneOptions.GainMargin = this.GainMargin;
                LooptuneOptions.PhaseMargin = this.PhaseMargin;
                LooptuneOptions.MinDecay = this.MinDecay;
                LooptuneOptions.MaxFrequency = this.MaxFrequency;                
                [SoftReqs,HardReqs] = ctrlutil.looptuneReqs(this.Wc,{},LooptuneOptions,this.Input,this.Output);
                
                %% LoopShape Goal
                LoopShapeGoal = SoftReqs(1);
                LoopShapeGoal.Name = [this.Name '_LoopShapeGoal']; 
                LoopShapeGoal.Openings = this.Openings;
                LoopShapeGoal.Models = this.Models;
                % make sure that there is no other goal with same name
                if any(strcmp(this.CDD.getTuningGoalName,LoopShapeGoal.Name))
                    error(message('Control:systunegui:LooptuneNameConflict',LoopShapeGoal.Name));                    
                end
                
                %% Margins Goal
                MarginsGoal(1) = SoftReqs(2);
                MarginsGoal(1).Openings = this.Openings;
                MarginsGoal(1).Models = this.Models;
                MarginsGoal(1).Name = [this.Name '_MarginsGoal']; 
                if length(SoftReqs)==3
                    MarginsGoal(1).Name = [this.Name '_InputMarginsGoal'];
                    MarginsGoal(2) = SoftReqs(3);
                    MarginsGoal(2).Openings = this.Openings;
                    MarginsGoal(2).Models = this.Models;
                    MarginsGoal(2).Name = [this.Name '_OutputMarginsGoal'];
                end
                % make sure that there is no other goal with same name
                for ct=1:length(MarginsGoal)
                    if any(strcmp(this.CDD.getTuningGoalName,MarginsGoal(ct).Name))
                        error(message('Control:systunegui:LooptuneNameConflict',MarginsGoal(ct).Name));
                    end
                end                
                
                %% Poles Goal              
                if isempty(HardReqs)
                    if ~(this.MinDecay==0 && ~isfinite(this.MaxFrequency))
                        PolesGoal = TuningGoal.Poles();
                        PolesGoal.Location = LoopShapeGoal.Location;
                        PolesGoal.MaxFrequency = this.MaxFrequency;
                    else % default values no poles goal
                        PolesGoal = [];
                    end
                else % setup creates poles goal
                    PolesGoal = HardReqs;
                end
                if ~isempty(PolesGoal)
                    PolesGoal.MinDecay = this.MinDecay;
                    PolesGoal.Models = this.Models;
                    PolesGoal.Name = [this.Name '_PolesGoal'];
                    % make sure that there is no other goal with same name
                    if any(strcmp(this.CDD.getTuningGoalName,PolesGoal.Name))
                        error(message('Control:systunegui:LooptuneNameConflict',PolesGoal.Name));
                    end
                end                              

                %% Check tuning goals are valid
                validateTuningGoal(this,LoopShapeGoal);
                for ct=1:length(MarginsGoal)
                    validateTuningGoal(this,MarginsGoal(ct));
                end
                if ~isempty(PolesGoal)
                    validateTuningGoal(this,PolesGoal);
                end
                                
                %% Add tuning goals by generating metadata and matlab code for codegen
                % loop shape 
                this.TuningGoalWrapper(1).setTuningGoal(LoopShapeGoal);
                tc = systuneapp.internal.dialogs.LoopShapeTuningGoalTC(this.CDD,this.TuningGoalWrapper(1));
                MetaData = tc.TuningGoalSpecTC.getMetaData;
                this.TuningGoalWrapper(1).MetaData = MetaData;
                this.TuningGoalWrapper(1).MetaData.MATLABCode = tc.generateMATLABCode(MetaData);                
                addTuningGoal(this.CDD,this.TuningGoalWrapper(1));
                
                % margins goal(s)
                for ct=1:length(MarginsGoal)
                    this.TuningGoalWrapper(ct+1) = systuneapp.data.TuningGoalWrapper;
                    this.TuningGoalWrapper(ct+1).setTuningGoal(MarginsGoal(ct));
                    tc = systuneapp.internal.dialogs.MarginsTuningGoalTC(this.CDD,this.TuningGoalWrapper(ct+1));
                    this.TuningGoalWrapper(ct+1).MetaData = tc.TuningGoalSpecTC.getMetaData;
                    this.TuningGoalWrapper(ct+1).MetaData.MATLABCode = tc.generateMATLABCode();                    
                    addTuningGoal(this.CDD,this.TuningGoalWrapper(ct+1));
                end
                % poles goal
                if ~isempty(PolesGoal)
                    this.TuningGoalWrapper(end+1) = systuneapp.data.TuningGoalWrapper;
                    this.TuningGoalWrapper(end).setTuningGoal(PolesGoal);
                    tc = systuneapp.internal.dialogs.PolesTuningGoalTC(this.CDD,this.TuningGoalWrapper(end));
                    this.TuningGoalWrapper(end).MetaData = tc.TuningGoalSpecTC.getMetaData;
                    this.TuningGoalWrapper(end).MetaData.MATLABCode = tc.generateMATLABCode();                    
                    addTuningGoal(this.CDD,this.TuningGoalWrapper(end));
                end
            catch ME
                systuneapp.throwCSTunerError(ME);
            end
        end
        function syncData(this)
            % this goal creates three goals and it is destroyed. No need to
            % sync.
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
end
