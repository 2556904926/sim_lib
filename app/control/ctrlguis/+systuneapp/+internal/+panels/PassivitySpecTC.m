classdef (Hidden) PassivitySpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Passivity tuning goal specifications
    
    % Copyright 2015 The MathWorks, Inc.
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = PassivitySpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.PassivitySpecGC(this);
        end
        
        function this = computeMetaData(this)
            % Call Parent computeMetaData to get Models and Passivity metadata
            % Revisit
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'IFP', this.Data.IFP);
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'OFP', this.Data.OFP);           

        end
       
        function this = setIFP(this, IFPExpr)
            %Error checking on IFP
            IFPVal = evalin('base',IFPExpr);
            this.Data.IFP = IFPVal;
            this.MetaData.IFP = IFPExpr;
        end
        
        function this = setOFP(this, OFPExpr)
            %Error checking on OFP
            OFPVal = evalin('base',OFPExpr);
            this.Data.OFP = OFPVal;
            this.MetaData.OFP = OFPExpr;
        end

    end
end
