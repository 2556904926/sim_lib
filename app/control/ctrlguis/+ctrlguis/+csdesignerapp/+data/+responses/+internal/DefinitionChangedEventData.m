classdef DefinitionChangedEventData < event.EventData
    %DefinitionChangedEventData Class used to pass event data during notify
    
    % The DefinitionChangedEventData class can be used to pass event data
    % to clients when the event being fired is a list changed event.
    
    properties
        Type        % Name | Response
    end
    
    methods
        function this = DefinitionChangedEventData(Type)
            % Check number of inputs
            narginchk(1,2);
            
            % Validate Type
            if strcmp(Type, 'Name') ||  strcmp(Type, 'Response') 
                this.Type = Type;
            else
                error(message('Controllib:general:UnexpectedError', ...
                    'Type must be Name or Response'));
            end
        end
    end
    
end

