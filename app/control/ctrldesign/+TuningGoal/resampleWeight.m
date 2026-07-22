function WF = resampleWeight(WF,Ts)
% Resamples SISO or MIMO weighting function in a manner that minimizes
% gain distortions. If not SISO, the weight is assumed to be stable.
% Ts is the working sample time for tuning (Ts=0 or Ts>0).

%   Copyright 2009-2014 The MathWorks, Inc.

% Note: 
% 1) Samples times must be zero or positive
% 2) D2C conversion may alter relative degree in SISO case so this should
%    be followed by regularizeWeight
% 3) The 'tustin' method typically has the least distortion, but 'matched'
%    produces a more "feasible" gain profile for roll-off weights.
Ts0 = WF.Ts;
if Ts0==Ts
   return
end
[Zeros,Poles,Gains] = zpkdata(WF);
[ny,nu] = size(Gains);
SISOWeight = (nu==1 && ny==1);

% Check feasibility
if ~SISOWeight && Ts0>0 && any(cellfun(@(r) any(r==0),[Zeros(:);Poles(:)]))
   % MIMO D2C conversion fails when there are poles or zeros at z=0
   error(message('Control:tuning:TuningReq18'))
end

% Discretize each I/O pair independently
for ct=1:ny*nu
   [Zeros{ct},Poles{ct},Gains(ct)] = ...
      localResampleDynamics(Zeros{ct},Poles{ct},Gains(ct),Ts0,Ts);
end

% Combine results
WF = zpk(Zeros,Poles,Gains,Ts,'TimeUnit',WF.TimeUnit);
if ~SISOWeight
   % MIMO weight from Weighted* goals
   WF = prescale(ss(WF));
end

%---------------------------------------------------------------------
function [z2,p2,k2] = localResampleDynamics(z1,p1,k1,Ts1,Ts2)
% Resamples dynamics of SISO weighting function using "matched" method to
% limit gain distortions near the Nyquist frequency.
%
% The poles and zeros can be stable or unstable and the relative degree is
% arbitrary. This function handles real negative poles/zeros and poles/zeros
% at z=0.
%
% Note: The 'tustin' method typically has the least distortion, but 
% 'matched' produces a more "feasible" gain profile for roll-off weights.

%   Copyright 2009-2016 The MathWorks, Inc.
if Ts1>0
   % D2C conversion
   % Ignore poles and zeros at z=0 (do not contribute to gain profile)
   z1 = z1(z1~=0);  p1 = p1(p1~=0);
   % Isolate real negative poles and zeros
   inz = (real(z1)<0 & imag(z1)==0);
   z1 = [z1(~inz) ; z1(inz)];   nz1 = sum(~inz);
   inp = (real(p1)<0 & imag(p1)==0);
   p1 = [p1(~inp) ; p1(inp)];   np1 = sum(~inp);
   % Transform remaining dynamics
   z0 = log(z1(1:nz1))/Ts1;
   p0 = log(p1(1:np1))/Ts1;
   % Transform real negative poles and zeros
   for ct=np1+1:numel(p1)
      [z,p] = localRealNeg(p1(ct),Ts1);
      z0 = [z0;z];  p0 = [p0;p]; %#ok<*AGROW>
   end
   for ct=nz1+1:numel(z1)
      [p,z] = localRealNeg(z1(ct),Ts1);
      z0 = [z0;z];  p0 = [p0;p];
   end
   % Preserve DC gain (exclude pseudo-integrators to minimize rounding errors
   % in 1-p1 and 1-z1)
   zeroTol = 100*eps;
   ip1 = find(abs(1-p1)>zeroTol);
   iz1 = find(abs(1-z1)>zeroTol);
   m = (numel(p1)-numel(ip1))-(numel(z1)-numel(iz1));
   ip0 = [ip1 ; (numel(p1)+1:numel(p0))'];
   iz0 = [iz1 ; (numel(z1)+1:numel(z0))'];
   k0 = (k1 / Ts1^m) * real( prod(-p0(ip0)) * prod(1-z1(iz1)) / ...
      prod(-z0(iz0)) / prod(1-p1(ip1)) );
else
   z0 = z1;  p0 = p1;  k0 = k1;
end
      
if Ts2>0
   % C2D conversion
   % Make sure no pole or zero gets mapped to the unit circle because
   % exp(Re(s)*Ts2)=1 due to limited precision
   zeroTol = 100*eps*pi/Ts2;  % exp(Ts2*r)=1+o(zeroTol) if |r|<zeroTol
   z0 = z0+sign(real(z0))*zeroTol;
   p0 = p0+sign(real(p0))*zeroTol;
   % Transform
   z2 = exp(Ts2*z0);
   p2 = exp(Ts2*p0);
   % Preserve DC gain (exclude pseudo-integrators to minimize rounding errors
   % in 1-p2 and 1-z2)
   ip = find(abs(p0)>2*zeroTol);
   iz = find(abs(z0)>2*zeroTol);
   m = numel(iz)-numel(z0)+numel(p0)-numel(ip);
   k2 = Ts2^m * k0 * real(prod(-z0(iz)) * prod(1-p2(ip)) / prod(-p0(ip)) / prod(1-z2(iz)));
else
   z2 = z0;  p2 = p0;  k2 = k0;
end


function [z,p] = localRealNeg(r,Ts)
% D2C conversion of 1/(z-r) with r<0. 
% Transforms (z+r)/((z+r)^2+eps^2) to work around log(-r) being complex
pert = 1e-4*abs(r);
a = [r pert;-pert r];
b = [1;0];
c = [1,0];
d = 0;
M = real(logm([a b;zeros(1,2) 1]))/Ts;
ac = M(1:2,1:2);
bc = M(1:2,3);
z = ltipack.sszero(ac,bc,c,d,[],Ts);
p = eig(ac);


% SAVED FROM EARLIER VERSION
% Tustin method for C2D:
% Make weight biproper with no poles or zeros past Nyquist frequency
% pSelect = (abs(p)<nf);
% zSelect = (abs(z)<nf);
% r = sum(pSelect)-sum(zSelect);
% k = (k/nf^r) * prod(-z(~zSelect)) / prod(-p(~pSelect));
% z = [z(zSelect,:) ; repmat(-nf,[r 1])];
% p = [p(pSelect,:) ; repmat(-nf,[-r 1])];
% % Discretize using Tustin formula
% zd = (2+Ts*z)./(2-Ts*z);
% pd = (2+Ts*p)./(2-Ts*p);
