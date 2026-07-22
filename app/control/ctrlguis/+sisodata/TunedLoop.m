classdef TunedLoop < matlab.mixin.SetGet & matlab.mixin.Copyable
%sisodata.TunedLoop class
%    sisodata.TunedLoop properties:
%       Name - Property is of type 'ustring'  
%       Description - Property is of type 'ustring'  
%       Identifier - Property is of type 'string'  
%       Feedback - Property is of type 'bool'  
%       ContainsDelay - Property is of type 'MATLAB array'  
%       ContainsFRD - Property is of type 'MATLAB array'  
%       TunedLFTSSData - Property is of type 'MATLAB array'  
%       Nominal - Property is of type 'double'  
%       TunedFactors - Property is of type 'handle vector'  
%       TunedLFT - Property is of type 'MATLAB array'  (read only) 
%       Ts - Property is of type 'double'  
%       ModelData - Property is of type 'MATLAB array'  
%       LoopConfig - Property is of type 'MATLAB array'  
%       ClosedLoopIO - Property is of type 'MATLAB array'  
%       Margins - Property is of type 'MATLAB array'  
%       Listeners - Property is of type 'MATLAB array'  
%
%    sisodata.TunedLoop methods:
%       addListeners -  Adds listener for changes in the open loop configuration
%       computeTunedLoop -  Recomputes tuned loop parameterization
%       getFixedPZ -  Get poles and zeros from the calculated open-loop that are not
%       getModel - Computes ssdata or frddata of tuned loop
%       getOpenLoop - Computes normalized open-loop @zpkdata, @ssdata, or @frdmodel model
%       getTunedLFT - Used to update the cache of the TunedLFT
%       getTunedPZ -  Get tunable open-loop poles and zeros (dynamics of the 
%       hasDelay -  Returns TRUE if the TunedLoop model has delays.
%       hasFRD -  Returns TRUE if the TunedLoop model has delays.
%       import -  Loop data.
%       isUncertain -  Checks if the TunedLoop is uncertain (e.g. an array)
%       pOpenLoop -  Computes parametric open-loop model for fast root locus update.
%       pfrespOL -  Parameterizes the open-loop frequency response in terms of the  
%       reset -  Cleans up dependent data when core data changes.
%       save -   Creates backup of TunedLoop data.
%       setTunedLFT - Sets the IC matrix and TunedBlocks of the TunedLFT and makes 
%       ss - Computes ss of tuned loop
%       utFactorizeLoop - L,C) computes the "plant" model P for the Open-Loop 
%       zpk - Compute ZPK of tuned loop


properties (SetAccess=protected, SetObservable)
    %TUNEDLFT Property is of type 'MATLAB array'  (read only)
    TunedLFT = [];
end

properties (SetObservable)
    %NAME Property is of type 'ustring' 
    Name = '';
    %DESCRIPTION Property is of type 'ustring' 
    Description = '';
    %IDENTIFIER Property is of type 'string' 
    Identifier = '';
    %FEEDBACK Property is of type 'bool' 
    Feedback = false;
    %CONTAINSDELAY Property is of type 'MATLAB array' 
    ContainsDelay = [];
    %CONTAINSFRD Property is of type 'MATLAB array' 
    ContainsFRD = [];
    %TUNEDLFTSSDATA Property is of type 'MATLAB array' 
    TunedLFTSSData = [];
    %NOMINAL Property is of type 'double' 
    Nominal = 1;
    %TUNEDFACTORS Property is of type 'handle vector' 
    TunedFactors = [];
    %TS Property is of type 'double' 
    Ts = 0;
    %MODELDATA Property is of type 'MATLAB array' 
    ModelData = [];
    %LOOPCONFIG Property is of type 'MATLAB array' 
    LoopConfig = [];
    %CLOSEDLOOPIO Property is of type 'MATLAB array' 
    ClosedLoopIO = [];
    %MARGINS Property is of type 'MATLAB array' 
    Margins = [];
    %LISTENERS Property is of type 'MATLAB array' 
    Listeners = [];
