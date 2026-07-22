function WF = checkWeight(Value,WID)
% Checks weighting function for Weighted* goals.
% Returns weight WF in ZPK form when SISO, and SS form otherwise.

%   Copyright 2009-2016 The MathWorks, Inc.
if isa(Value,'FRDModel') && nmodels(Value)==1
   % SISO FRD model
   if ~issiso(Value)
      error(message('Control:tuning:WeightedReq2'))
   elseif ~strcmp(Value.FrequencyUnit,'rad/TimeUnit')
      % Required so that we can safely align time units with those of CL
      error(message('Control:tuning:TuningReq2'))
   end
   % Fit continuous-time ZPK model to FRD data
   [R,f] = frdata(Value);  % f in rad/TimeUnit
   R = abs(R(:));
   if all(R==0)
      Value = 0;
   else
      Value = set(TuningGoal.fitMagProfile(f,abs(R(:))),'TimeUnit',Value.TimeUnit);
   end
elseif ~((isnumeric(Value) && ismatrix(Value )&& isreal(Value)) || ...
      (isa(Value,'DynamicSystem') && nmodels(Value)==1 && isreal(Value)))
   error(message('Control:tuning:WeightedReq1',WID))
end

% Check squareness
[ny,nu,~] = size(Value);
if ny~=nu
   error(message('Control:tuning:WeightedReq4',WID))
end

% Convert to SS or ZPK
try
   if ny==1
      WF = zpk(Value);
   else
      WF = ss(Value);
   end
catch %#ok<CTCH>
   error(message('Control:tuning:WeightedReq3',WID))
end

% Check sample time
if WF.Ts==-1
   error(message('Control:tuning:TuningReq19'))
end