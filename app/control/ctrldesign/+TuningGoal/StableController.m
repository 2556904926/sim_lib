classdef (CaseInsensitiveProperties = true, TruncatedProperties = true) ...
      StableController < TuningGoal.ControllerPoles
   % Constraint on the controller dynamics.
   %
   %   This tuning goal is obsolete. Use TuningGoal.ControllerPoles instead.
   %
   %   See also TuningGoal.ControllerPoles
   
   %   Author: P. Gahinet
   %   Copyright 2009-2014 The MathWorks, Inc.
   
   %   R = TuningGoal.StableController(BLOCKID) creates a tuning requirement
   %   R for constraining the controller dynamics. The string BLOCKID
   %   designates one of the tuned blocks making up the controller (see
   %   ParametricBlock). You can use this requirement to ensure that the
   %   controller is stable and free of fast dynamics.
   %
   %   Set properties to further configure the requirement. For example, if
   %   the "Compensator" block is parameterized as a second-order transfer
   %   function using ltiblock.tf, the requirement
   %      R = TuningGoal.StableController('Compensator')
   %      R.MinDecay = 0.1
   %      R.MaxFrequency = 30
   %   restricts its poles to the region:
   %      Re(s) < -0.1,    |s| < 30
   %   Type "help TuningGoal.StableController.<property name>" for details
   %   on individual properties.
   %
   %   Use VIEWSPEC(R) to visualize this requirement and use SYSTUNE and
   %   related commands to tune the control system parameters subject to
   %   this and other requirements.
   %
   %   Note: This requirement implicitly enforces stability of the specified
   %   tuned block.
   
   methods
      % Constructor
      function this = StableController(BlockName)
         narginchk(1,1)
         this = this@TuningGoal.ControllerPoles(BlockName);
      end
   end
   
   methods (Access = protected)
      function checkMinDecay(~,Value)
         % Enforce MINDECAY>0 for consistency with goal name
         if ~(isnumeric(Value) && isscalar(Value) && ...
               isreal(Value) && isfinite(Value) && Value>=0)
            error(message('Control:tuning:PoleReq1'))
         end
      end
   end
end
