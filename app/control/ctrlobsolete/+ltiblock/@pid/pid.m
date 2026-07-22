classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      pid < tunablePID
   %LTIBLOCK.PID  See tunablePID.
   
   %   Copyright 1986-2015 The MathWorks
   methods
      function blk = pid(varargin)
         blk@tunablePID(varargin{:});
      end
   end
   
   methods (Static, Hidden)
      function blk = loadobj(s)
         % Load filter for LTIBLOCK.PID objects
         blk = DynamicSystem.updateMetaData(s);
         blk.Version_ = ltipack.ver();
         % Since R2012b, Tf.Minimum>=0
         blk.Tf_.Minimum = max(0,blk.Tf_.Minimum);
         if blk.Tf_.Value<=0
            blk.Tf_.Value = 1;
         end
         if blk.Tf_.Maximum<=0
            blk.Tf_.Maximum = Inf;
         end
      end
   end
   
end