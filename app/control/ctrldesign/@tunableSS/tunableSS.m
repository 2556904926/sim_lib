classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      tunableSS < tunableLTI & StateSpaceModel
   %tunableSS  Tunable fixed-order state-space model.
   %
   %   BLK = tunableSS(NAME,NX,NY,NU) creates a continuous-time parametric  
   %   state-space block BLK with NX states, NY outputs, and NU inputs. 
   %   The string NAME specifies the block name.
   %
   %   BLK = tunableSS(NAME,NX,NY,NU,TS) creates a discrete-time parametric 
   %   state-space block BLK with sample time TS.
   %
   %   BLK = tunableSS(NAME,NX,NY,NU,...,AS) restricts the A matrix to one 
   %   of the following structures:
   %      AS='tridiag'     A is tridiagonal
   %      AS='full'        A is full (every entry is a free parameter)
   %      AS='companion'   A is in companion form (see CANON).
   %   The default parameterization uses a tridiagonal A matrix. Both 'tridiag' 
   %   and 'companion' are more compact (fewer parameters) than 'full'. Use 
   %   BLK.a.Free, BLK.b.Free,... to specify additional structure or fix 
   %   specific entries of A,B,C,D. For example, set BLK.a.Free(i,j)=true to
   %   designate A(i,j) as a free parameter, or set BLK.a.Free(i,j)=false to
   %   fix A(i,j) to its current value.
   %
   %   BLK = tunableSS(NAME,SYS,AS) uses the dynamic system SYS to dimension 
   %   the block, set its sample time, and initialize the block parameters.
   %   SYS is first converted to a state-space model with structure AS. If AS
   %   is omitted, SYS is converted to tridiagonal state-space form.
   %
   %   Use SYSTUNE to automatically tune the free parameters of BLK.
   %
   %   Example: Create a tridiagonal parameterization of 5th-order SISO 
   %   models with zero D matrix:
   %      blk = tunableSS('demo',5,1,1);
   %      blk.d.Value = 0;      % set D=0
   %      blk.d.Free = false;   % fix D to zero
   %
   %   See also tunableTF, tunablePID, CONTROLDESIGNBLOCK, SS, SYSTUNE, looptune.

