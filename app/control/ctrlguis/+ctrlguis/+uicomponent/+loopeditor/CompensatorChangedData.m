classdef CompensatorChangedData < event.EventData
    % Class used to pass compensator data during notify

    %
    % Copyright 2024 The MathWorks, Inc.

    %% Properties
    properties (Dependent,SetAccess=private)
        Compensator zpk
        PreviousCompensator zpk
    end

    properties (Access=private)
        Compensator_I
        PreviousCompensator_I
    end
    
    %% Constructor
    methods
        function this = CompensatorChangedData(Compensator,PreviousCompensator)
            arguments
                Compensator zpk
                PreviousCompensator zpk
            end
            this.Compensator_I = Compensator;
            this.PreviousCompensator_I = PreviousCompensator;
        end
    end    

    %% Get/Set
    methods
        % Compensator
        function Compensator = get.Compensator(this)
            Compensator = this.Compensator_I;
        end

        % PreviousCompensator
        function PreviousCompensator = get.PreviousCompensator(this)
            PreviousCompensator = this.PreviousCompensator_I;
        end
    end
end