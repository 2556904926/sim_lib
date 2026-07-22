classdef AtomicComponent < handle
    % Abstract base class for atomic tool components.  Atomic tool components can
    % be combined to construct composite tool components.  However, they cannot
    % themselves be composite.

    % Copyright 2024 The MathWorks, Inc.

    % ----------------------------------------------------------------------------
    properties (Access = private)
        % Logical. Set to true upon component initialization.
        Initialized = false;
    end

    % ----------------------------------------------------------------------------
    events
        % Event sent upon component change.  Event data is passed using a
        % ComponentEventData object.
        ComponentChanged
    end

    % ----------------------------------------------------------------------------
    % User-defined methods
    methods (Access = protected)
        function mStart(this)
            % Perform initial setup and one-time-only calculations.  Assign model
            % parameters.
        end

        function mReset(this)
            % Reset all independent variables and current state to their default
            % values.
        end

        function mUpdate(this)
            % Compute next state from current state and independent variables.
        end
    end

    % ----------------------------------------------------------------------------
    % methods
    %   function this = AtomicComponent(varargin)
    %     % Constructor.
    %     %
    %     % Subclasses should call
    %     %   obj = obj@controllib.widget.internal.tc.AtomicComponent( varargin{:} )
    %   end
    % end

    % ----------------------------------------------------------------------------
    % Component state management
    methods (Sealed)
        function setup(this)
            % Configures the component for the first time.
            if ~this.Initialized
                mStart(this);
                mReset(this)
                this.Initialized = true;
            else
                % No effect on initialized components.
                ctrlMsgUtils.warning('Controllib:toolpack:InitializedComponent')
            end
        end

        function this = update(this)
            % Updates the component state and compute outputs.

            % Initialize the component if it has not been initialized before.
            if ~this.Initialized
                setup(this)
            end

            % Update component state.
            mUpdate(this)

            % Notify ComponentChanged event
            notify(this, 'ComponentChanged')
        end
    end
end