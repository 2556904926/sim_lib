classdef (Hidden) TrackIO < TuningGoal.GenericIO
   % Manages scaled I/O specification for tracking-related goals.
   
   %   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Input signal scaling (default = []).
      %
      % Specifies the relative amplitude of each entry in vector-valued
      % reference signals. The transfer function from reference inputs
      % to tracking outputs is scaled accordingly so that cross-coupling
      % effects are measured relative to the amplitudes of each reference
      % signal. For example, suppose that y1,y2 must track r1,r2 with less
      % than 10% cross-coupling. If r1,r2 have comparable amplitudes, it is
      % enough to keep the gains from r1 to y2 and r2 to y1 below 0.1. But
      % if r1 is 100 times larger than r2, the gain from r1 to y2 must be
      % less than 0.001 to ensure that r1 changes y2 by less than 10% of
      % its r2 target.
      %
      % Use this property to correct scaling issues when the choice of units
      % results in a mix of small and large signals. All input scaling
      % factors are set to 1 by default (no scaling).
      InputScaling
   end
   
   methods
      
      function this = set.InputScaling(this,Value)
         % SET function for InputScaling
         if isempty(Value)
            % No scaling
            this.InputScaling = [];
         else
            if ~(isnumeric(Value) && isvector(Value) && isreal(Value) && ...
                  all(Value>0) && allfinite(Value))
               error(message('Control:tuning:InputScaling1'))
            end
            this.InputScaling = Value(:);
         end
      end
      
   end
   
end
