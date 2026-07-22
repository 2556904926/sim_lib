classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      tunableGain < tunableLTI
   %tunableGain  Tunable static gain.
   %
   %   BLK = tunableGain(NAME,NY,NU) creates a parametric gain block BLK  
   %   with NY outputs and NU inputs. The string NAME specifies the block name.
   %
   %   BLK = tunableGain(NAME,G) uses the gain value G to dimension the  
   %   block and initialize the block parameters.
   %
   %   Use the BLK.Gain.Free field to specify additional structure or fix 
   %   specific entries in MIMO gains G. For example, BLK.Gain.Free(1,2)=true
   %   designates G(1,2) as a free parameter, and BLK.Gain.Free(1,2)=false 
   %   fixes G(1,2) to its current value.
   %
   %   Use SYSTUNE to automatically tune the free parameters of BLK.
   %
   %   Example: Parameterize 2-by-2 gain matrices of the form [g1 0;0 g2]: 
   %      blk = tunableGain('g',zeros(2));
   %      blk.Gain.Free = [1 0;0 1];   % fix off-diagonal entries to zero
   %
   %   See also tunableTF, tunableSS, ControlDesignBlock, systune.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
   
   properties (Access = public, Dependent)   
      % Gain matrix (scalar- or matrix-valued parameter).
      %
      % Use this property to interact with the tunable parameters of
      % parametric gains. For example, you can initialize parameters, 
      % access their current values, and fix or free some parameters.
      Gain
   end
   
   properties (Access = protected)
      % Storage properties
      Gain_  % param.Continuous
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

      function blk = tunableGain(Name,varargin)
         ni = nargin;
         % Validate Name
         if ni==0
            blk.IOSize_ = [0 0];  return
         end
         % Check remaining input arguments
         try
            switch ni
               case 2
                  % ltiblk.ss(name,GainMatrix)
                  g0 = varargin{1};
                  if ~(isnumeric(g0) && ismatrix(g0))
                     error(message('Control:lftmodel:ltiblockGain1'))
                  end
                  [ny,nu] = size(g0);
                  g0 = double(g0);
               case 3
                  % ltiblk.gain(name,ny,nu)
                  if ~all(cellfun(@(x) isnumeric(x) && isscalar(x) && isreal(x) && ...
                        x==floor(x) && x>=0,varargin))
                     error(message('Control:lftmodel:ltiblockGain3'))
                  end
                  ny = varargin{1};  nu = varargin{2};
                  g0 = zeros(ny,nu);
               otherwise
                  error(message('Control:general:InvalidSyntaxForCommand','tunableGain','tunableGain'))
            end
            blk.Name = Name;
         catch ME
            throw(ME)
         end
         % Initialize block
         blk.IOSize_ = [ny,nu];
         blk.Gain_ = param.Continuous('Gain',g0);
         blk.Ts_ = 0;
      end
      
      function Value = get.Gain(blk)
         % GET method for Gain property
         Value = blk.Gain_;
      end
            
      function blk = set.Gain(blk,Value)
         % SET method for Gain property
         blk.Gain_ = pmodel.checkParameter(Value,'Gain',blk.IOSize_);
      end
      
      
   end
   

   %% SUPERCLASS INTERFACES
   methods (Access=protected)

      function displaySize(~,sizes)
         % Display for "size(sys)"
         disp(getString(message('Control:lftmodel:SizeGAIN1',sizes(1),sizes(2))))
      end
      
      % TUNABLEBLOCK
      function np = nparams_(blk,varargin)
         % Number of parameters
         if nargin>1
            % Number of free parameters
            np = numel(find(blk.Gain_.Free));
         else
            np = prod(blk.IOSize_);
         end
      end
      
      function isf = isfree_(blk)
         % True for free parameters
         isf = blk.Gain_.Free(:);
      end
      
      function blk = zeroThru_(blk,mustZero)
         % Fix specified entries of block feedthrough to zero to eliminate 
         % feedthrough term in H2 goals
         mustZero = mustZero & blk.Gain_.Free;
         blk.Gain_.Value(mustZero) = 0;
         blk.Gain_.Free(mustZero) = false;
      end
      
      function p = getp_(blk,varargin)
         % Get vector of parameter values
         g = blk.Gain_;
         if nargin>1
            p = g.Value(g.Free);
         else
            p = g.Value;
         end
         p = p(:);
      end
      
      function [pMin,pMax] = getpMinMax_(blk)
         % Get parameter bounds
         pMin = blk.Gain_.Minimum(:);
         pMax = blk.Gain_.Maximum(:);
      end
      
      function blk = setp_(blk,p,varargin)
         % Set vector of parameter values
         ni = nargin;
         g = blk.Gain_;
         if ni>2
            np = numel(find(g.Free));
         else
            np = prod(blk.IOSize_);
         end
         if np~=length(p)
            error(message('Control:pmodel:setp'))
         elseif ni>2
            g.Value(g.Free) = p;
         else
            g.Value(:) = p;
         end
         blk.Gain_ = g;
      end
      
      function P = randp_(blk,N,varargin)
         % Generates random samples of model parameters.
         [pMin,pMax] = getpMinMax(blk);
         p0 = blk.Gain.Value;
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
      
      %% MODEL CHARACTERISTICS
      function boo = isreal_(blk,~)
         % Returns true if the current value is real
         boo = isreal(blk.Gain_.Value);
      end
      
      function ns = order_(blk) %#ok<*MANU>
         ns = 0;
      end
      
      function [a,b,c,d,Ts] = ssdata_(blk,varargin)
         % Quick access to explicit state-space data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         d = blk.Gain_.Value;
         [ny,nu] = size(d);
         a = [];  b = zeros(0,nu);  c = zeros(ny,0);
         Ts = blk.Ts_;
      end      

      %% TRANSFORMATIONS
      function blk = chgTimeUnit_(blk,newUnits)
         % Rescale time vector: tnew = sf * told
         if blk.Ts_>0
            blk.Ts_ = tunitconv(blk.TimeUnit,newUnits) * blk.Ts_;
         end
         blk.TimeUnit = newUnits; % direct set
      end
      
      function blk = setValue_(blk,g)
         % G can be a matrix or a dynamic system (SETVALUE uses the DC gain 
         % for dynamic systems).
         try
            if isa(g,'DynamicSystem')
               g = dcgain(g);
            else
               g = double(g);
            end
         catch %#ok<CTCH>
            error(message('Control:lftmodel:ltiblockGain2',blk.Name))
         end
         if ~allfinite(g)
            error(message('Control:lftmodel:ltiblockGain2',blk.Name))
         end
         blk.Gain_.Value = g;
      end

      %% ANALYSIS
      function p = pole_(~,varargin)
         p = zeros(0,1);
      end

   end

         
   %% HIDDEN INTERFACES
   methods (Hidden)
      
      % CONTROLDESIGNBLOCK INTERFACE
      function Offset = getOffset(blk)
         % Get default feedthrough value
         Offset = blk.Gain_.Value;
      end
      
      function D = ltipack_ssdata(blk,~,S)
         % Converts to ltipack.ssdata object
         [a,b,c,d,Ts] = ssdata_(blk);
         if nargin>1
            d = d-S;
         end
         D = ltipack.ssdata(a,b,c,d,[],Ts);
      end
      
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         nyu = iosize(blk);
         ioSize = sprintf('%dx%d',nyu(1),nyu(2));
         str = getString(message('Control:lftmodel:ltiblockGain5',...
            blk.Name,ioSize,ncopies));
      end
      
      function [As,Bs,Cs,D0,Dsf] = sInfo(blk)
         % Structural information about (A,B,C,D) contribution of BLK-S 
         % to the closed-loop model LFT(H(s),blkdiag(Bj-Sj)). Due to the
         % block offset S, the structure of the feedthrough D is captured 
         % by its initial value D0 and its free (tunable) entries Dsf.
         % Note: Beware that the block offset S does not always cancel D0 
         % (blocks are centered only when closing feedback loops).
         ios = blk.IOSize_;
         As = false(0);
         Bs = false(0,ios(2));
         Cs = false(ios(1),0);
         % Fixed entries of BLK-S feedthrough are fixed to zero
         D0 = blk.Gain_.Value;
         Dsf = blk.Gain_.Free;
      end
      
      % OPTIMIZATION INTERFACE
      function ns = numState(blk) %#ok<*MANU>
         ns = 0;
      end
      
      function [a,b,c,d] = p2ss(M,p)
         % Constructs realization A(p),B(p),C(p),D(p) from parameter vector p
         ios = M.IOSize_;  ny = ios(1);  nu = ios(2);
         a = [];
         b = zeros(0,nu);
         c = zeros(ny,0);
         d = reshape(p,[ny nu]);
      end
      
      function gj = gradUV(~,~,u,v,j)
         % Computes the gradient of the inner product
         %    phi(p) = Re(Trace(U'*[A(p) B(p);C(p) D(p)]*V))
         % with respect to the block parameters p(j) where j is a vector
         % of indices. The real or complex matrices U and V must have the
         % same number of columns.
         G = real(u*v');
         gj = reshape(G(j),[numel(j) 1]);
      end
         
   end

   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for tunableGain objects
         blk = DynamicSystem.updateMetaData(s);
         blk.Version_ = ltipack.ver();
      end
      
   end

end




