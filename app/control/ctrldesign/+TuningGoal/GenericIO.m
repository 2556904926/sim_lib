classdef (Hidden) GenericIO
   % Manages I/O signal specification in tuning goals.
   
   %   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Input signals (string or string vector).
      %
      % Specifies the input signals by name. These signals can be the system
      % inputs (Gain and Variance), the commands to follow (Tracking,
      % StepTracking, Overshoot, Transient), the disturbances to reject
      % (StepRejection), or the noise and disturbances entering the plant
      % (LQG).
      %
      % When working with a GENSS model of the control system, you can refer
      % to any model input or any analysis point marked with an AnalysisPoint
      % block. When working with a Simulink model of the control system, you
      % can refer to any Linear Analysis point marked in the model or specified
      % with the addPoint method of the slTuner interface (see slTuner/addPoint).
      % Use getPoints to get the full list of analysis points for your model.
      Input
      
      % Output signals (string or string vector).
      %
      % Specifies the output signals by name. These signals can be the
      % system outputs (Gain and Variance), the responses to commands or
      % disturbances (Tracking, StepTracking, StepRejection, Overshoot,
      % Transient), or performance-measuring variables (LQG). For the LQG
      % goal, the output variables can be a mix of control signals, system
      % outputs, and internal state variables.
      %
      % When working with a GENSS model of the control system, you can refer
      % to any model output or any analysis point marked with an AnalysisPoint
      % block. When working with a Simulink model of the control system, you
      % can refer to any Linear Analysis point marked in the model or specified
      % with the addPoint method of the slTuner interface (see slTuner/addPoint).
      % Use getPoints to get the full list of analysis points for your model.
      Output
   end
   
   methods
      
      function this = set.Input(this,Value)
         % SET function for Input
         [ok,this.Input] = ltipack.isNameList(Value);
         if ~ok
            error(message('Control:tuning:InputOutputName1'))
         end
      end
      
      function this = set.Output(this,Value)
         % SET function for Output
         [ok,this.Output] = ltipack.isNameList(Value);
         if ~ok
            error(message('Control:tuning:InputOutputName1'))
         end
      end
      
   end
   
   methods (Access=protected)

      function Di = checkInputScaling(this,Di,nu)
         % Checks and formats input scaling
         if isempty(Di)
            Di = ones(nu,1);
         elseif numel(Di)~=nu
            error(message('Control:tuning:InputScaling2',getID(this)))
         end
      end
      
      function Do = checkOutputScaling(this,Do,ny)
         % Checks and formats output scaling
         if isempty(Do)
            Do = ones(ny,1);
         elseif numel(Do)~=ny
            error(message('Control:tuning:OutputScaling2',getID(this)))
         end
      end
   
   end
   
   
end
