classdef (Hidden) SystemLevel < TuningGoal.Generic
   % Base class for tuning requirements on feedback loops.
   
%   Copyright 2009-2012 The MathWorks, Inc.
   
   properties
      % Models (index vector, default=NaN).
      %
      % Specifies which models the requirement applies to (when using multiple 
      % models of the control system to reflect variability in the plant or
      % feedback structure). Use an index vector to select specific models in 
      % the array of tunable models (see SYSTUNE). Use the value NaN when the 
      % requirement applies to all models.
      Models = NaN;
      
      % Loop openings (string or string vector, default=empty).
      %
      % Specifies which feedback loops to open when evaluating the requirement.
      % When working with a GENSS model of the control system, you can open
      % loops at any location marked with an "analysis point" block (see
      % AnalysisPoint and getPoints). When working with a Simulink model of
      % the control system, you can open loops at any Linear Analysis point
      % marked in the model or flagged with the addPoint method of the slTuner
      % interface (see slTuner/addPoint).
      Openings = cell(0,1)
   end
   
   methods
      
      function this = set.Models(this,Value)
         % SET function for Models
         if ~isequaln(Value,NaN)
            Value = Value(:);
            if ~(isnumeric(Value) && isreal(Value) && ...
                  all(Value>0 & isfinite(Value) & Value==round(Value)))
               error(message('Control:tuning:TuningReq6'))
            end
         end
         this.Models = Value;
      end
      
      function this = set.Openings(this,Value)
         % SET function for Openings
         if isempty(Value)
            this.Openings = cell(0,1);
         else
            [ok,this.Openings] = ltipack.isNameList(Value);
            if ~ok
               error(message('Control:tuning:TuningReq5'))
            end
         end
      end
      
   end
         
   methods (Static, Hidden)
      
      function [ConfigID,SwitchConfigs] = getSwitchConfig(iOpen,SwitchConfigs)
         % Identifies loop switch configuration.
         %    IOPEN: Open channels
         %    SWITCHCONFIGS: Already registered configurations of openings.
         % This function creates a new entry in SWITCHCONFIGS if none matches
         % the specified configuration and returns a configuration index
         % relative to SWITCHCONFIGS.
         [nOL,nC] = size(SwitchConfigs);
         Config = true(nOL,1);
         Config(iOpen) = false;
         ConfigID = [];
         for ct=1:nC
            if isequal(Config,SwitchConfigs(:,ct))
               ConfigID = ct;  break;
            end
         end
         if isempty(ConfigID)
            % New opening configuration
            ConfigID = nC+1;
            SwitchConfigs = [SwitchConfigs , Config];
         end
      end
      
   end
         
end
