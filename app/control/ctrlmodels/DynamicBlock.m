classdef DynamicBlock < DynamicSystem & ControlDesignBlock
   % Dynamic Control Design blocks.
   %
   %   Dynamic Control Design blocks are special dynamic system components
   %   used for analyzing and tuning control systems. These include:
   %     * Parametric LTI blocks such as tunableGain, tunablePID,
   %       tunableTF, and tunableSS. For example,
   %           PI = tunablePID('C','pi')
   %       creates a tunable PI controller named "C".
   %     * Uncertain dynamics such as ULTIDYN
   %     * Analysis points for opening and closing loops (AnalysisPoint).
   %
   %   Using commands like CONNECT or FEEDBACK, these blocks can be combined
   %   with ordinary LTI models to build tunable or uncertain models of your
   %   control systems.
   %
   %   See also tunableGain, tunablePID, tunableTF, tunableSS, ULTIDYN,
   %   AnalysisPoint, ControlDesignBlock, DynamicSystem, GENLTI.
   
   %   Copyright 2010-2015 The MathWorks, Inc.
   
   properties (Access = protected)
      % Storage property for sampling time
      Ts_;
   end
   
   %% PROTECTED INTERFACES
   methods (Access = protected)
      
      % SINGLERATESYSTEM
      function Ts = getTs_(blk)
         Ts = blk.Ts_;
      end
      
      function blk = setTs_(blk,Ts)
         blk.Ts_ = Ts;
      end
      
   end
   
   
   %% HIDDEN INTERFACES
   methods (Hidden)
      
      %% CONTROLDESIGNBLOCK
      function D = ltipack_ssdata(blk,~,S)
         % Converts to ltipack.ssdata object
         [a,b,c,d,Ts] = ssdata_(blk);
         if nargin>1
            d = d-S;
         end
         D = ltipack.ssdata(a,b,c,d,[],Ts);
      end
      
      function D = ltipack_frddata(blk,freq,varargin)
         % Converts to ltipack.frddata object assuming FREQ in rad/TimeUnit
         D = frd(ltipack_ssdata(blk,varargin{:}),freq);
      end
      
      % LFTBlockWrapper
      function SNU = getStateInfo(~,~)
         % Get state names or units
         SNU = cell(0,1);
      end
      
   end
   
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      %% MODEL CHARACTERISTICS
      function [a,b,c,d,e,Ts] = dssdata_(blk,varargin)
         % Quick access to descriptor state-space data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         [a,b,c,d] = ssdata_(blk);
         e = eye(size(a));
         Ts = blk.Ts_;
      end
      
      function [a,b,c,d,e,Ts] = sparssdata_(blk,varargin)
         % Quick access to descriptor state-space data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         D = sparss(ltipack_ssdata(blk));
         [a,b,c,d,e] = getABCDE(D);
         Ts = blk.Ts_;
      end
      
      function [m,c,k,b,f,g,d,Ts] = mechssdata_(blk,varargin)
         % Quick access to MECHSS data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         D = mechss(ltipack_ssdata(blk));
         [m,c,k,b,f,g,d] = getMCKBFGD(D);
         Ts = blk.Ts_;
      end
      
      function [num,den,Ts,sdnum,sdden] = tfdata_(blk,varargin)
         % Quick access to transfer function data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         Data = tf(ltipack_ssdata(blk));
         num = Data.num;  den = Data.den;  Ts = blk.Ts_;
         sdnum = []; sdden = [];
      end
      
      function [z,p,k,Ts,covz,covp,covk] = zpkdata_(blk,varargin)
         % Quick access to ZPK data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         Data = zpk(ltipack_ssdata(blk));
         z = Data.z;  p = Data.p;  k = Data.k;  Ts = blk.Ts_;
         covz = []; covp = []; covk = [];
      end
      
      function [Kp,Ki,Kd,Tf,Ts] = piddata_(blk,varargin)
         % Extract PID coefficients
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         else
            try
               D = pid(ltipack_ssdata(blk));
            catch ME
               error(message('Control:ltiobject:piddata1'))
            end
            Kp = D.Kp;  Ki = D.Ki;  Kd = D.Kd;  Tf = D.Tf;  Ts = blk.Ts_;
         end
      end
      
      function [Kp,Ti,Td,N,Ts] = pidstddata_(blk,varargin)
         % Extract PIDSTD coefficients
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         else
            try
               D = pidstd(ltipack_ssdata(blk));
            catch ME
               error(message('Control:ltiobject:pidstddata1'))
            end
            Kp = D.Kp;  Ti = D.Ti;  Td = D.Td;  N = D.N;  Ts = blk.Ts_;
         end
      end
      
      %% CONVERSIONS
      function sys = ss_(blk,varargin)
         % Converts to @ss
         sys = ss_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = sparss_(blk,varargin)
         % Converts to @sparss
         sys = sparss_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = mechss_(blk,varargin)
         % Converts to @mechss
         sys = mechss_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = tf_(blk,varargin)
         % Converts to @tf
         sys = tf_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = zpk_(blk,varargin)
         % Converts to @zpk
         sys = zpk_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = frd_(blk,varargin)
         % Converts to @frd
         sys = frd_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pid_(blk,varargin)
         % Converts to @pid
         sys = pid_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pidstd_(blk,varargin)
         % Converts to @pidstd
         sys = pidstd_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pid2_(blk,varargin)
         % Converts to @pid2
         sys = pid2_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = pidstd2_(blk,varargin)
         % Converts to @pidstd2
         sys = pidstd2_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = genss_(blk)
         % Converts to @genss
         % Note: Clear block I/O names to allow multiple occurrences of block in
         % block in a block diagram (all BLK copies must be equal)
         blk.InputName_ = strings(0,1);
         blk.OutputName_ = strings(0,1);
         sys = genss_@ControlDesignBlock(blk);
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = uss_(blk)
         % Converts to @uss
         blk.InputName_ = strings(0,1);
         blk.OutputName_ = strings(0,1);
         sys = uss_@ControlDesignBlock(blk);
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = genfrd_(blk,freq)
         % Converts to @genfrd
         blk.InputName_ = strings(0,1);
         blk.OutputName_ = strings(0,1);
         sys = genfrd_@ControlDesignBlock(blk,freq);
         sys.TimeUnit = blk.TimeUnit;
      end
      
      function sys = ufrd_(blk,freq)
         % Converts to @ufrd
         blk.InputName_ = strings(0,1);
         blk.OutputName_ = strings(0,1);
         sys = ufrd_@ControlDesignBlock(blk,freq);
         sys.TimeUnit = blk.TimeUnit;
      end

      function sys = ltvss_(blk,varargin)
         % Converts to @ltvss
         sys = ltvss_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end

      function sys = lpvss_(blk,varargin)
         % Converts to @lpvss
         sys = lpvss_@ControlDesignBlock(blk,varargin{:});
         sys.TimeUnit = blk.TimeUnit;
      end

      %% ANALYSIS
      function varargout = dcgain_(blk)
         [varargout{1:nargout}] = dcgain_(ss(blk));
      end
      
      function fresp = evalfr_(blk,s)
         fresp = evalfr(ltipack_ssdata(blk),s);
      end
      
      function [h,SingularWarn,covH] = freqresp_(blk,w)
         [h,SingularWarn] = fresp(ltipack_ssdata(blk),w);
         covH = [];
      end
      
      function varargout = magphaseresp_(blk,varargin)
         [varargout{1:nargout}] = magphaseresp_(ss_(blk),varargin{:});
      end
      
      function varargout = nyquistresp_(blk,varargin)
         [varargout{1:nargout}] = nyquistresp_(ss_(blk),varargin{:});
      end
      
      function varargout = sigmaresp_(blk,varargin)
         [varargout{1:nargout}] = sigmaresp_(ss_(blk),varargin{:});
      end
      
      function varargout = sectorresp_(blk,varargin)
         [varargout{1:nargout}] = sectorresp_(ss_(blk),varargin{:});
      end
      
      function varargout = ifpofpresp_(blk,varargin)
         [varargout{1:nargout}] = ifpofpresp_(ss_(blk),varargin{:});
      end
      
      function varargout = vspresp_(blk,varargin)
         [varargout{1:nargout}] = vspresp_(ss_(blk),varargin{:});
      end
      
      function [y,t,Focus,x,ysd] = timeresp_(blk,varargin)
         [y,t,Focus] = timeresp_(ss_(blk),varargin{:});
         x = []; ysd = [];
      end
      
      function [y,x] = lsim_(blk,varargin)
         y = lsim_(ss_(blk),varargin{:});
         x = [];
      end
      
      function s = allmargin_(blk,opt)
         s = allmargin(ltipack_ssdata(blk),opt);
      end
      
      function fb = bandwidth_(blk,drop)
         fb = bandwidth(ltipack_ssdata(blk),drop);
      end
      
      function wc = getGainCrossover_(blk,g)
         wc = getGainCrossover(ltipack_ssdata(blk),g);
      end
      
      function wc = getSectorCrossover_(blk,varargin)
         wc = getSectorCrossover(ltipack_ssdata(blk),varargin{:});
      end
      
      function n = normh2_(blk)
         n = normh2(ltipack_ssdata(blk));
      end
      
      function [gpeak,fpeak] = norminf_(blk,varargin)
         [gpeak,fpeak] = norminf(ltipack_ssdata(blk),varargin{:});
      end
      
      function [Index,fIndex] = sectorbnd_(blk,varargin)
         [Index,fIndex] = sectorbnd(ltipack_ssdata(blk),varargin{:});
      end
      
      function [Index,fIndex] = ifpofp_(blk,varargin)
         [Index,fIndex] = ifpofp(ltipack_ssdata(blk),varargin{:});
      end
      
      function [z,g] = zero_(blk,varargin)
         [z,g] = zero(ltipack_ssdata(blk));
      end
      
      function [z,nrk] = tzero_(blk,varargin)
         [z,nrk] = tzero(ltipack_ssdata(blk),varargin{:});
      end
      
      function [r,k] = rlocus_(blk,k)
         % Root locus
         [r,k] = rlocus(ltipack_ssdata(blk),k);
      end
      
      %% TRANSFORMATIONS
      function [blk,icmap] = absorbDelay_(blk,~)
         if isa(blk,'StateSpaceModel')
            icmap = true(order(blk),1);
         else
            icmap = [];
         end
      end
      
      function blk = pade_(blk,varargin)
      end
      
      function [blk,u] = minreal_(blk,varargin)
         if isa(blk,'StateSpaceModel')
            u = eye(order(blk));
         else
            u = [];
         end
      end
      
      %% DESIGN
      function varargout = pidtune_(blk,varargin)
         % Convert block to ZPK model and proceed
         [varargout{1:nargout}] = pidtune_(zpk(blk),varargin{:});
      end
      
   end
   
   
end
