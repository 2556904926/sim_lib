function x0 = getx0(sys,q0,dq0)
%GETX0  Map MECHSS initial conditions to SPARSS initial conditions.
%
%   For a continuous-time MECHSS model SYS with initial conditions 
%   Q0=q(0), DQ0=q'(0),
%      X0 = GETX0(SYS,Q0,DQ0) 
%   computes a matching initial condition X0=x(0) for the first-order 
%   equivalent SPARSS(SYS). When [M;G] has no zero columns, X0 is simply 
%   [Q0;DQ0]. Otherwise part of DQ0 is dropped to reflect that SYS is 
%   part second order, part first order.
%
%   For a discrete-time MECHSS model, 
%      X0 = GETX0(SYS,Q0,Q1) 
%   takes the initial values Q0=q[0] and Q1=q[1] and returns x[0] for the 
%   equivalent SPARSS model.
%
%   The second and third input arguments can be ommitted when zero.
%
%   See also MECHSS, SPARSS.

%   Copyright 2020 The MathWorks, Inc.
if nmodels(sys)>1
   error(message('Control:general:RequiresSingleModel','getx0'))
end   
ni = nargin;
[M,~,K,~,~,G] = mechssdata(sys);
nq = size(K,1);
if ni<2 || isempty(q0) || isequal(q0,0)
   q0 = zeros(nq,1);
elseif numel(q0)~=nq
   error(message('Control:ltiobject:getX0'))
end
if ni<3 || isempty(dq0) || isequal(dq0,0)
   dq0 = zeros(nq,1);
elseif numel(dq0)~=nq
   error(message('Control:ltiobject:getX0'))
end
x0 = [q0;dq0(any([M;G],1),:)];