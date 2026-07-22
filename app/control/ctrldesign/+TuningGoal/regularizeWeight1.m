function WF = regularizeWeight1(WF,wc,Focus)
% Regularizes SISO weighting function acting on S or T=1-S.
%
% Takes a SISO weighting function WF in ZPK form and returns a bi-proper, 
% bi-stable approximation that is numerically "safe". The inputs are:
%   * wc: 0dB crossover frequencies (expects at least one)
%   * Focus: Frequency range of interest.
%
% Used for LoopShape, Min/MaxLoopGain, Rejection, Sensitivity, Tracking.

%   Copyright 2009-2016 The MathWorks, Inc.

% Parameters
GLOW = 0.1;   % low gain cutoff
GHIGH = 1e3;  % high gain cutoff
FSPAN = 1e4;  % weight dynamics confined to [wc(1)/FSPAN,FSPAN*wc(end)]
FSEP = 25;    % safe distance from region where shape must be preserved

% Resample in a way that limits gain distortions.
[z,p,k,Ts] = zpkdata(WF,'v');  % Ts=0 or Ts>0 in SYSTUNE
nf = pi/Ts;
wc = wc(wc>0 & wc<nf);
if Ts>0
   % Eliminate dynamics at z=0 (do not contribute to gain)
   z = z(z~=0);  p = p(p~=0);
end

% Regularize weight dynamics
if ~isempty(wc)
   % Key frequencies
   wmin = wc(1)/FSPAN;
   wmax = FSPAN*wc(end);
   fRegFocus = Focus .* [1/FSEP,FSEP]; % regularizing freqs based on FOCUS
   
   % Must-show dynamics
   fz = damp(z,Ts);  
   fp = damp(p,Ts);  
   fzp = [fz;fp];
   fzp = fzp(fzp>max(wmin,Focus(1)) & fzp<min(wmax,Focus(2)));
   
   % Compute gain over frequency range of interest
   lw1 = log10(wmin);
   lw2 = log10(min(wmax,nf));
   wTest = logspace(lw1,lw2,ceil(3*(lw2-lw1)));
   nw = numel(wTest);
   hTest = freqresp(WF,wTest);
   gTest = reshape(abs(hTest),[1 nw]);
   iLG = find(gTest>GLOW);
   iHG = find(gTest<GHIGH);
   
   % Low regularization frequency
   fRegLow = fRegFocus(1);
   if gTest(1)<1
      fRegLow = max(fRegLow,wTest(iLG(1))); % fRegLow>=wmin
      fRegLow = min(fRegLow,wc(1)/FSEP);    % fRegLow<=wc(1)/FSEP
   else
      wCross = localFindCross(wTest,gTest,iHG(1)+[-1,0],GHIGH);
      fRegLow = max(fRegLow,wCross);
      % Honor user-specified dynamics when reasonably close to wc
      rmin = min([fzp ; wc(1)]);
      fRegLow = min(fRegLow,rmin/FSEP);
      % wmin/FSEP<=min(rmin/FSEP,wmin)<=fRegLow<=rmin/FSEP
   end
   
   % High regularization frequency
   if Ts>0
      % No regularization needed near pi/Ts
      fRegHigh = Inf;
   else
      fRegHigh = fRegFocus(2);
      if gTest(end)<1
         fRegHigh = min(fRegHigh,wTest(iLG(end))); % fRegHigh<=wmax
         fRegHigh = max(fRegHigh,FSEP*wc(end));    % fRegHigh>=FSEP*wc(end)
      else
         wCross = localFindCross(wTest,gTest,iHG(end)+[0,1],GHIGH);
         fRegHigh = min(fRegHigh,wCross);
         rmax = max([fzp ; wc(end)]);
         fRegHigh = max(fRegHigh,FSEP*rmax);
         % Note: FSEP*rmax<=fRegHigh<=max(FSEP*rmax,wmax)<=FSEP*wmax
      end
   end
   
   % Regularize "out of range" dynamics and enforce bi-properness
   zLow = (fz<fRegLow);  zHigh = (fz>fRegHigh);
   pLow = (fp<fRegLow);  pHigh = (fp>fRegHigh);
   nzL = sum(zLow)-sum(pLow);
   nzH = sum(zHigh)-sum(pHigh)+numel(p)-numel(z);
   if Ts>0
      rLow = exp(-Ts*fRegLow);
      % Maintain gain at pi/Ts (z=-1)
      k = k * real(prod(1+z(zLow)) / prod(1+p(pLow))) / (1+rLow)^nzL;
      z = [z(~(zLow | zHigh)) ; repmat(rLow,[nzL 1]) ; zeros(nzH,1) ];
      p = [p(~(pLow | pHigh)) ; repmat(rLow,[-nzL 1]) ; zeros(-nzH,1) ];
   else
      k = k * prod(z(zHigh)) / prod(p(pHigh)) / fRegHigh^nzH;
      z = [z(~(zLow | zHigh)) ; repmat(-fRegLow,[nzL 1]) ; repmat(-fRegHigh,[nzH 1]) ];
      p = [p(~(pLow | pHigh)) ; repmat(-fRegLow,[-nzL 1]) ; repmat(-fRegHigh,[-nzH 1]) ];
   end
else
   % Note: Caller must ensure that |WF| is bounded from above when wc=[]
   %       (no change to weight dynamics)
   if Ts>0
      % Enforce properness (improper weights remain bounded in discrete time)
      p = [p ; zeros(numel(z)-numel(p),1)];
   end
end

% Reflect unstable dynamics
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

% Shift dynamics on the imaginary axis
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

%----------------------------
function wCross = localFindCross(w,g,ix,gCross)
% Approximates gain crossover frequency.
if ix(1)<1
   wCross = w(1);
elseif ix(2)>numel(w)
   wCross = w(end);
else
   w1 = w(ix(1));  w2 = w(ix(2));
   g1 = g(ix(1));  g2 = g(ix(2));
   wCross = w1*pow2(log2(w2/w1)*log2(gCross/g1)/log2(g2/g1));
end
