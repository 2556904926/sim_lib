classdef ListEventData < event.EventData
    %LISTEVENTDATA Class used to pass event data during notify
    
    % The ListEventData class can be used to pass event data to clients
    % when the event being fired is a list changed event. Any list can be
    % modified through three operations - add, remove, change (or set to a
    % new value). This class lets the user add a type to the list changed
    % event along with the new data (after the change).
    
    properties
        Type        % Add| Remove| ListChanged
        Data        % Data that was changed
    end
    
    methods
        function this = ListEventData(Type, Data)
            % Check number of inputs
            narginchk(1,2);
            
            % Validate Type
            T = lower(Type);
            if strcmpi(T, 'add') ||  strcmpi(T, 'remove')  ||  strcmpi(T, 'change')
                this.Type = Type;
            else
                error(message('Controllib:general:UnexpectedError', ...
                    'Type must be add, remove or change'));
            end
            
            if nargin == 2
                this.Data = Data;
            end
            
        end
    end
    
end

