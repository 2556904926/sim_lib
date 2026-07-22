classdef (Hidden) MarginsSpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Margins tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)      
    end
    
    methods
        function this = MarginsSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.MarginsSpecGC(this);
        end
        
        function this = setGainMargin(this, GainMarginExpr)
            % Set teh GainMargin property
            GainMargin = evalin('base',GainMarginExpr);
            this.Data.GainMargin = GainMargin;
        end
        
        function this = setPhaseMargin(this, PhaseMarginExpr)
            % Set the PhaseMargin property
            PhaseMargin = evalin('base',PhaseMarginExpr);
            this.Data.PhaseMargin = PhaseMargin;
        end    
    
        function this = setScalingOrder(this, ScalingOrderExpr)
            % Set the D-Scaling order property
            ScalingOrder = evalin('base',ScalingOrderExpr);
            this.Data.ScalingOrder = ScalingOrder;
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