%   Author(s): P. Gahinet
%   Copyright 2009-2015 The MathWorks, Inc.

   properties (Access = public, Dependent)
      % A matrix (matrix-valued parameter).
      %
      % Use this property to read the current value of the state matrix A,
      % to initialize A, or to fix/free specific entries of A.
      A
      % B matrix (matrix-valued parameter).
      %
      % Use this property to read the current value of the input-to-state
      % matrix B, to initialize B, or to fix/free specific entries of B.
      B
      % C matrix (matrix-valued parameter).
      %
      % Use this property to read the current value of the state-to-output
      % matrix C, to initialize C, or to fix/free specific entries of C.
      C
      % D matrix (matrix-valued parameter).
      %
      % Use this property to read the current value of the feedthrough
      % matrix D, to initialize D, or to fix/free specific entries of D.
      % For example, you can fix D to zero by typing 
      %    blk.D.Value = 0;  blk.D.Free = false;
      D
      % State names (string vector, default = empty string for all states).
      %
      % You can set this property to:
      %   * A string for first-order models, for example, 'position'
      %   * A string vector for models with two or more states, for example,
      %     {'position' ; 'velocity'}
      % Use the empty string '' for unnamed states.
      StateName
      % State units (string vector, default = empty string for all states).
      %
      % Use this property to keep track of the units each state is expressed in.
      % You can set "StateUnit" to:
      %   * A string for first-order models, for example, 'm/s'
      %   * A string vector for models with two or more states, for example,
      %    {'m' ; 'm/s'}
      StateUnit
   end
   
   properties (Access = protected)
      % Model parameterization (pmodel.ss)
      Parameterization_
   end
   
   properties (Access = protected, Transient)
      Nx_  % caches number of states
   end

   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genss';
      end
      
      % Note: getAttributes never called (first converted to GENSS)
      
   end
   
   
   methods
      
      function blk = tunableSS(Name,varargin)
         ni = nargin;
         if ni==0
            blk.IOSize_ = [0,0];   blk.Nx_ = 0;  return
         end
         % Detect Structure
         ixS = find(cellfun(@ischar,varargin),1);
         if isempty(ixS)
            Structure = 'tridiagonal';  % default
         else
            Structure = ltipack.matchKey(varargin{ixS},{'full','tridiagonal','companion'});
            if isempty(Structure)
               error(message('Control:lftmodel:ltiblockSS1'))
            end
            varargin(:,ixS) = [];  ni = ni-1;
         end
         % Check remaining input arguments
         try
            switch ni
               case 2
                  % tunableSS(name,SSObject)
                  sys = varargin{1};
                  try
                     sys = ss.convert(sys,'explicit');
                  catch ME
                     error(message('Control:lftmodel:ltiblockSS2'))
                  end
                  if nmodels(sys)~=1
                     error(message('Control:lftmodel:ltiblockSS3'))
                  end
                  [a0,b0,c0,d0,Ts] = ssdata(sys);
                  [ny,nu] = size(d0);   nx = size(a0,1);
                  [a0,b0,c0,d0] = tunableSS.initStruct(Structure,a0,b0,c0,d0,Ts);
               case {4,5}
                  % tunableSS(name,nx,ny,nu,Ts)
                  if ~all(cellfun(@(x) isnumeric(x) && isscalar(x) && isreal(x) && ...
                        x==floor(x) && x>=0,varargin(1:3)))
                     error(message('Control:lftmodel:ltiblockSS9'))
                  elseif ni==4
                     Ts = 0;
                  else
                     Ts = ltipack.utValidateTs(varargin{4});
                  end
                  [nx,ny,nu] = deal(varargin{1:3});
                  [a0,b0,c0,d0] = tunableSS.defaultABCD(Structure,nx,ny,nu,Ts);
               otherwise
                  error(message('Control:general:InvalidSyntaxForCommand','tunableSS','tunableSS'))
            end
         catch ME
            throw(ME)
         end
         
         % Construct block
         blk.IOSize_ = [ny,nu];
         blk.Nx_ = nx;
         blk.Parameterization_ = pmodel.ss(a0,b0,c0,d0);
         if ni==2
            % Note: Overwrites Name!
            blk = copyMetaData(sys,blk);
            blk.TimeUnit = sys.TimeUnit;
            % Must be done after setting blk.Nx_
            blk.StateName = sys.StateName;
            blk.StateUnit = sys.StateUnit;
         end
         try
            blk.Ts = Ts;      % errors if Ts=-1
            blk.Name = Name;  % errors if Name is not a variable name
         catch ME
            throw(ME)
         end
         
         % Set model structure
         switch Structure(1)
            case 'f' % full
               aFree = true(nx);
            case 't' % tridiagonal
               aFree = false(nx);
               aFree([1:nx+1:nx^2,2:nx+1:nx^2,nx+1:nx+1:nx^2]) = true;
            case 'c' % companion
               aFree = false(nx);
               if nx>0
                  aFree(2:nx+1:end) = true;  aFree(1,:) = true;
               end
         end
         blk.Parameterization_.a.Free = aFree;
      end
                  
      function Value = get.A(blk)
         % GET method for A property
         try
            Value = blk.Parameterization_.a;
         catch %#ok<*CTCH>
            Value = [];  % tunableSS()
         end
      end
      
      function Value = get.B(blk)
         % GET method for B property
         try
            Value = blk.Parameterization_.b;
         catch
            Value = [];
         end
      end
      
      function Value = get.C(blk)
         % GET method for C property
         try
            Value = blk.Parameterization_.c;
         catch
            Value = [];
         end
      end
      
      function Value = get.D(blk)
         % GET method for D property
         try
            Value = blk.Parameterization_.d;
         catch
            Value = [];
         end
      end
      
      function Value = get.StateName(blk)
         % GET method for StateName property
         Value = cellstr(getStateInfo(blk,'StateName'));
      end
      
      function Value = get.StateUnit(blk)
         % GET method for StateUnit property
         Value = cellstr(getStateInfo(blk,'StateUnit'));
      end
      
      function blk = set.A(blk,Value)
         % SET method for A property
         blk.Parameterization_.a = pmodel.checkParameter(...
            Value,'A',blk.Nx_([1 1]));
      end
      
      function blk = set.B(blk,Value)
         % SET method for B property
         blk.Parameterization_.b = pmodel.checkParameter(...
            Value,'B',[blk.Nx_ blk.IOSize_(2)]);
      end
      
      function blk = set.C(blk,Value)
         % SET method for C property
         blk.Parameterization_.c = pmodel.checkParameter(...
            Value,'C',[blk.IOSize_(1) blk.Nx_]);
      end
      
      function blk = set.D(blk,Value)
         % SET method for D property
         blk.Parameterization_.d = pmodel.checkParameter(...
            Value,'D',blk.IOSize_);
      end
      
      function blk = set.StateName(blk,Value)
         % SET method for StateName property
         Value = ltipack.mustBeStringVector(Value,'StateName',false);
         if ~any(numel(Value)==[0 blk.Nx_])
            ctrlMsgUtils.error('Control:ltiobject:ssProperties3','StateName')
         end
         blk.Parameterization_.StateName = Value;
      end
      
      function blk = set.StateUnit(blk,Value)
         % SET method for StateUnit property
         Value = ltipack.mustBeStringVector(Value,'StateUnit',false);
         if ~any(numel(Value)==[0 blk.Nx_])
            ctrlMsgUtils.error('Control:ltiobject:ssProperties3','StateUnit')
         end
         blk.Parameterization_.StateUnit = Value;
      end
         
   end
   
   %% SUPERCLASS INTERFACES
   methods (Access=protected)

      function displaySize(blk,sizes)
         % Display for "size(sys)"
         disp(getString(message('Control:lftmodel:SizeSS1',sizes(1),sizes(2),blk.Nx_)))
      end

      % PARAMETRIC BLOCK
      function np = nparams_(blk,varargin)
         % Number of parameters
         if nargin>1
            np = nparams(blk.Parameterization_,varargin{:});
         else
            np = prod(blk.IOSize_ + blk.Nx_);
         end
      end
      
      function isf = isfree_(blk)
         % True for free parameters
         isf = isfree(blk.Parameterization_);
      end
      
      function blk = zeroThru_(blk,mustZero)
         % Fix specified entries of block feedthrough to zero to eliminate 
         % feedthrough term in H2 goals
         mustZero = mustZero & blk.Parameterization_.d.Free;
         blk.Parameterization_.d.Value(mustZero) = 0;
         blk.Parameterization_.d.Free(mustZero) = false;
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
         nx = blk.Nx_;  ios = blk.IOSize_;
         Astruct = getStructure(blk);
         
         % Generate random samples
         P = zeros(nparams_(blk),N);
         for j=1:N
            [a,b,c,d] = tunableSS.randABCD(Astruct,nx,ios(1),ios(2),blk.Ts_);
            P(:,j) = [a(:);b(:);c(:);d(:)];
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
         [a,b,c,d] = ssdata_(blk);
         boo = isreal(a) && isreal(b) && isreal(c) && isreal(d);
      end
      
      function boo = isstatic_(blk,~)
         % Block is static if A=[] (note: order cannot change after construction)
         boo = isempty(blk.Parameterization_.a.Value);
      end
      
      function ns = order_(blk)
         % Get number of states
         ns = blk.Nx_;
      end
      
      function boo = isstable_(blk,varargin)
         boo = isstable(ltipack_ssdata(blk))==1;
      end
      
      function [a,b,c,d,Ts] = ssdata_(blk,varargin)
         % Quick access to explicit state-space data
         if ~isequal(1,1,varargin{:})
            ctrlMsgUtils.error('Control:ltiobject:access2')
         end
         blkParam = blk.Parameterization_;
         a = blkParam.a.Value;
         b = blkParam.b.Value;
         c = blkParam.c.Value;
         d = blkParam.d.Value;
         Ts = blk.Ts_;
      end
      
      %% ANALYSIS
      function p = pole_(blk,varargin)
         a = blk.Parameterization_.a.Value;
         if allfinite(a)
            p = eig(a);
         else
            p = NaN(size(a,1),1);
         end
      end

      function varargout = timeresp_(blk,varargin)
         % Note: Needed to return correct state vector
         [varargout{1:nargout}] = timeresp_(ss_(blk),varargin{:});
      end
      
      function varargout = lsim_(blk,varargin)
         [varargout{1:nargout}] = lsim_(ss_(blk),varargin{:});
      end
      
      function [op,SINGULAR] = findop_(blk,t,p,opspec)
         % Compute operating condition for each model
         [op,SINGULAR] = findop_(ss_(blk),t,p,opspec);
      end

      %% TRANSFORMATIONS
      function [blk,xkeep] = sminreal_(blk,~)
         xkeep = true(blk.Nx_,1);
      end
      
      function blk = chgTimeUnit_(blk,newUnits)
         % Change time units without altering system behavior
         Ts = blk.Ts_;
         sf = tunitconv(blk.TimeUnit,newUnits);
         if Ts==0
            % Rescale A,B according to tnew = sf * told
            blk.A.Value = blk.A.Value/sf;
            blk.A.Minimum = blk.A.Minimum/sf;
            blk.A.Maximum = blk.A.Maximum/sf;
            blk.A.Scale = blk.A.Scale/sf;
            blk.B.Value = blk.B.Value/sf;
            blk.B.Minimum = blk.B.Minimum/sf;
            blk.B.Maximum = blk.B.Maximum/sf;
            blk.B.Scale = blk.B.Scale/sf;
         elseif Ts>0
            % Update Ts
            blk.Ts_ = sf * Ts;
         end
         blk.TimeUnit = newUnits; % direct set
      end
      
      function blk = setValue_(blk,sys)
         % Sets block value. SYS can be any dynamic system with an explicit 
         % state-space representation. The order and structure are adjusted
         % to match the block order and structure.
         nx = blk.Nx_;
         Ts = blk.Ts_;
         try 
            sys = ss.convert(sys,'explicit');
         catch %#ok<CTCH>
            error(message('Control:lftmodel:ltiblockSS7',blk.Name))
         end
         try
            sys = alignSampleTime(sys,Ts,blk.TimeUnit);
         catch ME
            error(message('Control:lftmodel:setValue1',blk.Name))
         end
         
         % Adjust order
         nxsys = order(sys);
         if nxsys>nx
            % Use reduced-order approximation (note: actual order could be 
            % smaller or larger than NX)
            try %#ok<TRYNC>
               sys = balred(sys,nx);
               nxsys = order(sys);
            end
            if nxsys>nx
               error(message('Control:lftmodel:ltiblockSS8',blk.Name))
            end
         end
         if nxsys<nx
            % Add extra states
            [ny,nu] = iosize(sys);
            [a,b,c,d] = tunableSS.defaultABCD('tridiag',nx-nxsys,ny,nu,Ts);
            t = 1e-4;
            sys = sys + ss(a,t*b,t*c,t^2*d,Ts);
         end
         
         % Transform to desired structure
         [a,b,c,d] = ssdata(sys);
         try
            [a,b,c,d] = tunableSS.initStruct(getStructure(blk),a,b,c,d,Ts);
         catch ME
            throw(ME)
         end
         
         % Update parameters
         blkParam = blk.Parameterization_;
         blkParam.a.Value = a;
         blkParam.b.Value = b;
         blkParam.c.Value = c;
         blkParam.d.Value = d;
         blk.Parameterization_ = blkParam;
      end
      

   end
   
   
   %% HIDDEN INTERFACES
   methods (Hidden)

      % CONTROLDESIGNBLOCK
      function Offset = getOffset(blk)
         % Get default feedthrough value
         Offset = blk.Parameterization_.d.Value;
      end
      
      function D = ltipack_ssdata(blk,~,S)
         % Converts to ltipack.ssdata object
         [a,b,c,d,Ts] = ssdata_(blk);
         if nargin>1
            d = d-S;
         end
         D = ltipack.ssdata(a,b,c,d,[],Ts);
         % Note: Use default names <blkname>.xj when unspecified
         D.StateName = getStateInfo(blk,'StateName');   % string
         D.StateUnit = blk.Parameterization_.StateUnit; % to get compressed form
      end
      
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         nyu = iosize(blk);
         ioSize = sprintf('%dx%d',nyu(1),nyu(2));
         str = getString(message('Control:lftmodel:ltiblockSS6',...
            blk.Name,ioSize,blk.Nx_,ncopies));
      end
      
      function [As,Bs,Cs,D0,Dsf] = sInfo(blk)
         % Structural information about (A,B,C,D) contribution of BLK-S 
         % to the closed-loop model LFT(H(s),blkdiag(Bj-Sj)). Due to the
         % block offset S, the structure of the feedthrough D is captured 
         % by its initial value D0 and its free (tunable) entries Dsf.
         % Note: Beware that the block offset S does not always cancel D0 
         % (blocks are centered only when closing feedback loops).
         As = sInfo(blk.Parameterization_.a);
         Bs = sInfo(blk.Parameterization_.b);
         Cs = sInfo(blk.Parameterization_.c);
         D0 = blk.Parameterization_.d.Value; 
         Dsf = blk.Parameterization_.d.Free;
      end      
      
      % OPTIMIZATION
      function ns = numState(blk)
         % Size of A matrix from p2ss
         ns = blk.Nx_;
      end
      
      function [a,b,c,d] = p2ss(blk,p)
         % Constructs realization A(p),B(p),C(p),D(p) from parameter vector p
         nx = blk.Nx_;
         s = blk.IOSize_;  ny = s(1);  nu = s(2);
         i1 = 0;   i2 = nx^2;      a = reshape(p(i1+1:i2),nx,nx);
         i1 = i2;  i2 = i1+nx*nu;  b = reshape(p(i1+1:i2),nx,nu);
         i1 = i2;  i2 = i1+nx*ny;  c = reshape(p(i1+1:i2),ny,nx);
         i1 = i2;  i2 = i1+ny*nu;  d = reshape(p(i1+1:i2),ny,nu);
      end
      
      function gj = gradUV(blk,~,u,v,j)
         % Computes the gradient of the inner product
         %    phi(p) = Re(Trace(U'*[A(p) B(p);C(p) D(p)]*V))
         % with respect to the block parameters p(j) where j is a vector
         % of indices. The real or complex matrices U and V must have the
         % same number of columns.
         Gm = real(u*v');
         [rs,cs] = size(Gm);
         ios = blk.IOSize_;
         ny = ios(1);  nx = rs-ny;
         % Reorder entries
         np = rs*cs;
         k = nx*cs;
         g = zeros(np,1);
         g(1:k) = Gm(1:nx,:);
         g(k+1:np) = Gm(nx+1:nx+ny,:);
         % Select relevant entries
         gj = g(j);
      end
      
      % LFTBlockWrapper
      function SNU = getStateInfo(blk,Prop)
         % Get state names or units
         if isempty(blk.Parameterization_)
            SNU = [];
         else
            SNU = blk.Parameterization_.(Prop);
         end
         if isempty(SNU)
            if strcmp(Prop,'StateName')
               SNU = string(blk.Name) + ".x" + (1:blk.Nx_)';
            else
               SNU = strings(blk.Nx_,1);
            end
         end
      end
               
   end
   
   
   %% UTILITIES
   methods (Access = protected)

      function s = getStructure(blk)
         % Looks for tridiagonal or companion structure in A matrix
         aF = blk.Parameterization_.a.Free;
         n = size(aF,1);
         aF1 = aF;  aF1([1:n+1:n^2,2:n+1:n^2,n+1:n+1:n^2]) = false;
         aF2 = aF;  aF2(1,:) = false; aF2(2:n+1:n^2) = false;
         if n>2 && ~any(aF1(:))
            s = 'tridiag';
         elseif n>1 && ~any(aF2(:))
            s = 'companion';
         else
            s = 'full';
         end
      end
      
   end
   
   %% STATIC METHODS
   methods (Static, Access = protected)
      
      [a,b,c,d] = defaultABCD(Astruct,nx,ny,nu,Ts)
      [a,b,c,d] = randABCD(Astruct,nx,ny,nu,Ts)
            
      function [a,b,c,d] = initStruct(AStruct,a,b,c,d,Ts)
         % Transforms A,B,C,D to the specified structure
         nx = size(a,1);
         switch AStruct(1)
            case 't'
               % Make A tridiagonal if not already
               as = a;  
               as([1:nx+1:nx^2,2:nx+1:nx^2,nx+1:nx+1:nx^2]) = 0;
               if norm(as,1)>0
                  % Scale
                  [a,b,c] = ltipack.xscale(a,b,c,d,[],Ts,'Warn',false);
                  % Transform
                  [T,a] = bdschur(a,1e4);
                  b = T\b;
                  c = c*T;
                  % Discard entries outside tridiagonal band
                  a = triu(tril(a,1),-1);
                  % Scale again (T not orthogonal)
                  [a,b,c] = ltipack.xscale(a,b,c,d,[],Ts,'Warn',false);
               end
            case 'c'
               % Requires A to be a companion matrix
               as = a;
               as(1,:) = 0;  as(2:nx+1:nx^2) = 0;
               if norm(as,1)>0
                  error(message('Control:lftmodel:ltiblockSS5'))
               end
         end
      end
            
   end
   
   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for tunableSS objects
         blk = DynamicSystem.updateMetaData(s);
         % Restore transient property
         blk.Nx_ = size(s.Parameterization_.a.Value,1);
         % Update version
         blk.Version_ = ltipack.ver();
      end
      
   end
      
end

