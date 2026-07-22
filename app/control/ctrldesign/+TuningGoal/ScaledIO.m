classdef (Hidden) ScaledIO < TuningGoal.GenericIO
   % Manages scaled I/O specification in tuning goals.
   
   %   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Input signal scaling (default = []).
      %
      % Specifies the relative amplitude of each entry in vector-valued
      % input signals. The transfer function from inputs to outputs is
      % scaled accordingly so that the influence of each input on each
      % output is measured in relative terms. If H(s) is the closed-loop
      % I/O transfer, the tuning goal is evaluated for inv(Do) * H * Di
      % where Di and Do are the diagonal matrices of input and output
      % scalings.
      %
      % Use this property to correct scaling issues when the choice of units
      % results in a mix of small and large signals. All input scaling
      % factors are set to 1 by default (no scaling).
      InputScaling
      
      % Output signal scaling (default = []).
      %
      % Specifies the relative amplitude of each entry in vector-valued
      % output signals. The transfer function from inputs to outputs is
      % scaled accordingly so that the influence of each input on each
      % output is measured in relative terms. If H(s) is the closed-loop
      % I/O transfer, the tuning goal is evaluated for inv(Do) * H * Di
      % where Di and Do are the diagonal matrices of input and output
      % scalings.
      %
      % Use this property to correct scaling issues when the choice of units
      % results in a mix of small and large signals. All output scaling
      % factors are set to 1 by default (no scaling).
      OutputScaling
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
      
      function this = set.OutputScaling(this,Value)
         % SET function for OutputScaling
         if isempty(Value)
            % No scaling
            this.OutputScaling = [];
         else
            if ~(isnumeric(Value) && isvector(Value) && isreal(Value) && ...
                  all(Value>0) && allfinite(Value))
               error(message('Control:tuning:OutputScaling1'))
            end
            this.OutputScaling = Value(:);
         end
      end
      
   end
   
end