end


events 
    OpenLoopConfigChange
end  % events

    methods 
        function set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function set.Identifier(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Identifier')
        obj.Identifier = value;
        end

        function set.Feedback(obj,value)
            % DataType = 'bool'
        validateattributes(value,{'numeric','logical'}, {'scalar','nonnan'},'','Feedback')
        value = logical(value); %  convert to logical
        obj.Feedback = value;
        end

        function set.Nominal(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Nominal')
        value = double(value); %  convert to double
        obj.Nominal = value;
        end

        function set.TunedFactors(obj,value)
            % DataType = 'handle vector'
        validateattributes(value,{'handle'}, {'vector'},'','TunedFactors')
        obj.TunedFactors = value;
        end

        function set.Ts(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Ts')
        value = double(value); %  convert to double
        obj.Ts = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addListeners(this, LoopData);
       % Adds listener for changes in the open loop configuration
       
       
       % if this.Feedback
       %     this.Listeners = handle.listener(this, this.findprop('LoopConfig'),...
       %         'PropertyPreSet', ...
       %         {@LocalComputeTunedLoop, this, LoopData});
       % end
       end  % addListeners
       
        %----------------------------------------
       function computeTunedLoop(this,LoopData,varargin)
       % Recomputes tuned loop parameterization
       %    TL = TF1 ... TFn * lft(IC,diag(TB1,...TBm))
       % where 
       %   * the TFi's are the tuned factors (directly 
       %     tunable blocks
       %   * the TBj's are the indirectly tunable blocks.
       
       if nargin == 3
           LoopConfig = varargin{1};
       else
           LoopConfig = this.LoopConfig;
       end 
       
       % Set nominal index
       this.Nominal = getNominalModelIndex(LoopData.Plant);
       
       if LoopData.getconfig == 0
          %% Throw up a waitbar
          wb = waitbar(0,getString(message('Control:compDesignTask:AnalyzingModel')), ...
              'Name',getString(message('Control:compDesignTask:strSISODesignTask')));
       
          %% Get the TaskNode
          TaskNode = handle(getObject(getSelected(slctrlexplorer)));
       
          %% Create the loop opening IOs
          LoopOpenings = LoopConfig.LoopOpenings;
          for ct = numel(LoopOpenings):-1:1
             if LoopOpenings(ct).Status
                Active = 'on';
             else
                Active = 'off';
             end
             loopopeningio(ct) = linio(LoopOpenings(ct).BlockName,LoopOpenings(ct).PortNumber,...
                'none','on');
             loopopeningio(ct).Active = Active;
          end
       
          %% Create the FeedbackLoop IO
          OpenLoop = LoopConfig.OpenLoop;
          FeedbackLoop = linio(OpenLoop.BlockName,OpenLoop.PortNumber,'outin','on');
       
          loopio = struct('FeedbackLoop',FeedbackLoop,...
             'LoopOpenings',loopopeningio,...
             'Name',this.Name,...
             'Description',this.Description);
       
          % Recompute loop for SCD
          try
             waitbar(0.25,wb);
             newtunedloop = computeSingleTunedLoop(TaskNode,loopio,LoopData);
             waitbar(0.9,wb);
          catch ME
             close(wb);
             throw(ME);
          end
       
          this.TunedFactors = newtunedloop.TunedFactors;
          this.setTunedLFT(newtunedloop.TunedLFT.IC,newtunedloop.TunedLFT.Blocks);
          this.LoopConfig.BlocksInPathByName = newtunedloop.LoopConfig.BlocksInPathByName;
       
          % Update the SISODB
          LoopData.send('LoopDataChanged')
          close(wb);
       
       elseif this.Feedback
          % Tuned open loop
          BlockNames = get(LoopData.C,{'Identifier'}); % names of tuned blocks
          idxOL = find(strcmp(LoopConfig.OpenLoop.BlockName, BlockNames));
       
          % Find all loop openings for open loop IDXOL
          LoopOpenings = LoopConfig.LoopOpenings;
          if isempty(LoopOpenings)
             idxOpenings = [];
          else
             [junk,idxOpenings] = intersect(BlockNames,...
                {LoopOpenings([LoopOpenings.Status]).BlockName});
          end
       
          % Build data structure for open-loop analysis
          [cDepend,G] = getOpenLoopModel(LoopData.Plant,idxOL,idxOpenings);
          this.TunedFactors = LoopData.C(idxOL);
          this.setTunedLFT(G,LoopData.C(cDepend)); 
       
       else
          % Tuned closed loop
       end
       end  % computeTunedLoop
       
        %----------------------------------------
       function [FixedZeros,FixedPoles] = getFixedPZ(this,idx)
       %getFixedPZ  Get poles and zeros from the calculated open-loop that are not
       % graphically tunable. These are the poles of the TunedLFT of the
       % TunedLoop which can be computed and the fixed poles of the TunedFactors.
       
       
       
       if nargin == 1
           % Return Nominal value if no idx is specified
           idx = this.Nominal;
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
       
       end  % getFixedPZ
       
        %----------------------------------------
       function D = getModel(this,idx)
       % getModel Computes ssdata or frddata of tuned loop
       
       
       if nargin == 1;
           if this.Feedback
               idx = this.Nominal;
           else
               % Tuned loop is a compensator for closed loop editor.
               idx = 1;
           end
       end
       
       if isempty(this.ModelData{idx})
           % Recompute
           % Series portion of TunedLoop
           TunedFactors = this.TunedFactors;
           
           % LFT portion of TunedLoop
           D = getTunedLFT(this,[],idx);
           
           isFRD =  isa(D,'ltipack.frddata');
           
           for ct = 1:length(TunedFactors)
               if isFRD
                   D = D * frd(zpk(TunedFactors(ct)),D.Frequency);
               else
                   D = D * ss(TunedFactors(ct));
               end
           end
           this.ModelData{idx} = D;
       else
           D = this.ModelData{idx};
       end
       
       
       
       end  % getModel
       
        %----------------------------------------
       function D = getOpenLoop(this,TunedZPK,idxM)
       %getOpenLoop Computes normalized open-loop @zpkdata, @ssdata, or @frdmodel model
       % This function is used by the graphical editors to compute the open loop
       % displayed.
       % Note: The Open-Loop is defined as positive feedback because the loop is
       % defined by cutting a signal(i.e. all signs are lumped in the effective
       % plant). However because most users are used to designing with negative
       % feedback on such plots as root locus this function pulls out a negative
       % sign so that plots are presented as negative feedback.
       
       
       if nargin < 3
           idxM = this.Nominal;
       end
       
       % Series portion of TunedLoop
       TunedFactors = this.TunedFactors;
       
       if nargin > 1 && ~isempty(TunedZPK)
           idx = find(TunedZPK == TunedFactors);
       else
           idx = 0;
       end
       
       % LFT portion of TunedLoop
       D = getTunedLFT(this,[],idxM);
       
       if hasFRD(this)
           for ct = 1:length(TunedFactors)
               if ct == idx
                   D = D * frd(zpk(TunedFactors(ct),'normalized'),D.Frequency);
               else
                   D = D * frd(zpk(TunedFactors(ct)),D.Frequency);
               end
           end
       else
           for ct = 1:length(TunedFactors)
               if ct == idx
                   % REVISIT (cast to SS and ZPK)
                   D = D * ss(TunedFactors(ct),'normalized');
               else
                   D = D * ss(TunedFactors(ct));
               end
           end
       end
       
       % Treat loop as negative feedback for presentation purposes
       D = -D;
       end  % getOpenLoop
       
        %----------------------------------------
       function D = getTunedLFT(this,flag,idx)
       %getTunedLFT Used to update the cache of the TunedLFT
       % 
       % D = getTunedLFT(this) returns the ssdata of the TunedLFT
       % D = getTunedLFT(this,'zpk') returns the zpkdata of the TunedLoop
       
       
       if nargin < 3
           idx = this.Nominal;
       end
       
       if (nargin == 2) && (hasDelay(this) || hasFRD(this))
           ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
               'The Poles and Zeros can not be computed for time-delay or frequency response data systems.')
       end
       
       if hasFRD(this)
           % Compute FRD Data
           if isempty(this.TunedLFT.FRDData{idx})
               % Need to recompute
               this.TunedLFT.FRDData{idx} = LocalRecomputeFRD(this,idx);
           end
           D = this.TunedLFT.FRDData{idx};
       else
           SSData = this.TunedLFTSSData{idx};
           if isempty(SSData)
               % Need to recompute
               SSData = LocalRecompute(this,idx);
               this.TunedLFTSSData{idx}=SSData;
           end
           
           % If flag is zpk return zpkdata otherwise ssdata
           if (nargin >= 2) && strcmp(flag,'zpk')
               if isempty(this.TunedLFT.ZPKData{idx})
                   sw = warning('off','Control:transformation:StateSpaceScaling'); [lw,lwid] = lastwarn;
                   this.TunedLFT.ZPKData{idx} = zpk(SSData);
                   warning(sw); lastwarn(lw,lwid);
               end
               D = this.TunedLFT.ZPKData{idx};
           else
               D = SSData;
           
           end
       end
       end
       
       

        %----------------------------------------
       function [TunedZeros,TunedPoles] = getTunedPZ(this)
       % Get tunable open-loop poles and zeros (dynamics of the 
       % tuned factors)
       
       TunedZeros = zeros(0,1);
       TunedPoles = zeros(0,1);
       TunedFactors = this.TunedFactors;
       for ct = 1:length(TunedFactors)
          [Z,P] = getPZ(TunedFactors(ct),'Tuned');
          TunedZeros = [TunedZeros ; Z];
          TunedPoles = [TunedPoles ; P];
       end
       
       end  % getTunedPZ
       
        %----------------------------------------
       function boo = hasDelay(this)
       % Returns TRUE if the TunedLoop model has delays.
       
       if isempty(this.ContainsDelay)
           this.ContainsDelay = hasdelay(this.TunedLFT.IC);
       end
       boo = this.ContainsDelay;
       end  % hasDelay
       
        %----------------------------------------
       function boo = hasFRD(this)
       % Returns TRUE if the TunedLoop model has delays.
       
       
       if isempty(this.ContainsFRD)
           this.ContainsFRD = isa(this.TunedLFT.IC,'ltipack.frddata');
       end
       boo = this.ContainsFRD;
       end  % hasFRD
       
        %----------------------------------------
       function import(this, TunedLoopSnapshot, LoopData)
       % Imports Loop data.
       %
       
       
       utRestoreTunedLoop(TunedLoopSnapshot,this,LoopData);
       
       
       end  % import
       
        %----------------------------------------
       function boo = isUncertain(this)
       % Checks if the TunedLoop is uncertain (e.g. an array)
       
       boo = numel(this.TunedLFT.IC)>1;
          
       end  % isUncertain
       
        %----------------------------------------
       function S = pOpenLoop(this,C_tuned,C_ol,idxM)
       % Computes parametric open-loop model for fast root locus update.
       %
       % The parameterization is in terms of the currently tuned block C_tuned, 
       % which is assumed to be indirectly tunable for the open loop THIS.
       % The parametric open-loop model is further normalized with respect to 
       % the tuned factor C_OL.  This allows for fast update of the root locus 
       % plot (for the open loop THIS) when modifying C_tuned.
       %
       % pOpenLoop computes a 2x2 @ssdata model G22 and a SISO @ssdata model C 
       % such that the normalized open loop (with respect to C_OL) is given by
       %    OL = C * lft(G22,ss(C_tuned))
       % Note that C collects all tuned factors for the C_OL loop, including 
       % the normalized C_OL.
       
       %   Author(s): P. Gahinet
       
       if nargin < 4
           idxM = this.Nominal;
       end
       
       TunedFactors = this.TunedFactors;
       TunedLFTBlocks = this.TunedLFT.Blocks;  % indirectly tunable for this loop
       
       % Initialize C with normalized C_OL tuned factor
       % Note: Flip sign to account for negative feedback assumed by root locus
       % editor
       C = zpk(C_ol,'norm');
       C.k = -C.k;
       
       % Fold remaining tuned factors into C
       % RE: Use ZPK form for efficiency and to avoid
       %     extra states when some factors are improper
       for ct=1:length(TunedFactors)
          TF = TunedFactors(ct);
          if TF~=C_ol
             C = C * zpk(TF);
          end
       end
       
       % Compute 2x2 model G22
       idxB = find(C_tuned==TunedLFTBlocks);
       nB = length(TunedLFTBlocks);
       perm = [idxB 1:idxB-1 idxB+1:nB]; % Move C_tuned upfront in block list
       idxG = [1 1+perm];
       G22 = getsubsys(this.TunedLFT.IC(idxM),idxG,idxG); 
       % Close the lower loops around fixed comps
       % RE: No structural reduction here (performed later by RLOCUS)
       for ct=nB:-1:2
          G22 = utSISOLFT(G22,ss(TunedLFTBlocks(perm(ct))));
       end
       
       % Collect tuned poles and zeros
       [zC,pC] = getTunedPZ(this);
       
       % Build output
       S = struct('G22',G22,'C',ss(C),'TunedZero',zC,'TunedPole',pC);
       
       end  % pOpenLoop
       
        %----------------------------------------
       function S = pfrespOL(this,w,C,Cnorm,idxM)
       % Parameterizes the open-loop frequency response in terms of the  
       % currently edited compensator C.
       %
       % PFRESPOL computes a 2x2 frequency response hP together with the
       % normalized (initial) frequency response hC of the compensator C 
       % so that the frequency response hOL of the tuned loop THIS is  
       % given by
       %    hOL = gCnorm * lft(hP,gC*hC)
       % where
       %   * gC = getgain(C,'mag') is the gain of C
       %   * gCnorm = getgain(Cnorm,'mag') is the gain of the compensator
       %     Cnorm with respect to which the tuned loop THIS should be 
       %     normalized.
       %
       % This parameterization allows for fast update of the open-loop 
       % frequency-domain editors when dynamically modifying C.  The 
       % normalization wrt Cnorm avoids Divide by Zero issues when the
       % loop gain (gain of Cnorm) is zero.
       
       %   Author(s): P. Gahinet
       
       if nargin < 5
           idxM = this.Nominal;
       end
       
       
       % Note: Assumes that C is not a Tuned Factor for the tuned loop THIS
       % (see grapheditor/addlisteners)
       nw = length(w);
       hP = zeros(2,2,nw);
       TunedFactors = this.TunedFactors;
       TunedLFT = this.TunedLFT;
       nBlocks = length(TunedLFT.Blocks);
       idxB = find(C==TunedLFT.Blocks); % assumed to be single index
       
       % Compute frequency response of Tuned Factors
       hTF = ones(1,1,nw);
       for ct = 1:length(TunedFactors);
          if TunedFactors(ct)==Cnorm
             hTF = hTF .* fresp(zpk(Cnorm,'normalized'),w);
          else
             hTF = hTF .* fresp(zpk(TunedFactors(ct)),w);
          end
       end
       
       % Frequency response of C
       hC = fresp(zpk(C,'norm'),w);
       
       % Frequency response of IC
       hIC = fresp(TunedLFT.IC(idxM), w);
       
       % Move C to second I/O pair in IC
       otherBlocks = [1:idxB-1 idxB+1:nBlocks];
       perm = [1 1+idxB 1+otherBlocks];
       hIC = hIC(perm,perm,:);
       
       % Frequency response of remaining blocks
       hOB = zeros(nBlocks-1,1,nw);
       for ct=1:nBlocks-1
          hOB(ct,1,:) = fresp(zpk(TunedLFT.Blocks(otherBlocks(ct))),w);
       end
       
       % Compute hP by closing lower loops on remaining blocks
       idxLower = 3:nBlocks+1;
       for ct=1:nw
          s = hOB(:,1,ct);
          hP(:,:,ct) = hIC([1 2],[1 2],ct) + lrscale(hIC([1 2],idxLower,ct),[],s) * ...
             ((eye(nBlocks-1)-lrscale(hIC(idxLower,idxLower,ct),[],s)) \ hIC(idxLower,[1 2],ct));
       end
       
       % Add contribution of tuned factors and
       % account for assumed negative feedback
       hP(1,:,:) = -hP(1,:,:) .* hTF(1,[1 1],:);
       
       % Build data structure
       S = struct('P',permute(hP,[3 1 2]),'C',hC(:),'w',w);
       
       end  % pfrespOL
       
        %----------------------------------------
       function reset(this,Scope,C)
       % Cleans up dependent data when core data changes.
       %
       %   RESET(this,'all')
       %   RESET(this,'root',C)
       %   RESET(this,'gain',C)
       %   RESET(this,'ol',C)
       
       % 
       
       tmp = cell(length(this.TunedLFT.IC),1);
       
       if strcmp(Scope ,'all')
           this.ModelData = tmp;
           this.Margins = [];
           this.TunedLFT.SSData = tmp;
           this.TunedLFT.ZPKData = tmp;
           this.TunedLFT.FRDData = tmp;
           this.TunedLFTSSData = tmp;
       
       else
           % Check if TunedLoop depends on C
           isTunedFactor = any(C == this.TunedFactors);
           isTunedLFTBlock = any(C == this.TunedLFT.Blocks);
       
           if isTunedFactor || isTunedLFTBlock
               this.ModelData = tmp;
               this.Margins = [];
               
               % Only clear TunedLFT cache if necessary
               if isTunedLFTBlock
                   this.TunedLFT.SSData = tmp;
                   this.TunedLFT.ZPKData = tmp;
                   this.TunedLFT.FRDData = tmp;
                   this.TunedLFTSSData = tmp;
               end
           end
       
       end
       end  % reset
       
        %----------------------------------------
       function Design = save(this)
       %SAVE   Creates backup of TunedLoop data.
       
       
       Design = sisodata.TunedLoopSnapshot;
       
       Design = utStoreTunedLoop(Design,this);
       end  % save
       
        %----------------------------------------
       function setTunedLFT(this,IC,Blocks)
       % setTunedLFT Sets the IC matrix and TunedBlocks of the TunedLFT and makes 
       % sure structure has proper fields 
        
       
       tmp = cell(length(IC),1);
       
       this.TunedLFT = struct(...
           'IC', IC, ...
           'Blocks', Blocks, ...
           'SSData', {tmp}, ...
           'ZPKData', {tmp}, ...
           'FRDData', {tmp});
       
       this.ModelData = tmp;
       
       this.ContainsDelay = [];
       this.ContainsFRD=[];
       this.TunedLFTSSData = tmp;
       end  % setTunedLFT
       
        %----------------------------------------
       function D = ss(this,idxM)
       % SS Computes ss of tuned loop
       
       
       if nargin == 1
           idxM = this.Nominal;
       end
       
       if hasFRD(this)
           ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
               'The state-space model can not be computed for FRD systems.')
       else
           if isempty(this.ModelData{idxM})
               % Recompute
               % Series portion of TunedLoop
               TunedFactors = this.TunedFactors;
               
               % LFT portion of TunedLoop
               D = getTunedLFT(this,[],idxM);
               
               for ct = 1:length(TunedFactors)
                   D = D * ss(TunedFactors(ct));
               end
               this.ModelData{idxM} = D;
           else
               D = this.ModelData{idxM};
           end
       end
       end  % ss
       
        %----------------------------------------
       function P = utFactorizeLoop(this,C,idxM)
       % P = utFactorizeLoop(L,C) computes the "plant" model P for the Open-Loop 
       % such that L = P*C. This is used in automated tuning algorithms for
       % designing the compensator C for the open-loop. 
       %
       % For example consider the open loop defined by
       % L = C1*C2*C3*TunedLFT where TunedLFT defines the compensators that do no
       % appear in series with the loop.
       % P = utFactorizeLoop(this,C2) returns P such that
       % L = C2*P where P = C1*C3*TunedLFT
       
       
       if nargin < 3
           idxM = this.Nominal;
       end
       
       if this.Feedback
           % LFT portion of TunedLoop includes compensators
           % that do not appear in series in the loop
           P = getTunedLFT(this,[],idxM);
           
           % Compensators that appear in series with the open-loop
           TunedFactors = this.TunedFactors;
           
           isFRD =  isa(P,'ltipack.frddata');
           
           % Incorporate compensators that appear in series in the loop
           % except that specified by C
           for ct = 1:length(TunedFactors)
               if ~isequal(C,TunedFactors(ct))
                   if isFRD
                       P = P * frd(zpk(TunedFactors(ct)),P.Frequency);
                   else
                       P = P * ss(TunedFactors(ct));
                   end
               end
           end
       
       else 
           ctrlMsgUtils.error('Control:compDesignTask:utFactorizeLoop')
       end
       end  % utFactorizeLoop
       
        %----------------------------------------
       function D = zpk(this,idx)
       % ZPK Compute ZPK of tuned loop
       
       
       % Not supported for time-delays or frd
       
       if nargin == 1
           idx = this.Nominal;
       end
       
       if hasDelay(this) || hasFRD(this)
           ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
               'The Poles and Zeros can not be computed for time-delay or frequency response data systems.')
       else
           % Series portion of TunedLoop
           TunedFactors = this.TunedFactors;
           
           % LFT portion of TunedLoop
           D = getTunedLFT(this,'zpk',idx);
           
           for ct = 1:length(TunedFactors)
               D = D * zpk(TunedFactors(ct));
           end
       end
       
       
       end  % zpk
       
