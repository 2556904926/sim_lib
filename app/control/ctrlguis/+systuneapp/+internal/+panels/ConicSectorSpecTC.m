classdef (Hidden) ConicSectorSpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Conic Sector tuning goal specifications
    
    % Copyright 2015 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = ConicSectorSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.ConicSectorSpecGC(this);
        end
        
        function this = computeMetaData(this)
            % Call Parent computeMetaData to get Models and ConicSector metadata
            % Revisit
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'Q', this.Data.Q);         
            this.MetaData.Regularization = this.computeDynamicSystemExpr(this.Data.Regularization);
        end
       
        function this = setQ(this, QExpr)
            %Error checking on Q
            QVal = evalin('base',QExpr);
            this.Data.Q = QVal;
            this.MetaData.Q = QExpr;
        end
        
        function this = setRegularization(this, RegExpr)
            %Error checking on Q
            RegVal = evalin('base',RegExpr);
            this.Data.Regularization = RegVal;
            this.MetaData.Regularization = RegExpr;
        end

    end
end
