classdef SessionData
    % Class to manage saved session data of Control System Designer App.
    
    % Copyright 2015 The MathWorks, Inc.  
    
    properties
        Version
        DesignerData
        ToolsManager
        PlotsManager
        LocalVariables % Variables in LocalWorkspace
        Preferences
    end

    methods
        function this = SessionData
            this.Version = 1; 
        end
        function bool = isfield(this,FieldNameCellArraysOrString)
            Props = cell(properties(this));
            if ischar(FieldNameCellArraysOrString)
                bool = ~isempty(intersect(Props,FieldNameCellArraysOrString));
            else % it is cell array
                bool = cellfun(@(x) ~isempty(intersect(Props,x)),FieldNameCellArraysOrString);
            end
        end
    end   
end

% Version 1: Version, ControlDesignData, PlotManager
% Version 2: LocalVariables, HomeTab