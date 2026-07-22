classdef CompensatorChangingData < event.EventData
    % Class used to pass compensator data during notify

    %
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess=private)
        Compensator zpk
    end

    properties (Access=private)
        Compensator_I
    end
    
    %% Constructor
    methods
        function this = CompensatorChangingData(Compensator)
            arguments
                Compensator zpk
            end
            this.Compensator_I = Compensator;
        end
    end    

    %% Get/Set
    methods
        % Compensator
        function Compensator = get.Compensator(this)
            Compensator = this.Compensator_I;
        end
    end
end