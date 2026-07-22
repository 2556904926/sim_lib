classdef TunedLTI < ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock
    % TunedLTI  Class for managing tuned blocks that support tuning of
    % poles and zeros of system
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    % Public Properties
    properties
        Constraints
        FixedDynamics
        ZPK2ParFcn
    end
    
    % Observable Public Properties
    properties (SetObservable = true)
        PZGroup
        Gain = 1
    end
    
    properties (Transient)
        PZGroupListeners
    end
    
    methods
        function this = TunedLTI(ID, sys)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock(ID, sys);
            %             L = addlistener(this, 'PZGroup','PostSet',@LocalPZGroupChanged);
            %             this.Listeners.PZGroup = L;
            if isnumeric(sys)
                sys = ss(sys);
            end
            this.Ts = sys.Ts;
            setValue(this,sys);
        end
        
        function intializeWithBlockConfig(this,BlockConfig,RateConversionMethod,BlockStruct)
            this.Path = BlockConfig.BlockPath;
            this.Constraints = BlockStruct.Constraints;
            this.ZPK2ParFcn = BlockStruct.InvFcn;
            this.TsOrig = getTs(BlockConfig);
            
            InPars             = BlockStruct.TunableParameters;
            this.Name          = BlockConfig.Name;
            this.Parameters    = InPars;
            % REVISIT
            %         TunedBlocks(ct).AuxData       = struct('InportPort',BlockStruct.Inport,...
            %             'OutportPort',BlockStruct.Outport);
            this.Par2ZpkFcn    = BlockStruct.EvalFcn;
            
            
            % Determine C2D/D2C methods
            if strcmpi(RateConversionMethod{1},'prewarp')
                C2DMethod = RateConversionMethod;
            else
                C2DMethod = RateConversionMethod(1);
            end
            this.C2DMethod = C2DMethod;
            this.D2CMethod = C2DMethod;
            
        end
                       
        function setValue(this,S,DoNotNotify) %#ok<*INUSD>
            % REVISIT Verify size etc.
            OldName = this.Name;
            
            if isnumeric(S)
                S = ss(S);
            end
            this.Data_ = LocalCheckCompensatorModelData(S);
            zpkdata = zpk(S);
            this.Ts = zpkdata.Ts;
            % Clear fixed dynamics
            this.FixedDynamics = ltipack.zpkdata({zeros(0,1)},{zeros(0,1)},1,this.Ts);
            % Updates PZGroups and gain
            updatePZGroups(this, zpkdata);
            % Importing new gain
            setZPKGain_(this, zpkdata.k,[]);
            % Update parameters
            updateParams(this);
            % Update tuned and fixed parts of zpk
            updateZPK(this);
            if isempty(this.Data_.Name)
                this.Name = OldName;
            end
            % Clear data cache to recompute
            this.SSData = [];
            this.ZPKParamSpec.Dirty = true;
            
            if nargin==2
                % If a DoNotNotify flag is passed in, set the value silently.
                % Do not throw an event
                notifyValueChanged(this);
            end
        end
                
        function [Zeros,Poles] = getPZ(this,flag)
            %GETPZ  Returns vectors of poles and zeros.
            %
            %  getpz(this) gets poles and zeros of both pzgroups and fixed dynamics
            %  getpz(this,'Tuned') gets poles and zeros of only the pzgroups
            
            if isempty(this.PZGroup)
                Zeros = zeros(0,1);
                Poles = zeros(0,1);
            else
                Zeros = {this.PZGroup(:).Zero};
                Zeros = cat(1,Zeros{:});
                Poles = {this.PZGroup(:).Pole};
                Poles = cat(1,Poles{:});
            end
            
            if ~isempty(this.FixedDynamics) && (nargin == 1)
                Zeros = [Zeros;this.FixedDynamics.z{:}];
                Poles = [Poles;this.FixedDynamics.p{:}];
            end
            
        end
        
        function addPZ(this,Type,Zeros,Poles)
            % Adds new pole/zero group to the TunedZPK.
            
            if isempty(Zeros)
                PZType = 'Pole';
            else
                PZType = 'Zero';
            end
            
            if isAddpzAllowed(this,Type,PZType)
                % Create new PZ group
                NewGroup = ctrlguis.csdesignerapp.data.architectures.internal.(['PZGroup',Type])(this);
                NewGroup.Zero = Zeros(:);
                NewGroup.Pole = Poles(:);
                
                % Add to groups
                if utIsIntOrDiff(NewGroup,this.Ts)
                    % Prevent jumps when integrators or differentiators are deleleted
                    k = this.getZPKGain;
                    this.PZGroup = [this.PZGroup ; NewGroup];
                    this.setZPKGain(k);
                else
                    weakThis = matlab.lang.WeakReference(this);
                    this.PZGroup = [this.PZGroup ; NewGroup];
                    this.PZGroupListeners = [this.PZGroupListeners,...
                                                addlistener(this.PZGroup(end), 'PZDataChanged',... 
                                                            @(es,ed)notifyValueChanged(weakThis.Handle))];
                end
                updateParams(this);
                notifyValueChanged(this);
            else
                ctrlMsgUtils.error('Control:compDesignTask:addPZ');
            end
        end
        
        function deletePZ(this,PZGroup)
            %DELETEPZ  Deletes a new pole/zero group of the TunedZPK
            
            if isDeletepzAllowed(this, PZGroup)
                if isstruct(PZGroup)
                    idx = findPZGroup(this,PZGroup);
                else
                    for ct = 1:numel(this.PZGroup)
                        isel(ct) = (PZGroup == this.PZGroup(ct));
                    end
                    idx = find(isel == 1);
                end
                
                if any(idx)
                    % delete from groups
                    if utIsIntOrDiff(this.PZGroup(idx),this.Ts)
                        % Prevent jumps when integrators or differentiators are deleleted
                        k = this.getZPKGain;
                        delete(this.PZGroup(idx));
                        this.PZGroup = this.PZGroup([1:idx-1,idx+1:end],:);
                        this.setZPKGain(k);
                    else
                        delete(this.PZGroup(idx));
                        this.PZGroup = this.PZGroup([1:idx-1,idx+1:end],:);
                    end
                    updateParams(this)
                    notifyValueChanged(this);
                end
            else
                ctrlMsgUtils.error('Control:compDesignTask:deletePZ');
            end
        end
        
        function idx = findPZGroup(this,PZGroup)
            idx = [];
            TypeIdx = ismember({this.PZGroup.Type},PZGroup.Type);
            if any(TypeIdx)
                for ct = 1:numel(TypeIdx)
                    if isequal(this.PZGroup(ct).Zero,PZGroup.Zero) && ...
                            isequal(this.PZGroup(ct).Pole,PZGroup.Pole)
                        idx = ct;
                        return;
                    end
                end
            end
        end
        
        function Str = describe(this,~)
            % Full description of tuned components.
            
            if this.Ts
                DomainVar = 'z';
            else
                DomainVar = 's';
            end
            
