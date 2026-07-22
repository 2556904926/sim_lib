function sys = resampleModel(sys,Ts)
% Resamples state-space model (may error).

%   Copyright 2009-2014 The MathWorks, Inc.
hw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU> % warning in D2C
Ts0 = sys.Ts;
if Ts0~=Ts
   if Ts==0
      sys = d2c(sys);
   elseif Ts0==0
      sys = c2d(sys,Ts);
   else
      sys = d2d(sys,Ts);
   end
end