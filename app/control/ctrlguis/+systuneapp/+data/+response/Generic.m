classdef (Hidden) Generic < matlab.mixin.Heterogeneous
    % Base class for responses
    
    % Copyright 2009-2013 The MathWorks, Inc.
    
    properties
        % Requirement name (string).
        Name = '';
        
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
        % All feedback loops are closed by default. In MATLAB, you can open loops
        % at any location marked with a loop switch block (see LOOPSWITCH). In
        % Simulink, you can open loops at any "Controls", "Measurements", or
        % "Switches" signals registered in the slTunable interface with the model
        % (type "help slTunable" for details).
        Openings = cell(0,1)
    end
    
   methods

      function this = set.Name(this,Value)
         % SET function for Name
         if ischar(Value) && (isempty(Value) || isrow(Value))
            this.Name = Value;
         else
            error(message('Control:tuning:TuningReq1'))
         end
      end
      
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
         
    
   
         
end
