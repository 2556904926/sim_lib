classdef MatlabArchitecture < ctrlguis.csdesignerapp.data.architectures.internal.AbstractArchitecture
    % Abstract architecture class for pre-defined configurations for
    % Control System Designer

    % Copyright 2014-2017 The MathWorks, Inc.

    properties (Access = protected)
        LoopSign
        FixedBlocks
        %         SignalsWithID
        DataListeners
    end
    
    %% Implementation of Abstract Methods
    methods (Access = public)
        function b = isSimulink(this) %#ok<MANU>
            % Return true if architecture is simulink
            b = false;
        end
        
        % needs to be public for superclass access
        function S = saveSession_(this,S)
            for ct = 1:numel(this.FixedBlocks)
                FB(ct) = saveSession(this.FixedBlocks(ct));
            end
            S.FixedBlocks = FB;
            S.LoopSign = this.LoopSign;
            %             S.SignalsWithID = this.SignalsWithID;
        end
        
        function loadSession_(this,S)
            this.LoopSign = S.LoopSign;
            %             this.SignalsWithID = S.SignalsWithID;
        end
        
        function [Signals,ExpandedSignals] = getAvailableSignals(this,Type)
            % Return available signals for inputs outputs and locations
            if nargin == 1
                Type = 'All';
            end
            switch Type
                case 'All'
                    Signals = [this.System.InputName;this.System.OutputName;getPoints(this.System)];
                case 'Inputs'
                    Signals = [this.System.InputName; getPoints(this.System)];
                case 'Outputs'
                    Signals = [this.System.OutputName; getPoints(this.System)];
                case 'Locations'
                    Signals = getPoints(this.System);
                otherwise
                    error(message('Controllib:general:UnexpectedError','Invalid Type'))
            end
            % Create Unique List
            Signals = unique(Signals);
            ExpandedSignals = Signals;
        end
        
        
        function TB = getSeriesCompensators(this,Definition,hasFeedback)
            
            TunedNodeIdx = this.ConfigurationGraph.TunableBlocks;
            numTB = numel(TunedNodeIdx);
            SIdx = false(numTB,1);
            
            M = this.ConfigurationGraph.AdjacencyMatrix;
            if hasFeedback
                LoopIdx = this.ConfigurationGraph.Locations.(Definition.Location{:});
                LoopNode = false(length(M),1);
                LoopNode(LoopIdx) = true;
                LoopDSBlocks = M(:,LoopIdx)==1;
                % Break the loop at a given loop location - output of C or input of u
                % Zero out the column of LoopIdx - this is equivalent to cutting all links
                % that the location of loopidx feeds to.
                M(:,LoopIdx)=false;
            else
                
                LoopIdx = this.ConfigurationGraph.Locations.(Definition.Output{:});
                LoopNode = false(length(M),1);
                LoopNode(LoopIdx) = true;
                
                LoopDSIdx = this.ConfigurationGraph.Locations.(Definition.Input{:});
                LoopDSBlocks = false(length(M),1);
                LoopDSBlocks(LoopDSIdx) = true;
            end
            if ~isempty(Definition.Openings)
                OpeningNode = this.ConfigurationGraph.Locations.(Definition.Openings{:});
                M(:,OpeningNode) = false;
            end
            
            % Find all the blocks in path (i.e., the blocks can be reached and observed
            % from the loopio)
            RNode = ctrlguis.csdesignerapp.utils.internal.findReachableNodes(M',LoopDSBlocks);
            ONode = ctrlguis.csdesignerapp.utils.internal.findReachableNodes(M, LoopNode);
            BlocksInPath = RNode & ONode;
            
            for ct = 1:numTB
                TunedNode = TunedNodeIdx(ct);
                % If the TunedBlock is also the loop location, we consider it as a
                % block-in-series. Otherwise, we check the three loop conditions to
                % decide if the block is in series
                if ~LoopNode(TunedNode)
                    
                    % The block has to be in the path
                    if ~BlocksInPath(TunedNode)
                        continue
                    end
                    
                    % Conditon 1: All the immediate downstream blocks of the tuned block can
                    % not see the tuned block.
                    DSBlocks = M(:,TunedNode);
                    RNodes = ctrlguis.csdesignerapp.utils.internal.findReachableNodes(M',DSBlocks);
                    if any(RNodes(TunedNode))
                        continue
                    end
                    
                    % Conditon 2: All the immediate downstream block of the Loop IO cannot
                    % see the loop IO, if the tuned block's output is cut
                    Mtmp = M;
                    Mtmp(:,TunedNode) = false;
                    RNodes = ctrlguis.csdesignerapp.utils.internal.findReachableNodes(Mtmp',LoopDSBlocks);
                    if any(RNodes(LoopNode))
                        continue
                    end
                end
                % If both conditions are passed, the TunedBlock is in series connection
                SIdx(ct) = true;
            end
            
            TB = this.TunedBlocks(SIdx);
        end
        
        function validateSampleTime(this)
            % Checks sample time and time unit consistency
            
            % Gather all models
            nG = length(this.FixedBlocks);
            nC = length(this.TunedBlocks);
            AllModels = cell(nG+nC,1);
            for ct=1:nG
                AllModels{ct} = this.FixedBlocks(ct).getValue;
            end
            for ct=1:nC
                C = this.TunedBlocks(ct).getValue;
                AllModels{nG+ct} = C;
            end
            
            % Reconcile plant/sensor/prefilter/compensator sample times and time units
            % RE: The overall sample time is stored as this.Compensator.Ts
            try
                [AllModels{1:nG+nC}] = matchSamplingTimeN(AllModels{:});
                Ts = abs(AllModels{1}.Ts);
                for ct=1:nG
                    CurrentValue = this.FixedBlocks(ct).getValue;
                    if CurrentValue.Ts ~=Ts
                        this.FixedBlocks(ct).setValue(AllModels{ct});
                    end
                end
                for ct=1:nC
                    CurrentValue = this.TunedBlocks(ct).getValue;
                    if CurrentValue.Ts ~=Ts
                        this.TunedBlocks(ct).setValue(AllModels{nG+ct});
                    end
                end
            catch ME
                ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck11')
            end
            
        end
    end
    %% Public Methods
    methods (Access = public)
        %         function Signals = getSignalsWithID(this)
        %             Signals = this.SignalsWithID;
        %         end
        
        %         function setSignalsWithID(this, ID, Name)
        %             % Cache old names for event
        %             OldName = this.SignalsWithID(:,2);
        %
        %             % Is the ID Valid?
        %             for ct = 1:numel(ID)
        %                 [b,idx] = ctrlguis.csdesignerapp.utils.internal.findItemIndexInList(ID{ct}, this.SignalsWithID(:,1));
        %                 ix = find(idx==1);
        %
        %                 if b
        %                     % Is the signal being changed, an input?
        %                     IsSignalInput = cellfun(@(x)strcmpi(this.SignalsWithID{ix,2},x),this.System.InputName);
        %                     if any(IsSignalInput)
        %                         this.System.InputName{IsSignalInput} = Name{ct};
        %                         idx = ismember(this.LFT.IC.InputName,this.SignalsWithID{ix,2});
        %                         if any(idx)
        %                             this.LFT.IC.InputName{idx} = Name{ct};
        %                         end
        %                     end
        %
        %                     % Is the signal being changed, an output?
        %                     IsSignalOutput = cellfun(@(x)strcmpi(this.SignalsWithID{ix,2},x),this.System.OutputName);
        %                     if any(IsSignalOutput)
        %                         this.System.OutputName{IsSignalOutput} = Name{ct};
        %                         idx = ismember(this.LFT.IC.OutputName,this.SignalsWithID{ix,2});
        %                         if any(idx)
        %                             this.LFT.IC.OutputName{idx} = Name{ct};
        %                         end
        %                     end
        %
        %                     % Is the signal being changed, a location?
        %                     Points = getPoints(this.System);
        %                     IsSignalLocation = cellfun(@(x)strcmpi(this.SignalsWithID{ix,2},x), Points);
        %                     if any(IsSignalLocation)
        %                         this.System.Blocks.(Points{IsSignalLocation}).Location = Name{ct};
        %                         this.System.Blocks.(Points{IsSignalLocation}).Name = Name{ct};
        %                         this.LFT.IC.Blocks.(Points{IsSignalLocation}).Location = Name{ct};
        %                         this.LFT.IC.Blocks.(Points{IsSignalLocation}).Name = Name{ct};
        %                     end
        %
        %                     if isfield(this.ConfigurationGraph.Locations,this.SignalsWithID{ix,2})
        %                         oldField = this.SignalsWithID{ix,2};
        %                         newField = Name{ct};
        %                         [this.ConfigurationGraph.Locations.(newField)] = this.ConfigurationGraph.Locations.(oldField);
        %                         this.ConfigurationGraph.Locations = rmfield(this.ConfigurationGraph.Locations,oldField);
        %                     end
        %
        %                     % Finally, Update look up table
        %                     this.SignalsWithID{ix,2} = Name{ct};
        %
        %                 end
        %             end
        %
        %             ChangedIdx = ismember(this.SignalsWithID(:,2), Name);
        %             Data.NewName = Name;
        %             Data.OldName = OldName(ChangedIdx);
        %
        %             ED = ctrluis.toolstrip.dataprocessing.GenericEventData(Data);
        %             this.notify('SignalsListChanged', ED);
        %         end
        
        function Blocks = getFixedBlocks(this,ID)
            Blocks = this.FixedBlocks;
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
        
        function bool = hasFeedbackLoop(this, BlkID)
            M = this.ConfigurationGraph.AdjacencyMatrix;
            Location = getLocationForBlock(this,BlkID);
            LoopIdx = this.ConfigurationGraph.Locations.(Location);
            LoopNode = false(length(M),1);
            LoopNode(LoopIdx) = true;
            LoopDSBlocks = M(:,LoopIdx)==1;
            % Find all the blocks in path (i.e., the blocks can be reached and observed
            % from the loopio)
            RNode = ctrlguis.csdesignerapp.utils.internal.findReachableNodes(M',LoopDSBlocks);
            ONode = ctrlguis.csdesignerapp.utils.internal.findReachableNodes(M, LoopNode);
            BlocksInPath = RNode & ONode;
            
            [~,TBIdx] = ismember(this.TunedBlocks.getIdentifier,BlkID);
            bool = BlocksInPath(logical(TBIdx))';
        end
        
        function Plant = getOpenLoopPlant(this,C,Openings,Input,Output)
            TB = getTunedBlocks(this);
            IC = this.LFT.IC;
            if nargin==5
                for ct=1:length(TB)
                    if any(TB(ct)==C)
                        Tuned{ct} = ss(1);
                    else
                        Tuned{ct} = getValue(TB(ct));
                    end
                end
                Blocks  = blkdiag(Tuned{:});
                sys = lft(Blocks,IC);
                Plant = getIOTransfer(sys,Input,Output,Openings);
            else
                idxOL = find(this.TunedBlocks == C(1));
                if isempty(idxOL)
                    for ct = 1:1:length(TB)
                        Tuned{ct} = getValue(TB(ct));
                    end
                    Blocks  = blkdiag(Tuned{:});
                    Plant = lft(Blocks,IC);
                else
                    if ~isempty(Openings)
                        IC.Blocks.(Openings{:}).Open = 1;
                    end
                    
                    IC(:,this.ConfigurationGraph.ExternalInputs) = [];
                    IC(this.ConfigurationGraph.ExternalOutputs,:) = [];
                    IC = IC([1:idxOL-1,idxOL+1:end,idxOL],[1:idxOL-1,idxOL+1:end,idxOL]);
                    
                    TB = getTunedBlocks(this);
                    
                    for ct = 1:1:length(TB)
                        Tuned{ct} = getValue(TB(ct));
                        if numel(C)>1 && any(this.TunedBlocks==C(2:end))
                            Tuned{ct} = ss(1);
                        end
                    end
                    Blocks  = blkdiag(Tuned{:});
                    Blocks = Blocks([1:idxOL-1,idxOL+1:end],[1:idxOL-1,idxOL+1:end]);
                    Plant = lft(Blocks,IC);
                end
            end
        end
        
        % Used by the dialog
        function LS = getLoopSignWithID(this)
            LS(:,1) = getLoopID(this);
            for ct = 1:numel(this.LoopSign)
                if this.LoopSign(ct) == 1
                    LS{ct,2} = '+';
                else
                    LS{ct,2} = '-';
                end
                
            end
        end
        
        function setLoopSignWithID(this, varargin)
            if nargin < 3
                Idx = 1;
                LS = varargin{1};
            else
                Idx = arrayfun(@(x) strcmpi(x,varargin{1}),getLoopID(this));
                LS = varargin{2};
            end
            
            if strcmpi(LS,'+')
                this.LoopSign(Idx) = 1;
            else
                this.LoopSign(Idx) = -1;
            end
        end
        
        % Used by designer data to add default responses at start up
        function CL = getDefaultClosedLoops(this)       % Closed-loop responses
            CL(1).Input = 'r';
            CL(1).Output = 'y';
            CL(1).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','r','y')); % r to y
            
            CL(2).Input = 'r';
            CL(2).Output = 'u';
            CL(2).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','r','u')); % r to u
            
            CL(3).Input = 'du';
            CL(3).Output = 'y';
            CL(3).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','du','y')); % du to y
            
            CL(4).Input = 'dy';
            CL(4).Output = 'y';
            CL(4).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','dy','y')); % dy to y
            
            CL(5).Input = 'n';
            CL(5).Output = 'y';
            CL(5).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','n','y')); % n to y
        end
        
        function validateFixedBlocks(this)
            % Built-in loop structure
            idx = 1;
            nG = numel(this.FixedBlocks);
            GFRD = {};
            GSize = zeros(nG,1);
            for ct=1:nG
                Component = this.FixedBlocks(ct);
                GData = this.FixedBlocks(ct).getValue;
                if ~isempty(GData)
                    % Check validity of modified component
                    GData = LocalCheckFixedModelData(GData,Component.getIdentifier);
                    if isa(GData,'frd')
                        GFRD{idx} = GData; %#ok<AGROW>
                        idx = idx+1;
                    end
                end
                GSize(ct) = nmodels(GData);
                this.FixedBlocks(ct).setValue(GData);
            end
            % Ensure FRD models are compatible
            if ~isempty(GFRD)
                try
                    LocalCheckFRDConsistency(GFRD);
                catch ME
                    ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck13')
                end
            end
            % Ensure Arrays are compatible
            % Elements must be single model or vectors of same size
            if ~all((GSize == 1) | (GSize == max(GSize)))
                ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck16')
            end
        end
        
        function updateArchitecture(this)
            computeClosedLoop(this);
            this.notify('SystemChanged');
            this.isDirty = true;
        end
        function LS = getLoopSign(this)
            LS = this.LoopSign;
        end
        
        function drawDiagram(this)
            %---Check if the User has Simulink
            if license('test', 'SIMULINK')
                % Create Simulink model
                [NewDiagram, DiagramName] = this.createEmptyBlockDiagram;
                % Create variables in base workspace
                this.assignLTIDataInBaseWS;
                % Call abstract method
                try
                    this.drawDiagram_(NewDiagram,DiagramName);
                catch ex
                    close_system(NewDiagram,0);
                    if isa(ex.cause{1},'MSLException')
                        error(ex.cause{1}.identifier,ex.cause{1}.message)
                    else
                        error(ex.identifier,ex.message);
                    end
                end
            else
                warning(getString(message('Control:compDesignTask:DrawDiagramMsg2')));
            end
        end
    end
    
    methods (Access = protected)
        function FB = createFixedBlock(this,ID,Value)
            
            if true
                import ctrlguis.csdesignerapp.data.architectures.internal.FixedBlock;
                FB = FixedBlock(ID,Value);
            else
                FB = sisodata.fixedmodel;
                FB.Model = Value;
                FB.Identifier = ID;
            end
        end
        
        function [NewDiagram, DiagramName] = createEmptyBlockDiagram(this)
            
            % Find adequate name for new diagram
            AllDiagrams = find_system('Type','block_diagram');
            % name must be a valid function name
            DiagramName = strrep(this.getName,' ','_'); %remove  spaces
            DiagramName = strrep(DiagramName,')',''); % Remove (
            DiagramName = strrep(DiagramName,'(',''); % Remove )
            if ~isvarname(DiagramName)
                DiagramName = 'untitled';
            end
            if ~isempty(AllDiagrams)
                %---Look first for an exact match
                ExactMatch = strmatch(DiagramName,AllDiagrams,'exact');
                if ~isempty(ExactMatch)
                    DiagramName = sprintf('%s_',DiagramName);
                    % Look for an available name of the form DiagramName_xxx
                    UsedInds = strmatch(DiagramName,AllDiagrams);
                    if ~isempty(UsedInds)
                        %---Look for minimum available number to use
                        UsedNames = strvcat(AllDiagrams{UsedInds});
                        %---Weed out names that don't end in scalar values.
                        strVals = real(UsedNames(:,length(DiagramName)+1:end));
                        strVals(find(strVals(:,1)<48 | strVals(:,1)>57),:)=[];
                        RealVals = zeros(size(strVals,1),1);
                        for ctR=1:size(strVals,1),
                            RealVals(ctR,1) = str2double(char(strVals(ctR,:)));
                        end
                        if ~isnan(RealVals),
                            NextInd = setdiff(1:max(RealVals)+1,RealVals);
                            NextInd = NextInd(1);
                        else
                            NextInd=1;
                        end
                    else
                        NextInd=1;
                    end % if/else isempty(UsedInds)
                    DiagramName = sprintf('%s%d',DiagramName,NextInd);
                end % if ~isempty(ExactMatch)
            end % if ~isempty(AllDiagrams)
            
            %---Open New Simulink diagram
            NewDiagram = new_system(DiagramName,'model');
        end
        
        function assignLTIDataInBaseWS(this)
            % Write model data in workspace
            blks = this.getBlocks;
            for k = 1:length(blks)
                blkValue = blks{k}.getValue;
                [~,~,n] = size(blkValue);
                if n>1
                    blkValue = blkValue(:,:,this.getNominalIndex);
                end
                assignin('base',blks{k}.Name,blkValue);
            end
        end
        
    end
    
    %% Abstract public methods
    methods (Abstract, Access = protected)
        % To create Simulink model based on configuration
        drawDiagram_(this,NewDiagram,DiagrameName);
    end
    
    methods (Hidden = true)
        function LS = qeGetLoopSign(this)
            LS = this.LoopSign;
        end
    end
    
    events
        %         SignalsListChanged
    end
    
end

function LocalCheckFRDConsistency(List)
% Checks all FRD models have the same frequency grid
FRDList = List(isa(List,'frd'));
if ~isempty(FRDList)
    sys1 = FRDList(1);
    freqs = sys1.Frequency;
    tunits = sys1.TimeUnit;
    funits = sys1.FrequencyUnit;
    for j=2:length(FRDList)
        sysj = FRDList(j);
        cf = funitconv(sysj.FrequencyUnit,funits,tunits);
        if ~FRDModel.isSameFrequencyGrid(freqs,cf*sysj.Frequency)
            ctrlMsgUtils.error('Control:ltiobject:mrgfreq1')
        end
    end
end
end

function sys = LocalCheckFixedModelData(sys,Component)
% Checks model data for plant, sensor, prefilter, and compensator.

% Check model class
if isa(sys,'idfrd')
    sys = frd(sys);
elseif ~isa(sys,'frd')
    if ~isreal(sys)
        ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck03',Component)
    elseif isa(sys,'idlti')
        % IDMODEL support
        % Check the number of inputs to the model
        nu = size(sys,2);
        if nu > 0
            % If the model is not a time series extract the
            % model from the input channels to output channels.
            sys = zpk(sys);
        else
            % If the model is a time series model error out.
            ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck04',Component)
        end
    elseif isnumeric(sys)
        % Double
        sys = zpk(sys);
    end
end

% Check dimensions
if any(iosize(sys)~=1)
    ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck06',Component)
end
sizes = size(sys);
if prod(sizes(3:end)) ~= max(sizes(3:end))
    ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck15',Component)
end
end

