function [sys,errCode] = checkMagProfile(Value)
% Checks frequency-dependent magnitude specification
% Error codes:
%   1: Not a scalar or continuous-time SISO model
%   2: Cannot compute ZPK representation
%   3: Gain profile is identically zero

%   Copyright 2009-2013 The MathWorks, Inc.
errCode = 0;  sys = [];
if isnumeric(Value) && isscalar(Value) && isreal(Value) && ...
      isfinite(Value) && Value>0
   % Positive finite scalar
   sys = zpk(Value);
elseif isa(Value,'FRDModel') && issiso(Value) && nmodels(Value)==1
   % SISO FRD model
   if Value.Ts==-1
      error(message('Control:tuning:TuningReq19'))
   elseif ~strcmp(Value.FrequencyUnit,'rad/TimeUnit')
      % Required so that we can safely align time units with those of G,C
      error(message('Control:tuning:TuningReq2'))
   end
   % Fit ZPK model to FRD data
   [R,f] = frdata(Value);  % f in rad/TimeUnit
   mag = abs(R(:));
   if all(mag==0)
      errCode = 3;  return
   elseif ~allfinite(mag)
      errCode = 1;  return
   end
   sys = TuningGoal.fitMagProfile(f,mag);
   sys.TimeUnit = Value.TimeUnit;
elseif isa(Value,'DynamicSystem') && issiso(Value) && nmodels(Value)==1 && ...
      isreal(Value) && isfinite(Value)
   if Value.Ts==-1
      error(message('Control:tuning:TuningReq19'))
   end
   try
      sys = zpk(Value);
   catch %#ok<CTCH>
      errCode = 2;  return
   end
   if sys.k==0
      errCode = 3;  return
   end
else
   errCode = 1;
end
