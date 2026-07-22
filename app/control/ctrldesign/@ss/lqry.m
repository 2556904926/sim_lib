function [K,S,clp] = lqry(sys,Q,R,N)
%LQRY  Linear-quadratic regulator design with output weighting.
%
%   LQRY computes the state-feedback control u = -K*x that minimizes
%   the cost function
%
%      J = Integral {y'Qy + u'Ru + 2*y'Nu} dt     (continuous time)
%
%      J = Sum {y'Qy + u'Ru + 2*y'Nu}             (discrete time)
%
%   for the system dynamics 
%
%      dx/dt = Ax + Bu,  y = Cx + Du              (continuous time)
%
%      x[n+1] = Ax[n]+Bu[n],  y[n] = Cx[n]+Du[n]  (discrete time).
%
%   [K,S,CLP] = LQRY(SYS,Q,R,N) calculates the optimal gain matrix K for 
%   the continuous or discrete state-space model SYS. LQRY also returns 
%   the solution S of the associated algebraic Riccati equation and the 
%   closed-loop poles CLP = EIG(A-B*K). The matrix N is set to zero when 
%   omitted.
%
%   Note: 
%     * (A,B) must be stabilizable and [Q N;N' R] must be nonnegative
%       definite.
%     * The optimal cost is J(x0) = x0'*S*x0 where x0 is the initial state.
%
%   See also LQR, LQGREG, LQG, ICARE, IDARE.

%   Author(s): J.N. Little, Clay M. Thompson, P. Gahinet
%   Copyright 1986-2018 The MathWorks, Inc.
narginchk(3,4)
if ndims(sys)>2 %#ok<ISMAT>
   error(message('Control:general:RequiresSingleModel','lqry'))
elseif hasdelay(sys)
   throw(ltipack.utNoDelaySupport('lqry',sys.Ts,'all'))
end

% Extract system data
[A,B,C,D,~,Ts] = dssdata(sys);
E = sys.E;
[ny,nu] = size(D);
nx = size(A,1);

% Validate Q,R,N
if nargin<4
   N = [];
end
try
   [Q,R,N] = ltipack.checkQRS(ny,nu,Q,R,N,{'Q','R','N'});
catch ME
   throw(ME)
end

% Factor [Q N;N' R] and use square-root formulation when possible
[F,G,INDEF] = ltipack.factorQRS(Q,R,N);
if INDEF
   % Explicitly form [QQ NN;NN' RR] = [C D;0 I]'*[Q N;N' R]*[C D;0 I]
   aux1 = Q*D+N;  aux2 = N'*D+R;
   QQ = C'*Q*C;   QQ = (QQ+QQ')/2;
   RR = D' * aux1 + aux2;   RR = (RR+RR')/2;
   NN = C' * aux1;
   % Check positive semi-definiteness
   ev = eig([QQ NN;NN' RR]);
   if min(ev)<-1e2*eps*max(abs(ev))
      warning(message('Control:design:MustBePositiveDefinite','[C D;0 I]''*[Q N;N'' R]*[C D;0 I]','lqry'))
   end
else
   % Use factored form of [QQ NN;NN' RR] to avoid squaring-up effects
   B = [B zeros(nx,ny+nu)];
   QQ = zeros(nx);
   NN = [zeros(nx,nu) C'*F];
   G = G+D'*F;
   RR = [zeros(nu) G;G' -eye(ny+nu)];
end   
   
% Solve Riccati equation
if Ts==0
   [X,K,clp,INFO] = icare(A,B,QQ,RR,NN,E);
else
   [X,K,clp,INFO] = idare(A,B,QQ,RR,NN,E);
end
   
% Handle failures
switch INFO.Report
   case 2
      % S and K are not finite
      error(message('Control:design:lqr1'))
   case 3
      % Could not compute stabilizing S
      error(message('Control:design:lqr2'))
end

% Compute S
U = INFO.U;  V = INFO.V;  Sx = INFO.Sx;
if isempty(E)
   S = X;
else
   % S = E'*X*E;
   S = E' * (Sx .* (V/U) .* Sx');
   S = (S+S')/2;
end
K = K(1:nu,:);