%             if CapitalizeFlag
                Str = sprintf('%s(%s)',this.Identifier,DomainVar);
%             else
                Str = sprintf('%s(%s)',this.Identifier,DomainVar);
%             end
        end
        
        function value = getValue(this)
            value = zpk(this);
        end
        
        %% Gains - ZPK for graphical editor and Formatted for pzeditor
        function Gain = getZPKGain(this, flag)
            Gain = this.Gain * formatfactor(this,'z');
            %             Needed by graphical editor
            if nargin==2 % (Requested only sign of gain)
                if strcmpi(flag(1),'m')
                    Gain = abs(Gain);
                elseif Gain==0
                    Gain = 1;  % beware of compensator set to zero
                else
                    Gain = sign(Gain);
                end
            end
        end
        
        function Gain = getFormattedGain(this)
            %GETGAIN  Gets the formatted gain of the TunedZPKdata.
            %
            %   Gain = getFormattedGain(this)
            %   Gain = getFormattedGain(this,'mag')
            %   Gain = getFormattedGain(this,'sign')
            %
            %   The formatted gain is the ZPK gain divided by the format factor
            %   (see FORMATFACTOR for details).
            
            if strncmpi(this.Format,'z',1)
                Gain = this.getZPKGain;
            else
                Gain = this.Gain * formatfactor(this,'t');
            end
            
            if nargin==2
                if strcmpi(flag(1),'m')
                    % Getting just magnitude
                    Gain = abs(Gain);
                else
                    % Getting just sign
                    Gain = sign(Gain);
                end
            end
        end
        
        function setFormattedGain(this,NewGain,notifyFlag)
            %SETFORMATTEDGAIN  Sets the formatted gain data.
            %
            %   setFormattedGain(this,NewGain)
            
            %
            %   The formatted gain is the ZPK gain divided by the format factor
            %   (see FORMATFACTOR for details).
            
         
            if nargin==2
                notifyFlag = true;
            end
            if strncmpi(this.Format,'z',1)
                setZPKGain_(this,NewGain,[]);
            else
                setTimeConstantGain_(this,NewGain);
            end
            this.updateParams;
            
            if notifyFlag    
                this.notify('GainChanged');
            end
        end
        
        function setTimeConstantGain_(this,NewGain)
            this.Gain = NewGain/formatfactor(this,'t');
        end
        
        function setZPKGain(this,Gain,flag)
            %SETZPKGAIN   Sets ZPK model gain.
            %
            %   SETZPKGAIN(MODEL,GAIN) sets the gain of the ZPK representation of MODEL.
            %   SETZPKGAIN(MODEL,GAIN,'mag') sets the magnitude of the ZPK gain.
            if nargin==2
                flag = [];
            end
            setZPKGain_(this,Gain,flag);
            
            this.updateParams;
            this.notify('GainChanged');
        end
        
        %% NEEDED FOR SRO
        function setGainValue(this, Value, Format)
            %setGainValue   Set gain value for model api param spec
            %
            %   Format = 1 is formatted gain
            %   Format = 2 is invariant gain
            
            %   Copyright 1986-2007 The MathWorks, Inc.
            
            if nargin == 2
                Format = 1;
            end
            
            if isequal(Format, 1)
                this.setFormattedGain(Value, false);
            else
                this.Gain = Value;
                updateParams(this);
            end
            notifyValueChanged(this);
        end
        
        function Gain = getGainValue(this,Format)
            %getGainValue   Get gain value for model api param spec
            %
            %   Format = 1 is formatted gain
            %   Format = 2 is invariant gain
            
            if nargin == 1
                Format = 1;
            end
            
            if isequal(Format, 1)
                Gain = this.getFormattedGain;
            else
                Gain = this.Gain;
            end
        end
        
        function Value = getZPKParameterSpec(this)
            %
            if isempty(this.ZPKParamSpec.GainSpec) || this.ZPKParamSpec.Dirty
                this.ZPKParamSpec.GainSpec = this.createGainSpec;
            end
            
            if this.ZPKParamSpec.Dirty
                this.ZPKParamSpec.PZGroupSpec = this.createPZGroupSpec;
                this.ZPKParamSpec.Dirty = false;
            end
            
            Value = struct('GainSpec',this.ZPKParamSpec.GainSpec, ...
                'PZGroupSpec',this.ZPKParamSpec.PZGroupSpec);
        end
        
        function GainSpec = createGainSpec(this)
            % Create Model API Parameter Spec for the Gain
            
            ParamID = modelpack.CSDParameterID(...
                'Gain', ...
                [1,1], ...
                this.Identifier, ...
                'double', ...
                {''},...
                getString(message('Control:compDesignTask:strGain')));
            GainSpec = modelpack.CSDParameterSpec(ParamID,...
                {getString(message('Control:compDesignTask:strFormatFormatted')),...
                getString(message('Control:compDesignTask:strFormatInvariant'))});
            
            GainSpec.Maximum = inf;
            GainSpec.Minimum = -inf;
            GainSpec.InitialValue = this.getFormattedGain;
            GainSpec.Known = true;
            GainSpec.TypicalValue = this.getFormattedGain;
        end
        
        function PZGroupSpec = createPZGroupSpec(this)
            % Create Model API Parameter Spec for PZGroups
            
            PZG = this.PZGroup;
            
            if length(PZG) == 0
                PZGroupSpec = [];
            else
                for ct = length(PZG):-1:1
                    PZGroupSpec(ct,1) = PZG(ct).getParameterSpec;
                end
            end
        end
        
        function NewValue = convertGainValue(this,Value,OldFormat,NewFormat)
            % convertGainVALUE converts value based on Format used by model api
            %
            % Format = 1; Value = Formatted Gain;
            % Format = 2; Value = Invariant Gain;
            
            if isequal(OldFormat, NewFormat)
                NewValue = Value;
            else
                if OldFormat == 1;
                    %Formatted to Invariant
                    NewValue = Value / this.formatfactor;
                else
                    %Invariant to Formatted
                    NewValue = Value * this.formatfactor;
                end
            end
        end
        %% CONSTRAINTS
        function Constraints = getConstraints(this)
            % REVISIT
            Constraints = this.Constraints;
        end
        
        function boo = isStatic(this)
            % Checks if compensator is static
            boo = isempty(this.PZGroup);
        end
        
        function bool = isTunable(this)
            % isTunable Determines if block is tunable based on constraints and sample
            % time
            
            if isequal(this.Ts, this.TsOrig) || isempty(this.Constraints)
                bool = true;
            else
                Constraints = this.Constraints; %#ok<*PROP>
                if isinf(Constraints.MaxZeros) && isinf(Constraints.MaxPoles) && ...
                        (isempty(this.FixedDynamics) || isstatic(this.FixedDynamics)) || ...
                        (Constraints.MaxZeros == 0) && (Constraints.MaxPoles == 0)
                    bool = true;
                else
                    bool = false;
                end
            end
        end
        
        function b = isAddpzAllowed(this,GroupType,PZType)
            % Checks if adding the pole/zero violates any constraints.
            %
            
            %   Copyright 1986-2007 The MathWorks, Inc.
            
            Constraints = this.Constraints; %#ok<*PROPLC>
            
            if isempty(Constraints)
                b = true;
            else
                [z,p] = getPZ(this);
                CurrentZ = length(z);
                CurrentP = length(p);
                MaxZ = Constraints.MaxZeros;
                MaxP = Constraints.MaxPoles;
                
                switch GroupType
                    case 'Real'
                        if strcmpi(PZType, 'Zero')
                            b = MaxZ > CurrentZ;
                            % check for proper flag
                            if b && (isfield(Constraints,'allowImproper') && ~Constraints.allowImproper)
                                b = CurrentZ < CurrentP;
                            end
                        else
                            b = MaxP > CurrentP;
                        end
                        
                    case 'Complex'
                        if strcmpi(PZType, 'Zero')
                            b = (MaxZ-1) > CurrentZ;
                            % check for proper flag
                            if b && (isfield(Constraints,'allowImproper') && ~Constraints.allowImproper)
                                b = CurrentZ+1 < (CurrentP);
                            end
                        else
                            b = (MaxP-1) > CurrentP;
                        end
                        
                    case {'LeadLag', 'Lead', 'Lag'}
                        if (MaxZ > CurrentZ) && (MaxP > CurrentP)
                            b = true;
                        else
                            b = false;
                        end
                        
                    case 'Notch'
                        if ((MaxZ-1) > CurrentZ) && ((MaxP-1) > CurrentP)
                            b = true;
                        else
                            b = false;
                        end
                        
                end
            end
            
            
            
        end
        
        function bool = isDeletepzAllowed(this, PZGroup)
            if isTunable(this)
                Constraints = this.Constraints;
                if isempty(Constraints) ||  ...
                        ~isfield(Constraints,'allowImproper') || ...
                        (isfield(Constraints,'allowImproper') && Constraints.allowImproper)
                    bool = true;
                else
                    % Check if deletion makes it inproper
                    % only need to check real and complex
                    switch PZGroup.Type
                        case 'Real'
                            if isempty(PZGroup.Pole)
                                bool = true;
                            else
                                [z,p] = getPZ(this);
                                if length(z) < length(p)
                                    bool = true;
                                else
                                    bool = false;
                                end
                            end
                        case 'Complex'
                            if isempty(PZGroup.Pole)
                                bool = true;
                            else
                                [z,p] = getPZ(this);
                                if (length(z)+1) < length(p)
                                    bool = true;
                                else
                                    bool = false;
                                end
                            end
                        otherwise
                            bool = true;
                    end
                end
                
            else
                bool = false;
            end
        end
        
        function bool = isGainBlock(this)
            % Returns true if compensator is pure gain block
            % used by pzeditor
            
            
            for ct=1:length(this)
                bool(ct) = false;
                if isa(this(ct),'ctrlguis.csdesignerapp.data.architectures.internal.TunedLTI') && ~isempty(this(ct).Constraints) ...
                        && (this(ct).Constraints.MaxZeros == 0) && (this(ct).Constraints.MaxPoles == 0)
                    bool(ct) = true;
                end
            end
        end
        
        function b = utIsGainTunable(this)
            % Used to determine if gain is tunable for the TunedZPK
            
            b = false;
            if this.isTunable
                if ~isfield(this.Constraints,'isStaticGainTunable') || ...
                        this.Constraints.isStaticGainTunable
                    b = true;
                end
            end
        end
        
        %% MODEL DATA
        function D = getZPKData(this,NormalizedFlag)
            [Z,P] = getPZ(this);
            if nargin==1
                K = getZPKGain(this);
            else
                K = getZPKGain(this,'sign');
            end
            D = ltipack.zpkdata({Z},{P},K,this.Ts);
        end
        
        function D = getSSData(this,NormalizedFlag)
            if isempty(this.SSData)
                % Recompute normalized state-space model
                [z,p] = getPZ(this);
                [a,b,c,d,e] = zpkreal(z,p,getZPKGain(this,'sign'));
                this.SSData = ltipack.ssdata(a,b,c,d,e,this.Ts);
            end
            D = this.SSData;
            if nargin==1
                % Return SS of model, balance gain across b and c matrices
                g = getZPKGain(this,'mag');
                D.d = D.d * g;
                D.c = D.c * sqrt(g);
                D.b = D.b * sqrt(g);
            end
         end
        
        
        
        function D = zpk(this, NormalizedFlag)
            %ZPK   Get ZPK model of tunable model.
            %
            %   D = ZPK(MODEL) returns the @zpkdata representation of MODEL.
            
            [Z,P] = getPZ(this);
            if nargin==1
                K = getZPKGain(this);
            else
                K = getZPKGain(this,'sign');
            end
            if isempty(Z) || isempty(P)
                D = zpk(Z,P,K, this.Ts);
            else
                D = zpk({Z},{P},K,this.Ts);
            end
            % D = ltipack.zpkdata({Z},{P},K,this.Ts);
            D.Name = this.Name;
        end
        
        function D = ss(this,NormalizedFlag)
            %SS   Get SS model of tunable model.
            %
            %   D = SS(MODEL) returns the @ssdata representation of MODEL.
            %
            %   D = SS(MODEL,'normalized') extracts the normalized @ssdata
            %   representation where the ZPK gain has been replaced by its sign.
            
            
            % Recompute normalized state-space model
            [z,p] = getPZ(this);
            [a,b,c,d,e] = zpkreal(z,p,getZPKGain(this,'sign'));
            D = utCreateLTI(ltipack.ssdata(a,b,c,d,e,this.Ts));
            
            if nargin==1
                % Return SS of model, balance gain across b and c matrices
                g = getZPKGain(this,'mag');
                D.d = D.d * g;
                D.c = D.c * sqrt(g);
                D.b = D.b * sqrt(g);
            end
            D.Name = this.Name;
        end
        
        function updatePZGroups(this,zpkdata)
            % Imports compensator data.
            %
            
            % RE: Two compensator representations are used
            %                                 prod(s-zi)
            %  1) C(s) = sign_r * K_r * s^m * ----------  when FORMAT = 'ZeroPoleGain'
            %                                 prod(s-pj)
            %
            %                                 prod(1-s/zi)
            %  2) C(s) = sign_b * K_b * s^m * ------------  when FORMAT = 'TimeConstant'
            %                                 prod(1-s/pj)
            %
            %                                         prod(1-(z-1)/(zi-1))
            %     (or C(z) = sign_b * K_b * (z-1)^m * --------------------
            %                                         prod(1-(z-1)/(pi-1))
            %
            %  The fields GainSign and GainMag store sign_* and K_*
            
            NewPZGroup = ctrlguis.csdesignerapp.data.architectures.internal.PZGroup.empty;
            
            if isempty(zpkdata)
                % Leave value unchanged except during first import
                if isempty(this.Gain)
                    this.Gain = 1;
                end
            else
                % Importing new value
                z = [zpkdata.z{:}];
                p = [zpkdata.p{:}];
                Ts = abs(zpkdata.Ts);
                
                % Detect notch components
                [z,p,zn,pn] = this.LocalFindNotch(z,p,Ts);
                
                % Real poles and zeros
                pr = p(~imag(p),:);
                zr = z(~imag(z),:);
                
                % Complex poles and zeros
                pc = p(imag(p)>0,:);
                zc = z(imag(z)>0,:);
                              
                              
                % Update PZ groups
                N = 0;
                for ct=1:length(zr)
                   PZG = ctrlguis.csdesignerapp.data.architectures.internal.PZGroupReal(this);
                   PZG.Zero = zr(ct);
                   PZG.Pole = zeros(0,1);
                   NewPZGroup(N+ct,1) = PZG;
                end
                N = N + length(zr);
                for ct=1:length(pr)
                    PZG = ctrlguis.csdesignerapp.data.architectures.internal.PZGroupReal(this);
                    PZG.Zero = zeros(0,1);
                    PZG.Pole = pr(ct);
                    NewPZGroup(N+ct,1) = PZG;
                end
                N = N + length(pr);
                for ct=1:length(zc)
                    PZG = ctrlguis.csdesignerapp.data.architectures.internal.PZGroupComplex(this);
                    PZG.Zero = [zc(ct);conj(zc(ct))];
                    PZG.Pole = zeros(0,1);
                    NewPZGroup(N+ct,1) = PZG;
                end
                N = N + length(zc);
                for ct=1:length(pc)
                    PZG = ctrlguis.csdesignerapp.data.architectures.internal.PZGroupComplex(this);
                    PZG.Zero = zeros(0,1);
                    PZG.Pole = [pc(ct);conj(pc(ct))];
                    NewPZGroup(N+ct,1) = PZG;
                end
                N = N + length(pc);
                for ct=1:size(zn,2)
                    PZG = ctrlguis.csdesignerapp.data.architectures.internal.PZGroupNotch(this);
                    PZG.Zero = zn(:,ct);
                    PZG.Pole = pn(:,ct);
                    NewPZGroup(N+ct,1) = PZG;
                end
            end
            this.PZGroup = NewPZGroup;
        end
        
        %% LOAD/SAVE
        function S = saveSession(this)
            PZG = repmat(struct('Type',[],'Zero',[],'Pole',[]),0,1);
            for ct = 1:numel(this.PZGroup)
                PZG(ct) = save(this.PZGroup(ct));
            end
            
            S = struct(...
                'Name', this.Name, ...
                'Identifier', this.Identifier, ...
                'Ts', this.Ts, ...
                'TsOrig', this.TsOrig,...
                'Format', this.Format, ...
                'Par2ZPKFcn', this.Par2ZpkFcn, ...
                'ZPK2ParFcn', this.ZPK2ParFcn, ...
                'MaskParamSpec', this.MaskParamSpec, ...
                'Path', this.Path, ...
                'C2DMethod', this.C2DMethod, ...
                'D2CMethod', this.D2CMethod, ...
                'Constraints', this.Constraints, ...
                'FixedDynamics', this.FixedDynamics, ...
                'Parameters', this.Parameters, ...
                'PZGroup', PZG, ...
                'ZPKGain', this.getZPKGain,...
                'Value',getValue(this));
        end
        
        function loadSession(this,S)
            if isvalid(this) && isequal(S.Ts, this.Ts)
                % Only load if the block is still valid and if the Ts of
                % saved block matches Ts of current block value (required
                % for undo/redo)
                if isempty(S.PZGroup) && ~isstruct(S.PZGroup)
                    % The block has never been initialized - coming from
                    % sisoinit
                    loadSession@ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock(this,S);
                    if isnumeric(S.Value)
                        S.Value = ss(S.Value);
                    end
                    this.Ts = S.Value.Ts;
                    if isempty(S.Value.Name)
                        S.Value.Name = S.Name;
                    end
                    setValue(this,S.Value);
                else
                    % Redo the PZGroups to preserve lead lags
                    for ct = 1:numel(this.PZGroup)
                        delete(this.PZGroup(ct));
                    end
                    this.PZGroup =  [];
                    if ~isempty(S.PZGroup)
                        PZGroupTemp = [];
                        for ct = 1:numel(S.PZGroup)
                            PZGroupTemp = [PZGroupTemp; ...
                                ctrlguis.csdesignerapp.data.architectures.internal.(['PZGroup',S.PZGroup(ct).Type])(this)];
                            PZGroupTemp(end).Zero = S.PZGroup(ct).Zero(:);
                            PZGroupTemp(end).Pole = S.PZGroup(ct).Pole(:);
                        end
                        this.PZGroup = PZGroupTemp;
                    end
                    
                    this.FixedDynamics = S.FixedDynamics;
                    this.setZPKGain_(S.ZPKGain,[]);
                    this.Parameters = S.Parameters;
                    this.updateParams;
                    this.Name = S.Name;
                    this.Ts = S.Ts;
                    this.TsOrig = S.TsOrig;
                    notifyValueChanged(this)
                end
            end
        end

        function nominalIndex = getNominalIndex(this)
            nominalIndex = 1;
        end
    end
    
    %% Set/Get methods
    methods
        function set.PZGroup(this, Value)
            this.PZGroup = Value;
            % Make dirty PZGROUPSpec
            resetZPKParameterSpec(this);
            resetPZGroupListeners(this);
        end
    end
    
    %% Protected Methods
    methods (Access = protected)
        function resetPZGroupListeners(this)
            delete(this.PZGroupListeners)
            this.PZGroupListeners = event.listener.empty;
            weakThis = matlab.lang.WeakReference(this);
            for ct =1:length(this.PZGroup)
                this.PZGroupListeners(ct) = event.listener(this.PZGroup,'PZDataChanged',@(es,ed) cbPZGroupChanged(weakThis.Handle));
            end
           
        end
        
        function cbPZGroupChanged(this)
            updateParams(this)
%             notifyValueChanged(this)
        end
        
        function resetZPKParameterSpec(this)
            this.ZPKParamSpec.Dirty = true;
        end
        
        function setZPKGain_(this,Gain,Flag) 
            TunedGain = Gain/formatfactor(this,'z');
            
            if isempty(Flag)
                this.Gain = TunedGain;
            else
                if this.Gain==0
                    GainSign = 1;
                else
                    GainSign = sign(this.Gain);
                end
                this.Gain = GainSign*abs(TunedGain);
            end
        end
    end
    
    methods (Static = true)
        %%%%%%%%%%%%%%%%%%
        % LocalFindNotch %
        %%%%%%%%%%%%%%%%%%
        function [z,p,zn,pn] = LocalFindNotch(z,p,Ts)
            % Detects notch filters in imported compensator
            NearTol = sqrt(eps);
            nz = length(z);
            np = length(p);
            
            % Get natural freq. and damping
            [wz,zetaz] = damp(z,Ts);
            [wp,zetap] = damp(p,Ts);
            
            % Sort Wn
            zeta = [zetaz;zetap];
            idx = [1:nz,nz+1:nz+np]';
            [wn,is] = sort([wz;wp]);
            idx = idx(is,:);
            zeta = zeta(is,:);
            
            % Find isolated groups of four roots with same wn
            nr = nz+np;
            delta = [(abs(wn(2:nr,:)-wn(1:nr-1,:))<NearTol*wn(1:nr-1,:));0];
            isNotchSeed = ...
                [delta(1:nr-3,:) & delta(2:nr-2,:) & delta(3:nr-1,:) & ~delta(4:nr,:) ; zeros(3,1)];
            
            % Such groups with two poles and two zeros qualify as notches
            isZero = (idx<=nz);
            isPole = (idx>nz);
            isPZPair = (filter([1 1 1 1],[1 0 0 0],isZero)==2 & ...
                filter([1 1 1 1],[1 0 0 0],isPole)==2);
            isNotchSeed = isNotchSeed & [isPZPair(4:nr,:);zeros(3,1)];
            
            % Check compatibility of damping (|zetaz|<|zetap|)
            for k=find(isNotchSeed)',
                zetaz = zeta(k-1+find(isZero(k:k+3)));
                zetap = zeta(k-1+find(isPole(k:k+3)));
                isNotchSeed(k) = (abs(zetaz(1))<=abs(zetap(1)));
            end
            
            % Extract notches
            idxn = find(isNotchSeed);
            zn = zeros(2,length(idxn));
            pn = zeros(2,length(idxn));
            for ct=1:length(idxn),
                % Position of notch poles and zeros in Z and P
                k = idxn(ct);
                idxz = idx(k-1+find(isZero(k:k+3)));
                idxp = idx(k-1+find(isPole(k:k+3)))-nz;
                % Extract notch
                zk = z(idxz(1));
                pk = p(idxp(1));
                zn(:,ct) = real(zk) + [1i;-1i] * abs(imag(zk));
                pn(:,ct) = real(pk) + [1i;-1i] * abs(imag(pk));
            end
            
            % Delete notch roots from Z and P
            isNotch = zeros(nr,1);
            isNotch([idxn;idxn+1;idxn+2;idxn+3],:) = 1;
            z(idx(isZero & isNotch),:) = [];
            p(idx(isPole & isNotch)-nz,:) = [];
        end
    end
    
    methods (Hidden = true)
        function Data = getData(this)
           Data = this.Data_;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%
% LocalCheckCompensatorModelData  %
%%%%%%%%%%%%%%%%%%%%%%%
function sys = LocalCheckCompensatorModelData(sys,Component)
% Checks model data for plant, sensor, prefilter, and compensator.

% Check model class
if isa(sys,'frd')
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck02',Component)
elseif ~isreal(sys)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck03',Component)
elseif isa(sys,'idlti')
   % SITB support
   % Check the number of inputs to the model
   nu = size(sys,'nu');
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

% Check for delays
if hasdelay(sys),
   if sys.Ts,
      % Map delay times to poles at z=0 in discrete-time case
      sys = delay2z(sys);
   else
      ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck14',Component)
   end
end

% Check dimensions
sizes = size(sys);
if prod(sizes(3:end))~=1
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck05')
elseif any(sizes~=1)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck06',Component)
end

% Convert to zpk
sw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>
sys = zpk(sys);
delete(sw);
end
