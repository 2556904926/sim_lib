classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) hinfstruct < ltioptions.Generic
   % Options set for structured H-infinity synthesis.
   
   % Author: P. Gahinet
%   Copyright 2009-2012 The MathWorks, Inc.
   
   properties
      % Display level (default = 'final').
      %
      % This option controls the amount of information displayed by the 
      % underlying optimization process. By default HINFSTRUCT prints a
      % one-line summary at the end of each optimization run. Set 
      % Display='iter' to show the optimization progress after each 
      % iteration, Display='sub' to show the result of each subproblem
      % involved in solving problems with spectral radius constraints, and 
      % Display='off' to run silently without printing any message in the 
      % command window.
      Display = 'final';

      % Maximum number of iterations (default = 300).
      MaxIter = 300;
      
      % Number of randomized starts (default = 0).
      %
      % You can automatically run one or more optimizations starting from
      % random initial values to mitigate the risk of premature termination
      % due to local minima. Setting RandomStart=0 runs a single optimization
      % starting from the initial values of the tunable blocks. Setting
      % RandomStart=N>0 runs N additional optimizations starting from N
      % randomly generated values of the free parameters.
      RandomStart = 0;
      
      % Parallel computing flag (default = false).
      % 
      % Setting UseParallel=true enables parallel computing by distributing the
      % randomized starts among MATLAB workers and running the optimizations 
      % concurrently. This option requires the Parallel Computing Toolbox.
      UseParallel = false;
      
      % Target H-infinity norm (default = 0).
      %
      % The optimization stops when the peak closed-loop gain falls below
      % the specified TargetGain value. Set TargetGain=0 to minimize the
      % peak closed-loop gain. Set TargetGain=Inf to only stabilize the
      % closed-loop system.
      TargetGain = 0;
      
      % Relative tolerance for termination criterion (default = 1e-3)
      %
      % The optimization stops when the relative decrease of the H-infinity
      % norm over the last 10 iterations falls below TolGain. Increasing 
      % TolGain speeds up termination at the expense of higher final values
      % for the H-infinity norm. Decreasing TolGain improves the final values
      % at the expense of more iterations.
      TolGain = 1e-3;
      
      % Minimum decay rate for closed-loop poles (default = 1e-7).
      %
      % Constrains the closed-loop poles to satisfy
      %    Re(p) < -MinDecay.
      % Increase this value to push the closed-loop poles farther into the 
      % stable region.
      MinDecay = 1e-7;
      
      % Maximum closed-loop natural frequency (default = NaN).
      %
      % Constrains the closed-loop poles to
      %    |p| < MaxFrequency.
      % Use this option to prevent fast dynamics and high-gain control.
      % When set to NaN, MaxFrequency is set automatically based on the 
      % open-loop dynamics.
      MaxFrequency = Inf;
   end
   
   properties (Hidden, Dependent)
      % Renamed properties
      SpecRadius
      StableOffset
   end
   
   properties (Hidden, Transient)
      StableExclude;      % obsolete
      StableRadius = 0;   % obsolete
      Hidden = struct(...
         'Trace',NSOptLog.Options(),... % Display/instrumentation options
         'Phase2','off',...   % Run Phase 2 when on
         'Simulink',false);
   end
   
   
   methods
      
      function value = get.SpecRadius(this)
         value = this.MaxFrequency;
      end
      
      function value = get.StableOffset(this)
         value = this.MinDecay;
      end
      
      function this = set.Display(this,value)
         % SET method for Display option
         value = ltipack.matchKey(value,{'off','final','sub','iter'});
         if isempty(value)
            error(message('Control:tuning:hinfstruct10'))
         end
         this.Display = value;
      end
            
      function this = set.MaxIter(this,value)
         % SET method for MaxIter option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && ~isnan(value) && value>0)
            ctrlMsgUtils.error('Control:tuning:hinfstruct11')
         end
         this.MaxIter = round(double(value));
      end
      
      function this = set.RandomStart(this,value)
         % SET method for RandomStart option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>=0)
            ctrlMsgUtils.error('Control:tuning:hinfstruct12')
         end
         this.RandomStart = round(double(value));
      end
      
      function this = set.UseParallel(this,value)
         % SET method for UseParallel option
         if isnumeric(value)
            value = (value~=0);
         end
         if ~(isscalar(value) && islogical(value))
            ctrlMsgUtils.error('Control:tuning:hinfstruct14')
         end
         this.UseParallel = logical(value);
      end
                  
