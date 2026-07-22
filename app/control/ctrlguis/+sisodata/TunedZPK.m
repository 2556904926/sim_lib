classdef (CaseInsensitiveProperties) TunedZPK < sisodata.TunedBlock
%sisodata.TunedZPK class
%   sisodata.TunedZPK extends sisodata.TunedBlock.
%

%    sisodata.TunedZPK properties:
%       Name - Property is of type 'ustring'  
%       Identifier - Property is of type 'string'  
%       Description - Property is of type 'ustring'  
%       Format - Property is of type 'string'  
%       Ts - Property is of type 'double'  
%       TsOrig - Property is of type 'double'  
%       MaskParamSpec - Property is of type 'MATLAB array'  
%       Parameters - Property is of type 'MATLAB array'  
%       SSData - Property is of type 'MATLAB array'  
%       Par2ZpkFcn - Property is of type 'MATLAB array'  
%       C2DMethod - Property is of type 'MATLAB array'  
%       D2CMethod - Property is of type 'MATLAB array'  
%       AuxData - Property is of type 'MATLAB array'  
%       Constraints - Property is of type 'MATLAB array'  
%       ZPK2ParFcn - Property is of type 'MATLAB array'  
%       Gain - Property is of type 'MATLAB array'  
%       PZGroup - Property is of type 'handle vector'  
%       Variable - Property is of type 'ustring'  
%       FixedDynamics - Property is of type 'MATLAB array'  
%       Listeners - Property is of type 'MATLAB array'  
%
%    sisodata.TunedZPK methods:
%       addListeners -  add listeners to keep parameters and zpk in sync
%       addPZ -  Adds new pole/zero group to the TunedZPK.
%       convertGainValue - converts value based on Format used by model api
%       createGainSpec -  Create Model API Parameter Spec for the Gain
%       createPZGroupSpec -  Create Model API Parameter Spec for PZGroups
%       deletePZ -  Deletes a new pole/zero group of the TunedZPK
%       describe -  Full description of tuned components.
%       getFormattedGain - GETGAIN  Gets the formatted gain of the TunedZPKdata.
%       getGainValue -   Get gain value for model api param spec
%       getPZ -  Returns vectors of poles and zeros.
%       getZPKGain -   Get ZPK model gain.
%       import -  compensator data.
%       isAddpzAllowed -  Checks if adding the pole/zero violates any constraints.
%       isDeletePZAllowed - ISDELTEPZALLOWED  checks if a pzgroup can be deleted from the compensator.
%       isStatic -  Checks if compensator is static
%       isTunable - Determines if block is tunable based on constraints and sample
%       reset -  Cleans up dependent data when core data changes.
%       save -   Creates backup of compensator data.
%       setFormattedGain -  Sets the formatted gain data.
%       setGainValue -   Set gain value for model api param spec
%       setParameterValue - set parameter value of the idx parameter and updates zpk
%       setParameters -  setPARAMS set parameters and updates zpk representation
%       setZPKGain -   Sets ZPK model gain.
%       ss -   Get SS model of tunable model.
%       updatePZGroups -  Imports compensator data.
%       updateParams - Calculates the parameters from the zpk representation
%       updateZPK - Calculates the zpk representation from the parameters
%       utIsGainTunable -  Used to determine if gain is tunable for the TunedZPK
%       zpk -   Get ZPK model of tunable model.


properties (Access=protected, SetObservable)
    %ZPKPARAMSPEC Property is of type 'MATLAB array' 
    ZPKParamSpec = struct( 'GainSpec', [], 'PZGroupSpec', [], 'Dirty', true );
end

properties (SetObservable)
    %CONSTRAINTS Property is of type 'MATLAB array' 
    Constraints = [];
    %ZPK2PARFCN Property is of type 'MATLAB array' 
    ZPK2ParFcn = [];
    %GAIN Property is of type 'MATLAB array' 
    Gain = [];
    %PZGROUP Property is of type 'handle vector' 
    PZGroup = [];
    %VARIABLE Property is of type 'ustring' 
    Variable = '';
    %FIXEDDYNAMICS Property is of type 'MATLAB array' 
    FixedDynamics = [];
    %LISTENERS Property is of type 'MATLAB array' 
    Listeners = [];
