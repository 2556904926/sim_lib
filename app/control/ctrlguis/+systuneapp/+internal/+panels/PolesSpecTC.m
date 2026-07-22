classdef (Hidden) PolesSpecTC < systuneapp.internal.panels.StableControllerSpecTC
    % Tool component for Stable Controller tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = PolesSpecTC(Data) 
            % Call parent constructor
            this = this@systuneapp.internal.panels.StableControllerSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.PolesSpecGC(this);
        end

        function Value = getValue(this)
            % Get value stored in TC
            Value.Data = this.Data;
            Value.MetaData= this.MetaData;
        end
        
        function Value = getMetaData(this)
            % Get MetaData
            Value = this.MetaData;
        end
        
        function this = setMinDamping(this, MinDampingExpr)
            % Set the MinDamping property
            MinDamping = evalin('base', MinDampingExpr);
            this.Data.MinDamping = MinDamping;
        end
        
        function this = setFocus(this, FocusExpr)
            % Set the focus
            Focus = evalin('base', FocusExpr);
            this.Data.Focus = Focus;
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
        
        function computeMetaData(this)
            % Derive MetaData from Data whenever it is empty
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
        end
    end
    
end
