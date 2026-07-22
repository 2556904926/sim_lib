classdef (CaseInsensitiveProperties = true, TruncatedProperties = true, Hidden) ...
      MaxGain < TuningGoal.Gain
   % Obsolete, use TuningGoal.Gain instead.
   
%   Copyright 2009-2013 The MathWorks, Inc.
   
   properties (Hidden, Dependent)
      GainLimit
   end
   
   methods
      
      % Constructor
      function this = MaxGain(varargin)
         this@TuningGoal.Gain(varargin{:});
      end
      
      function Value = get.GainLimit(this)
         Value = this.MaxGain;
      end
         
      function this = set.GainLimit(this,Value)
         this.MaxGain = Value;
      end
      
   end
   
end