%       function this = set.StableRadius(this,value)
%          % SET method for StableRadius option
%          if ~(isnumeric(value) && isscalar(value) && isreal(value)) || value<0 || isinf(value)
%             ctrlMsgUtils.error('Control:tuning:NonNegativeFiniteScalar','StableRadius')
%          end
%          this.StableRadius = double(value);
%       end
      
      function this = set.MinDecay(this,value)
         % SET method for MinDecay option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>=0)
            error(message('Control:tuning:NonNegativeFiniteScalar','MinDecay'))
         end
         this.MinDecay = double(value);
      end
      
      function this = set.MaxFrequency(this,value)
         % SET method for MaxFrequency option
         if isequaln(value,NaN)
            % Remap NaN to Inf (used to mean "automatically adjusted")
            value = Inf;
         elseif ~(isnumeric(value) && isscalar(value) && isreal(value) && value>0)
            ctrlMsgUtils.error('Control:tuning:PositiveScalar','MaxFrequency')
         end
         this.MaxFrequency = double(value);
      end
      
      function this = set.TargetGain(this,value)
         % SET method for TargetGain option
         if ~(isnumeric(value) && isscalar(value) && isreal(value) && value>=0)
            ctrlMsgUtils.error('Control:tuning:NonNegativeScalar','TargetGain')
         end
         this.TargetGain = double(value);
      end
      
      function this = set.TolGain(this,value)
         % SET method for TolGain option
         if ~(isnumeric(value) && isscalar(value) && isreal(value) && value>0 && value<1)
            ctrlMsgUtils.error('Control:tuning:hinfstruct16')
         end
         this.TolGain = double(value);
      end
      
      function this = set.SpecRadius(this,value)
         this.MaxFrequency = value;
      end
      
      function this = set.StableOffset(this,value)
         this.MinDecay = value;
      end
      
   end
   
   methods (Access = protected)
      function cmd = getCommandName(~)
         cmd = 'hinfstruct';
      end
   end
   
   methods (Hidden)
      function Opt = systuneOptions(this)
         % Maps HINFSTRUCT option set to SYSTUNE option set
         Opt = systuneOptions();
         Opt.Display = this.Display;
         Opt.MaxIter = this.MaxIter;
         Opt.RandomStart = this.RandomStart;
         Opt.UseParallel = this.UseParallel;
         Opt.SoftTarget = this.TargetGain;
         Opt.SoftTol = this.TolGain;
         Opt.MinDecay = this.MinDecay;
         Opt.Hidden.Trace = this.Hidden.Trace;
      end
   end
   
   methods(Static, Hidden)
      
      function opt = loadobj(s)
         % Load filter
         if isstruct(s)
            % Pre-R2012a
            opt = hinfstructOptions();
            opt.Display = NSOptLog.Options.getDisplay(s.Trace.Verbosity,12);
            opt.MaxIter = s.MaxIter;
            opt.RandomStart = s.RandomStart;
            opt.TargetGain = s.TargetGain;
            opt.TolGain = s.TolGain;
            opt.MinDecay = s.StableOffset;
            if isfinite(s.SpecRadius)
               opt.MaxFrequency = s.SpecRadius;
            end
         else
            opt = s;
            if opt.Version_<13
               % R2012a
               opt.StableExclude = [];
               opt.StableRadius = 0;
            end
            if opt.Version_<15
               % Get display from Verbosity flag (Display used to be dependent)
               opt.Display = NSOptLog.Options.getDisplay(...
                  opt.Hidden.Trace.Verbosity,opt.Version_);
               % Reset "Hidden" which is no longer saved
               opt.Hidden = get(hinfstructOptions(),'Hidden');
            end
            opt.Version_ = ltipack.ver();
         end
      end
      
   end
   
end

