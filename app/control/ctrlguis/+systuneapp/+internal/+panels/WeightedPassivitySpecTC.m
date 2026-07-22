classdef (Hidden) WeightedPassivitySpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Wighted Gain tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = WeightedPassivitySpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods            
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.WeightedPassivitySpecGC(this);
        end

        function this = computeMetaData(this)
            
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'IFP', this.Data.IFP);
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'OFP', this.Data.OFP);    
            % Derive MetaData from Data whenever it is empty
            if isnumeric(this.Data.WL)
                this.MetaData.WL = mat2str(this.Data.WL);
            
            elseif isa(this.Data.WL,'lti') && ~isa(this.Data.WL,'frd')
                
                WLZPK = zpk(this.Data.WL);
                this.MetaData.WL = ['zpk([' num2str(WLZPK.z{:}) '],[' num2str(WLZPK.p{:}) '],[' num2str(WLZPK.k(:)) '])'];
            elseif isa(this.Data.WL,'frd')
                
                [Resp, Freq] = frdata(this.Data.WL, 'v');
                this.MetaData.WL = ['frd([' num2str(Resp') '],[' num2str(Freq') '])'];
            end
            
            if isnumeric(this.Data.WR)
                this.MetaData.WR = mat2str(this.Data.WR);
            
            elseif isa(this.Data.WR,'lti') && ~isa(this.Data.WR,'frd')
                
                WRZPK = zpk(this.Data.WR);
                this.MetaData.WR = ['zpk([' num2str(WRZPK.z{:}) '],[' num2str(WRZPK.p{:}) '],[' num2str(WRZPK.k(:)') '])'];
            elseif isa(this.Data.WR,'frd')
                
                [Resp, Freq] = frdata(this.Data.WR, 'v');
                this.MetaData.WR = ['frd([' num2str(Resp') '],[' num2str(Freq') '])'];
            end
            
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
        end

        function this = setW(this, WExpr, LorR)
            % Set WL and WR
            WVal = evalin('base',WExpr);
            if LorR == 'L'
                this.Data.WL = WVal;
                this.MetaData.WL = WExpr;
            elseif LorR == 'R'
                this.Data.WR = WVal;
                this.MetaData.WR = WExpr;
            end
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
