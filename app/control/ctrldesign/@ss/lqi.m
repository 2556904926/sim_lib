function [K,S,clp,Kw] = lqi(sys,Q,R,N)
%LQI  Linear-Quadratic-Integral control.
%
%   LQI computes an optimal state-feedback control u that makes the output
%   y track the reference command r in the feedback loop shown below. For
%   a plant SYS with state-space equations
%      dx/dt = Ax + Bu,  y = Cx + Du
%   or their discrete-time counterpart, u is of the form
%      u = -K [x;xi]
%   where xi is the integrator output. For MIMO systems, the number of
%   integrators is equal to the dimension of the output y. In discrete
%   time, xi is computed using the forward Euler formula
%      xi[n+1] = xi[n] + Ts*(r[n] - y[n])
%   where Ts is the sample time of SYS.
%
%                                      .---------------------.
%                                   x  |    .---.            | x
%                                      '--->|   |            |
%              e = r-y  .----------.        |-K |        .---'---.
%     r ---->O----------|Integrator|------->|   |------->|  SYS  |-----> y
%            ^          '----------'  xi    '---'   u    '-------'  |
%            |-                                                     |
%            |                                                      |
%            '------------------------------------------------------'
%
%   [K,S,CLP] = lqi(SYS,Q,R,N) calculates the optimal gain matrix K given
%   the state-space model SYS of the plant and the weighting matrices Q,R,N.
%   The control u = -K z = -K [x;xi] minimizes the cost function
%
%      J = Integral {z'Qz + u'Ru + 2*z'Nu} dt    (continuous time)
%
%      J = Sum {z'Qz + u'Ru + 2*z'Nu}            (discrete time).
%
%   The matrix N is set to zero when omitted. LQI also returns the solution
%   S of the associated algebraic Riccati equation and the closed-loop
%   poles CLP.
%
%   Note: 
%     * (A,B) must be stabilizable and [Q N;N' R] must be nonnegative
%       definite.
%     * The optimal cost is J(x0) = x0'*S*x0 where x0 is the initial state.
%
%   See also LQR, LQGREG, LQGTRACK, LQG, ICARE, IDARE.

%   Author: Murad Abu-Khalaf, P. Gahinet
%   Copyright 2008-2018 The MathWorks, Inc.
narginchk(3,4)
if ndims(sys)>2 %#ok<ISMAT>
   error(message('Control:general:RequiresSingleModel','lqi'))
elseif hasdelay(sys)
   throw(ltipack.utNoDelaySupport('lqi',sys.Ts,'all'))
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
   [Q,R,N] = ltipack.checkQRS(nx+ny,nu,Q,R,N,{'Q','R','N'});
catch ME
   throw(ME)
end

% Augment plant with integrators
if Ts==0
   A = [A zeros(nx,ny); -C zeros(ny,ny)];
   B = [B ; -D];
else
   % Discrete-time integrator based on Forward Euler
   A = [A zeros(nx,ny); -C*abs(Ts) eye(ny,ny)];
   B = [B ; -D*abs(Ts)];
end
if ~isempty(E)
   E = blkdiag(E,eye(ny));
end
nz = nx+ny;
 
% Factor [Q N;N' R] and use square-root formulation when possible
[F,G,INDEF] = ltipack.factorQRS(Q,R,N);
if INDEF
   % Proceed with original Q,R,N when [Q N;N' R] is numerically indefinite
   warning(message('Control:design:MustBePositiveDefinite','[Q N;N'' R]','lqi'))
   if Ts==0
      [X,K,clp,INFO] = icare(A,B,Q,R,N,E);
   else
      [X,K,clp,INFO] = idare(A,B,Q,R,N,E);
   end
else
   % Proceed with factored form [Q N;N' R] = [F;G] * [F',G']
   BB = [B zeros(nz,nz+nu)];
   QQ = zeros(nz);
   NN = [zeros(nz,nu) F];
   RR = [zeros(nu) G;G' -eye(nz+nu)];
   if Ts==0
      [X,K,clp,INFO] = icare(A,BB,QQ,RR,NN,E);
   else
      [X,K,clp,INFO] = idare(A,BB,QQ,RR,NN,E);
   end
   K = K(1:min(nu,end),:);
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
if nargout>3
   % Optimal control is u[n] = -K*x[n]-Kw*w[n] when
   %    x[n+1] = Aa xaug[n] + Ba u[n] + [I_nx;0] w[n]
   if Ts==0
      Kw = zeros(nu,nx);
   else
      % Kw = (R+B'*X*B)\(B'*X*E)
      if isempty(E)
         E = 1;
      end
      aux = [-E*(Sx.\U) B ; B'*(Sx.*V) R]\[eye(nz);zeros(nu,nz)];
      Kw = aux(nz+1:nz+nu,1:nx); % w[n] does not affect xi[n]
   end
end