classdef (Hidden) ReportText < handle
    % Class to separate report text from app objects.
    
    % Copyright 2013 The MathWorks, Inc.      
    
    properties(Access = public) % make private
    end
    
    methods 
        function this = ReportText()                      
        end
    end
    events
       NewData
       NewWarning
    end
end
        