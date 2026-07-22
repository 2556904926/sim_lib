classdef GraphicalEditorData < handle
    % Class to manage the data needed for graphical editors.
    
    % Copyright 2014 The MathWorks, Inc..
    
    properties (Access = protected)
        % Handle to the response being tuned
        Response        
        
        % Listener to react to any change in Reponse, EditedBlock,
        % GainTargetBlock
        DataListeners
        
    end
    
    properties (Access = public)
        % Block being edited - to which Poles and Zeros are added
        EditedBlock          % Accessed by widgets to add appropriate listeners during drag
                             % Accessed by Graphical Editor's menu
                            
        % Block who's gain is being modified
        % Note: We cache the gain target block when the user asks for it.
        % However, we comput the normalized system with respect to the gain
        % target block only when the gain is moved for the first time. That
        % way, if the gain target block changes multiple times without
        % modifying the gain, computations are nto repeated. Gain target
        % block gets assigned to EditedBlock when the gain is modified. 
        GainTargetBlock      % Accessed by the widgets to add appropriate listeners during drag
                             % Accessed by Graphical Editor's menu
                            
        % Check if data is uncertain
        isUncertain = false; % Accessed by graphical editor during update
        
        % Struct containing response of uncertain models
        UncertainData        % Accessed by graphical editor during update
        
        % Sample time of block being tuned
        Ts                   % Accessed by the widgets
        
        % Singular loop
        SingularLoop
        
        % Is the gain tunable
        GainTunable
        
                
        % Cache value for performance
        FixedZeros
        FixedPoles
        
        AddPZCompensator
    end
    
    methods (Access = public)
        % Public API
        function this = GraphicalEditorData(Response, varargin)
            % Set the response
            setResponse(this, Response);
            
            % Set the compensator
            initializeCompensatorTarget(this);
            
            
            % Add listener to change in response
            addDataListeners(this);
        end
        
        function Name = getName(this)
            % For Figure title
            Name = getName(this.Response);
        end
        
        function computeFixedPZ(this)
            %getFixedPZ  Get poles and zeros from the calculated open-loop that are not
            % graphically tunable. These are the poles of the TunedLFT of the
            % TunedLoop which can be computed and the fixed poles of the TunedFactors.
            [FixedZeros, FixedPoles] = getFixedPZ(this.Response);
            
            this.FixedZeros = FixedZeros;
            this.FixedPoles = FixedPoles;
       end
        
        
        function [FixedZeros,FixedPoles] = getFixedPZ(this)
            FixedZeros = this.FixedZeros;
            FixedPoles = this.FixedPoles;
        end
        
        function setGain(this, Gain, flag)
            % Accessed by ResponseView Widget during drag
            if nargin == 2
                this.EditedBlock.setZPKGain(Gain);
            else
                this.EditedBlock.setZPKGain(Gain,flag);
            end
        end
        
        function Gain = getGain(this)
            Gain = getZPKGain(this.EditedBlock,'mag');
        end
        
        function Format = getFormat(this)
            Format = getFormat(this.EditedBlock);
            Format = lower(Format(1));
        end
        
                
        function OL = getOpenLoop(this, idx)
            if nargin == 1
                OL = getOpenLoop(this.Response, this.EditedBlock);
            else
                OL = getOpenLoop(this.Response, this.EditedBlock,idx);
            end
        end
        
        
        function enableDataListeners(this, bool)
            for ct = 1:numel(this.DataListeners)
                this.DataListeners(ct).Enabled = bool;
            end
        end
        
        function ValidC = getValidCompensators(this,GroupType,PZType)
            % Return list of compensators to which poles and zeros can be
            % added
            
            Compensators = getTunedFactors(this.Response);
            
            % Find valid TunedFactors which can pzgroup can be added
            ValidC = [];
            for ct = 1:length(Compensators)
                if Compensators(ct).isTunable && Compensators(ct).isAddpzAllowed(GroupType,PZType);
                    ValidC = [ValidC; Compensators(ct)]; %#ok<AGROW>
                end
            end
        end
        
        function ValidC = getValidGainTargets(this)
            ValidC = [];
            % Find list of valid gain targets
            C = getTunedFactors(this.Response);
            for ct = 1:length(C)
                if C(ct).utIsGainTunable;
                    ValidC = [ValidC; C(ct)]; %#ok<AGROW>
                end
            end
        end
        function updateMultiModelFrequency(this,ed)
        end
        
                
        function initializeCompensatorTarget(this)
            % Set compeanstor during construction - does additional checks
            % like determining whether the compensator is in series
            Compensators = getTunedFactors(this.Response);
            DefaultTarget = ctrlguis.csdesignerapp.data.architectures.internal.TunedLTI('Default',zpk(1));
            
            % If there are no compensators in series
            if isempty(Compensators)
                this.EditedBlock = DefaultTarget;
                this.GainTargetBlock = [];
                this.GainTunable = false;
            else
                ValidIdx = [];
                for ct = 1:numel(Compensators)
                    if Compensators(ct).isTunable
                        if ~isfield(Compensators(ct).Constraints,'isStaticGainTunable') || ...
                                Compensators(ct).Constraints.isStaticGainTunable
                            ValidIdx = [ValidIdx; ct];
                        end
                    end
                end
                
                if isempty(ValidIdx)
                    % If there is one compensator in series, and it has constraints
                    this.EditedBlock = DefaultTarget;
                    this.GainTargetBlock = [];
                    this.GainTunable = false;
                else
                    % Keep current setting if valid else take first valid tunedfactor
                    if isempty(this.GainTargetBlock)
                        idx = [];
                    else
                        idx = find(this.GainTargetBlock==Compensators);
                    end
                    if isempty(idx)
                        Target = Compensators(ValidIdx(1));
                    else
                        Target = Compensators(idx);
                    end
                    this.EditedBlock = Target;
                    this.GainTargetBlock = Target;
                    this.GainTunable = true;
                end
            end
        end
    end
    
    methods (Access = private)
        % Making setResponse and setCompensator private means that we will
        % not be able to re-target the listener to something new once it is
        % constructed.
        
        function setResponse(this, Response)
            if issiso(Response)
                this.Response = Response;
                this.Ts = getTs(this.Response);
            else
                return;
                % Revisit: Error out if response cannot be set
            end
            
        end
        
        function addDataListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            this.DataListeners = [];
            this.DataListeners = [this.DataListeners; ...
                                    addlistener(this.Response,'ValueChanged',@(es,ed)fireDataChanged(weakThis.Handle))];
        end
        
        function fireDataChanged(this)
            this.notify('DataChanged');
        end
    end
    
    methods (Hidden = true)
        % Needed by response optimization
        function R = getResponse(this)
            R = this.Response;
            
        end
    end
    events
        DataChanged
    end
end