end  % public methods 


    methods (Hidden) % possibly private or hidden
        %----------------------------------------
       function setLoopConfig(this,LoopData,LoopConfig)
       % SETLOOPCONFIG
       %
        
       % Author(s): John W. Glass 03-Oct-2005
       
       try
           computeTunedLoop(this,LoopData,LoopConfig)
       catch Ex
           if strcmp(Ex.identifier,'Slcontrol:controldesign:SignalNotInFeedbackLoop')
               errstr = getString(message('Control:compDesignTask:errSetLoopConfig1', ...
                   LoopConfig.OpenLoop.BlockName,...
                   sprintf('%d',LoopConfig.OpenLoop.PortNumber)));
           else
               msg = ltipack.utStripErrorHeader(Ex.message);
               errstr = getString(message('Control:compDesignTask:errSetLoopConfig2',this.Name,msg));
           end

           return
       end
       
       % If successful write the loop configuration data
       this.LoopConfig.OpenLoop = LoopConfig.OpenLoop;
       this.LoopConfig.LoopOpenings = LoopConfig.LoopOpenings;
       
       end  % setLoopConfig
       
end  % possibly private or hidden 

end  % classdef

function D = LocalRecomputeFRD(this,idx)
Blocks = this.TunedLFT.Blocks;
if isempty(Blocks)
    D = this.TunedLFT.IC(idx);
else
    freqs = this.TunedLFT.IC(idx).Frequency;
    for ct=length(Blocks):-1:1
        C(ct,1) = frd(zpk(Blocks(ct)),freqs);
    end
    D = utSISOLFT(this.TunedLFT.IC(idx),C);
end
end

function D = LocalRecompute(this,idx)

TunedLFT = this.TunedLFT;
Blocks = TunedLFT.Blocks;
if isempty(Blocks)
    D = TunedLFT.IC(idx);
else
    for ct=length(Blocks):-1:1
        C(ct,1) = ss(Blocks(ct));
    end
    D = utSISOLFT(TunedLFT.IC(idx),C);
end


end
