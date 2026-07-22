classdef AddPlotEventData < event.EventData
    %ADDPLOTEVENTDATA
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        PlotType
        ResponseType
    end
    methods
        function data = AddPlotEventData(plottype, resptype)
            %ADDPLOTEVENTDATA
            
            data.PlotType = plottype;
            data.ResponseType = resptype;
        end
    end
end
