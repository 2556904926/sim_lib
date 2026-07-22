function [K,S,clp,Kw] = lqr(sys,Q,R,N)
%LQR  Linear-quadratic regulator design for state-space systems.
%
%   LQR computes the state-feedback control u = -K*x that minimizes
%   the cost function
%
%      J = Integral {x'Qx + u'Ru + 2*x'Nu} dt     (continuous time)
%
%      J = Sum {x'Qx + u'Ru + 2*x'Nu}             (discrete time)
%
%   for the state dynamics dx/dt = Ax+Bu or x[n+1] = Ax[n]+Bu[n].
%
%   [K,S,CLP] = LQR(SYS,Q,R,N) calculates the optimal gain matrix K for the
%   continuous or discrete state-space model SYS. LQR also returns the
%   solution S of the associated algebraic Riccati equation and the 
%   closed-loop poles CLP = EIG(A-B*K). The matrix N is set to zero when 
%   omitted.
%
%   [K,S,CLP] = LQR(A,B,Q,R,N) is an equivalent syntax for continuous-time
%   models with dynamics dx/dt = Ax+Bu.
%
%   Note: 
%     * (A,B) must be stabilizable and [Q N;N' R] must be nonnegative
%       definite.
%     * The optimal cost is J(x0) = x0'*S*x0 where x0 is the initial state.
%
%   See also DLQR, LQRY, LQI, LQG, LQGREG, LQGTRACK, ICARE, IDARE.

%   Author(s): J.N. Little, P. Gahinet
%   Copyright 1986-2018 The MathWorks, Inc.
narginchk(3,4)
if ndims(sys)>2 %#ok<ISMAT>
   error(message('Control:general:RequiresSingleModel','lqr'))
elseif hasdelay(sys)
   throw(ltipack.utNoDelaySupport('lqr',sys.Ts,'all'))
end

% Extract system data
[A,B,~,~,~,Ts] = dssdata(sys);
E = sys.E;
[nx,nu] = size(B);

% Validate Q,R,N
if nargin<4
   N = [];
end
try
   [Q,R,N] = ltipack.checkQRS(nx,nu,Q,R,N,{'Q','R','N'});
catch ME
   throw(ME)
end

% Factor [Q N;N' R] and use square-root formulation when possible
[F,G,INDEF] = ltipack.factorQRS(Q,R,N);
if INDEF
   % Proceed with original Q,R,N when [Q N;N' R] is numerically indefinite
   warning(message('Control:design:MustBePositiveDefinite','[Q N;N'' R]','lqr'))
   if Ts==0
      [X,K,clp,INFO] = icare(A,B,Q,R,N,E);
   else
      [X,K,clp,INFO] = idare(A,B,Q,R,N,E);
   end
else
   % Proceed with factored form [Q N;N' R] = [F;G] * [F',G']
   BB = [B zeros(nx,nx+nu)];
   QQ = zeros(nx);
   NN = [zeros(nx,nu) F];
   RR = [zeros(nu) G;G' -eye(nx+nu)];
   if Ts==0
      [X,K,clp,INFO] = icare(A,BB,QQ,RR,NN,E);
   else
      [X,K,clp,INFO] = idare(A,BB,QQ,RR,NN,E);
   end
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

% Compute Kw
K = K(1:nu,:);
if nargout>3
   % Optimal control is u[n] = -K*x[n]-Kw*w[n] when
   %    Ex[n+1] = Ax[n] + Bu[n] + w[n]
   if Ts==0
      Kw = zeros(nu,nx);
   else
      % Kw = (R+B'*X*B)\(B'*X)
      if isempty(E)
         E = 1;
      end
      aux = [-E*(Sx.\U) B ; B'*(Sx.*V) R]\[eye(nx);zeros(nu,nx)];
      Kw = aux(nx+1:nx+nu,:);
   end
end
