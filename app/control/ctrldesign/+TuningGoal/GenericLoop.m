classdef (Hidden) GenericLoop
   % Manages feedback loop specification in tuning goals.
   
   %   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Feedback loop locations (string or string vector).
      %
      % Specifies the locations(s) where open-loop responses (LoopShape,
      % MinLoopGain, MaxLoopGain), stability margins (Margins), sensitivity
      % functions (Sensitivity), disturbance attenuation (Rejection), or
      % closed-loop dynamics (Poles) are assessed. When working with a GENSS
      % model of the control system, you can refer to any location marked
      % with an AnalysisPoint block. When working with a Simulink model of
      % the control system, you can refer to any Linear Analysis point marked
      % in the model or specified with the addPoint method of the slTuner
      % interface (see slTuner/addPoint). Use getPoints to get the full list
      % of analysis points for your model.
      %
      % For TuningGoal.Poles, no locations are specified by default and the
      % requirement applies to the full set of closed-loop poles. When
      % locations are specified, the requirement applies only to the poles
      % of the closed-loop sensitivity function measured at these locations.
      % This is useful to target a particular feedback loop, for example,
      % the inner loop in a cascade architecture with its outer loop open.
      %
      % Example 1: If the plant has two measurements q and alpha and you
      % mark them as analysis points, you can specify the loop shape L for
      % the "q" loop with the "alpha" loop open using
      %    R = TuningGoal.LoopShape('q',L)
      %    R.Openings = 'alpha';
      %
      % Example 2: For a control system with two cascaded feedback loops
      % "Inner" and "Outer" marked by AnalysisPoint blocks of the same name,
      % you can require MIMO margins of 5 dB and 40 degrees using
      %    R = TuningGoal.Margins({'Inner','Outer'},5,40)
      Location = cell(0,1);
   end
   
   methods
      
      function this = set.Location(this,Value)
         % SET function for Location
         [ok,this.Location] = ltipack.isNameList(Value);
         if ~ok
            error(message('Control:tuning:LoopLocation1'))
         end
      end
                  
   end
   
end
