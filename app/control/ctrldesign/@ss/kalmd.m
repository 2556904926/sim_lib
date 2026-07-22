function [kest,l,p,m,z] = kalmd(sys,qn,rn,Ts)
%KALMD  Discrete Kalman estimator for continuous-time plant.
%
%   [KEST,L,P,M,Z] = KALMD(SYS,Qn,Rn,Ts) computes a discrete Kalman 
%   estimator KEST for the continuous plant 
%        .
%        x = Ax + Bu + Gw      {State equation}
%        y = Cx + Du +  v      {Measurements}
%
%   with process and measurement noise
%
%     E{w} = E{v} = 0,  E{ww'} = Qn,  E{vv'} = Rn,  E{wv'} = 0.
%
%   The state-space model SYS specifies the plant data (A,[B G],C,[D 0]).
%   The continuous plant and covariance matrices (Q,R) are first 
%   discretized using the sample time Ts and zero-order hold approximation, 
%   and the discrete Kalman estimator for the resulting discrete plant is 
%   then calculated with KALMAN.
%
%   KALMD also returns the estimator gain L, innovation gain M, and the 
%   steady-state error covariances P and Z (type HELP KALMAN for details).
%
%   See also LQRD, KALMAN, LQGREG.

%   Author(s): Clay M. Thompson, P. Gahinet
%   Copyright 1986-2010 The MathWorks, Inc.
narginchk(4,4)
if ndims(sys)>2 %#ok<ISMAT>
   error(message('Control:general:RequiresSingleModel','kalmd'))
elseif hasdelay(sys)
   throw(ltipack.utNoDelaySupport('kalmd',sys.Ts,'all'))
end

% Extract plant data
try
   [a,bb,c,dd,tsp] = ssdata(sys);
catch %#ok<CTCH>
   error(message('Control:general:NotSupportedSingularE','kalmd'))
end
Nx = size(a,1);
[Ny,md] = size(dd);
if tsp~=0
   error(message('Control:design:kalmd1'))
elseif Ny==0
   error(message('Control:design:kalmd2'))
end

% Validate Qn,Rn
Nw = size(qn,1);
if Nw>md
   error(message('Control:design:kalmd3'))
end
try
   [qn,rn] = ltipack.checkQRS(Nw,Ny,qn,rn,[],{'Qn','Rn','Nn'});
catch ME
   throw(ME)
end

% Extract B,G,D,H
Nu = md-Nw;
b = bb(:,1:Nu);   d = dd(:,1:Nu);
g = bb(:,Nu+1:Nu+Nw);   h = dd(:,Nu+1:Nu+Nw);
if any(h(:))
   error(message('Control:design:kalmd5'))
end

% Form G*Q*G', enforce symmetry and check positivity
qn = g * qn *g';
qn = (qn+qn')/2;
rn = (rn+rn')/2;

% Discretize plant and compute discrete equivalent of continuous noise
[ad,bd] = c2d(a,b,Ts);
M = [-a  qn ; zeros(Nx) a'];
phi = expm(M*Ts);
phi12 = phi(1:Nx,Nx+1:2*Nx);
phi22 = phi(Nx+1:2*Nx,Nx+1:2*Nx);
Qd = phi22'*phi12;
Qd = (Qd+Qd')/2; % Make sure Qd is symmetric
Rd = rn/Ts;

% Warn if Qd or Rd indefinite
ev = eig(Qd);
if min(ev)<-1e2*eps*max(abs(ev))
   warning(message('Control:design:kalmd4'))
end
ev = eig(Rd);
if min(ev)<-1e2*eps*max(abs(ev))
   warning(message('Control:design:kalmd6'))
end
% Prevent repeat warnings in KALMAN
hw = ctrlMsgUtils.SuspendWarnings('Control:design:MustBePositiveDefinite'); %#ok<NASGU>

% Call KALMAN on discretized plant/noise to derive KEST
sysd = ss(ad,[bd eye(Nx)],c,[d zeros(Ny,Nx)],Ts,'TimeUnit',sys.TimeUnit);
sysd.StateName = sys.StateName;
sysd.InputName = [sys.InputName(1:Nu);repmat({''},[Nx 1])];
sysd.OutputName_ = sys.OutputName_;
[kest,l,p,m,z] = kalman(sysd,Qd,Rd);
