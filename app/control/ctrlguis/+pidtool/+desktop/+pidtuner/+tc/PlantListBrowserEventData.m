classdef PlantListBrowserEventData < event.EventData
    %PLANTLISTBROWSEREVENTDATA
    
    % Author(s): Baljeet Singh 22-oCT-2014
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        Request
        Variables
    end
    methods
        function data = PlantListBrowserEventData(request,vars)
            %PLANTLISTBROWSEREVENTDATA
            
            data.Request = request;
            data.Variables = vars;
        end
    end
end
