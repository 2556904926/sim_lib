classdef (Hidden) WeightedVarianceSpecTC <  controllib.widget.internal.tc.AtomicComponent
    % Tool component for Wighted Variance tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for Weighted Variance
        MetaData    % To store GUI state
    end
    
    
    methods
        function this = WeightedVarianceSpecTC(Data)
            % Construct with specifications given as input
            this.Data = Data;
            % Compute default GUI state
            updateMetaData(this);
        end
    end
    %% Tool-Component API
    methods     
         function Value = getValue(this)
             %Get value stored in TC
             Value.Data = this.Data;
             Value.MetaData = this.MetaData;
         end
  
         function MetaData = getMetaData(this)
             % Get the MetaData
             MetaData = this.MetaData;
         end
        
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.WeightedVarianceSpecGC(this);
        end
        
        function updateMetaData(this)
            % UpdateMetaData will be called in two cases:
            % 1. When the tuning goal specification panel is constructed.
            % 2. If the tuning goal changes outside the dialog, but the
            % dialog is live
            if isempty(this.Data.TuningGoalWrapper.MetaData)
                computeMetaData(this);
            else
                this.MetaData = this.Data.TuningGoalWrapper.MetaData;
            end
        end
        
        function this = computeMetaData(this)
            % Derive MetaData from Data whenever it is empty
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
            
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
                this.MetaData.WR = ['zpk([' num2str(WRZPK.z{:}) '],[' num2str(WRZPK.p{:}) '],[' num2str(WRZPK.k(:)) '])'];
            elseif isa(this.Data.WR,'frd')
                
                [Resp, Freq] = frdata(this.Data.WR, 'v');
                this.MetaData.WR = ['frd([' num2str(Resp') '],[' num2str(Freq') '])'];
            end
        end

        function this = setW(this, WExpr, LorR)
            % Set WL or WR properties
            WLVal = evalin('base',WExpr);
            if LorR == 'L'
                this.Data.WL = WLVal;
                this.MetaData.WL = WExpr;
            elseif LorR == 'R'
                this.Data.WR = WLVal;
                this.MetaData.WR = WExpr;
            end
        end
        
        function setModels(this, ModelsExpr)
            % Set the models property
            Models = evalin('base', ModelsExpr);
            this.Data.Models = Models;
            if ~isnan(this.Data.Models)
                % update MetaData only if Models is not NaN
                this.MetaData.Models = Models;
            end
        end
    end
end
