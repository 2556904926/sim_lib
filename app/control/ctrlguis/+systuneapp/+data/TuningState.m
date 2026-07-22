classdef (Hidden) TuningState < handle
    % Class to separate tuning state from app objects.
    
    % Copyright 2013 The MathWorks, Inc.        
    
    properties(Access = public) % make private
        IsTuning
    end
    
    methods 
        function this = TuningState(state)
            this.IsTuning = state;            
        end
    end
end
        