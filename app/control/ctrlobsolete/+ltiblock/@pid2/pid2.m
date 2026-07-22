classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      pid2 < tunablePID2
   %LTIBLOCK.PID2  see tunablePID2.
   
   %   Copyright 1986-2014 The MathWorks, Inc.
   methods
      function blk = pid2(varargin)
         blk@tunablePID2(varargin{:});
      end
   end
   
   methods (Static, Hidden)
      function blk = loadobj(s)
         % Load filter for LTIBLOCK.PID2 objects
         blk = DynamicSystem.updateMetaData(s);
         blk.Version_ = ltipack.ver();
         % Since R2013a, b.Minimum>=0 and c.Minimum>=0
         blk.b_.Minimum = max(0,blk.b_.Minimum);
         blk.c_.Minimum = max(0,blk.c_.Minimum);
         if blk.b_.Maximum<=0
            blk.b_.Maximum = Inf;
         end
         if blk.c_.Maximum<=0
            blk.c_.Maximum = Inf;
         end
      end
   end
   
end
