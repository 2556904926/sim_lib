classdef (Hidden) LoopShapeSpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Loop Shape tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = LoopShapeSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API    
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.LoopShapeSpecGC(this);
        end
        
        function this = computeMetaData(this)
            % Derive MetaData from Data whenever it is empty
            if this.Data.Create
                % If the tuning goal is created from GUI, open in the
                % basic mode
                this.MetaData.EnableLoopGain = false;
            else
                % If the tuning goal was created elsewhere, open in
                % advanced mode
                this.MetaData.EnableLoopGain = true;
            end
            
            % Default values for fields not in data (Cross-over frequency)
            this.MetaData.Wc = 0.1;
            
             % Call Parent computeMetaData to get Models and LoopGain
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'LoopGain', this.Data.LoopGain);
        end

        function this = setCrossTol(this,CrossTolExpr)
            % Set the CrossTol property
            CrossTol = evalin('base', CrossTolExpr);
            if (isnumeric(CrossTol) && isscalar(CrossTol) && isreal(CrossTol) && ...
                    isfinite(CrossTol) && CrossTol>=0)
                this.Data.CrossTol = CrossTol;
            else
                error(message('Control:systunegui:LoopShapeSpecErrCrossTolerance'));
            end
        end
    
        function this = setWc(this,WcExpr)
            % Set the Wc property
            Wc = evalin('base', WcExpr);
            if (isnumeric(Wc) && isscalar(Wc) && isreal(Wc) && ...
                    isfinite(Wc) && ~isnan(Wc) && Wc>0)
                this.MetaData.Wc = Wc;
            else 
                error(message('Control:systunegui:LoopShapeSpecErrWc'));
            end
        end
                               
        function this = setLoopGain(this, LoopGain)
            % Set the LoopGain property
            LoopGainVal = evalin('base',LoopGain);
            if isnumeric(LoopGainVal)
                % If numeric, set to dc gain
                this.Data.LoopGain = zpk(LoopGainVal);
            else
                this.Data.LoopGain = LoopGainVal;
            end
            this.MetaData.LoopGain = LoopGain;
        end
        
        function this = setStabilize(this, Stabilize)
            % Set the stabilize property. Stabilize can either be true or
            % false
            this.Data.Stabilize = logical(Stabilize);
        end
        
         function this = setLoopScaling(this, LoopScaling)
            % Set the loop scaling property
            % Input 'LoopScaling' is either 'on' or 'off'
            this.Data.LoopScaling = LoopScaling;
         end
    end
end
