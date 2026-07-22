function [Phi, Gamma] = c2d(a, b, t)
%C2D  Converts continuous-time dynamic system to discrete time.
%
%   SYSD = C2D(SYSC,TS,METHOD) computes a discrete-time model SYSD with
%   sample time TS that approximates the continuous-time model SYSC.
%   The string METHOD selects the discretization method among the following:
%      'zoh'           Zero-order hold on the inputs
%      'foh'           Linear interpolation of inputs
%      'impulse'       Impulse-invariant discretization
%      'tustin'        Bilinear (Tustin) approximation.
%      'matched'       Matched pole-zero method (for SISO systems only).
%      'least-squares' Least-squares minimization of the error between
%                      frequency responses of the continuous and discrete
%                      systems (for SISO systems only).
%      'damped'        Damped Tustin approximation based on TRBDF2 formula
%                      (sparse models only).
%   The default is 'zoh' when METHOD is omitted. The sample time TS should
%   be specified in the time units of SYSC (see "TimeUnit" property).
%
%   C2D(SYSC,TS,OPTIONS) gives access to additional discretization options. 
%   Use C2DOPTIONS to create and configure the option set OPTIONS. For 
%   example, you can specify a prewarping frequency for the Tustin method by:
%      opt = c2dOptions('Method','tustin','PrewarpFrequency',.5);
%      sysd = c2d(sysc,.1,opt);
%
%   For state-space models,
%      [SYSD,G] = C2D(SYSC,Ts,METHOD)
%   also returns the matrix G mapping the states xc(t) of SYSC to the states 
%   xd[k] of SYSD:
%      xd[k] = G * [xc(k*Ts) ; u[k]]
%   Given an initial condition x0 for SYSC and an initial input value u0=u(0), 
%   the equivalent initial condition for SYSD is (assuming u(t)=0 for t<0):
%      xd[0] = G * [x0;u0] .
%
%   For gridded LTV/LPV models (see ssInterpolant), C2D discretizes the LTI
%   model at each grid point and interpolates the resulting discrete-time
%   data. To interpolate the continuous-time data instead, first convert
%   the gridded model to LTVSS or LPVSS. For all other LTV/LPV models, C2D
%   uses the Tustin method which amounts to fixed-step integration with the
%   trapezoidal rule.
%
%   See also C2DOPTIONS, D2C, D2D, SSINTERPOLANT, LTVSS, LPVSS, DYNAMICSYSTEM.

%Other syntax
%C2D	Conversion of state space models from continuous to discrete time.
%	[Phi, Gamma] = C2D(A,B,T)  converts the continuous-time system:
%		.
%		x = Ax + Bu
%
%	to the discrete-time state-space system:
%
%		x[n+1] = Phi * x[n] + Gamma * u[n]
%
%	assuming a zero-order hold on the inputs and sample time T.
%
%	See also D2C.

%	J.N. Little 4-21-85
%   Copyright 1986-2011 The MathWorks, Inc.

narginchk(3,3);
if ~isnumeric(a)
   % Watch for c2d(sys,Ts,method) for sys=genmat
   error(message('Control:general:NotSupportedModelsofClass','c2d',class(a)))
end
error(abcdchk(a,b));

[m,n] = size(a); %#ok<ASGLU>
[m,nb] = size(b); %#ok<ASGLU>
s = expm([[a b]*t; zeros(nb,n+nb)]);
Phi = s(1:n,1:n);
Gamma = s(1:n,n+1:n+nb);

% end c2d
