function WF = regularizeWeight2(WF,Focus,BiFlag)
% Regularizes weighting functions for gain and passivity goals.
%
% Takes a SISO weighting function WF in ZPK form and returns a numerically 
% "safe" approximation with the following properties:
%   * BIFLAG=false: WF is stable and proper
%   * BIFLAG=true: WF is bi-stable and bi-proper
% The other inputs are:
%   * FOCUS: Frequency range of interest.
%
% Used for Gain, WeightedGain, WeightedVariance, WeightedPassivity.

%   Copyright 2009-2016 The MathWorks, Inc.

% Note: 
% 1) Weight dynamics outside [FMIN,FMAX] are treated as dynamics at w=0 
%    or w=Inf and always regularized. This is necessary for numerical 
%    stability and because conversion from TF/SS to ZPK or weight 
%    inversion (WeightedPassivity) may perturb poles at w=0 or w=Inf
% 2) Dynamics inside [FMIN,FMAX] are preserved since there is no basis
%    for dropping a particular subset of these dynamics
% 3) The regularization frequencies FREGLOW and FREGHIGH are chosen to
%    capture all dynamics in [FMIN,FMAX] plus about 60dB worth of asymtotes
% 4) When Ts>0, no regularization takes place at high frequency and poles
%    or zeros at z=0 are added to enforce (bi)properness

% Parameters
GSEP = 1e3;   % safe gain variation for regularization
FSEP = 25;    % safe distance from region where shape must be preserved
FSPAN = 1e8;  % max dynamic range factor

% ZPK data
[z,p,k,Ts] = zpkdata(WF,'v');  % Ts=0 or Ts>0 in SYSTUNE
nf = pi/Ts;
Focus(2) = min(Focus(2),nf);

% Set [FMIN,FMAX] range
if Ts==0
   FMIN = 1/FSPAN;   FMAX = FSPAN;
else
   FMIN = nf/FSPAN;   FMAX = nf;
end 
% Shrink [FMIN,FMAX] based on FOCUS
if Focus(1)<FMAX
   FMIN = max(FMIN,Focus(1)/FSEP);
end
if Focus(2)>FMIN
   FMAX = min(FMAX,FSEP*Focus(2));
end

% Dynamics in [FMIN,FMAX]
fz = damp(z,Ts);  nz = numel(fz);
fp = damp(p,Ts);  np = numel(fp);
fzp = [fz;fp];
fzp = fzp(fzp>=FMIN & fzp<=FMAX);

% Compute regularization frequencies FREGLOW,FREGHIGH
fRegLow = FMIN;
fRegHigh = FMAX;
if isempty(fzp)
   % No dynamics in [FMIN,FMAX]: Limit the [FREGLOW,FREGHIGH] span to six decades
   A = (Focus(1)==0);
   B = (Focus(2)==Inf);
   if A && B
      fRegLow = 1e-3;  fRegHigh = 1e3;
   elseif A
      fRegLow = 1e-6*fRegHigh;
   elseif B
      fRegHigh = 1e6*fRegLow;
   end
else
   % Pick FREGLOW,FREGHIGH to capture all dynamics in [FMIN,FMAX] plus 
   % 60dB-worth of the left/right asymptotes (regard asymptotes as a way 
   % to enforce a particular slope in the response, for which 60dB is enough)
   wmin = 0.8*min(fzp);
   wmax = 1.25*max(fzp);
   smin = max(1,abs(sum(fz<wmin)-sum(fp<wmin)));  % slope to the left of wmin
   smax = max(1,abs(sum(fz<wmax)-sum(fp<wmax)));  % slope to the right of wmax
   fRegLow = max(fRegLow,wmin/max(FSEP,GSEP^(1/smin)));
   fRegHigh = min(fRegHigh,wmax*max(FSEP,GSEP^(1/smax)));
end
%[fRegLow fRegHigh]

% Regularize "out of range" dynamics and enforce properness
pLow = (fp<fRegLow);  
if Ts==0
   pHigh = (fp>fRegHigh);
else
   pHigh = false(np,1);
end
if BiFlag || any(pLow)
   zLow = (fz<fRegLow); 
else
   zLow = false(nz,1);
end
if BiFlag || any(pHigh)
   zHigh = (fz>fRegHigh);
else
   zHigh = false(nz,1);
end
% nL: number of poles (nL>0) or zeros (nL<0) at fRegLow
% nH: number of poles (nH>0) or zeros (nH<0) at fRegHigh
nL = sum(pLow)-sum(zLow);
if BiFlag
   nH = sum(pHigh)-sum(zHigh)+numel(z)-numel(p);  % make bi-proper
else
   nH = sum(pHigh)-sum(zHigh)+max(0,numel(z)-numel(p));  % make proper
end
if Ts>0
   rLow = exp(-Ts*fRegLow);
   % Maintain gain at pi/Ts (z=-1)
   k = k * real(prod(1+z(zLow)) / prod(1+p(pLow))) * (1+rLow)^nL;
   z = [z(~(zLow | zHigh)) ; repmat(rLow,[-nL 1]) ; zeros(-nH,1) ];
   p = [p(~(pLow | pHigh)) ; repmat(rLow,[nL 1]) ; zeros(nH,1) ];
else
   k = k * prod(z(zHigh)) / prod(p(pHigh)) * fRegHigh^nH;
   z = [z(~(zLow | zHigh)) ; repmat(-fRegLow,[-nL 1]) ; repmat(-fRegHigh,[-nH 1]) ];
   p = [p(~(pLow | pHigh)) ; repmat(-fRegLow,[nL 1]) ; repmat(-fRegHigh,[nH 1]) ];
end
   
% Reflect unstable poles and zeros
if Ts>0
   iz = find(abs(z)>1);
   ip = find(abs(p)>1);
   k = k * prod(z(iz))/prod(p(ip));
   z(iz) = 1./z(iz);
   p(ip) = 1./p(ip);
else
   iz = find(real(z)>0);
   ip = find(real(p)>0);
   z(iz) = -z(iz);
   p(ip) = -p(ip);
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

WF = zpk(z,p,k,Ts,'TimeUnit',WF.TimeUnit);
