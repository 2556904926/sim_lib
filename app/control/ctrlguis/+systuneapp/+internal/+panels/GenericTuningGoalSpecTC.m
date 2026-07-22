classdef (Hidden) GenericTuningGoalSpecTC < controllib.widget.internal.tc.AtomicComponent
    % Generic tool component tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = public, SetObservable)
        Data        % Specification for tuning goals
        MetaData    % To store GUI state
    end
    
    methods
        function this = GenericTuningGoalSpecTC(Data)
            this.Data = Data;
            updateMetaData(this);
        end
    end
    %% Tool-Component API
    methods
        function Value = getValue(this)     
             % Get value stored in TC
             Value.Data = this.Data;
             Value.MetaData = this.MetaData;
        end
        
        function MetaData = getMetaData(this)
            MetaData = this.MetaData;
        end
        
        function this = setFocus(this, FocusExpr)
            % Set the focus
            Focus = evalin('base', FocusExpr);
            if isnumeric(Focus) && isvector(Focus) && numel(Focus) == 2 && ...
                    all(Focus >= 0) && (Focus(2) > Focus(1))
                this.Data.Focus = Focus;
            else
                error(message('Control:tuning:TuningReq7'));
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
        
        function computeMetaData(this, fieldName, fieldValue)
            % Derive MetaData from Data whenever it is empty
            if isnan(this.Data.Models)
                this.MetaData.Models = [1, 2];
            else
                this.MetaData.Models = this.Data.Models;
            end
            this.MetaData.(fieldName) = this.computeDynamicSystemExpr(fieldValue);
        end
    end
    
    methods(Static)
        function expression = computeDynamicSystemExpr(Value)
            % Static function to compute expression given a dynamic system
            if isnumeric(Value)
                expression = mat2str(Value);                
            elseif isa(Value,'lti') && ~isa(Value,'frd')                
                expression = systuneapp.util.createExpressionForZPKModel(Value);                
            elseif isa(Value,'frd')
                [Resp, Freq] = frdata(Value, 'v');
                expression = ['frd(' mat2str(Resp') ',' mat2str(Freq') ')'];
            end
        end
        
    end
end

