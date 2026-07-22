classdef AbstractArchitecture < handle & matlab.mixin.Copyable
    % Abstract Architecture for Control System Designer
    
    %   Copyright 2014-2017 The MathWorks, Inc.
    
    %% Protected properties
    properties (Access = protected)
        % Name of the configuration
        Name
        % List of TunedBlocks
        TunedBlocks
        % Cached system value
        System
        % Nominal Index
        NominalIndex = 1
        % Time Units
        TimeUnits = 'seconds'
        % LFT
        LFT
        ConfigurationGraph
        % Used to determine if closed loop should be recomputed
        isDirty = true;
        % Format
        Format = 'TimeConstant1'
    end
    
    properties
        % SaveData - needed to decide order of compensator during load
        SaveData
    end
    
    %% Abstract public methods
    methods (Access = public, Abstract = true)
        SavedArchitecture = saveSession_(this);
        loadSession_(this,SavedArchitecture);
        b = isSimulink(this);
        Config = getConfiguration(this)
        CopiedArch = copyArch(this)
    end
    
    %% Abstract protected methods
    methods (Access = protected, Abstract = true)
        % REVISIT should do compute sys = ClosedLoop_(this)
        computeClosedLoop(this);
    end
    
    %% Set method for system
    methods
        function sys = get.System(this)
            if this.isDirty
                computeClosedLoop(this);
                this.isDirty = false;
            end
            sys = this.System;
        end
    end
    %% Public methods
    methods (Access = public)
        
        function Ts = getTs(this)
            % Return Sample Time
            Ts = this.System.Ts;
        end
        
        function Name = getName(this)
            % Returns Architectuers Name
            Name = this.Name;
        end
        
        function sys = genss(this)
            if isa(this.System,'ss')
                sys = genss(this.System);
            else
                sys = this.System;
            end
        end
        
        function sys = getCL(this,Design)
            TB = getTunedBlocks(this);
            sys = this.System;
            if isSimulink(this)
                if isa(sys,'genss')
                    % sys will be empty if there are no tunable blocks,
                    % no analysis points and no openings.
                    if nargin == 2
                        % REVISIT (case where all compensators are not in
                        % designLoop
                        % list
                        S = getValueStructure(Design);
                    else
                        % getCL(this) returns closed loop for current values
                        % getCL(this,Design) returns closed loop
                        
                        S = sys.Blocks;
                        for ct =length(TB):-1:1
                            %                 append(getValue(TB(ct)));
                            S.(getIdentifier(TB(ct))) = getValue(TB(ct));
                            S.(getIdentifier(TB(ct))).Ts = this.System.Ts;
                        end
                    end
                    sys = replaceBlock(sys,S);
                end
                % ReplaceBlock can turn sys into an ss if there are no
                % analysis points and no tunable blocks
                sys = genss(sys);
            else
                Fixed = this.LFT.IC;
                % Tuned = this.LFT.Blocks;
                %                 Tuned = zpk*ones(length(TB),1);
                if nargin == 2
                    Tuned = struct2cell(getValueStructure(Design));
                    Tuned = Tuned(end:-1:1);
                else
                    for ct = 1:1:length(TB)
                        Tuned{ct} = getValue(TB(ct));
                    end
                end
                sys = lft(blkdiag(Tuned{:}),Fixed);
                sys.InputName = this.System.InputName;
                sys.OutputName = this.System.OutputName;
            end

        end
        
        function Idx = getNominalIndex(this)
            % Return Nominal Model Index
            S = size(this.System);
            if ndims(this.System)==2
                this.NominalIndex = 1;
            end
            Idx = this.NominalIndex;
        end
        
        function setNominalIndex(this,Idx)
            % Set Nominal Model Index
            S = size(this.System);
            ns = prod(S(3:end));
            if Idx > 0 && Idx <= ns
                this.NominalIndex = Idx;
            else
                error(message('Controllib:general:UnexpectedError','Index out of range'))
            end
            this.notify('NominalIndexChanged');
        end
        
        function Blocks = getTunedBlocks(this,ID)
            Blocks = this.TunedBlocks;
            if nargin == 2
                idx = [];
                for ct = 1:length(Blocks)
                    if strcmp(ID,getIdentifier(Blocks(ct)))
                        idx =ct;
                        break;
                    end
                end
                if isempty(idx)
                    error(message('Controllib:general:UnexpectedError', ...
                        'No Block with the specified ID found'));
                else
                    Blocks = Blocks(idx);
                end
            end
        end
        
        function Design = exportDesign(this)
            % Store Design
            TB = getTunedBlocks(this);
            for ct = numel(TB):-1:1
                Data.(getIdentifier(TB(ct))) = getValue(TB(ct));
            end
            Design = ctrlguis.csdesignerapp.data.internal.Design(Data);
        end
        
        function importDesign(this,Design)
            DesignData = getValueStructure(Design);
            BlockIDs = fields(DesignData);
            
            if ~isequal(this.getTs,DesignData.(BlockIDs{1}).Ts)
                % apply design only when all tuned blocks have same sample
                % time with the architecture sample time
                DesignSampleTime = mat2str(DesignData.(BlockIDs{1}).Ts);
                if strcmp(DesignSampleTime,'0')
                    DesignSampleTime = getString(message('Control:designerapp:LinearizationOptionsContinuous'));
                end
                if isSimulink(this)
                    errorString = getString(message('Control:designerapp:SimulinkRetrieveDesignSampleTimeMismatch',DesignSampleTime));
                else
                    errorString = getString(message('Control:designerapp:MATLABRetrieveDesignSampleTimeMismatch',DesignSampleTime));
                end
                error(errorString);
%                 uialert(this.UIFigure,errorString,getString(message('Control:designerapp:strToolTitleShort')));
                return;
            end
                        
            for ct = 1:length(BlockIDs)
                try
                    TB = getTunedBlocks(this,BlockIDs{ct});
                    % Update TB value but do not notify
                    setValue(TB,DesignData.(BlockIDs{ct}),true);
                end
            end
            % Throw SystemChanged event. Reduces the number of updates. 
            notify(this,'SystemChanged');
        end
        
        function CG = getConfigurationGraph(this)
            CG = this.ConfigurationGraph;
        end
        
        function setFormat(this,Format)
            this.Format = Format;
            TB = this.getTunedBlocks;
            for ct=1:numel(TB)
                setFormat(TB(ct), Format);
            end
        end
        
                
        function System = convertToSystemWithShortNames(~,System)
            % Default implementation for Matlab architecture
        end
        
        %% LOAD/SAVE
        function S = saveSession(this)
            
            if isempty(this.TunedBlocks)
                TunedBlks = [];
            else
                for ct = 1:numel(this.TunedBlocks)
                    TunedBlks(ct) = saveSession(this.TunedBlocks(ct));
                end
            end
            S = struct(...
                'Name',this.Name,...
                'TunedBlocks', TunedBlks, ...
                'NominalIndex', this.NominalIndex, ...
                'TimeUnits', this.TimeUnits, ...
                'Config', getConfiguration(this));
            % ML/SL specific save
            S = saveSession_(this,S);
        end
        
        function loadSession(this, S)
            this.Name = S.Name;
            this.NominalIndex = S.NominalIndex;
            this.TimeUnits = S.TimeUnits;
            for ct = 1:numel(S.TunedBlocks)
                Idx = ct;
                for ct1 = 1:numel(this.TunedBlocks)
                    TBID = this.TunedBlocks(ct1).getIdentifier;
                    if strcmpi(TBID, S.TunedBlocks(ct).Identifier)
                        Idx = ct1;
                        this.SaveData(ct) = Idx;
                        break;
                    end
                end
                loadSession(this.TunedBlocks(Idx),S.TunedBlocks(ct));
            end
            loadSession_(this,S);
        end
        
        function val = isArchitectureDirty(this)
            val = this.isDirty;
        end
        
        function val = setArchitectureDirty(this,val)
            if islogical(val)
                this.isDirty = val;
                if val
                    notify(this,"MarkedDirty");
                end
            end
        end
    end
    
    
    %%  Protected Methods
    methods (Access = protected)
        function this = AbstractArchitecture()
        end
        
        function TB = createTunableBlock(this,ID,Value,varargin)
            % REVISIT
            if true
                import ctrlguis.csdesignerapp.data.architectures.internal.TunedLTI;
                if isnumeric(Value)
                    Value = ss(Value);
                end
                TB = TunedLTI(ID,Value);
                TB.Name = ID;
                if ~isempty(this.Format)
                    setFormat(TB,this.Format);
                end
                if nargin==4
                    setPath(TB,varargin{1});
                end
                % add listener
                weakThis = matlab.lang.WeakReference(this);
                addlistener(TB,'ValueChanged',@(es,ed) setArchitectureDirty(weakThis.Handle,true));
                addlistener(TB,'GainChanged',@(es,ed) setArchitectureDirty(weakThis.Handle,true));
            else
                TB = sisodata.TunedZPK;
                TB.SSData = ltipack.ssdata;
                tm = sisodata.TunedZPKSnapshot;
                tm.Name = ID;
                tm.Value = Value;
                TB.import(tm);
            end
        end
        
        function [DoesExist, Idx] = findTunedBlock(this, ID)
            DoesExist = false;
            Idx = [];
            for ct = 1:numel(this.TunedBlocks)
                Name = this.TunedBlocks(ct).getIdentifier;
                if strcmpi(Name, ID)
                    DoesExist = true;
                    Idx = ct;
                    break;
                end
            end
        end
    end
    
    %% Hidden QE Methods
    methods (Hidden = true)
        function sys = qeGetSystem(this)
            sys = this.System;
        end
    end
    
    %% Events
    events
        MarkedDirty
        SystemChanged
        NominalIndexChanged
    end
end

