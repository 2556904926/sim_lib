classdef (CaseInsensitiveProperties) TunedBlock  < matlab.mixin.SetGet & matlab.mixin.Copyable & matlab.mixin.Heterogeneous
%sisodata.TunedBlock class
%    sisodata.TunedBlock properties:
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
%
%    sisodata.TunedBlock methods:
%       formatfactor -  Computes format factor.
%       getDisplayString -  This function generates the strings for the numerator
%       getMaskParameterSpec -   method to return any mask parameter specs for the
%       getProperty -  Returns the property specified by PropName
%       isGainBlock -  Returns true if compensator is pure gain block
%       ss -   Get SS model of tunable model.
%       zpk -   Get ZPK model of tunable model.


properties (SetObservable)
    %NAME Property is of type 'ustring' 
    Name = '';
    %IDENTIFIER Property is of type 'string' 
    Identifier = '';
    %DESCRIPTION Property is of type 'ustring' 
    Description = '';
    %FORMAT Property is of type 'string' 
    Format = 'TimeConstant1';
    %TS Property is of type 'double' 
    Ts = 0;
    %TSORIG Property is of type 'double' 
    TsOrig = 0;
    %MASKPARAMSPEC Property is of type 'MATLAB array' 
    MaskParamSpec = [];
    %PARAMETERS Property is of type 'MATLAB array' 
    Parameters = [];
    %SSDATA Property is of type 'MATLAB array' 
    SSData = [];
    %PAR2ZPKFCN Property is of type 'MATLAB array' 
    Par2ZpkFcn = [];
    %C2DMETHOD Property is of type 'MATLAB array' 
    C2DMethod = [];
    %D2CMETHOD Property is of type 'MATLAB array' 
    D2CMethod = [];
    %AUXDATA Property is of type 'MATLAB array' 
    AuxData = [];
end


    methods 
        function set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function set.Identifier(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Identifier')
        obj.Identifier = value;
        end

        function set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function set.Format(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Format')
        obj.Format = value;
        end

        function set.Ts(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Ts')
        value = double(value); %  convert to double
        obj.Ts = value;
        end

        function set.TsOrig(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','TsOrig')
        value = double(value); %  convert to double
        obj.TsOrig = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
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
       
       if nargin==1
          TargetFormat = this.Format;
       end
       
       Ts = this.Ts;
       
       % Initialize settings based on sample time
       if isequal(Ts,0)
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
       
           
       end  % formatfactor
       
        %----------------------------------------
       function [NumStr, DenStr] = getDisplayString(this)
       % getDisplayString  This function generates the strings for the numerator
       % and denominator for displaying the compensator in the pzeditor panel and
       % automated tuning panel
       
       %   Author(s): P. Gahinet
       %   Revised: C. Buhr, R. Chen
       
       % get format and ts
       Format = this.Format;
       Ts = this.Ts;
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
          NumStr = LocalFormat(Z,Ts,Format);
          DenStr = LocalFormat(P,Ts,Format);
       end
       end  % getDisplayString
       
          
       %-------------------------Helper Functions----------------------
       
       %%%%%%%%%%%%%%%%%%%
       %%% LocalFormat %%%
       %%%%%%%%%%%%%%%%%%%

        %----------------------------------------
       function MaskParamSpec = getMaskParameterSpec(this) 
       % GETMASKPARAMETERSPECS  method to return any mask parameter specs for the
       % tuned block
       %
        
       % Author(s): A. Stothert 22-Nov-2005
       
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
             PID = modelpack.STParameterID(...
                sprintf('%s (mask)',InPars(ct_P).Name), ...
                NewDim, ...
                this.Identifier, ...
                'double', ...
                {''}, ...
                InPars(ct_P).Name);
             idxMask = numel(MaskParamSpec)+1;
             if isempty(MaskParamSpec)
                %First Spec
                MaskParamSpec = modelpack.STParameterSpec(PID);
             else
                MaskParamSpec(idxMask,1) = modelpack.STParameterSpec(PID);
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
       
       
       end  % getMaskParameterSpec
       
        %----------------------------------------
       function Prop = getProperty(this,PropName)
       % Returns the property specified by PropName
       
       
       Prop = this.(PropName);
       end  % getProperty
       
        %----------------------------------------
       function bool = isGainBlock(this)
       % Returns true if compensator is pure gain block
       % used by pzeditor
       
       
       for ct=1:length(this)
           bool(ct) = false;
           if isa(this(ct),'sisodata.TunedZPK') && ~isempty(this(ct).Constraints) ...
               && (this(ct).Constraints.MaxZeros == 0) && (this(ct).Constraints.MaxPoles == 0)
               bool(ct) = true;
           end
       end
       
       end  % isGainBlock
       
        %----------------------------------------
       function D = ss(this,NormalizedFlag)
       %SS   Get SS model of tunable model.
       %
       %   D = SS(MODEL) returns the @ssdata representation of MODEL.
       % 
       %   D = SS(MODEL,'normalized') extracts the normalized @ssdata
       %   representation where the ZPK gain has been replaced by its sign.
       
       %   Author(s): P. Gahinet
       if isempty(this.SSData.d)
          % Recompute normalized state-space model
          [z,p] = getPZ(this);
          [a,b,c,d] = zpkreal(z,p,getZPKGain(this,'sign'));
          this.SSData = ltipack.ssdata(a,b,c,d,[],this.Ts);
       end
       D = this.SSData;
       if nargin==1
          g = getZPKGain(this,'mag');
          D.d = D.d * g;
          D.c = D.c * g;
       end
       
       end  % ss
       
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

end  % classdef

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
end  % LocalFormat

