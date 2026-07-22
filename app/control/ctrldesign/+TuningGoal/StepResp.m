classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      StepResp < TuningGoal.StepTracking
   % Same as TuningGoal.StepTracking.
   %
   %   See also TuningGoal.StepTracking.
   
   % Copyright 2009-2013 The MathWorks, Inc.   
   methods
      % Constructor
      function this = StepResp(varargin)
         this = this@TuningGoal.StepTracking(varargin{:});
      end
   end
end