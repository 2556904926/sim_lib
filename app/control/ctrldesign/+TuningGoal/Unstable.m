classdef (Hidden) Unstable
   % Manages "Stabilize" property in tuning goals, which allows for
   % unstable closed-loop dynamics.
   
%   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Stabilize closed-loop dynamics? (default = true) 
      %
      % By default, tuning goals seek to stabilize the specified I/O 
      % transfer function (Gain, WeightedGain) or feedback loop (LoopShape,
      % MinLoopGain, MaxLoopGain). Set this property to FALSE if stability 
      % is not required or cannot be achieved,  for example, if a gain 
      % constraint pplies to an unstable open-loop transfer function.
      Stabilize = true;
   end
   
   methods
      
      function this = set.Stabilize(this,Value)
         % SET function for Stabilize
         if isequal(Value,0) || isequal(Value,1)
            Value = logical(Value);
         elseif ~(isscalar(Value) && islogical(Value))
            error(message('Control:tuning:Stabilize1'))
         end
         this.Stabilize = Value;
      end
                  
   end
                  
end
