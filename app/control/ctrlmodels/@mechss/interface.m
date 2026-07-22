function sys = interface(sys,C1,IC1,varargin)
%INTERFACE  Specify physical interface between components.
%
%   INTERFACE specifies physical couplings between components in  
%   structural models. It supports decomposition workflows such as 
%   Dynamic Substructuring.
%
%   SYS = INTERFACE(SYS,C1,IC1,C2,IC2) interfaces the components with  
%   names C1 and C2. SYS is the MECHSS obtained by summing the input/output 
%   models of individual components, and IC1 and IC2 are the indices of
%   the coupled degrees of freedom (DOF) relative to the DOFs of C1 and C2.
%   The interface is assumed rigid and satisfies the standard consistency
%   and equilibrium conditions. In particular, q1(IC1)=q2(IC2) if q1 and q2
%   are the displacement vectors for C1 and C2. The output SYS is a 
%   "dual-assembly" model of the aggregate structure.
%
%   SYS = INTERFACE(SYS,C,IC) interfaces the component C with the
%   ground. This amounts to the constraint q(IC)=0 for the degrees of 
%   freedom q of C selected by the index vector IC.
%
%   SYS = INTERFACE(...,KI,CI) further specifies the stiffness KI and
%   damping CI for non-rigid interfaces.
%
%   SYS = INTERFACE(...,METHOD) specifies the assembly method. METHOD
%   is either "primal" or "dual" (default). Dual assembly maintains
%   sparsity at the expense of additional algebraic variables. Primal
%   assembly uses a minimal number of DOFs but may suffer from fill-in.
%
%   Note: Use showStateInfo(SYS) to get the list of components 
%   (sub-structures) of SYS and their number of DOFs.
%
%   See also SHOWSTATEINFO, MECHSS.

%   Copyright 2020 The MathWorks, Inc.
narginchk(3,8)
ni = nargin;

KI = []; CI = [];
METHOD = 'dual';
GROUNDED = (ni<5 || isnumeric(varargin{1}));
if GROUNDED
   % INTERFACE(SYS,C,IC)
   % INTERFACE(SYS,C,IC,KI)
   % INTERFACE(SYS,C,IC,METHOD)
   % INTERFACE(SYS,C,IC,KI,CI)
   % INTERFACE(SYS,C,IC,KI,METHOD)
   % INTERFACE(SYS,C,IC,KI,CI,METHOD)
   ni = ni+2;
   varargin = [cell(1,2) varargin];
end
C2 = varargin{1};
IC2 = varargin{2};
if ni>5
   if localIsString(varargin{3})
      METHOD = varargin{3};
   else
      KI = varargin{3};
   end
end
if ni>6
   if localIsString(varargin{4})
      METHOD = varargin{4};
   else
      CI = varargin{4};
   end
end
if ni>7
   METHOD = varargin{5};
end
% Validate METHOD
METHOD = ltipack.matchKey(METHOD,{'primal','dual'});
if isempty(METHOD)
   error(message('Control:combination:interface9'))
end

% Validate C1,C2
try
   C1 = localCheckC(C1,'C1');
   IC1 = localCheckN(IC1,'IC1');
   if ~GROUNDED
      C2 = localCheckC(C2,'C2');
      IC2 = localCheckN(IC2,'IC2');
      if numel(IC1)~=numel(IC2)
         error(message('Control:combination:interface4'))
      end
   end
catch ME
   throw(ME)
end

% Validate KI and CI
if ~isempty(KI)
   s = size(KI);
   if ~(ismatrix(KI) && isnumeric(KI) && s(1)==s(2))
      error(message('Control:combination:interface7'))
   elseif s(1)~=numel(IC1)
      error(message('Control:combination:interface8'))
   end
   KI = sparse(double(KI));
end
if ~isempty(CI)
   s = size(CI);
   if ~(ismatrix(CI) && isnumeric(CI) && s(1)==s(2))
      error(message('Control:combination:interface7'))
   elseif s(1)~=numel(IC1)
      error(message('Control:combination:interface8'))
   end
   CI = sparse(double(CI));
end

% Add interface
Data = sys.Data_;
try
   for ct=1:numel(Data)
      Data(ct) = interface(Data(ct),C1,IC1,C2,IC2,KI,CI,METHOD);
   end
catch ME
   throw(ME)
end
sys.Data_ = Data;
   
%----------------------------------

function C = localCheckC(C,ArgName)
if ischar(C)
   C = string(C);
end
if ~(isstring(C) && isscalar(C) && strlength(C)>0)
   error(message('Control:combination:interface5',ArgName))
end

function N = localCheckN(N,ArgName)
if ~(isnumeric(N) && isvector(N) && isreal(N) && ~any(rem(N,1)))
   error(message('Control:combination:interface6',ArgName))
end


function boo = localIsString(s)
boo = ischar(s) || isstring(s);