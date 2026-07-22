classdef (Hidden) Response < handle & matlab.mixin.Copyable
    % Response  Manages data associated with a response

    % Copyright 2014-2023 The MathWorks, Inc.

    properties (Access = private)
        ResponseDefinition  % Response definition
        Architecture        % Architecture to compute data from
        Identifier          % Unique identifier needed for optimization
        HasFRD              % Cache if system is frd
        HasDelay            % Cache if system has delays
    end

    properties (Access = private, Transient)
        Value              % Cached value of response
        DirtyFlag = true;  % True when dependent data is out of date
        TunedBlockListeners % Listners to Tuned block value changes
        ArchitectureListeners

        % Tuned Response Data
        IC
        TunedFactors
        TunedBlocks
        Nominal

        % Cached Data
        TunedLFT_ZPKData
        TunedLFT_FRDData
        TunedLFT_SSData
        ModelData
        Margins
        InputLabels
        OutputLabels
    end

    properties (Access = public, Hidden, Transient)
        EditHandles = [];  % Handle to editor
    end
    methods (Access = public)
        function this = Response(RespDefinition,Arch,ID)
            % Construct Response Object
            % Resp = Response(RespDefinition,Arch)
            % Resp = Response(RespDefinition,Arch, ID)
            % RespDefinition - Defines IOs of response: ResponseConfiguration
            % Architecture - Defines the architecture of system: AbstractArchitecture
            % ID - uses specified ID otherwise will create one
            if nargin > 0
                this.Architecture = Arch;
                setDefinition(this,RespDefinition)
                setArchitecture(this, Arch)
            end

            if nargin < 3
                % Initialize with a unique id - cannot be changed later - used by SDO
                this.Identifier = sprintf('R%d', localGetID);
            else
                this.Identifier = ID;
            end


        end

        function delete(this)
            delete(this.TunedBlockListeners)
            if ~isempty(this.EditHandles)
                delete(this.EditHandles);
                this.EditHandles = [];
            end
        end

        function Name = getName(this)
            % Returns name of the response as a string
            % If the input argument is a array then it returns the names as
            % a cell array
            Name = cell(numel(this),1);
            for ct = 1:numel(this)
                % Return name of Tuned Block
                Name{ct,1} = this(ct).ResponseDefinition.Name;
            end
            if numel(this) == 1
                Name = Name{1,:};
            end
        end

        function setName(this,NewName)
            % Sets the name of the response
            import ctrlguis.csdesignerapp.data.responses.internal.DefinitionChangedEventData;
            this.ResponseDefinition.Name = NewName;
            notify(this,'DefinitionChanged',DefinitionChangedEventData('Name'));
            this.DirtyFlag = true;
        end

        function Identifier = getIdentifier(this)
            Identifier = cell(numel(this),1);
            for ct = 1:numel(this)
                % Return name of Tuned Block
                Identifier{ct,1} = this(ct).Identifier;
            end
            if numel(this) == 1
                Identifier = Identifier{1,:};
            end
        end

        function setDirty(this,Flag,varargin)
            % Set dirty flag and send ValueChanged event if dirty
            this.DirtyFlag = Flag;
            reset(this,'all')
            if Flag
                notify(this,'ValueChanged');
            end
        end

        function Flag = isDirty(this)
            Flag = this.DirtyFlag;
        end

        function setArchitecture(this, Arch)
            % Set Architecture of response and sets the listeners for
            % architecture changes
            import ctrlguis.csdesignerapp.data.responses.internal.DefinitionChangedEventData;

            validateattributes(Arch,{'ctrlguis.csdesignerapp.data.architectures.internal.AbstractArchitecture'},{});
            this.Architecture = Arch;
            updateTunedResponseData(this)
            addArchitectureListeners(this)
            notify(this,'DefinitionChanged',DefinitionChangedEventData('Response'));
            this.DirtyFlag = true;
        end

        function setDefinition(this,RespDef)
            % Sets the response definition and notifies clients that it has
            % changed.
            import ctrlguis.csdesignerapp.data.responses.internal.DefinitionChangedEventData;

            validateattributes(RespDef,{'ctrlguis.csdesignerapp.data.responses.internal.ResponseConfiguration'},{});
            this.ResponseDefinition = RespDef;
            if ~isempty(this.Architecture)
                updateTunedResponseData(this)
            end
            % Set Dirty
            this.DirtyFlag = true;
            notify(this,'DefinitionChanged',DefinitionChangedEventData('Response'))
        end

        function RespDef = getDefinition(this)
            % Returns the response definition
            RespDef = this.ResponseDefinition;
        end

        function hText = getDisplayPreviewText(this)
            % Returns text for preview
            hText = getDisplayPreviewText(this.ResponseDefinition);
        end

        function [b,nsys] = isUncertain(this)
            % Checks if the TunedResponseData is uncertain (e.g. an array)
            nsys = numel(this.IC);
            b = nsys>1;
        end

        function b = issiso(this)
            % Vectorized Returns true if SISO
            b = false(size(this));
            for ct = 1:length(this)
                b(ct) = isequal(getIOSize(this(ct)),[1,1]);
            end
        end

        function b = isLoopTransfer(this)
            % Vectorized
            b = false(size(this));
            for ct = 1:length(this)
                b(ct) = isa(this(ct).ResponseDefinition,...
                    'ctrlguis.csdesignerapp.data.responses.internal.LoopTransfer');
            end
        end

        function Margins = getMargins(this)
            %             if isempty(this.Margins)
            % Compute margins
            % RE: Units are: GM(absolute)  Pm(degree)  Wcg,Wcp(radians/sec)
            sw = warning('off','Control:transformation:StateSpaceScaling'); [lw,lwid] = lastwarn;
            [Gm,Pm,junk,Wcg,Wcp,isStable] = utGetMinMargins(allmargin(getOpenLoop(this)));
            warning(sw); lastwarn(lw,lwid);

            % Build and store result
            this.Margins = struct('Gm',Gm,'Pm',Pm,'Wcg',Wcg,'Wcp',Wcp,'Stable',isStable);
            %             end

            Margins = this.Margins;
        end

        function D = getOpenLoop(this,C,idxM)
            %getOpenLoop Computes normalized open-loop @zpkdata, @ssdata, or @frdmodel model
            % This function is used by the graphical editors to compute the open loop
            % displayed.
            % Note: The Open-Loop is defined as positive feedback because the loop is
            % defined by cutting a signal(i.e. all signs are lumped in the effective
            % plant). However because most users are used to designing with negative
            % feedback on such plots as root locus this function pulls out a negative
            % sign so that plots are presented as negative feedback.
            % For Closed-Loop we do not use negative

            if nargin < 3
                idxM = getNominalIndex(this.Architecture);
            end
            % Series portion of TunedLoop
            TunedFactors = this.TunedFactors;

            if nargin > 1 && ~isempty(C)
                idx = find(C == TunedFactors);
            else
                idx = 0;
            end

            % LFT portion of TunedLoop

            D = getTunedLFT(this,[],idxM);
            if ~isempty(TunedFactors) && all(isvalid(TunedFactors))
                if hasFRD(this)
                    for ct = 1:length(TunedFactors)
                        if ct == idx
                            D = D * frd(getZPKData(TunedFactors(ct),'normalized'),D.Frequency);
                        else
                            D = D * frd(getZPKData(TunedFactors(ct)),D.Frequency);
                        end
                    end
                else
                    for ct = 1:length(TunedFactors)
                        if ct == idx
                            % REVISIT (cast to SS and ZPK)
                            D = D * getSSData(TunedFactors(ct),'normalized');
                        else
                            D = D * getSSData(TunedFactors(ct));
                        end
                    end
                end
            end

            % Treat loop as negative feedback for presentation purposes if
            % its a loop transfer
            if isLoopTransfer(this)
                D = -D;
            end

        end

        function P = getOpenLoopPlant(this,C,idxM)
            % Revisit Check if is LoopTransfer?
            if nargin == 2
                idxM = getNominalIndex(this.Architecture);
            end

            if isLoopTransfer(this)
                % LFT portion of TunedLoop includes compensators
                % that do not appear in series in the loop
                P = getTunedLFT(this,[],idxM);

                % Compensators that appear in series with the open-loop
                TunedFactors = this.TunedFactors;

                isfrd =  isa(P,'ltipack.frddata');

                % Incorporate compensators that appear in series in the loop
                % except that specified by C
                for ct = 1:length(TunedFactors)
                    if ~isequal(C,TunedFactors(ct))
                        if isfrd
                            P = P * frd(getZPKData(TunedFactors(ct)),P.Frequency);
                        else
                            P = P * getSSData(TunedFactors(ct));
                        end
                    end
                end

            else
                ctrlMsgUtils.error('Control:compDesignTask:utFactorizeLoop')
            end
        end

        function [TunedZeros, TunedPoles] = getTunedPZ(this)
            % Get list of tunable poles and zeros
            TunedZeros = zeros(0,1);
            TunedPoles = zeros(0,1);
            TunedFactors = this.TunedFactors;
            for ct = 1:length(TunedFactors)
                [Z,P] = getPZ(TunedFactors(ct),'Tuned');
                TunedZeros = [TunedZeros ; Z];
                TunedPoles = [TunedPoles ; P];
            end
        end

        function [FixedZeros, FixedPoles] = getFixedPZ(this,idx)
            if nargin == 1
                % Return Nominal value if no idx is specified
                idx = getNominalIndex(this.Architecture);
            end
            FixedZeros = zeros(0,1);
            FixedPoles = zeros(0,1);

            % Append poles and zeros for the fixed part of TunedFactors (series blocks)
            TunedFactors = this.TunedFactors;
            for ct = 1:length(TunedFactors)
                FixedDynamics = TunedFactors(ct).FixedDynamics;
                if ~isempty(FixedDynamics)
                    FixedZeros = [FixedZeros; FixedDynamics.z{1}]; %#ok<AGROW>
                    FixedPoles = [FixedPoles; FixedDynamics.p{1}]; %#ok<AGROW>
                end
            end

            if ~hasDelay(this) && ~hasFRD(this)
                % Only get TunedLFT poles/zeros if they can be computed
                % Append poles and zeros for the TunedLFT
                G = this.getTunedLFT('zpk',idx);

                FixedZeros = [FixedZeros; G.z{1}];
                FixedPoles = [FixedPoles; G.p{1}];
            end

        end

        function [ny,nu] = getIOSize(this)
            % REVISIT: should this be optimized? (e.g. when value changes
            % but not structure
            S = iosize(getValue(this));
            if nargout == 2
                ny = S(1);
                nu = S(2);
            else
                ny = S;
            end
        end

        function [NomValue, Value] = getValue(this,Design)
           P = this.IC;
           DataModel = createArray([length(P) 1],class(P));
           if nargin > 1
              for ct = 1:length(P)
                 DataModel(ct,1) =  getOpenLoopForDesign(this,Design,ct);
              end
           else
              for ct = 1:length(P)
                 DataModel(ct,1) =  getOpenLoop(this,[],ct);
              end
           end
           if isempty(this.Value)
              if isa(P,'ltipack.frddata')
                 Value = frd.make(DataModel);
              else
                 Value = ss.make(DataModel);
              end
              set(Value,'InputName',this.InputLabels,...
                 'OutputName',this.OutputLabels);
              this.Value = Value;
           else
              Value = setPrivateData(this.Value,DataModel);
           end

           Value = convertToSystemWithShortNames(this.Architecture, Value);
           NomValue = Value(:,:,getNominalIndex(this.Architecture));

        end

        function nominalIndex = getNominalIndex(this)
            if ~isempty(this.Architecture) && isvalid(this.Architecture)
                nominalIndex = getNominalIndex(this.Architecture);
            end
        end

        function NomValue = getModel(this)
            % Get model method for response optimization
            NomValue = getValue(this);
            if isLoopTransfer(this)
                NomValue = -NomValue;
            end
        end

        function Ts = getTs(this)
            Ts = this.IC(1).Ts;
        end


        function C = getTunedFactors(this)
            C = this.TunedFactors;
        end

        function D = getTunedLFT(this,flag,idx)
            %getTunedLFT Used to update the cache of the TunedLFT
            %
            % D = getTunedLFT(this) returns the ssdata of the TunedLFT
            % D = getTunedLFT(this,'zpk') returns the zpkdata of the TunedLoop

            if nargin < 3
                idx = getNominalIndex(this.Architecture);
            end

            if (nargin == 2) && (hasDelay(this) || hasFRD(this))
                ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
                    'The Poles and Zeros can not be computed for time-delay or frequency response data systems.')
            end

            if hasFRD(this)
                % Compute FRD Data
                if isempty(this.TunedLFT_FRDData{idx})
                    % Need to recompute
                    Blocks = this.TunedBlocks;
                    if isempty(Blocks)
                        D = this.IC(idx);
                    else
                        freqs = this.IC(idx).Frequency;
                        for ct=length(Blocks):-1:1
                            C(ct,1) = frd(getZPKData(Blocks(ct)),freqs);
                        end
                        D = utSISOLFT(this.IC(idx),C);
                    end
                    this.TunedLFT_FRDData{idx} = D;
                end
                D = this.TunedLFT_FRDData{idx};
            else
                SSData = this.TunedLFT_SSData{idx};
                if isempty(SSData)
                    % Need to recompute
                    Blocks = this.TunedBlocks;
                    if isempty(Blocks)
                        SSData = this.IC(idx);
                    else
                        for ct=length(Blocks):-1:1
                            C(ct,1) = getSSData(Blocks(ct));
                        end
                        SSData = utSISOLFT(this.IC(idx),C);
                    end
                    this.TunedLFT_SSData{idx} = SSData;
                end

                % If flag is zpk return zpkdata otherwise ssdata
                if (nargin >= 2) && strcmp(flag,'zpk')
                    if isempty(this.TunedLFT_ZPKData{idx})
                        sw = warning('off','Control:transformation:StateSpaceScaling'); [lw,lwid] = lastwarn;
                        this.TunedLFT_ZPKData{idx} = zpk(SSData);
                        warning(sw); lastwarn(lw,lwid);
                    end
                    D = this.TunedLFT_ZPKData{idx};
                else
                    D = SSData;

                end
            end


        end

        function CList = getDependency(this)
            TB = [this.TunedFactors;this.TunedBlocks];
            CList = TB(:);
        end

        function bool = hasFRD(this)
            bool = this.HasFRD;
        end

        function bool = hasDelay(this)
            % Retruns true if system has delays
            bool = this.HasDelay;
        end

        function edit(this,Anchor,Region)
            if nargin < 2
                Anchor = [];
            end
            if nargin < 3
                Region = 'SOUTH';
            end

            switch class(getDefinition(this))
                case 'ctrlguis.csdesignerapp.data.responses.internal.IOTransfer'
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseInputOutputTransferTC(this,ResponseWrapper);
                case 'ctrlguis.csdesignerapp.data.responses.internal.LoopTransfer'
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseLoopTransferTC(this,ResponseWrapper);
                case 'ctrlguis.csdesignerapp.data.responses.internal.SensitivityTransfer'
                    ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseSensitivityTransferTC(this,ResponseWrapper);
            end

            ResponseDialogGC = createView(ResponseDialogTC);
            ResponseDialogGC.show(Anchor,true,Region);
            update(ResponseDialogTC);

            ResponseWrapper.EditHandles = ResponseDialogGC;
        end
        function S = saveSession(this)
            S.Definition = saveSession(this.ResponseDefinition);
            S.Identifier = this.Identifier;
        end

        function reset(this,Scope,C)
            tmp = cell(length(this.IC),1);
            this.TunedLFT_SSData = tmp;
            this.TunedLFT_ZPKData = tmp;
            this.TunedLFT_FRDData = tmp;
            this.ModelData = tmp;
            this.Margins = [];
        end

        function D = getOpenLoopForDesign(this,Design,idxM)
            %getOpenLoop Computes open-loop @zpkdata, @ssdata, or @frdmodel model

            if nargin < 3
                idxM = getNominalIndex(this.Architecture);
            end
            % Series portion of TunedLoop

            VStruct = getValueStructure(Design);

            if hasFRD(this)
                % Compute FRD Data

                % Need to recompute
                Blocks = this.TunedBlocks;
                if isempty(Blocks)
                    D = this.IC(idxM);
                else
                    freqs = this.IC(idxM).Frequency;
                    for ct=length(Blocks):-1:1
                        BlockID = getIdentifier(Blocks(ct));
                        if isfield(VStruct,BlockID)
                            C(ct,1) = frd(getPrivateData(VStruct.(BlockID)),freqs);
                        else
                            C(ct,1) = frd(getZPKData(Blocks(ct)),freqs);
                        end
                    end
                    D = utSISOLFT(this.IC(idxM),C);
                end
            else
                % Need to recompute
                Blocks = this.TunedBlocks;
                if isempty(Blocks)
                    SSData = this.IC(idxM);
                else
                    for ct=length(Blocks):-1:1
                        BlockID = getIdentifier(Blocks(ct));
                        if isfield(VStruct,BlockID)
                            C(ct,1) = ss(getPrivateData(VStruct.(BlockID)));
                        else
                            C(ct,1) = getSSData(Blocks(ct));
                        end
                    end
                    SSData = utSISOLFT(this.IC(idxM),C);
                end
                D = SSData;
            end
            TunedFactors = this.TunedFactors;
            if hasFRD(this)
                for ct = 1:length(TunedFactors)
                    BlockID = getIdentifier(TunedFactors(ct));
                    if isfield(VStruct,BlockID)
                        D = D * frd(getPrivateData(VStruct.(BlockID)),D.Frequency);
                    else
                        D = D * frd(getZPKData(TunedFactors(ct)),D.Frequency);
                    end
                end
            else
                for ct = 1:length(TunedFactors)
                    BlockID = getIdentifier(TunedFactors(ct));
                    if isfield(VStruct,BlockID)
                        D = D * ss(getPrivateData(VStruct.(BlockID)));
                    else
                        D = D * getSSData(TunedFactors(ct));
                    end
                end
            end

            % Treat loop as negative feedback for presentation purposes if
            % its a loop transfer
            if isLoopTransfer(this)
                D = -D;
            end

        end



        function testfunction(this)
            updateTunedResponseData(this)
        end

    end

    methods
        function set.DirtyFlag(this,flag)
            this.DirtyFlag = flag;
            if flag
                notify(this,"MarkedDirty");
            end
        end
    end
    methods (Access = protected)
        function updateTunedResponseData(this)
            % Get response from architecture
            Resp = getResponse(this.ResponseDefinition,genss(this.Architecture));
            Resp = convertToSystemWithShortNames(this.Architecture,Resp);
            this.InputLabels = Resp.InputName;
            this.OutputLabels = Resp.OutputName;


            % Get TunedFactors and check that TunedFactors are in list
            if isa(this.ResponseDefinition,'ctrlguis.csdesignerapp.data.responses.internal.SensitivityTransfer') || ~issiso(Resp)
                % Sensitivty Transfer cannot have tuned factors nor mimo
                TunedFactors = [];
            else
                TunedFactors = getSeriesCompensators(this);
                if ~isempty(TunedFactors)
                    F = fieldnames(Resp.Blocks);
                    if ~isempty(F)
                        [~,~,idx1] = intersect(getIdentifier(TunedFactors),F);
                        for ct = 1:length(idx1)
                            Resp = replaceBlock(Resp,F{idx1(ct)},getValue(ss(1)));
                        end
                    end
                end
            end


            % Determine which blocks are in the response and create IC
            if isa(Resp,'genlti')
                for ct = 1: nmodels(Resp)
                    [IC(:,:,ct),B,S] = getLFTModel(Resp(:,:,ct));
                    if ~isequal(zeros(size(S)), S)
                        % Fold in S
                        [ny,nu] = iosize(Resp);
                        In = eye(length(B));
                        Q = blkdiag(eye(ny),[In;In]);
                        R = blkdiag(eye(nu),[In,-In]);
                        Pbar = Q*IC(:,:,ct)*R;
                        IC(:,:,ct) = lft(Pbar,S);
                    end
                end
                Bnames = cell(0,1);
                for ct =1:length(B)
                    Bnames{ct,1} = B{ct}.Name;
                end
                TB = getTunedBlocks(this.Architecture);
                if isempty(TB)
                    TunedBlocks = [];
                else
                    % TunedBlocks order should be same as Bnames. Using
                    % Bnames as first argument, and 'stable' as optional
                    % argument in intersect for this.
                    [~,idx2,idxTB2] = intersect(Bnames,getIdentifier(TB),'stable');
                    TunedBlocks = TB(idxTB2)';
                end
            else
                IC = Resp;
                TunedBlocks = [];
            end

            this.IC = getPrivateData(IC);
            this.TunedBlocks = TunedBlocks(:);
            this.TunedFactors = TunedFactors(:);
            this.HasFRD = isa(IC,'frd');
            this.HasDelay = hasdelay(IC);
            addArchitectureListeners(this);
            this.Value = [];
            reset(this,'all')

            % Set response dirty
            this.DirtyFlag = true;
        end

        function C = getSeriesCompensators(this)
            C = getSeriesCompensators(this.Architecture,this.ResponseDefinition, isLoopTransfer(this));
        end


        function addArchitectureListeners(this)
            delete(this.TunedBlockListeners);
            this.TunedBlockListeners = [];
            FBListeners = [];
            FBListeners = [FBListeners;...
                addlistener(this.Architecture,'SystemChanged',@(es,ed) plantChanged(this))];

            TB = getDependency(this);
            TBListeners = [];

            weakThis = matlab.lang.WeakReference(this);
            for ct = 1:numel(TB)
                TBListeners = [TBListeners; ...
                    addlistener(TB(ct),'ValueChanged',@(es,ed) setDirty(weakThis.Handle,true,es))]; %#ok<AGROW>
                TBListeners = [TBListeners; ...
                    addlistener(TB(ct),'GainChanged',@(es,ed) setDirty(weakThis.Handle,true,es))];%#ok<AGROW>
                TBListeners = [TBListeners; ...
                    addlistener(TB(ct),'RefreshModeChanged', @(es,ed)notifyRefreshModeChanged(weakThis.Handle,ed))];%#ok<AGROW>
            end

            NominalListener = addlistener(this.Architecture, 'NominalIndexChanged', @(es,ed)plantChanged(this));

            this.TunedBlockListeners =  [FBListeners;TBListeners;NominalListener];
        end

        function notifyRefreshModeChanged(this,ED)
            ED = ctrluis.toolstrip.dataprocessing.GenericEventData(ED.Data);
            this.notify('RefreshModeChanged',ED);
        end

        function plantChanged(this)
            updateTunedResponseData(this)
            % Set Dirty
            this.DirtyFlag = true;
            notify(this,'PlantValueChanged');
        end

    end

    methods(Hidden)
        function l = addListenerToSyncData(this,fcn)
            l = addlistener(this,'DefinitionChanged',fcn);
        end
    end

    events
        DefinitionChanged
        ValueChanged
        PlantValueChanged
        RefreshModeChanged
        MarkedDirty
    end
end

function idx = localGetID()
persistent ID;
if isempty(ID)
    ID = 0;
end
ID = ID + 1;
idx = ID;
end







