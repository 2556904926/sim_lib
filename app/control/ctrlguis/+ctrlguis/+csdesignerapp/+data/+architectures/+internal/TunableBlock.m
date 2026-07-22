classdef TunableBlock < ctrlguis.csdesignerapp.data.architectures.internal.Block & matlab.mixin.Copyable
    % TunableBlock  Class for managing tuned block data
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    properties (Dependent = true, SetObservable = true)
        Name        % Name from blockconfig/ hard-coded name
    end
    
    properties
        Ts
         TsOrig
        C2DMethod
        D2CMethod
        MaskParamSpec       % Needed by response optimization
    end
    properties(Access = protected)
        Identifier
        Path
        Description
        
       
        
%         Format = 'zeropolegain';
        Format = 'TimeConstant1';
        Listeners
        
        Par2ZpkFcn
        Parameters
        ZPKParamSpec = struct('GainSpec',[],'PZGroupSpec',[],'Dirty',true);
    end
    
    properties(Access = protected)
        Data_
        SSData  % Normalized state-space data (cached)
        RefreshMode

    end
    

    
    methods 
        %% Constructor
        function this = TunableBlock(ID, sys)
            this.Identifier = ID;
            % REVISIT- do we want to cache Data_?
            this.Data_ = LocalCheckCompensatorModelData(sys,ID);
        end
        
        % Listener notification
        function notifyValueChanged(this)
            this.SSData = [];
            this.ZPKParamSpec.Dirty = true;
            this.notify('ValueChanged');
        end
        
        %% Utilities
        function [ny,nu] = iosize(this)
            [ny, nu] = iosize(this.Data_);
            if nargout==1
                ny = [ny nu];
            end
        end
        
        function setRefreshMode(this,Mode)
            if ~strcmpi(this.RefreshMode,Mode)
                this.RefreshMode = Mode;
                ED = ctrluis.toolstrip.dataprocessing.GenericEventData(Mode);
                this.notify('RefreshModeChanged',ED);
            end
        end
        
        function Ts = getTs(this)
            Value = getValue(this);
            Ts = Value.Ts;
        end
        
        function Value = getValue(this)
            Value = this.Data_;
        end

        function Format = getFormat(this)
            Format = this.Format;
        end
        
        function Format = setFormat(this,Format)
            this.Format = Format;
        end

        function [NumStr, DenStr] = getDisplayString(this)
            % getDisplayString  This function generates the strings for the numerator
            % and denominator for displaying the compensator in the pzeditor panel and
            % automated tuning panel
            
            % get format and ts
            Format = this.Format;
            Ts = getTs(this);
            % Get ZPK data
            D = zpk(this);
            Z = D.z{1};
            P = D.p{1};
            
            % if pure gain, don't show num and den
            if isempty(Z) && isempty(P)
                % Pure gain
                NumStr = '';
                DenStr = '';
            else
                % Generate num,den strings
                NumStr = this.LocalFormat(Z,Ts,Format);
                DenStr = this.LocalFormat(P,Ts,Format);
            end
        end
        
        %% Name, Identifier and Path
        function Name = get.Name(this)
            % Return name of Tuned Block
            Name = this.Data_.Name;
        end
        
        function set.Name(this,Name)
            % Set name of Tuned Block
            this.Data_.Name = Name;
        end
        
        function Name = getIdentifier(this)
            Name = cell(0,1);
            for ct = 1:numel(this)
                % Return name of Tuned Block
                Name = [Name; {this(ct).Identifier}];
            end
            if numel(this) == 1
                Name = Name{1,:};
            end
        end
        
        function setIdentifier(this,Name)
            % Set name of Tuned Block
            this.Identifier = Name;
        end
        
        function Path = getPath(this)
            Path = this.Path;
        end
        
        function setPath(this,Path)
            this.Path = Path;
        end
        
               
        %% Parameter related methods required by SDO
        function Params = getParameters(this)
            Params = this.Parameters;
        end
        
        function setParameterValue(this,idx,Value)
            CurrentValue = this.Parameters(idx).Value;
            this.Parameters(idx).Value = Value;
            try
                updateZPK(this);
            catch
                this.Parameters(idx).Value = CurrentValue;
            end
            notifyValueChanged(this)
        end
        
        function MaskParamSpec = getMaskParameterSpec(this)
            % GETMASKPARAMETERSPECS  method to return any mask parameter specs for the
            % tuned block
            
            if numel(this.Parameters) == 0
                %Quick exit as no parameters
                MaskParamSpec = [];
                return
            end
            
            %Find tunable mask parameters
            InPars     = this.Parameters;
            idxTunable = strcmp({InPars.Tunable},'on');
            idxNumeric = cellfun(@isnumeric,{InPars.Value});
            InPars     = InPars(idxTunable & idxNumeric);
            if isempty(InPars)
                %Quick exit as no tunable numeric parameters
                MaskParamSpec = [];
                return
            end
            
            %Check for known parameters
            MaskParamSpec = this.MaskParamSpec;
            if ~isempty(MaskParamSpec)
                KnowID       = MaskParamSpec.getID;
                KnownNames   = KnowID.getFullName;
            else
                KnownNames   = cell(0,1);
            end
            
            for ct_P = 1:numel(InPars)
                %Check if already have a Spec for the parameter
                FullName = sprintf('%s:%s',this.Identifier,InPars(ct_P).Name);
                if ~isempty(KnownNames)
                    idxMask = strcmp(KnownNames,FullName);
                else
                    idxMask = false;
                end
                NewDim = size(InPars(ct_P).Value);
                if ~any(idxMask)
                    %Need to create a new parameter spec
                    PID = modelpack.CSDParameterID(...
                        sprintf('%s (mask)',InPars(ct_P).Name), ...
                        NewDim, ...
                        this.Identifier, ...
                        'double', ...
                        {''}, ...
                        InPars(ct_P).Name);
                    idxMask = numel(MaskParamSpec)+1;
                    if isempty(MaskParamSpec)
                        %First Spec
                        MaskParamSpec = modelpack.CSDParameterSpec(PID);
                    else
                        MaskParamSpec(idxMask,1) = modelpack.CSDParameterSpec(PID);
                    end
                else
                    %Check that dimensions are up to date
                    pID = MaskParamSpec(idxMask,1).getID;
                    OldDim = pID.getDimensions;
                    if ~isequal(OldDim,NewDim)
                        pID.update([],'Dimension',NewDim)
                        MaskParamSpec(idxMask,1).setDimensions(NewDim);
                    end
                end
                % Update initial, typical, max and min  values
                MaskParamSpec(idxMask,1).InitialValue = InPars(ct_P).Value;
                MaskParamSpec(idxMask,1).Known        = true(NewDim);
                MaskParamSpec(idxMask,1).Minimum      = -inf(NewDim);
                MaskParamSpec(idxMask,1).Maximum      = inf(NewDim);
                MaskParamSpec(idxMask,1).TypicalValue = ones(NewDim);
            end
            
            %Store mask parameters
            this.MaskParamSpec = MaskParamSpec(1:numel(InPars));
        end
        
        function NewValue = convertValue(this,Value,OldFormat,NewFormat,units)
            % REVISIT
            NewValue = Value;
        end

        
        %% Display preview text
        function DisplayText = getDisplayPreviewText(this)
            DisplayText = [ ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('type', ...
                getString(message(['Control:designerapp:DisplayTunableBlock']))), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayName')),this.Name), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayTs')),this.Ts), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayValue')), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayBlock(this)), ...
                ];
        end
        
        %% Name
        function Name = getName(this)
            Name = this.Name;
        end
        
        %% Load/Save
        function loadSession(this,TB)
            this.Data_ = LocalCheckCompensatorModelData(TB.Value,TB.Identifier); 
        end
    end
    
    methods (Access = protected)
        function FF = formatfactor(this,TargetFormat)
            %FORMATFACTOR  Computes format factor.
            %
            %   FF = FORMATFACTOR(TunedBlock) computes the format factor FF that links
            %   the invariant gain to the formatted gain and ZPK model gain:
            %   TargetForamt: zpk
            %           ZPK Gain = FF * Invariant Gain
            %   TargetFormat: time-constant
            %           TC Gaing = FF * Invariant Gain
            %
            %   FF = FORMATFACTOR(TunedBlock,FORMAT) computes the format factor FF for
            %   the specified format.
            
            %   Author(s): P. Gahinet
            %   Copyright 1986-2012 The MathWorks, Inc.
            
            if nargin==1
                TargetFormat = this.Format;
            end
            
            Ts = this.Ts;
            
            % Initialize settings based on sample time
            if isequal(Ts,0) %#ok<*PROPLC>
                % Continuous
                InvariantFreq = 1e-6;
                sz = 1j*InvariantFreq;
            else
                % Discrete
                InvariantFreq = 1e-6/Ts*pi; % 1e-6 * Nyquist freq in rad/s
                sz = exp(1j*InvariantFreq*Ts);
            end
            
            % Get pole/zero data
            [Z,P] = getPZ(this);
            
            % Factor
            
            Factor = abs( prod(sz-P(:)) / prod(sz-Z(Z~=sz,:)));
            
            switch lower(TargetFormat(1))
                case 't'
                    % Time constant formats
                    if ~isequal(Ts,0), % discrete
                        P = P-1;   Z = Z-1;
                    end
                    FF = abs(Factor * real(prod(-Z(Z~=0,:)))/prod(-P(P~=0,:)));
                    if ~isequal(Ts,0), % discrete
                        NumDiff =  (numel(find(Z==0))-numel(find(P==0)));
                        if NumDiff~=0
                            FF = FF * Ts^NumDiff;
                        end
                    end
                    
                case 'z'
                    % Zero-pole-gain format
                    if ~isequal(Ts,0), % discrete
                        P = P-1;   Z = Z-1;
                    end
                    FF = Factor * sign(real(prod(-Z(Z~=0,:))/prod(-P(P~=0,:))));
            end
            
            
        end
        

    end
    
    methods (Static = true)
        function EventName = getDataChangedEventName()
            EventName = 'ValueChanged';
        end
        
        function str = LocalFormat(P,Ts,Format)
            % Formats display
            Format = lower(Format);
            
            % Defaults
            str = '';
            if Ts == 0
                Var = 's';
            elseif strcmp(Format(1), 'z')
                % ZeroPoleGain format
                Var = 'z';
            else
                Var = 'w';
                P = (P-1)/Ts;  % Equivalent s-domain root is (z-1)/Ts
            end
            
            % Sort roots
            P = [P(~imag(P),:) ; P(imag(P)>0,:)];
            
            % Put roots at the origin (s=0 or z=1) upfront
            if strcmp(Var,'z')
                indint = find(P==1);
            else
                indint = find(P==0);
            end
            nint = length(indint);
            P(indint,:) = [];
            switch Var
                case {'s','w'}
                    if nint>1
                        str = sprintf('%s^%d',Var,nint);
                    elseif nint==1
                        str = Var;
                    end
                case 'z'
                    if nint>1
                        str = sprintf('(z-1)^%d',nint);
                    elseif nint==1
                        str = sprintf('(z-1)');
                    end
            end
            
            % Loop over remaining roots
            Signs = {'+','-'};
            switch Format
                case 'zeropolegain'  % zero/pole/gain
                    for ct = 1:length(P)
                        Pct = P(ct);
                        SignType = Signs{1+(real(Pct)>0)};
                        if ~imag(Pct),
                            if real(Pct)
                                NextStr = sprintf('(%s %s %0.3g)',Var,SignType,abs(real(Pct)));
                            else
                                NextStr = Var;
                            end
                        else
                            if real(Pct)
                                NextStr = sprintf('(%s^2 %s %0.3g%s + %0.3g)',Var,SignType,...
                                    2*abs(real(Pct)),Var,(real(Pct)^2+imag(Pct)^2));
                            else
                                NextStr = sprintf('(%s^2 + %0.3g)',Var,real(Pct)^2+imag(Pct)^2);
                            end
                        end
                        str = sprintf('%s %s',str,NextStr);
                    end
                    
                case 'timeconstant1'  % time constant 1, i.e., (1 + Tp s)
                    for ct = 1:length(P)
                        Pct = P(ct);
                        SignType = Signs{1+(real(Pct)>0)};
                        if ~imag(Pct),
                            % Real root
                            rp = 1/abs(real(Pct));
                            if rp==1,
                                NextStr = sprintf('(1 %s %s)',SignType,Var);
                            else
                                NextStr = sprintf('(1 %s %0.2g%s)',SignType,rp,Var);
                            end
                        elseif real(Pct)
                            % Complex root with nonzero real part
                            w = abs(Pct);
                            rp = 2*abs(real(Pct))/w^2;
                            if w==1,
                                NextStr = sprintf('(1 %s %0.2g%s + %s^2)',SignType,rp,Var,Var);
                            else
                                NextStr = sprintf('(1 %s %0.2g%s + (%0.2g%s)^2)',SignType,rp,Var,1/w,Var);
                            end
                        else
                            % Root j*b
                            NextStr = sprintf('(1 + (%0.2g%s)^2)',1/abs(Pct),Var);
                        end
                        str = sprintf('%s %s',str,NextStr);
                    end
                    
                case 'timeconstant2'  % time constant 2 (natural frequency), i.e., (1 + s/p)
                    for ct = 1:length(P)
                        Pct = P(ct);
                        SignType = Signs{1 + (real(Pct)>0)};
                        if ~imag(Pct)
                            % Real root
                            rp = abs(real(Pct));
                            if rp == 1,
                                NextStr = sprintf('(1 %s %s)', SignType, Var);
                            else
                                NextStr = sprintf('(1 %s %s/%0.2g)', SignType, Var, rp);
                            end
                        elseif real(Pct)
                            % Complex root with nonzero real part
                            wn = sqrt(real(Pct)^2 + imag(Pct)^2);
                            rp = 2 * abs(real(Pct)) / wn;
                            if wn == 1
                                NextStr = sprintf('(1 %s %0.2g%s + %s^2)', ...
                                    SignType, rp, Var, Var);
                            else
                                NextStr = sprintf('(1 %s %0.2g%s/%0.2g + (%s/%0.2g)^2)', ...
                                    SignType, rp, Var, wn, Var, wn);
                            end
                        else
                            % Complex root with zero real part (root j*b)
                            NextStr = sprintf('(1 + (%s/%0.2g)^2)', Var, abs(Pct));
                        end
                        str = sprintf('%s %s', str, NextStr);
                    end
                    
            end
            
            % Set string to 1 if no root
            if isempty(str)
                str = '1';
            end
            
        end
    end
    
    methods (Abstract = true)
        [p,z] = getPZ(this);
    end
    
    events
        GainChanged
        ValueChanged
        ConstraintsChanged
        RefreshModeChanged
    end
end

%%%%%%%%%%%%%%%%%%%%%%%
% LocalCheckCompensatorModelData %
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
%% Things that the tuned block needs to provide

% 1. Add a pzgroup addPZ
% 2. Modify a pzgroup
% 3. Delete a pzgroup deletePZ
% 4. Provide a description for each PZGroup C.PZGroup(isel).describe(Ts);
