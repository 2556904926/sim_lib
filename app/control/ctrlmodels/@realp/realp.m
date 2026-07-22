classdef (CaseInsensitiveProperties, TruncatedProperties) ...
      realp < tunableBlock & StaticModel
   %REALP  Create real tunable parameter.
   %
   %   P = REALP(NAME,VALUE) creates a tunable real-valued parameter P with 
   %   name and initial value specified by the string NAME and the numeric  
   %   array VALUE. The resulting parameter object P is of class @realp.
   %
   %   Using ordinary arithmetic operators (+, -, *, /, \, ^), you can 
   %   combine real parameter objects into rational expressions and use 
   %   these expressions to create parametric models (both static and
   %   dynamic). You can then use such models to perform parameter studies, 
   %   or tune control systems. See CONTROLDESIGNBLOCK and GENLTI for more 
   %   information.
   %
   %   Example: Construct the parametric matrix M = [1 a-b;0 a*b^2/(a+b)]  
   %   where a and b are real parameters with initial values 2 and -1:
   %      a = realp('a',2)
   %      b = realp('b',-1)
   %      M = [1 a-b;0 a*b^2/(a+b)]
   %   The resulting M is a generalized matrix (see GENMAT) depending on a,b.
   %
   %   Example: Create a low-pass filter H(s) = w0/(s+w0) parameterized by the
   %   cutoff frequency w0:
   %      w0 = realp('w0',10);   s = tf('s');
   %      H = tf(w0,[1 w0]);
   %   This produces a generalized state-space model H (see GENSS). For the
   %   current value w0=10 its transfer function tf(H) is 10/(s+10) as expected.
   %
   %   See also GENMAT, GENSS, GENFRD, CONTROLDESIGNBLOCK.
   
%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
   
   properties (Dependent)
      % Parameter value (double array).
      Value
      % Lower bound for the parameter value.
      Minimum
      % Upper bound for the parameter value.
      Maximum
      % True for tunable parameters.
      %
      % For matrix-valued parameters, this property specifies which entries of 
      % the matrix are tunable.
      Free
   end 
   
   properties (Access = protected)
      Value_
      Minimum_
      Maximum_
      Free_
   end
      
   %% TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genmat';
      end
      
      % Note: getAttributes never called (first converted to GENMAT)
                  
   end
    
   %% PUBLIC METHODS
   methods
      
      function blk = realp(name,value)
         ni = nargin;
         if ni==2
            if ~(isnumeric(value) && isreal(value) && ismatrix(value))
               error(message('Control:lftmodel:realp2'))
            end
            ios = size(value);
            blk.Name = name;
            blk.IOSize_ = ios;
            blk.Free_ = true(ios);
            blk.Value_ = full(double(value));
         elseif ni==0
            blk.IOSize_ = [0 0];
         else
            error(message('Control:lftmodel:realp1'))
         end
      end
            
      function Value = get.Value(blk)
         % GET function for Value property
         Value = blk.Value_;
      end
      
      function Value = get.Minimum(blk)
         % GET function for Mimimum property
         Value = blk.Minimum_;
         if isempty(Value)
            Value = -Inf(blk.IOSize_);
         end
      end
      
      function Value = get.Maximum(blk)
         % GET function for Maximum property
         Value = blk.Maximum_;
         if isempty(Value)
            Value = Inf(blk.IOSize_);
         end
      end
      
      function Value = get.Free(blk)
         % GET function for Free property
         Value = blk.Free_;
      end
      
      function blk = set.Value(blk,A)
         % SET function for Value property
         if ~(isnumeric(A) && isreal(A))
            error(message('Control:lftmodel:realp3','Value'))
         elseif isscalar(A)
            A = repmat(A,blk.IOSize_);
         elseif ~isequal(size(A),blk.IOSize_)
            error(message('Control:lftmodel:realp8'))
         end
         blk.Value_ = full(double(A));
      end
      
      function blk = set.Minimum(blk,A)
         % SET function for Minimum property
         if ~(isnumeric(A) && isreal(A))
            error(message('Control:lftmodel:realp3','Minimum'))
         elseif isscalar(A)
            A = repmat(A,blk.IOSize_);
         elseif ~isequal(size(A),blk.IOSize_)
            error(message('Control:lftmodel:realp8'))
         end
         blk.Minimum_ = full(double(A));
      end
      
      function blk = set.Maximum(blk,A)
         % SET function for Maximum property
         if ~(isnumeric(A) && isreal(A))
            error(message('Control:lftmodel:realp3','Maximum'))
         elseif isscalar(A)
            A = repmat(A,blk.IOSize_);
         elseif ~isequal(size(A),blk.IOSize_)
            error(message('Control:lftmodel:realp8'))
         end
         blk.Maximum_ = full(double(A));
      end
      
      function blk = set.Free(blk,A)
         % SET function for Free property
         if isnumeric(A)
            A = (A~=0);
         end
         if ~islogical(A)
            error(message('Control:lftmodel:realp9'))
         elseif isscalar(A)
            A = repmat(A,blk.IOSize_);
         elseif ~isequal(size(A),blk.IOSize_)
            error(message('Control:lftmodel:realp8'))
         end
         blk.Free_ = A;
      end
      
