classdef PulseTrain < pidtool.desktop.relinearizetool.AbsPulseTrain
   % Pulse Train signal specs.
   
   % Author(s): Baljeet Singh 20-Sep-2013
   % Copyright 2013 The MathWorks, Inc.
   
   properties (SetObservable, Dependent)
      BreakPoints
   end
   
   methods
      function this = PulseTrain(BP)
         %STEP constructor
         % BP: [time y-coordinate], N-by-2 matrix
         if nargin>0
            this.BreakPoints_ = BP;
         end
      end
      
      function val = get.BreakPoints(this)
         val = this.BreakPoints_;
      end
      
      function set.BreakPoints(this, val)
         this.BreakPoints_ = val;
      end
      
   end
end
