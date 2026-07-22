classdef (Hidden) AbstractConfig < handle
    %   M = SYSTUNE.DATA.MATLABCONFIGDATA.AbstractConfig
    %   Abstract class for matlab based configurations
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(Access = public, SetObservable)
        ClosedLoop
        Dirty
    end
    properties (Access = private)
        TuningInfo_ = [];        
    end
    
    properties(Dependent)
        TunedBlocks
    end
    
    methods
        function TBList = get.TunedBlocks(this)
            TBList = {this.getTunableBlocks.BlockPath};
        end
    end
    
    methods (Access = public)
              
        Name = getName(this)
        TB = getTunableBlocks(this)
        MLConfigTC = getMLConfigTC(this)
            

        function CL = getCL(this)
            CL = computeCL(this);
            CL = setTuningInfo(CL,getTuningInfo(this));
            this.Dirty = false;
        end
        
        function Ts = getTs(this)
           CL = getCL(this);
           Ts = CL.Ts;
        end
        
        function Signals = getAvailableSignals(this,Type)
            if nargin == 1
                Type = 'All';
            end
            
            T = getCL(this);
            
            % Switch Names
            BlockSet = T.Blocks;
            BV = struct2cell(BlockSet);
            iSW = find(cellfun(@(x) isa(x,'AnalysisPoint'),BV));
            nSW = numel(iSW);
            SWData = BV(iSW,:);
            SWIndex = cell(nSW,1);
            chID = cell(nSW,1);
            chOpen = cell(nSW,1);
            ich = 0;
            for ct=1:nSW
                blk = SWData{ct};
                nch = size(blk,1);
                chID{ct} = blk.Location;
                chOpen{ct} = blk.Open;
                SWIndex{ct} = ich+1:ich+nch;
                ich = ich + nch;
            end
            SNames = cat(1,chID{:});  % loop channel IDs
            
            switch Type
                case 'Inputs'
                    Signals = unique([T.InputName ; SNames]);
                case 'Outputs'
                    Signals = unique([T.OutputName ; SNames]);
                case 'Locations'
                    Signals = SNames;
                case 'All'
                    Signals = unique([T.InputName; T.OutputName ; SNames]);    
            end
            
            
        end
        
        function CL = genss(this)
            CL = getCL(this);
        end
               
        function sys = getIOTransfer(this,varargin)
            sys = getIOTransfer(this.getCL,varargin{:});
        end
        
        function sys = getDynamics(this,varargin)
            sys = getDynamics(this.getCL,varargin{:});
        end
        
        function sys = getLoopTransfer(this,varargin)
            sys = getLoopTransfer(this.getCL,varargin{:});
        end
        
        function sys = getSensitivity(this,varargin)
            sys = getSensitivity(this.getCL,varargin{:});
        end
        
        function varargout = getBlockParam(this,varargin)
            
            try
                TunedBlocks = getTunableBlocks(this);
                numin = nargin;
                numout = nargout;
                if numin == 1
                    % Get all of the blocks
                    for ct = numel(TunedBlocks):-1:1
                        out{ct} = getParameterization(TunedBlocks(ct));
                    end
                    if numout == 1
                        % Single input single output case, stick to cell array output for
                        % consistency
                        varargout{1} = out;
                    else
                        for ct = numel(out):-1:1
                            varargout{ct} = out{ct};
                        end
                    end
                else
                    for ct = numin-1:-1:1
                        blk = varargin{ct};
                        % Replace with local find index
                        BlockNames = {TunedBlocks.Name}';
                        blkind = find(ltipack.strcmpEnd(strtrim(blk),deblank(BlockNames)));
                        varargout{ct} = getParameterization(TunedBlocks(blkind));
                    end
                    
                end
                
            catch Ex
                throw(Ex);
            end
   
        end

        function setBlockParam(this,ID,TC)          
            TunedBlocks = getTunableBlocks(this);

            %Find block
            BlockNames = {TunedBlocks.Name}';
            blkind = find(ltipack.strcmpEnd(strtrim(ID),deblank(BlockNames)));
            % Override the name, not to run into any issue later
            setParameterization(TunedBlocks(blkind),TC);
        end
                   
        function setConfigData(this,varargin)
            this.Dirty = true;
            validateConfigurationData_(this,varargin{:});
            EventType = setConfigData_(this,varargin{:});
            notify(this,EventType)
        end
        
        function setBlockValue(this,varargin)
            % REVISIT
            if isa(varargin{1},'ltipack.LFTModelArray')
                % setBlockValue(ST,M)
                BV = varargin{1}.Blocks;
            else
                BV = varargin{1};
                if ~isstruct(BV)
                    error(message('Slcontrol:controldesign:setBlockValue3'))
                end
            end
            try
                TunedBlocks = getTunableBlocks(this);
                for ct = 1:numel(TunedBlocks)
                    setValue(TunedBlocks(ct),BV);
                end
            catch ME
                throw(ME)
            end
        end
        
        function setTunedValue(this,varargin)
           % Same as setBlockValue for now
           setBlockValue(this,varargin{:})
        end
    end
    
    methods (Access = private)
       
    end
    
    methods(Static)
        function this = loadobj(this)
            loadobj_(this);
        end
    end
    
    methods(Access = public, Hidden = true)
        
        function this = loadobj_(this)
        end
    end
    methods (Hidden = true)
       function setTuningInfo(this,Info)
          % Caches Info structure from SYSTUNE's best run
          this.TuningInfo_ = Info;
       end
       function Info = getTuningInfo(this)
          % Accesses cached Info structure
          Info = this.TuningInfo_;
       end
    end
    events
        ConfigChanged
        DataChanged
    end
end
