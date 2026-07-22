classdef PlantsEventData < event.EventData
    %PLANTSEVENTDATA
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        Added
        RemovedAt
        RenamedAt
    end
    methods
        function data = PlantsEventData(added, removedat, renamedat)
            %PLANTSEVENTDATA
            
            data.Added = added;
            data.RemovedAt = removedat;
            data.RenamedAt = renamedat;
        end
    end
end
