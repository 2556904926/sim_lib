function sys = setTestValue(sys,t0,p0)
%setTestValue  Modify test values for validating data function.
%
%   SYS = setTestValue(SYS,T0) modifies the test time T0 used to validate 
%   the data function. The data function is re-evaluated for this new value.
%
%   SYS = setTestValue(SYS,T0,P0) also modifies the test parameters P0 used 
%   to validate the data function of LPV models.
%
%   Use this function to modify clashing test values when combining LTV or
%   LPV models.
%
%   See also LTVSS, LPVSS.

%   Copyright 2022 The MathWorks, Inc.
narginchk(2,3)
if ~(isnumeric(t0) && isreal(t0) && isscalar(t0) && isfinite(t0))
   error(message('Control:ltiobject:LTV1'))
end
sys.t0_ = t0;
if nargin>2
   if ~(isnumeric(p0) && isreal(p0) && isvector(p0) && ...
         allfinite(p0) && numel(p0)==numel(sys.ParameterName_))
      error(message('Control:ltiobject:LPV2'))
   end
   sys.p0_ = p0;
end
try
   sys = validateDataFcn(sys);
catch ME
   throw(ME)
end
