classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
   systune < ltioptions.Generic
   % Options set for SYSTUNE.
   
   % Author: P. Gahinet
%   Copyright 2009-2012 The MathWorks, Inc.
   
   properties
      % Display level (default = 'final').
      %
      % This option controls the amount of information displayed by the 
      % underlying optimization process. By default SYSTUNE prints a
      % one-line summary at the end of each optimization run. Set 
      % Display='iter' to show the optimization progress after each 
      % iteration, Display='sub' to show the result of each subproblem
      % involved in solving problems with soft and hard constraints, and 
      % Display='off' to run silently without printing any message in the 
      % command window.
      Display = 'final';

      % Maximum number of iterations (default = 500).
      MaxIter = 500;
      
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
      
      % Models or design points to ignore (default = empty).
      %
      % When tuning against an array of models or over a grid of design
      % points, use this option to skip specific models or ignore portions
      % of the design space (for example, grid points outside the flight
      % envelope or operating range). This provides a quick way to narrow
      % the scope of tuning without having to reconfigure each tuning goal.
      %
      % Set this property to a vector of absolute indices into the model 
      % array CL0 (first input argument of SYSTUNE). The default is an 
      % empty vector (no models skipped).
      SkipModels = zeros(0,1);
      
      % Target value for soft constraints (default = 0).
      %
      % The optimization stops when the maximum value of the soft constraints
      % falls below the specified SoftTarget value.
      SoftTarget = 0;
      
      % Relative tolerance for termination criterion (default = 1e-3)
      %
      % The optimization stops when the relative decrease in soft constraint
      % value over the last 10 iterations falls below SoftTol. Increasing 
      % SoftTol speeds up termination at the expense of higher final values
      % for the soft constraints. Decreasing SoftTol improves the final values
      % at the expense of more iterations.
      SoftTol = 1e-3;
      
      % A-priori estimate of best soft constraint value (default = 1).
      %
      % For problems mixing soft and hard constraints, providing a rough 
      % estimate of the best achievable value for the soft constraints  
      % typically speeds up the optimization. This parameter is ignored when 
      % all constraints are of the same nature (hard or soft).
      SoftScale = 1;
      
      % Minimum decay rate for stabilized dynamics (default = 1e-7).
      %
      % Constrains all stabilized poles and zeros to satisfy
      %      Re(s)  < -MinDecay    (continuous time)
      %    log(|z|) < -MinDecay    (discrete time).
      % Most tuning goals carry an implicit closed-loop stability constraint,
      % and the Passivity and ConicSector goals carry an implicit minimum-
      % phase constraint. "Stabilized dynamics" refers to the poles and zeros
      % affected by these implicit constraints. Adjust the default value if
      % it cannot be met or conflicts with other requirements. To constrain
      % the decay rate of a specific feedback loop, use the TuningGoal.Poles
      % goal instead.
      MinDecay = 1e-7;
      
      % Maximum spectral radius for stabilized dynamics (default = 1e8).
      %
      % Constrains all stabilized poles and zeros to satisfy
      %    |s| < MaxRadius.
      % This is useful to prevent poles and zeros from going to infinity as
      % a result of algebraic loops becoming singular or control effort
      % growing unbounded. Adjust the default value if it cannot be met or 
      % conflicts with other requirements. To constrain the spectral radius
      % of a specific feedback loop, use the TuningGoal.Poles goal instead.
      % This option is ignored in discrete time since it is redundant with
      % the stability constraint.
      MaxRadius = 1e8;
   end
   
   properties (Hidden)
      % Deprecated in R2014a
      ScalingOrder = 0;
   end

   properties (Hidden, Transient)
      Hidden = struct(...
         'Problem','MultiObj',...        % Problem type
         'Trace',NSOptLog.Options(),...  % Display/instrumentation options
         'StopFcn',@() false,...         % Support for user-driven interrupts
         'StabilizeOnly',false,...       % Only stabilize
         'Simulink',false)   % Flags Simulink use. Affects rules for resolving 
                             % signal namesand loop opening locations          
   end
   
   
   methods
            
      function this = set.Display(this,value)
         % SET method for Display option
         value = ltipack.matchKey(value,{'off','final','sub','iter'});
         if isempty(value)
            error(message('Control:tuning:systune1'))
         end
         this.Display = value;
      end
      
      function this = set.MaxIter(this,value)
         % SET method for MaxIter option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && ~isnan(value) && value>0)
            error(message('Control:tuning:systune2'))
         end
         this.MaxIter = round(double(value));
      end
      
      function this = set.RandomStart(this,value)
         % SET method for RandomStart option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>=0)
            error(message('Control:tuning:systune3'))
         end
         this.RandomStart = round(double(value));
      end
      
      function this = set.UseParallel(this,value)
         % SET method for UseParallel option
         if isnumeric(value)
            value = (value~=0);
         end
         if ~(isscalar(value) && islogical(value))
            error(message('Control:tuning:systune4'))
         end
         this.UseParallel = logical(value);
      end
      
      function this = set.SkipModels(this,value)
         % SET method for SkipModels option
         if isempty(value)
            this.SkipModels = zeros(0,1);
         else
            if ~(isnumeric(value) && isreal(value) && isvector(value) && ...
                  all(isfinite(value) & value>0 & value==round(value)))
               error(message('Control:tuning:systune45'))
            end
            this.SkipModels = value(:);
         end
      end
      
      function this = set.SoftTarget(this,value)
         % SET method for SoftTarget option
         if ~(isnumeric(value) && isscalar(value) && isreal(value) && value>=0)
            error(message('Control:tuning:NonNegativeScalar','SoftTarget'))
         end
         this.SoftTarget = double(value);
      end
      
      function this = set.SoftTol(this,value)
         % SET method for SoftTol option
         if ~(isnumeric(value) && isscalar(value) && isreal(value) && value>0 && value<1)
            error(message('Control:tuning:systune5'))
         end
         this.SoftTol = double(value);
      end
      
      function this = set.SoftScale(this,value)
         % SET method for SoftScale option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>0)
            error(message('Control:tuning:PositiveScalar','SoftScale'))
         end
         this.SoftScale = double(value);
      end
         
      function this = set.MinDecay(this,value)
         % SET method for MinDecay option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>=0)
            error(message('Control:tuning:NonNegativeFiniteScalar','MinDecay'))
         end
         this.MinDecay = double(value);
      end
      
      function this = set.MaxRadius(this,value)
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>0)
            error(message('Control:tuning:PositiveScalar','MaxRadius'))
         end
         this.MaxRadius = double(value);
      end
      
      function this = set.ScalingOrder(this,value)
         % SET method for ScalingOrder option
         if ~(isnumeric(value) && isscalar(value) && ...
               isreal(value) && isfinite(value) && value>=0 && rem(value,1)==0)
            error(message('Control:tuning:systune6'))
         elseif value>0
            warning(message('Control:tuning:systune26'))
         end
         this.ScalingOrder = double(value);
      end
         
   end
   
   methods (Access = protected)
      function cmd = getCommandName(~)
         cmd = 'systune';
      end
   end
   
   methods(Static, Hidden)
      
      function opt = loadobj(s)
         % Load filter
         opt = s;
         if opt.Version_<15
            % Get display from Verbosity flag (Display used to be dependent)
            opt.Display = NSOptLog.Options.getDisplay(...
               opt.Hidden.Trace.Verbosity,opt.Version_);
            % Reset "Hidden" which is no longer saved
            opt.Hidden = get(systuneOptions(),'Hidden');
         end
         opt.Version_ = ltipack.ver();
      end
      
   end
   
end