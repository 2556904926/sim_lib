classdef (Sealed) CustomSettings < handle
    % Maintain settings and feature flags for Control System Designer

    % Copyright 2020-2021 The MathWorks, Inc.

    properties
        UseDocumentTiling logical = true
    end

    methods (Access = private)
        function obj = CustomSettings
        end
    end
    
    methods (Static)
        function singleObj = getInstance
            mlock
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = ctrlguis.csdesignerapp.utils.internal.CustomSettings;
            end
            singleObj = localObj;
        end

        % UseDocumentTiling
        function Value = getUseDocumentTiling
            obj = ctrlguis.csdesignerapp.utils.internal.CustomSettings.getInstance;
            Value = obj.UseDocumentTiling;
        end

        function setUseDocumentTiling(Value)
            obj = ctrlguis.csdesignerapp.utils.internal.CustomSettings.getInstance;
            obj.UseDocumentTiling = Value;
        end
    end
end

