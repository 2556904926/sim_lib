classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      looptune < rctoptions.hinfstruct
   % Options set for MIMO tuning with LOOPTUNE.
   
   % Author: P. Gahinet
%   Copyright 2009-2012 The MathWorks, Inc.
   
   properties
      % Target gain margin (in dB, default = 7.6).
      GainMargin = 7.6;
      % Target phase margin (in degrees, default = 45).
      PhaseMargin = 45;
   end
   
   properties (Hidden)
      % Set to true to consider independent/concurrent variations in all 
      % input and output channels of the feedback loop
      ioMargin = false;
   end
   
   methods
      
      function this = looptune()
         % Constructor
         this.TargetGain = 1;
      end
      
      function this = set.GainMargin(this,value)
         % SET method for GainMargin option
         if ~(isnumeric(value) && isscalar(value) && isreal(value) && ...
               isfinite(value) && value>0)
            ctrlMsgUtils.error('Control:tuning:PositiveFiniteScalar','GainMargin')
         end
         this.GainMargin = double(value);
      end
      
      function this = set.PhaseMargin(this,value)
         % SET method for PhaseMargin option
         if ~(isnumeric(value) && isscalar(value) && isreal(value) && ...
               isfinite(value) && value>0)
            ctrlMsgUtils.error('Control:tuning:PositiveFiniteScalar','PhaseMargin')
         end
         this.PhaseMargin = double(value);
      end
      
      function alpha = getAlpha(this)
         % Computes ALPHA coefficient for stability margin constraint.
         %
         % The gain and phase margin requirements are converted into 
         % uncertainty of the form 
         %    (1+delta)/(1-delta) ,  |delta| < ALPHA
         % at the plant inputs or the plant outputs.
         %
         % If the uncertainty is equally distributed between the plant 
         % inputs and outputs, the uncertainty bound should be changed to 
         %    |delta| < BETA = ALPHA/(1+SQRT(1+ALPHA^2))
         cm = cos(this.PhaseMargin*pi/180);
         gm = db2mag(this.GainMargin);
         alpha = max((gm-1)/(gm+1),sqrt((1-cm)/(1+cm)));
      end
      
   end
   
   methods (Access = protected)
      function cmd = getCommandName(~)
         cmd = 'looptune';
      end
   end
   
   methods (Hidden)
      function Opt = systuneOptions(this)
         % Maps LOOPTUNE option set to SYSTUNE option set
         Opt = systuneOptions();
         Opt.Display = this.Display;
         Opt.MaxIter = this.MaxIter;
         Opt.RandomStart = this.RandomStart;
         Opt.UseParallel = this.UseParallel;
         Opt.SoftTarget = this.TargetGain;
         Opt.SoftTol = this.TolGain;
         Opt.MinDecay = this.MinDecay;
         Opt.Hidden.Simulink = this.Hidden.Simulink;
         Opt.Hidden.Trace = this.Hidden.Trace;
      end
   end

   methods(Static, Hidden)
      function opt = loadobj(s)
         % Load filter
         if isstruct(s)
            % Pre-R2012a
            opt = looptuneOptions();
            opt.Display = NSOptLog.Options.getDisplay(s.Trace.Verbosity,12);
            opt.GainMargin = s.GainMargin;
            opt.PhaseMargin = s.PhaseMargin;
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
               opt.Hidden = get(looptuneOptions(),'Hidden');
            end
            opt.Version_ = ltipack.ver();
         end
      end
   end
   
end
