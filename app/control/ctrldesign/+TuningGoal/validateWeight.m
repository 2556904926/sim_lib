function validateWeight(WF,Ts)
% Checks that MIMO weight can be resampled at the new sample time Ts.

%   Copyright 2009-2016 The MathWorks, Inc.
Ts0 = WF.Ts;
if Ts0==0 || Ts0==Ts
   return
end
[Zeros,Poles,Gains] = zpkdata(WF);
[ny,nu] = size(Gains);
if ~(nu==1 && ny==1) && any(cellfun(@(r) any(r==0),[Zeros(:);Poles(:)]))
   % MIMO D2C conversion fails when there are poles or zeros at z=0
   error(message('Control:tuning:TuningReq18'))
end
