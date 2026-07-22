classdef (Hidden) BandLimited
   % Base class for band-limited tuning requirements.
   
%   Copyright 2009-2012 The MathWorks, Inc.
   
   properties
      % Frequency focus (interval).
      %
      % This property specifies the frequency band [FMIN,FMAX] of interest for  
      % the requirement. Gain constraints only apply between the frequencies 
      % FMIN and FMAX, and pole constraints only apply to poles with natural
      % frequency between FMIN and FMAX. The default is [0,Inf] in continuous
      % time and [0,pi/Ts] in discrete time. For best results with stability 
      % margin requirements, pick a frequency band extending about one decade 
      % on each side of the gain crossover frequencies.
      Focus = [0,Inf];
   end
   
   methods
      
      function this = set.Focus(this,Value)
         % SET function for band limit
         if isnumeric(Value) && isreal(Value) && numel(Value)==2 && ...
               Value(1)>=0 && Value(1)<Value(2)
            this.Focus = reshape(double(Value),[1 2]);
         else
            error(message('Control:tuning:TuningReq7'))
         end
      end
      
   end
                  
end
