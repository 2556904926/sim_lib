classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      tunableTF < tunableLTI
   %tunableTF  Tunable fixed-order transfer function.
   %
   %   BLK = tunableTF(NAME,NZ,NP) creates a parametric SISO transfer 
   %   function BLK with NP poles and at most NZ zeros. The string NAME 
   %   specifies the block name. Note that the leading coefficient of the 
   %   denominator is always fixed to 1.
   %
   %   BLK = tunableTF(NAME,NZ,NP,TS) creates a discrete-time parametric
   %   transfer function with sample time TS.
   %
   %   BLK = tunableTF(NAME,SYS) uses the transfer function SYS (see TF)
   %   to set the transfer function order, sample time, and initial
   %   parameter values.
   %
   %   Use SYSTUNE to automatically tune the free parameters of BLK.
   %
   %   Example: Create a parametric SISO transfer function with two zeros,  
   %   four poles, and at least one integrator:
   %      blk = tunableTF('demo',2,4);
   %      blk.den.Value(end) = 0;     % set last denominator entry to zero
   %      blk.den.Free(end) = false;  % fix it to zero
   %
   %   See also tunableSS, tunablePID, CONTROLDESIGNBLOCK, TF, SYSTUNE, looptune.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.

   properties (Access = public, Dependent)   
      % Numerator vector (row vector of parameters).
      %
      % Use this property to read the current value of the vector of numerator
      % coefficients or to initialize, fix, or free specific coefficients in
      % the numerator.
      Numerator
      % Denominator vector (row vector of parameters).
      %
      % Use this property to read the current value of the vector of denominator
      % coefficients or to initialize, fix, or free specific coefficients in
      % the denominator. Note that the leading coefficient (first entry of the
      % vector) is always fixed to the value 1.
      Denominator
   end
   
   properties (Access = protected)
      % Model parameterization (pmodel.tf)
      Parameterization_
   end
   
   properties (Access = protected, Transient)
      Nz_  % caches number of zeros
      Np_  % caches number of poles
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genss';
      end
      
      % Note: getAttributes never called (first converted to GENSS)
      
   end
   
   % CONSTRUCTION, INITIALIZATION, CONVERSION
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods      

      function blk = tunableTF(Name,varargin)
         ni = nargin;
         blk.IOSize_ = [1 1];
         if ni==0
            return
         end
         % Check remaining input arguments
         try
            switch ni
               case 2
                  % tunableTF(name,TFObject)
                  sys = varargin{1};
                  try
                     sys = tf.convert(sys);
                  catch ME %#ok<*NASGU>
                     error(message('Control:lftmodel:ltiblockTF2'))
                  end
                  if ~(nmodels(sys)==1 && issiso(sys))
                     error(message('Control:lftmodel:ltiblockTF1'))
                  end
                  [num,den,Ts] = tfdata(sys,'v');
                  if den(1)==0  % improper
                     error(message('Control:lftmodel:ltiblockTF3'))
                  end
                  idnz = find(num~=0,1);
                  if isempty(idnz)
                     % num = 0: assume nz=np
                     warning(message('Control:lftmodel:ltiblockTF11',numel(den)-1))
                     num = zeros(size(den));
                  else
                     num = num(idnz:end);
                  end
                  nz = numel(num)-1;   np = numel(den)-1;
               case {3,4}
                  % tunableTF(name,nz,np,Ts)
                  if ~all(cellfun(@(x) isnumeric(x) && isscalar(x) && isreal(x) && ...
                        x==floor(x) && x>=0,varargin(1:2)))
                     error(message('Control:lftmodel:ltiblockTF4'))
                  end
                  nz = varargin{1};  np = varargin{2};
                  if nz>np
                     error(message('Control:lftmodel:ltiblockTF10'))
                  end
                  if ni==3
                     Ts = 0;
                  else
                     Ts = ltipack.utValidateTs(varargin{3});
                  end
                  [num,den] = tunableTF.defaultND(varargin{1:2},Ts);
               otherwise
                  error(message('Control:general:InvalidSyntaxForCommand','tunableTF','tunableTF'))
            end
         catch ME
            throw(ME)
         end
                           
         % Initialize block
         blk.Nz_ = nz;
         blk.Np_ = np;
         blk.Parameterization_ = pmodel.tf(num,den);
         if ni==2
            % Note: Overwrites Name!
            blk = copyMetaData(sys,blk);
            blk.TimeUnit = sys.TimeUnit;
         end
         try
            blk.Ts = Ts;      % errors if Ts=-1
            blk.Name = Name;  % errors if Name is not a variable name
         catch ME
            throw(ME)
         end
            
      end
      
      function Value = get.Numerator(blk)
         % GET method for NUM property
         try
            Value = blk.Parameterization_.num;
         catch %#ok<*CTCH>
            Value = [];  % tunableTF()
         end
      end
            
      function Value = get.Denominator(blk)
         % GET method for DEN property
         try
            Value = blk.Parameterization_.den;
         catch
            Value = [];
         end
      end
      
      function blk = set.Numerator(blk,Value)
         % SET method for NUM property
         blk.Parameterization_.num = pmodel.checkParameter(...
            Value,'Numerator',getSize(blk.Parameterization_.num));
      end
      
      function blk = set.Denominator(blk,pDen)
         % SET method for DEN property
         pDen = pmodel.checkParameter(...
            pDen,'Denominator',getSize(blk.Parameterization_.den));
         if pDen.Value(1)~=1 || pDen.Free(1)
            % Check constraint on DEN(1)
            error(message('Control:pmodel:monicDen'))
         end
         blk.Parameterization_.den = pDen;
      end
      
   end
   
   
   %% SUPERCLASS INTERFACES
   methods (Access=protected)
      
      function displaySize(blk,~)
         % Display for "size(sys)"
         if isempty(blk.Np_)
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeTF1',0,0))
         else
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeTF1',blk.Nz_,blk.Np_))
         end
      end
      
      % PARAMETRIC BLOCK
      function np = nparams_(blk,varargin)
         % Number of parameters
         if nargin>1
            np = nparams(blk.Parameterization_,varargin{:});
         else
            np = blk.Nz_ + blk.Np_ + 2;
         end
      end
      
      function isf = isfree_(blk)
         % True for free parameters
         isf = isfree(blk.Parameterization_);
      end
      
      function blk = zeroThru_(blk,mustZero)
         % Fix specified entries of block feedthrough to zero to eliminate 
         % feedthrough term in H2 goals
         if mustZero && blk.Nz_==blk.Np_ && blk.Parameterization_.num.Free(1)
            blk.Parameterization_.num.Value(1) = 0;
            blk.Parameterization_.num.Free(1) = false;
         end
      end
            
      function p = getp_(blk,varargin)
         % Get vector of parameter values
         p = getp(blk.Parameterization_,varargin{:});
      end
      
      function [pMin,pMax] = getpMinMax_(blk)
         % Get parameter bounds
         [pMin,pMax] = getpMinMax(blk.Parameterization_);
      end
      
      function blk = setp_(blk,p,varargin)
         % Set vector of parameter values
         blk.Parameterization_ = setp(blk.Parameterization_,p,varargin{:});
      end
      
      function P = randp_(blk,N,varargin)
         % Generates random samples of model parameters.
         Ts = blk.Ts_;
         
         % Generate random samples
         P = zeros(nparams_(blk),N);
         for j=1:N
            [num,den] = tunableTF.randND(blk.Nz_,blk.Np_,Ts);
            P(:,j) = [num.';den.'];
         end
         
         % Enforce bounds (may compromise stability)
         [pMin,pMax] = getpMinMax(blk);
         ix = find(isfinite(pMin) | isfinite(pMax));
         P(ix,:) = pmodel.randBounded(N,pMin(ix),pMax(ix));

         if nargin>2
            P = P(isfree_(blk),:);
         end
      end
      
   end

   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      %% MODEL CHARACTERISTICS
      function boo = isreal_(blk,~)
         % Returns true if the current value is real
         blkParam = blk.Parameterization_;
         boo = isreal(blkParam.num.Value) && isreal(blkParam.den.Value);
      end
      
      function boo = isstatic_(blk,~)
         % Block is static if DEN==1 (note: order cannot change after construction)
         boo = (blk.Np_==0);
      end
      
      function ns = order_(blk)
         % Get number of states
         ns = blk.Np_;
      end
   
      function boo = isstable_(blk,varargin)
         boo = isstable(ltipack_tfdata(blk))==1;
      end
      
      function [a,b,c,d,Ts] = ssdata_(blk,varargin)
         % Quick access to explicit state-space data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         D = ltipack_ssdata(blk);
         a = D.a;  b = D.b;  c = D.c;  d = D.d;  Ts = blk.Ts_;
      end
      
      function [num,den,Ts,sdnum,sdden] = tfdata_(blk,varargin)
         % Quick access to transfer function data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         blkParam = blk.Parameterization_;
         N = blkParam.num.Value;
         D = blkParam.den.Value;
         num = {[zeros(1,numel(D)-numel(N)) N]};
         den = {D};
         Ts = blk.Ts_;
         sdnum = []; sdden = [];
      end

      function [z,p,k,Ts,covz,covp,covk] = zpkdata_(blk,varargin)
         % Quick access to ZPK data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         D = zpk(ltipack_tfdata(blk));
         z = D.z;  p = D.p;  k = D.k;  Ts = blk.Ts_;
         covz = []; covp = []; covk = [];
      end

      function [Kp,Ki,Kd,Tf,Ts] = piddata_(blk,varargin)
         % Extract PID coefficients
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         try
            D = pid(ltipack_tfdata(blk));
         catch ME
            error(message('Control:ltiobject:piddata1'))
         end
         Kp = D.Kp;  Ki = D.Ki;  Kd = D.Kd;  Tf = D.Tf;  Ts = blk.Ts_;
      end
      
      function [Kp,Ti,Td,N,Ts] = pidstddata_(blk,varargin)
         % Extract PIDSTD coefficients
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         try
            D = pidstd(ltipack_tfdata(blk));
         catch ME
            error(message('Control:ltiobject:pidstddata1'))
         end
         Kp = D.Kp;  Ti = D.Ti;  Td = D.Td;  N = D.N;  Ts = blk.Ts_;
      end

      %% CONVERSIONS
      function sys = tf_(blk,~)
         % Converts to @tf
         sys = tf.make(ltipack_tfdata(blk));
         sys.TimeUnit = blk.TimeUnit;
      end
       
      function sys = zpk_(blk,~)
         % Converts to @zpk
         sys = zpk.make(zpk(ltipack_tfdata(blk)));
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pid_(blk,varargin)
         % Converts to @pid
         sys = pid.make(pid(ltipack_tfdata(blk),varargin{:}));
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pidstd_(blk,varargin)
          % Converts to @pidstd
          sys = pidstd.make(pidstd(ltipack_tfdata(blk),varargin{:}));
          sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pid2_(blk,varargin)
          % Converts to @pid2
          sys = pid2.make(pid2(ltipack_tfdata(blk),varargin{:}));
          sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pidstd2_(blk,varargin)
          % Converts to @pidstd2
          sys = pidstd2.make(pidstd2(ltipack_tfdata(blk),varargin{:}));
          sys.TimeUnit = blk.TimeUnit;
      end
      
      function blk = chgTimeUnit_(blk,newUnits)
          % Change time units without altering system behavior
          Ts = blk.Ts_;
         sf = tunitconv(blk.TimeUnit,newUnits);
         if Ts==0
            % Rescale NUM,DEN according to tnew = sf * told
            lnum = length(blk.Numerator.Value);
            lden = length(blk.Denominator.Value);  % >= lnum
            powSF = cumprod([1 sf(:,ones(lden-1,1))]);
            % Note: must preserve den(1)=1
            blk.Denominator.Value = blk.Denominator.Value ./ powSF;
            blk.Denominator.Minimum = blk.Denominator.Minimum ./ powSF;
            blk.Denominator.Maximum = blk.Denominator.Maximum ./ powSF;
            blk.Denominator.Scale = blk.Denominator.Scale ./ powSF;
            powSF = powSF(:,lden-lnum+1:lden);
            blk.Numerator.Value = blk.Numerator.Value ./ powSF;
            blk.Numerator.Minimum = blk.Numerator.Minimum ./ powSF;
            blk.Numerator.Maximum = blk.Numerator.Maximum ./ powSF;
            blk.Numerator.Scale = blk.Numerator.Scale ./ powSF;
         elseif Ts>0
            % Update Ts
            blk.Ts_ = sf * Ts;
         end
         blk.TimeUnit = newUnits; % direct set
      end

      function sys = getValue_(blk)
         % Returns current value
         sys = tf(blk);
      end
      
      %% ANALYSIS
      function p = pole_(blk,varargin)
         p = roots(blk.Parameterization_.den.Value);
      end
      
      function [z,g] = zero_(blk,varargin)
         num = blk.Parameterization_.num.Value;
         z = roots(num);
         g = num(end-numel(z));
      end

      function varargout = dcgain_(blk)
         [varargout{1:nargout}] = dcgain(ltipack_tfdata(blk));
      end
      
      function [h,SingularWarn,covH] = freqresp_(blk,w)
         [h,SingularWarn] = fresp(ltipack_tfdata(blk),w);
         covH = [];
      end

      function [m,p,w,FocusInfo,sdm,sdp] = magphaseresp_(blk,grade,wspec)
         [m,p,w,FocusInfo] = magphaseresp_(tf_(blk),grade,wspec);
         sdm = []; sdp = []; % default for systems with no covariance info
      end
      
      function varargout = nyquistresp_(blk,wspec)
         [varargout{1:nargout}] = nyquistresp_(tf_(blk),wspec);
      end
      
      function fb = bandwidth_(blk,drop)
         fb = bandwidth(ltipack_tfdata(blk),drop);
      end
      
      function fresp = evalfr_(blk,s)
         fresp = evalfr(ltipack_tfdata(blk),s);
      end
      
      function s = allmargin_(blk,opt)
         s = allmargin(ltipack_tfdata(blk),opt);
      end      
      
      %% TRANSFORMATIONS
      function blk = setValue_(blk,sys)
         % Sets block value. SYS can be any SISO dynamic system. The number
         % of poles and zeros is adjusted to match the block structure.
         Ts = blk.Ts_;  nz = blk.Nz_;  np = blk.Np_;
         try
            sys = tf.convert(sys);
         catch ME
            error(message('Control:lftmodel:ltiblockTF6',blk.Name))
         end
         try
            sys = alignSampleTime(sys,Ts,blk.TimeUnit);
         catch ME
            error(message('Control:lftmodel:setValue1',blk.Name))
         end

         % Adjust order
         npsys = order(sys);
         if npsys>np
            % Use reduced-order approximation
            try %#ok<TRYNC>
               sys = balred(sys,np);
               npsys = order(sys);
            end
            if npsys>np
               error(message('Control:lftmodel:ltiblockTF8',blk.Name))
            end
         end
         if npsys<np
            % Add extra poles
            [naug,daug] = tunableTF.defaultND(0,np-npsys,Ts);
            sys = sys + tf(1e-8*naug,daug,Ts,'TimeUnit',blk.TimeUnit);
         end
         
         % Normalize DEN
         [num,den] = tfdata(sys,'v');
         d1 = den(1);
         if d1==0
            error(message('Control:lftmodel:ltiblockTF9',blk.Name))
         else
            den = den/d1;  num = num/d1;
         end
         
         % Adjust number of zeros
         z = roots(num);
         if numel(z)>nz
            % Keep low-frequency zeros
            [wn,~] = damp(z,Ts);
            [wn,is] = sort(wn);
            idx = find(wn>0,1);
            if isempty(idx)
               num = poly(z(1:nz));
            else
               z = z(is(1:nz));
               if ~isconjugate(z)
                  % Last entry is an isolated complex zero
                  if Ts==0
                     z(end) = -abs(z(end));
                  else
                     z(end) = exp(-abs(log(z)));
                  end
               end
               numr = poly(z);
               % Match response near DC
               fMatch = 1i*wn(idx)/50;
               if Ts~=0
                  fMatch = exp(Ts*fMatch);
               end
               num = numr * real(polyval(num,fMatch)/polyval(numr,fMatch));
            end
         else
            num = num(np-nz+1:end);
         end
         
         % Initialize parameters
         blkParam = blk.Parameterization_;
         blkParam.num.Value = num;
         blkParam.den.Value = den;
         blk.Parameterization_ = blkParam;
      end
      
   end

   
   %% HIDDEN INTERFACES
   methods (Hidden)

      % CONTROLDESIGNBLOCK
      function Offset = getOffset(blk)
         % Get default feedthrough value
         blkParam = blk.Parameterization_;
         num = blkParam.num.Value;
         den = blkParam.den.Value;
         if numel(num)<numel(den)
            Offset = 0;
         else
            Offset = num(1);
         end
      end
      
      
      function D = ltipack_tfdata(blk)
         % Converts to ltipack.tfdata object
         [num,den,Ts] = tfdata_(blk);
         D = ltipack.tfdata(num,den,Ts);
      end
      
      
      function D = ltipack_ssdata(blk,~,S)
         % Converts to ltipack.ssdata object
         D = ss(ltipack_tfdata(blk));
         D.StateName = blk.Name + ".x" + (1:blk.Np_)';
         if nargin>1
            D.d = D.d-S;
         end
      end
      
      function D = ltipack_frddata(blk,freq,~,S)
         % Converts to ltipack.frddata object
         D = frd(ltipack_tfdata(blk),freq);
         if nargin>3
            D.Response = D.Response-S;
         end
      end
      
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         str = ctrlMsgUtils.message('Control:lftmodel:ltiblockTF5',...
            blk.Name,blk.Nz_,blk.Np_,ncopies);
      end
      
      function [As,Bs,Cs,D0,Dsf] = sInfo(blk)
         % Structural information about (A,B,C,D) contribution of BLK-S 
         % to the closed-loop model LFT(H(s),blkdiag(Bj-Sj)). Due to the
         % block offset S, the structure of the feedthrough D is captured 
         % by its initial value D0 and its free (tunable) entries Dsf.
         N = blk.Parameterization_.num;
         D = blk.Parameterization_.den;
         numS = sInfo(N);  nz = numel(numS)-1;
         denS = sInfo(D);  np = numel(denS)-1;
         % A,B
         As = false(np);  Bs = false(np,1);
         if np>0
            As(1,:) = denS(2:np+1);  As(2:np+1:end) = true;   Bs(1) = true;
         end
         % C,D
         if nz<np || ~numS(1)
            % Strictly proper
            Cs = false(1,np);
            Cs(np-nz-1+find(numS)) = true;
            D0 = 0;
            Dsf = false;
         else
            % Rel degree is zero. Watch for exact cancellations in C
            Cv = N.Value(:,2:np+1) - N.Value(1) * D.Value(:,2:np+1);
            Cs = (N.Free(:,2:np+1) | D.Free(:,2:np+1) | Cv~=0);
            D0 = N.Value(1);
            Dsf = N.Free(1);
         end
      end      
      
      %% OPTIMIZATION
      function ns = numState(blk)
         % Size of A matrix from p2ss
         ns = blk.Np_;
      end
      
      function [a,b,c,d] = p2ss(blk,p)
         % Constructs realization from parameter vector p
         nz = blk.Nz_;  np = blk.Np_;
         num = p(1:nz+1,:).';   den = p(nz+3:nz+np+2,:).'; % ignore den(1)=1
         % A,B
         a = zeros(np);  b = zeros(np,1);
         if np>0
            a(1,:) = -den;  a(2:np+1:end) = 1;   b(1) = 1;
         end
         if nz<np
            d = 0;
            c = [zeros(1,np-nz-1) num];
         else
            % rel degree is zero
            d = num(1);
            c = num(:,2:np+1) - d * den;
         end
      end
      
      
      %------------------------------------------------
      function gj = gradUV(~,p,u,v,j)
         % Computes the gradient of the inner product
         %    phi(p) = Re(Trace(U'*[A(p) B(p);C(p) D(p)]*V))
         % with respect to the block parameters p(j) where j is a vector
         % of indices. The real or complex matrices U and V must have the
         % same number of columns.
         lden = size(u,1);
         lnum = length(p)-lden;
         w = v(1:lden-1,:);
         if lnum<lden
            g = [v(lden-lnum:lden-1,:) * u(lden,:)' ; 0 ; -w * u(1,:)'];
         else
            % biproper case
            g =  [-p(lnum+2:lnum+lden,:)'*w; w; ...
               zeros(1,size(u,2)) ; -p(1)*w] * u(lden,:)';  % C(p)
            g(1) = g(1) + v(lden,:) * u(lden,:)';  % D(p)
            g(lnum+2:lnum+lden,:) = g(lnum+2:lnum+lden,:) - w * u(1,:)';  % A(p)
         end
         gj = real(g(j));
      end

      % LFTBlockWrapper
      function SNU = getStateInfo(blk,Prop)
         % Get state names or units
         if strcmp(Prop,'StateName')
            SNU = blk.Name + ".x" + (1:blk.Np_)';
         else
            SNU = strings(blk.Np_,1);
         end
      end

   end
   
   
   % STATIC METHODS FOR INITIALIZATION
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   methods (Static = true, Access = protected)
      
      % Default initialization of NUM,DEN
      [num,den] = defaultND(nz,np,Ts)
      % Random initialization of NUM,DEN
      [num,den] = randND(nz,np,Ts)
      
   end

   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for tunableTF objects
         blk = DynamicSystem.updateMetaData(s);
         % Restore transient properties
         blk.Nz_ = numel(s.Parameterization_.num.Value)-1;
         blk.Np_ = numel(s.Parameterization_.den.Value)-1;
         % Update version
         blk.Version_ = ltipack.ver();
      end
      
   end

end
