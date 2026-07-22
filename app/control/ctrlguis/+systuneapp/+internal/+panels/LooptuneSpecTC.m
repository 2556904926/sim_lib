classdef (Hidden) LooptuneSpecTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for Looptune goal specifications
    
    % Copyright 2013 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for Looptune goal
        MetaData
    end
    
    methods
    
        function this = LooptuneSpecTC(Data)
            % Construct with specifications given as input
            this.Data = Data;
            % Compute default GUI state
            updateMetaData(this);
        end
        
        %% Tool-Component API
        function Value = getValue(this)
            Value.Data = this.Data;
            Value.MetaData = this.MetaData;
        end              
        function gc = createView(this)
            % Create the view
            gc = systuneapp.internal.panels.LooptuneSpecGC(this);
        end        
        % set properties
        function setWc(this, WcExpr)
            Wc = evalin('base', WcExpr);
            this.Data.Wc = Wc;
        end
        function setGainMargin(this, GainMarginExpr)
            GainMargin = evalin('base',GainMarginExpr);
            this.Data.GainMargin = GainMargin;
        end        
        function setPhaseMargin(this, PhaseMarginExpr)
            PhaseMargin = evalin('base',PhaseMarginExpr);
            this.Data.PhaseMargin = PhaseMargin;
        end
        function setMinDecay(this, MinDecayExpr)
            MinDecay = evalin('base', MinDecayExpr);
            this.Data.MinDecay = MinDecay;
        end                
        function setMaxFrequency(this, MaxFrequencyExpr)
            MaxFrequency = evalin('base',MaxFrequencyExpr);
            this.Data.MaxFrequency = MaxFrequency;
        end 
        function setModels(this, ModelsExpr)
            Models = evalin('base', ModelsExpr);
            this.Data.Models = Models;
            if ~isnan(this.Data.Models)
                % Set metadata only if Models is not NaN
                this.MetaData.Models = Models;
            end
        end  
        % metadata
        function MetaData = getMetaData(this)
            % Get MetaData
            MetaData = this.MetaData;
        end          
        function updateMetaData(this)
            computeMetaData(this);
        end
        function this = computeMetaData(this)            
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
        end
    end
end
