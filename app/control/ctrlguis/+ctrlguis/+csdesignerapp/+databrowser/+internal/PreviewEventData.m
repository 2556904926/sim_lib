classdef PreviewEventData < matlab.ui.eventdata.internal.AbstractEventData
    %% Event data generated from CSD data browser for preview panel.
    %
    %  Event data for CSD app includes selected data index and additional
    %  event names that need to be listened for monitoring additional
    %  changes while selected for preview.
    
    %  Copyright 2020 The MathWorks, Inc.
    
    %% Properties
    properties(SetAccess=private)
        %% Index of the selected data browser item.
        %  Index is used by "getData" and "getName" to locate information.
        Index
        
        %% External event names that may change the selected item.
        %  ExternalEvents specifies event names that may externally change
        %  the selected data browser item. Hence, these events are listened
        %  to monitor the changes and update the preview panel accordingly.
        ExternalEvents
    end
    
    %% Constructor    
    methods
        function obj = PreviewEventData(index,externalEvents)
            obj = obj@matlab.ui.eventdata.internal.AbstractEventData();
            obj.Index = index;
            obj.ExternalEvents = externalEvents;
        end        
    end
    
end