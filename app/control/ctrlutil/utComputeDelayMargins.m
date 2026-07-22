function Dm = utComputeDelayMargins(Pm,Wcp,Ts,Td,rtol)
% Utility to calculate delay margins
% Pm is in rads
% Wcp is in rad/s
% Ts is sample time
% Td is total delay in seconds (Td = integer delay * Ts in discrete time)
% rtol is relative accuracy on computed crossings/margins

%   Copyright 1986-2023 The MathWorks, Inc.
if nargin < 5
   rtol = 0;
end

% Delay margins: contributions from jw-axis or unit circle
Dm = inf(1,numel(Pm));
nzf = (Wcp~=0);
Dm(:,~nzf & abs(Pm)<rtol) = 0;   % for Pm=0 at Wcp=0
Wcp = Wcp(:,nzf);
dmarg = Pm(:,nzf)./Wcp;
% Enforce Dm>=-Td with some slack for rounding errors
atol = sqrt(eps)*(1+Td);
ix = find(dmarg<-Td-atol);
dmarg(:,ix) = dmarg(:,ix)+2*pi./abs(Wcp(:,ix));
Dm(:,nzf) = max(-Td,dmarg);
if Ts
   % Express Dm has a (fractional) multiple of the sample period
   Dm = Dm/abs(Ts);
end