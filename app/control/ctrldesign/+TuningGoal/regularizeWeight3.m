function WU = regularizeWeight3(WU,wSlow)
% Regularizes input shaping function for transient matching goals.
%
% Takes a SISO shaping function WU in ZPK form and returns a stable and
% numerically "safe" approximation that preserves the time-domain 
% characteristics of the overall reference model.
% 
% The inputs are:
%   * WU: proper and marginally stable SISO transfer function
%   * wSlow: slowest natural frequency of transient dynamics 
%            (approximate reciprocal of slowest time constant)
%
% Used for StepTracking, Transient.

%   Copyright 2009-2016 The MathWorks, Inc.
[z,p,k,Ts] = zpkdata(WU,'v');  % Ts=0 or Ts>0 in SYSTUNE
fz = damp(z,Ts);
fp = damp(p,Ts);
fRegLow = 1e-3*min(wSlow,pi/Ts);

% Regularize poles at frequencies below FREGLOW
pLow = (fp<fRegLow);
if any(pLow)
   zLow = (fz<fRegLow);
   nL = sum(pLow)-sum(zLow);
   if Ts>0
      rLow = exp(-Ts*fRegLow);
      % Maintain gain at pi/Ts (z=-1)
      k = k * real(prod(1+z(zLow)) / prod(1+p(pLow))) * (1+rLow)^nL;
      z = [z(~zLow) ; repmat(rLow,[-nL 1]) ];
      p = [p(~pLow) ; repmat(rLow,[nL 1]) ];
   else
      z = [z(~zLow) ; repmat(-fRegLow,[-nL 1]) ];
      p = [p(~pLow) ; repmat(-fRegLow,[nL 1]) ];
   end
end
   
% Shift dynamics on the imaginary axis (except zeros at s=0/z=1)
[wnz,zeta] = damp(z,Ts);
iz = find(wnz>0 & zeta<1e-3);
[wnp,zeta] = damp(p,Ts);
ip = find(zeta<1e-3);
if Ts>0
   z(iz) = z(iz) .* exp(-1e-3*Ts*wnz(iz));
   p(ip) = p(ip) .* exp(-1e-3*Ts*wnp(ip));
else
   z(iz) = z(iz)-1e-3*wnz(iz);
   p(ip) = p(ip)-1e-3*wnp(ip);
end

WU = zpk(z,p,k,Ts,'TimeUnit',WU.TimeUnit);