end


    methods 
        function set.PZGroup(obj,value)
            % DataType = 'handle vector'
        if ~isempty(value)
           validateattributes(value,{'handle'}, {'vector'},'','PZGroup')
        end
        obj.PZGroup = value;
        end

        function set.Variable(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Variable = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addListeners(this, LoopData)
       % add listeners to keep parameters and zpk in sync
       
       
       L = addlistener(this,'PZGroup','PostSet', @(es,ed) LocalPZGroupChanged(this));
       this.Listeners.PZGroup = L;
       end  % addListeners
       
       
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%
       %%% LocalPZGroupChanged %%%
       %%%%%%%%%%%%%%%%%%%%%%%%%%%

        %----------------------------------------
       function addPZ(this,Type,Zeros,Poles)
       % Adds new pole/zero group to the TunedZPK.
       %
       
       
       if isempty(Zeros)
           PZType = 'Pole';
       else
           PZType = 'Zero';
       end
       
       if isAddpzAllowed(this,Type,PZType)
           % Create new PZ group
           NewGroup = sisodata.(['PZGroup',Type])(this);
           set(NewGroup,'Zero',Zeros(:),'Pole',Poles(:));
       
           % Add to groups
           if utIsIntOrDiff(NewGroup,this.Ts)
               % Prevent jumps when integrators or differentiators are deleleted
               k = this.getZPKGain;
               this.PZGroup = [this.PZGroup ; NewGroup];
               this.setZPKGain(k);
           else
               this.PZGroup = [this.PZGroup ; NewGroup];
           end
       else
           ctrlMsgUtils.error('Control:compDesignTask:addPZ')
       end
       end  % addPZ
       
        %----------------------------------------
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
       end  % convertGainValue
       
        %----------------------------------------
       function GainSpec = createGainSpec(this)
       % Create Model API Parameter Spec for the Gain
       
       
         
       PID = modelpack.STParameterID(...
           'Gain', ...
           [1,1], ...
           this.Identifier, ...
           'double', ...
           {''},...
           getString(message('Control:compDesignTask:strGain')));
       GainSpec = modelpack.STParameterSpec(PID,...
           {getString(message('Control:compDesignTask:strFormatFormatted')),...
            getString(message('Control:compDesignTask:strFormatInvariant'))});
           
       GainSpec.Maximum = inf;
       GainSpec.Minimum = -inf;
       GainSpec.InitialValue = this.getFormattedGain;
       GainSpec.Known = true;
       GainSpec.TypicalValue = this.getFormattedGain;
           
           
           
           
           
       end  % createGainSpec
       
        %----------------------------------------
       function PZGroupSpec = createPZGroupSpec(this)
       % Create Model API Parameter Spec for PZGroups
       
         
       PZGroup = this.PZGroup;
       
       if length(PZGroup) == 0
           PZGroupSpec = [];
       else
       
           for ct = length(PZGroup):-1:1
               PZGroupSpec(ct,1) = PZGroup(ct).getParameterSpec;
           end
       
       end
       
       
       end  % createPZGroupSpec
       
        %----------------------------------------
       function deletePZ(this,PZGroup)
       %DELETEPZ  Deletes a new pole/zero group of the TunedZPK
       
       %   Author(s): C. Buhr
       
       if isDeletePZAllowed(this, PZGroup)
           isel = find(PZGroup == this.PZGroup);
           
           % delete from groups
           if utIsIntOrDiff(PZGroup,this.Ts) 
               % Prevent jumps when integrators or differentiators are deleleted
               k = this.getZPKGain;
               delete(this.PZGroup(isel));
               this.PZGroup = this.PZGroup([1:isel-1,isel+1:end],:);
               this.setZPKGain(k);
           else
               delete(this.PZGroup(isel));
               this.PZGroup = this.PZGroup([1:isel-1,isel+1:end],:);
           end
       else 
               ctrlMsgUtils.error('Control:compDesignTask:deletePZ')
       end
       end  % deletePZ
       
        %----------------------------------------
       function Str = describe(this,CapitalizeFlag)
       % Full description of tuned components.
       
       %   Author(s): P. Gahinet
       if this.Ts
           DomainVar = 'z';
       else
           DomainVar = 's';
       end
       
       if CapitalizeFlag
          Str = sprintf('%s %s(%s)',this.Name,this.Identifier,DomainVar);
       else
          Str = sprintf('%s %s(%s)',lower(this.Name),this.Identifier,DomainVar);
       end   
       
       end  % describe
       
        %----------------------------------------
       function Gain = getFormattedGain(this,flag)
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
       end  % getFormattedGain
       
        %----------------------------------------
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
       
       end  % getGainValue
       
        %----------------------------------------
       function [Zeros,Poles] = getPZ(this,flag)
       %GETPZ  Returns vectors of poles and zeros.
       % 
       %  getpz(this) gets poles and zeros of both pzgroups and fixed dynamics
       %  getpz(this,'Tuned') gets poles and zeros of only the pzgroups
       
       %   Author(s): P. Gahinet
       
       
       if isempty(this.PZGroup)
           Zeros = zeros(0,1);
           Poles = zeros(0,1);
       else
           Zeros = get(this.PZGroup,{'Zero'});
           Zeros = cat(1,Zeros{:});
           Poles = get(this.PZGroup,{'Pole'});    
           Poles = cat(1,Poles{:});
       end
       
       if ~isempty(this.FixedDynamics) && (nargin == 1)
           Zeros = [Zeros;this.FixedDynamics.z{:}];
           Poles = [Poles;this.FixedDynamics.p{:}];
       end
       end  % getPZ
       
        %----------------------------------------
       function Gain = getZPKGain(this,flag)
       %GETZPKGAIN   Get ZPK model gain.
       %
       %   GAIN = GETZPKGAIN(MODEL) computes the gain of the ZPK representation of MODEL.
       %   GAIN = GETZPKGAIN(MODEL,'sign') computes the sign of the ZPK gain.
       %   GAIN = GETZPKGAIN(MODEL,'mag') computes the magnitude of the ZPK gain.
       
       %   Author(s): P. Gahinet
       
       % Convert gain to zpk format
       Gain = this.Gain * formatfactor(this,'z');
       
       if nargin==2
          if strcmpi(flag(1),'m')
             Gain = abs(Gain);
          elseif Gain==0
             Gain = 1;  % beware of compensator set to zero
          else
             Gain = sign(Gain);
          end
       end
       end  % getZPKGain
       
        %----------------------------------------
       function import(this,TunedZPKSnapshot)
       % Imports compensator data.
       %
       
       
       
       utRestoreTunedZPK(TunedZPKSnapshot,this);
       
       % After importing compensator data make the parameterspec dirty
       this.resetZPKParameterSpec;
       
       
       end  % import
       
        %----------------------------------------
       function b = isAddpzAllowed(this,GroupType,PZType)
       % Checks if adding the pole/zero violates any constraints.
       %
       
       
       Constraints = this.Constraints;
       
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
       
       
       
       end  % isAddpzAllowed
       
        %----------------------------------------
       function bool = isDeletePZAllowed(this,PZGroup)
       %ISDELTEPZALLOWED  checks if a pzgroup can be deleted from the compensator.
       
       %   Author(s): C. Buhr
       
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
       
       
       
       end  % isDeletePZAllowed
       
        %----------------------------------------
       function boo = isStatic(this)
       % Checks if compensator is static
       
       boo = isempty(this.PZGroup);
       end  % isStatic
       
        %----------------------------------------
       function bool = isTunable(this)
       % isTunable Determines if block is tunable based on constraints and sample
       % time
       
       
       if isequal(this.TsOrig, this.Ts) || isempty(this.Constraints)
           bool = true;
       else
           Constraints = this.Constraints;
           if isinf(Constraints.MaxZeros) && isinf(Constraints.MaxPoles) && ...
                   (isempty(this.FixedDynamics) || isstatic(this.FixedDynamics)) || ...
                    (Constraints.MaxZeros == 0) && (Constraints.MaxPoles == 0)
               bool = true;
           else
               bool = false;
           end
       end
       end  % isTunable
       
        %----------------------------------------
       function reset(this,Scope)
       % Cleans up dependent data when core data changes.
       %
       %   RESET(this,'all')
       %   RESET(this,'gain')
       
       
       switch Scope
          case 'all'
              this.SSData.d = [];
              this.updateParams;
              
          case 'gain'
              this.updateParams;
       end
       end  % reset
       
        %----------------------------------------
       function Design = save(this,Design)
       %SAVE   Creates backup of compensator data.
       
       
       if nargin == 1
           Design = sisodata.TunedZPKSnapshot;
       end
       
       Design = utStoreTunedZPK(Design,this);
       end  % save
       
        %----------------------------------------
       function setFormattedGain(this,NewValue)
       %SETFORMATTEDGAIN  Sets the formatted gain data.
       %
       %   setFormattedGain(this,NewGain)
       
       %
       %   The formatted gain is the ZPK gain divided by the format factor 
       %   (see FORMATFACTOR for details).
       
       
       if strncmpi(this.Format,'z',1)
           this.setZPKGain(NewValue);
       else
           this.Gain = NewValue/formatfactor(this,'t');
       end
       
       
       end  % setFormattedGain
       
        %----------------------------------------
       function setGainValue(this, Value, Format)
       %setGainValue   Set gain value for model api param spec
       %
       %   Format = 1 is formatted gain
       %   Format = 2 is invariant gain
       
       
       if nargin == 2
           Format = 1;
       end
       
       if isequal(Format, 1)
           this.setFormattedGain(Value);
       else
           this.Gain = Value;
       end
       
       end  % setGainValue
       
        %----------------------------------------
       function setParameterValue(this,idx,Value)
       % setParameterValue set parameter value of the idx parameter and updates zpk
       % representation
       
       
       CurrentValue = this.Parameters(idx).Value;
       
       this.Parameters(idx).Value = Value;
       try
           this.updateZPK;
       catch
           this.Parameters(idx).Value = CurrentValue;
       end
       end  % setParameterValue
       
        %----------------------------------------
       function setParameters(this,Parameters)
       % setPARAMS set parameters and updates zpk representation
       
       
       CurrentValue = this.Parameters;
       
       this.Parameters = Parameters;
       try
           this.updateZPK;
       catch
           this.Parameters = CurrentValue;
       end
       end  % setParameters
       
        %----------------------------------------
       function setZPKGain(this,Gain,flag)
       %SETZPKGAIN   Sets ZPK model gain.
       %
       %   SETZPKGAIN(MODEL,GAIN) sets the gain of the ZPK representation of MODEL.
       %   SETZPKGAIN(MODEL,GAIN,'mag') sets the magnitude of the ZPK gain.
       
       
       TunedGain = Gain/formatfactor(this,'z');
       
       if nargin==2
          this.Gain = TunedGain;
       else
          if this.Gain==0
             GainSign = 1;
          else
             GainSign = sign(this.Gain);
          end
          this.Gain = GainSign*abs(TunedGain);
       end
       end  % setZPKGain
       
        %----------------------------------------
       function D = ss(this,NormalizedFlag)
       %SS   Get SS model of tunable model.
       %
       %   D = SS(MODEL) returns the @ssdata representation of MODEL.
       % 
       %   D = SS(MODEL,'normalized') extracts the normalized @ssdata
       %   representation where the ZPK gain has been replaced by its sign.
       
       %   Author(s): P. Gahinet
       if isempty(this.SSData) || isempty(this.SSData.d)
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
       
       end  % ss
       
        %----------------------------------------
       function updatePZGroups(this,zpkdata)
       % Imports compensator data.
       %
       
       %   Author(s): P. Gahinet
       
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
          [z,p,zn,pn] = LocalFindNotch(z,p,Ts);
          
          % Real poles and zeros
          pr = p(~imag(p),:);
          zr = z(~imag(z),:);
          
          % Complex poles and zeros
          pc = p(imag(p)>0,:);
          zc = z(imag(z)>0,:);
          
          % Adjust length of PZ group list (reuse existing groups)
          Nr = length(pr) + length(zr);
          Nc = length(pc)+length(zc);
          Nn = size(zn,2);
          
          PZGroup = this.PZGroup;
          
          PZTypes = get(PZGroup,{'Type'});
       
          RealPZGroups = PZGroup(strcmp(PZTypes, 'Real'));
          ComplexPZGroups = PZGroup(strcmp(PZTypes, 'Complex'));
          NotchPZGroups = PZGroup(strcmp(PZTypes, 'Notch'));
          LeadLagPZGroups = PZGroup(strcmp(PZTypes, 'LeadLag'));
          
          % Can't reconstruct lead-lag
          delete(LeadLagPZGroups);
          
          
          % Add/Delete real pzgroups 
          if length(RealPZGroups) > Nr
             delete(RealPZGroups(Nr+1:end));
             RealPZGroups(Nr+1:end) = [];
          else
             for ct = 1:Nr-length(RealPZGroups)
                RealPZGroups = [RealPZGroups; sisodata.PZGroupReal(this)];
             end
          end
          
          % Add/Delete complex pzgroups 
          if length(ComplexPZGroups) > Nc
             delete(ComplexPZGroups(Nc+1:end));
             ComplexPZGroups(Nc+1:end) = [];
          else
             for ct = 1:Nc-length(ComplexPZGroups)
                ComplexPZGroups = [ComplexPZGroups; sisodata.PZGroupComplex(this)];
             end
          end
          
          % Add/Delete Notch pzgroups
          if length(NotchPZGroups) > Nn
             delete(NotchPZGroups(Nn+1:end));
             NotchPZGroups(Nn+1:end) = [];
          else
             for ct = 1:Nn-length(NotchPZGroups)
                NotchPZGroups = [NotchPZGroups; sisodata.PZGroupNotch(this)];
             end
          end   
          
          this.PZGroup = [RealPZGroups; ComplexPZGroups; NotchPZGroups];
          
          % Update PZ groups
          N = 0;
          for ct=1:length(zr)
              set(this.PZGroup(N+ct),'Type','Real','Zero',zr(ct),'Pole',zeros(0,1));
              this.PZGroup(N+ct).resetParameterSpec;
          end
          N = N + length(zr);
          for ct=1:length(pr)
              set(this.PZGroup(N+ct),'Type','Real','Zero',zeros(0,1),'Pole',pr(ct));
              this.PZGroup(N+ct).resetParameterSpec;
          end
          N = N + length(pr);
          for ct=1:length(zc)
              set(this.PZGroup(N+ct),'Type','Complex',...
                  'Zero',[zc(ct);conj(zc(ct))],'Pole',zeros(0,1));
              this.PZGroup(N+ct).resetParameterSpec;
          end
          N = N + length(zc);
          for ct=1:length(pc)
              set(this.PZGroup(N+ct),'Type','Complex',...
                  'Zero',zeros(0,1),'Pole',[pc(ct);conj(pc(ct))]);
              this.PZGroup(N+ct).resetParameterSpec;
          end
          N = N + length(pc);
          for ct=1:size(zn,2)
              set(this.PZGroup(N+ct),'Type','Notch',...
                  'Zero',zn(:,ct),'Pole',pn(:,ct));
          end
       
       end
       end  % updatePZGroups
          
       
       
       %%%%%%%%%%%%%%%%%%
       % LocalFindNotch %
       %%%%%%%%%%%%%%%%%%

        %----------------------------------------
       function updateParams(this)
       % UPDATEPARAMS Calculates the parameters from the zpk representation
       
       
       if ~isempty(this.ZPK2ParFcn)
           % Only update when there are parameters to update
           if isTunable(this)
       
               [Z,P] = getPZ(this);
               K = this.getZPKGain;
               
               zpkdata = ltipack.zpkdata({Z},{P},K,this.Ts);
               zpkdata = localConvertTs(this,zpkdata);
       
               if iscell(this.ZPK2ParFcn)
                   NewParams = feval(this.ZPK2ParFcn{1},this.Parameters,[zpkdata.z{:}],...
                       [zpkdata.p{:}],zpkdata.k,this.ZPK2ParFcn{2:end});
               else
                   NewParams = this.ZPK2ParFcn(this.Parameters,[zpkdata.z{:}], ...
                       [zpkdata.p{:}],zpkdata.k);
               end
       
               this.Parameters = NewParams;
           else
               % if not tunable parameters should not be updateable
           end
       end
       end  % updateParams
       
       
       

        %----------------------------------------
       function updateZPK(this)
       % UPDATEZPK Calculates the zpk representation from the parameters
       
       
       if ~isempty(this.Parameters)
           if iscell(this.Par2ZpkFcn)
               [zpkTuned,zpkFixed] = feval(this.Par2ZpkFcn{1},this.Parameters,this.Par2ZpkFcn{2:end});
           else
               [zpkTuned,zpkFixed] = this.Par2ZpkFcn(this.Parameters);
           end
           
           if isTunable(this)
               % Update fixed dynamics, Note fixed dynamics are static for
               % isTunable = true
               zpkFixed = localConvertTs(this, zpkFixed);
               this.FixedDynamics = getPrivateData(zpkFixed);
               zpkTuned = localConvertTs(this, zpkTuned);
               this.updatePZGroups(getPrivateData(zpkTuned));
               this.setZPKGain(zpkTuned.k * zpkFixed.k);
           else
               % Put all dynamics in fixedDynamics
               sys = getPrivateData(localConvertTs(this,zpkFixed*zpkTuned));
               this.updatePZGroups(ltipack.zpkdata({[]},{[]},1,this.Ts));
               this.FixedDynamics = sys;
               this.setZPKGain(sys.k);
           end
       end
       end  % updateZPK
       
       
       %% 

        %----------------------------------------
       function b = initializeCompTarget(this)
       % Used to determine if gain is tunable for the TunedZPK
       
       
       b = false;
       if this.isTunable
           if ~isfield(this.Constraints,'isStaticGainTunable') || ...
                   this.Constraints.isStaticGainTunable
               b = true;
           end
       end
       
       
       
       
           
       
       end  % initializeCompTarget
       
        %----------------------------------------
       function D = zpk(this,NormalizedFlag)
       %ZPK   Get ZPK model of tunable model.
       %
       %   D = ZPK(MODEL) returns the @zpkdata representation of MODEL.
       % 
       %   D = ZPK(MODEL,'normalized') extracts the normalized @zpkdata
       %   representation where the ZPK gain has been replaced by its sign.
       
       %   Author(s): P. Gahinet
       [Z,P] = getPZ(this);
       if nargin==1
          K = getZPKGain(this);
       else
          K = getZPKGain(this,'sign');
       end
       D = ltipack.zpkdata({Z},{P},K,this.Ts);     
       
       end  % zpk
       
end  % public methods 


    methods (Hidden) % possibly private or hidden
        %----------------------------------------
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
       end  % getZPKParameterSpec
       
        %----------------------------------------
       function resetZPKParameterSpec(this)
       %
       
       
       this.ZPKParamSpec.Dirty = true;
       
       end  % resetZPKParameterSpec
       
end  % possibly private or hidden 

end  % classdef

function LocalPZGroupChanged(this,event)
% Make dirty PZGROUPSpec
this.resetZPKParameterSpec;
end  % LocalPZGroupChanged

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
end  % LocalFindNotch

    
function zpkdata = localConvertTs(this,zpkdata)

Ts = this.Ts;
TsOrig = this.TsOrig;

if ~isequal(Ts,TsOrig)
    if isequal(Ts,0)
        %d2c
        p = d2cOptions;
        if numel(this.D2CMethod)==1
            p.Method = this.D2CMethod{1};
        else
            p.Method = 'tustin';
            p.PrewarpFrequency = this.D2CMethod{2};
        end
        zpkdata =  d2c(zpkdata,p);        
    else
        if isequal(TsOrig,0)
            %c2d
            p = c2dOptions;
            if numel(this.C2DMethod)==1
                p.Method = this.C2DMethod{1};
            else
                p.Method = 'tustin';
                p.PrewarpFrequency = this.C2DMethod{2};
            end
            zpkdata =  c2d(zpkdata,Ts,p);
        else
            %d2d
            p = d2dOptions;
            if numel(this.C2DMethod)==1
                p.Method = this.C2DMethod{1};
            else
                p.Method = 'tustin';
                p.PrewarpFrequency = this.C2DMethod{2};
            end
            zpkdata =  d2d(zpkdata,Ts,p);            
        end
    end
end
end  % localConvertTs

        

