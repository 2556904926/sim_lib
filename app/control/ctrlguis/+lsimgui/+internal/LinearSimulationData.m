classdef LinearSimulationData < matlab.mixin.SetGet
    % Data class for Linear Simulation Tool
    
    % Copyright 2020 The MathWorks, Inc.
    properties (SetObservable,AbortSet)
        StartTime = 0
        Interval = 0
        SimulationSamples = []
        TableData = {}
        MinimumSignalInterval = []
        Systems = lsimgui.utils.internal.createEmptySystemSpecification()
        InitialStates = 0
        Interpolation = 'zoh';
    end
    
    properties (Dependent,SetObservable,AbortSet)
        NumberOfSystems
        NumberOfInputs
        ChannelNames
        TimeVector
        InputSignals
    end
    
    properties (Access = private)
        ChannelNames_I = {''}
        InputSignals_I = lsimgui.utils.internal.createEmptySignal()
    end
    
    events
        InputSignalsSynced
    end
    
    methods (Access = public)
        function this = LinearSimulationData(nInputs)
             arguments
                nInputs = 1;
            end
            this.NumberOfInputs = nInputs;
        end
        
        function resetSignal(this,idx)
            arguments
                this
                idx = 1:length(this.InputSignals)
            end
            signals = repmat(lsimgui.utils.internal.createEmptySignal(),1,length(idx));
            updateInputSignals(this,signals,idx);
        end
    end
    
    methods
        % InputSignals
        function InputSignals = get.InputSignals(this)
            InputSignals = this.InputSignals_I;
        end
        
        function set.InputSignals(this,InputSignals)
            this.InputSignals_I = InputSignals;
        end
        
        % NumberOfInputs
        function NumberOfInputs = get.NumberOfInputs(this)
            NumberOfInputs = length(this.InputSignals);
        end
        
        function set.NumberOfInputs(this,NumberOfInputs)
            n = length(this.InputSignals);
            if n > NumberOfInputs
                % remove inputs
                this.ChannelNames_I = this.ChannelNames_I(1:NumberOfInputs);
                this.InputSignals = this.InputSignals(1:NumberOfInputs);
            else
                % add inputs
                this.ChannelNames_I = [this.ChannelNames_I,repmat({''},1,NumberOfInputs - n)];
                this.InputSignals = ...
                    [this.InputSignals,repmat(lsimgui.utils.internal.createEmptySignal(),...
                            1,NumberOfInputs - n)];
            end
        end
        
        % NumberOfSystems
        function NumberOfSystems = get.NumberOfSystems(this)
            NumberOfSystems = length(this.Systems);
        end
        
        function set.NumberOfSystems(this,NumberOfSystems)
            n = length(this.Systems);
            if n > NumberOfSystems
                % remove systems
                this.Systems = this.Systems(1:NumberOfSystems);
            else
                % add inputs
                this.Systems = [this.Systems,...
                    repmat(lsimgui.utils.internal.createEmptySystemSpecification(),...
                    1,NumberOfSystems - n)];
            end
        end
        
        % ChannelNames
        function ChannelNames = get.ChannelNames(this)
            ChannelNames = this.ChannelNames_I;
        end
        
        function set.ChannelNames(this,ChannelNames)
            arguments
                this
                ChannelNames cell
            end
            this.ChannelNames_I = ChannelNames;
            this.NumberOfInputs = length(ChannelNames);
        end
        
        % TimeVector
        function TimeVector = get.TimeVector(this)
            TimeVector = this.StartTime + (0:this.SimulationSamples-1)*this.Interval;
        end
        
        function set.TimeVector(this,TimeVector)
            arguments
                this
                TimeVector (1,:) {mustBeNonnegative,mustBeFinite,mustBeNonempty,mustBeNumeric}
            end
            allIntervals = TimeVector(2:end)-TimeVector(1:end-1);
            interval = max(allIntervals);
            tolerance = 10000*eps;
            if interval-min(allIntervals)<tolerance && interval>0
                n = -floor(log10(tolerance));
                this.StartTime = round(TimeVector(1),n);
                this.Interval = round(interval,n);
                this.SimulationSamples = length(TimeVector);
            else
                throw(MException('Control:lsimgui:InvalidTimeVector',...
                    getString(message('Controllib:gui:errTimeVectorRequirement1'))));
            end
        end
        
        % Update Signals
        function updateInputSignals(this,signals,idx)
            if nargin < 3
                idx = 1:this.NumberOfInputs;
            end
            this.InputSignals(idx) = signals;
            allIntervals = [this.InputSignals.Interval];
            this.MinimumSignalInterval = min(allIntervals(2:2:end) - allIntervals(1:2:end)) + 1;
        end
        
        % Sync Signals
        function syncInputSignals(this)
            for k=1:length(this.InputSignals)
                % Don't modify empty rows
                if length(this.InputSignals(k).Interval)>=2
                    this.InputSignals(k).Interval = [this.InputSignals(k).Interval(1), ...
                        this.InputSignals(k).Interval(1)+this.MinimumSignalInterval-1];
                end
            end
            this.SimulationSamples = this.MinimumSignalInterval;
            notify(this,'InputSignalsSynced');
        end
    end
end



