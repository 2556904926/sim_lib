function sys = dss2ss(sys,varargin)
%DSS2SS  Converts descriptor state-space model to explicit form.
%
%   SYS = DSS2SS(DSYS) eliminates the E matrix in the descriptor 
%   state-space model
%
%      DSYS:   E dx = A x + B u,   y = C x + D u.
%
%   DSYS must be proper and SYS has fewer states than DSYS when E is
%   singular (the explicit form removes the algebraic variables). Use 
%   FINDOP to compute matching initial conditions when the state is
%   reduced.
%
%   For state-space arrays DSYS,
%      SYS = DSS2SS(DSYS,'consistent')
%   eliminates E while preserving state consistency, i.e., ensuring that
%   all models in SYS share the same state vector x. This requires all
%   E matrices to be invertible.
%
%   See also DSS, SS, ISPROPER, DYNAMICSYSTEM/FINDOP.

%   Copyright 2023 The MathWorks, Inc.
try
  sys = dss2ss_(sys,varargin{:});
catch E
   ltipack.throw(E,'command','dss2ss',class(sys))
end