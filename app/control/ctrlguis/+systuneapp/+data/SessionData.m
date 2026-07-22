classdef (Hidden) SessionData
    % Class to manage saved session data of Control System Tuner App.
    
    % Copyright 2013 The MathWorks, Inc.  
    
    properties
        Version
        ControlDesignData
        HomeTab
        SystuneTab
        PlotManager
        LocalVariables % Variables in LocalWorkspace
    end

    methods
        function this = SessionData
            this.Version = 2; 
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

% Version 1: Version, ControlDesignData, SystuneTab, PlotManager
% Version 2: LocalVariables, HomeTab