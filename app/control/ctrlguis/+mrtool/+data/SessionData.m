classdef (Hidden) SessionData
    % Class to manage saved session data of Model Reduction App.
    
    % Copyright 2015 The MathWorks, Inc.  
    
    properties
        Version = 1
        Models
        Tools
        PlotManager
    end

    methods
        function this = SessionData()
        end
    end   
end

% Version 1: Version, Models, Tools, PlotManager