end

   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)

      function displaySize(~,sizes)
         % Display for "size(M)"
         if all(sizes==1)
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeREALP1'))
         else
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeREALP2',sizes(1),sizes(2)))
         end
      end
      
      % TUNABLEBLOCK
      function np = nparams_(blk,varargin)
         % Number of parameters
         if nargin>1
            % Number of free parameters
            np = numel(find(blk.Free_));
         else
            np = prod(blk.IOSize_);
         end
      end
      
      function isf = isfree_(blk)
         % True for free parameters
         isf = blk.Free_(:);
      end
      
      function blk = zeroThru_(blk,mustZero)
         % Fix specified entries of block feedthrough to zero to eliminate 
         % feedthrough term in H2 goals
         mustZero = mustZero & blk.Free_;
         blk.Value_(mustZero) = 0;
         blk.Free_(mustZero) = false;
      end
      
      function p = getp_(blk,varargin)
         % Get vector of parameter values
         if nargin>1
            p = blk.Value_(blk.Free_);
         else
            p = blk.Value_;
         end
         p = p(:);
      end
      
      function [pMin,pMax] = getpMinMax_(blk)
         % Get parameter bounds
         pMin = blk.Minimum(:);
         pMax = blk.Maximum(:);
      end
      
      function blk = setp_(blk,p,varargin)
         % Set vector of parameter values
         ni = nargin;
         if ni>2
            np = numel(find(blk.Free_));
         else
            np = prod(blk.IOSize_);
         end
         if np~=length(p)
            error(message('Control:pmodel:setp'))
         elseif ni>2
            blk.Value_(blk.Free_) = p;
         else
            blk.Value_(:) = p;
         end
      end 

      function P = randp_(blk,N,varargin)
         % Generates random samples of model parameters.
         [pMin,pMax] = getpMinMax(blk);
         p0 = blk.Value_;
         np = numel(p0);
         P = zeros(np,N);
         for ct=1:np
            P(ct,:) = TuningGoal.randomizeGain(N,p0(ct),pMin(ct),pMax(ct));
         end
         if nargin>2
            P = P(isfree_(blk),:);
         end
      end
            
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
            
      %% INDEXING
      function M = createLHS(~)
         % Creates LHS in assignment.
         % Returns 0x0 GENMAT
         M = genmat();
      end
      
      %% TRANSFORMATIONS
      function M = repmat_(blk,s)
         M = repmat_(genmat(blk),s);
      end
      
      function M = uminus_(blk)
         M = uminus_(genmat(blk));
      end
      
      function blk = setValue_(blk,g)
         % Modify block value. G can be a REALP or a numeric array.
         if isa(g,'ControlDesignBlock')
            g = getValue(g);
         end
         if ~(isnumeric(g) && isreal(g))
            error(message('Control:lftmodel:realp10',blk.Name))
         end
         blk.Value = g;
      end

            
   end
   
   
   %% HIDDEN INTERFACES
   methods (Hidden)
      
      % CONTROLDESIGNBLOCK
      function Offset = getOffset(blk)
         % Get default value
         Offset = blk.Value_;
      end
      
      function D = ltipack_ssdata(blk,varargin)
         % Converts to ltipack.ssdata
         d = numeric_array(blk,varargin{:});
         [ny,nu] = size(d);
         D = ltipack.ssdata([],zeros(0,nu),zeros(ny,0),d,[],0);
      end

      function D = ltipack_frddata(blk,freq,varargin)
         % Converts to ltipack.frddata
         d = numeric_array(blk,varargin{:});
         D = ltipack.frddata(repmat(d,[1 1 length(freq)]),freq,0);
      end
      
      function M = numeric_array(blk,~,S)
         % Converts to double array. Evaluates blk-S when S supplied
         % (R is always [] for non-uncertain blocks)
         M = blk.Value_;
         if nargin>1
            M = M-S;
         end
      end
      
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         nyu = blk.IOSize_;
         if all(nyu==1)
            str = ctrlMsgUtils.message('Control:lftmodel:realp5',blk.Name,ncopies);
         else
            ioSize = sprintf('%dx%d',nyu(1),nyu(2));
            str = ctrlMsgUtils.message('Control:lftmodel:realp4',blk.Name,ioSize,ncopies);
         end
      end
      
      function [As,Bs,Cs,D0,Dsf] = sInfo(blk)
         % Structural information about (A,B,C,D) contribution of BLK-S 
         % to the closed-loop model LFT(H(s),blkdiag(Bj-Sj)). Due to the
         % block offset S, the structure of the feedthrough D is captured 
         % by its initial value D0 and its free (tunable) entries Dsf.
         ios = blk.IOSize_;
         As = false(0);
         Bs = false(0,ios(2));
         Cs = false(ios(1),0);
         D0 = blk.Value_;
         Dsf = blk.Free_;
      end
      
      function CS = randSample_(blk,N)
         % Randomly samples real parameter. Returns N-by-1 cell array of 
         % double values.
         P = randp_(blk,N);
         isf = isfree_(blk);
         if ~all(isf)
            % Overwrite fixed entries
            p0 = getp_(blk);
            P(~isf,:) = p0(~isf,ones(N,1));
         end
         CS = squeeze(num2cell(reshape(P,[blk.IOSize_ N]),[1 2]));
      end
      
      % OPTIMIZATION
      function ns = numState(~)
         % Size of A matrix from p2ss
         ns = 0;
      end

      function [a,b,c,d] = p2ss(blk,p)
         % Constructs realization A(p),B(p),C(p),D(p) from parameter vector p
         ios = blk.IOSize_;
         a = [];  b = zeros(0,ios(2));  c = zeros(ios(1),0);  d = reshape(p,ios);
      end
      
      function gj = gradUV(~,~,u,v,j)
         % Computes the gradient of the inner product
         %    phi(p) = Re(Trace(U'*[A(p) B(p);C(p) D(p)]*V))
         % with respect to the block parameters p(j) where j is a vector
         % of indices. The real or complex matrices U and V must have the
         % same number of columns.
         Gm = real(u*v');
         gj = reshape(Gm(j),[numel(j) 1]);
      end
      
   end
   
   
   methods (Access = protected)
      % Indexing operations (see RedefinesParen)
      function M = parenReference(blk, indexingOperation)
         % Indexing forces conversion to GENMAT
         M = parenReference(genmat(blk), indexingOperation);
      end
            
   end
   
   
   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for @realp objects
         if isstruct(s)
            if isfield(s,'pID')
               % Reloading 11a version (subclass of param.Continuous)
               blk = realp(s.pID.Name,s.Value_);
               if ~isempty(s.Free_)
                  blk.Free = s.Free_;
               end
               if ~isempty(s.Minimum_)
                  blk.Minimum = s.Minimum_;
               end
               if ~isempty(s.Maximum_)
                  blk.Maximum = s.Maximum_;
               end
            end
         else
            % Update version
            blk = s;
            blk.Version_ = ltipack.ver();
         end
      end
      
   end
   
end
