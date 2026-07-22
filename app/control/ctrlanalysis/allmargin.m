function s = allmargin(mag,phase,w,Ts,Td,UNWRAP)
%ALLMARGIN  All stability margins and crossover frequencies.
%
%   S = ALLMARGIN(L) computes the gain, phase, and delay margins and the 
%   corresponding crossover frequencies for the negative feedback loop
%
%         u --->O---->[ L ]----+---> y
%             - |              |
%               +<-------------+
%
%   When L is SISO, S is a structure with the following fields:
%     * GMFrequency: all -180 deg crossover frequencies in rad/TimeUnit
%       (relative to the time units specified in L.TimeUnit, the default
%       being seconds)
%     * GainMargin: corresponding gain margins (g.m. = 1/G where G is the
%       gain at crossover)
%     * PMFrequency: all 0 dB crossover frequencies (in rad/TimeUnit)
%     * PhaseMargin: corresponding  phase margins (in degrees)
%     * DelayMargin, DMFrequency: delay margins (in the units specified
%       in L.TimeUnit for continuous-time systems, and in multiples of
%       the sample time for discrete-time systems) and corresponding
%       critical frequencies
%     * Stable: 1 if nominal closed loop is stable, 0 if unstable, and NaN
%       if stability cannot be assessed (as in the case for FRD models)
%
%   When L is an N-by-N MIMO transfer function, S is N-by-1 and S(j) gives  
%   the stability margins for the j-th feedback channel with all other
%   loops closed (one-loop-at-a-time margins).
%
%   S = ALLMARGIN(L,Focus=[FMIN,FMAX]) only looks at margins in the 
%   frequency range [FMIN,FMAX] and ignores stability issues outside this 
%   range, for example, low-frequency instabilities.
%
%   S = ALLMARGIN(MAG,PHASE,W,TS) computes the stability margins from the
%   frequency response data W, MAG, PHASE and the sample time TS. ALLMARGIN
%   expects gain values MAG in absolute units and phase values PHASE in
%   degrees. Interpolation is used between frequency points to approximate
%   the true stability margins.
%
%   See also MARGIN, DISKMARGIN, BODE, NYQUIST, NICHOLS, LTIVIEW, DYNAMICSYSTEM.

%   Author(s): P.Gahinet
%   Copyright 1986-2021 The MathWorks, Inc.
narginchk(3,6);
ni = nargin;
if ni<4
   Ts = 0;
end
if ni<5
   Td = 0;
end
if ni<6
   % Note: Phase unwrapping can mess delay contribution
   UNWRAP = true;
end
nf = numel(w);  
w = reshape(w,[1 nf]);
if ~(isnumeric(mag) && isnumeric(phase) && isnumeric(w) && ...
      isreal(w) && isreal(mag) && isreal(phase) && ...
      numel(mag)==nf && numel(phase)==nf)
   error(message('Control:analysis:margin2','allmargin'))
elseif any(diff(w)<=0)
   error(message('Control:analysis:margin3','allmargin'))
end
mag = reshape(mag,[nf 1]);
phase = reshape(phase,[nf 1]);
if any(mag<0)
   error(message('Control:analysis:margin4','allmargin'))
end
% Eliminate Inf/NaN values (messes up interpolation)
idxf = find(isfinite(mag) & isfinite(phase));
w = w(:,idxf);  mag = mag(idxf,:);  phase = phase(idxf,:);
% Convert phase to radians
phase = (pi/180)*phase;
if UNWRAP
   phase = unwrap(phase);
end

%------------------------------------
% Gain margins (-180 phase crossings)
%------------------------------------
[Wcg,ic] = ltipack.util.interpPhaseCrossover(w,phase,pi);
t = rem(ic,1);
ic = floor(ic);
Gm = 1./mag(ic,:).^(1-t)./mag(ic+1,:).^t;  % in abs units
Wcg = Wcg.';  Gm = Gm.';

%------------------------------------
% Phase margins (0dB gain crossings)
%------------------------------------
[Wcp,ic] = ltipack.util.interpGainCrossover(w,mag,1);
if numel(Wcp)>50
   % Limity to first 50 (could be thousands for models with large delays)
   Wcp = Wcp(1:50);  ic = ic(1:50);
end
t = rem(ic,1);
ic = floor(ic);
Pm = (1-t).*phase(ic,:)+t.*phase(ic+1,:);  % in radians
Pm = mod(Pm,2*pi)-pi;
Wcp = Wcp.';  Pm = Pm.';
Ts = abs(Ts);
if Ts>0
   Td = Td*Ts;
end
Dm = utComputeDelayMargins(Pm,Wcp,Ts,Td);  % note: requires Pm in rad
Pm = (180/pi) * Pm; % in deg

% Construct output
s = struct(...
   'GainMargin',Gm,...
   'GMFrequency',Wcg,...
   'PhaseMargin',Pm,...
   'PMFrequency',Wcp,...
   'DelayMargin',Dm,...
   'DMFrequency',Wcp,...
   'Stable',NaN);
