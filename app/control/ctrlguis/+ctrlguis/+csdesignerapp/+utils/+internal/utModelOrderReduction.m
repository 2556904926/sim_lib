function [ReducedC, msg] = utModelOrderReduction(Model,FullC,DesiredOrder)
%UTMODELORDERREDUCTION generate a reduced order controller

%   Author(s): R. Chen
%   Copyright 1986-2011 The MathWorks, Inc.

% get closed loop system with full order controller
SysFull = feedback(Model*FullC,1);
% carry out order reduction on controller C
ReducedC = balred(FullC,DesiredOrder);
% get closed loop system with reduced order controller
SysReduced = feedback(Model*ReducedC,1);
% check closed loop stability for reduced order system
if isstable(SysReduced)
   % get sensitivity ratio
   if norm(SysReduced,inf)>10*norm(SysFull,inf)
      msg = getString(message('Control:compDesignTask:AutomatedTuningModRed3'));
   else
      msg = '';
   end
else
   [lw,lwid] = lastwarn;
   if strcmp(lwid,'Control:transformation:ModelReductionMaxOrder')
      error(message('Control:compDesignTask:AutomatedTuningModRed1',lw));
   else
      error(message('Control:compDesignTask:AutomatedTuningModRed2',lw));
   end
end
