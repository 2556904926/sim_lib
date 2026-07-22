function varargout = utGetMinMargins(s)
% Utility to derive min. stability margins from ALLMARGIN's output.
% smin = utGetMinMargins(s)
% [Gm,Pm,Dm,Wcg,Wcp,isStable] = utGetMinMargins(s)

%   Copyright 1986-2021 The MathWorks, Inc.    
EXTRA = isfield(s,'GMPhase');

% Compute min (worst-case) gain margin
GM = s.GainMargin;
if isempty(GM)
   s.GainMargin = Inf;
   s.GMFrequency = NaN;
   if EXTRA
      s.GMPhase = NaN;
   end
else
   [~,imin] = min(abs(log2(GM)));
   s.GainMargin = GM(imin);
   s.GMFrequency = s.GMFrequency(imin);
   if EXTRA
      s.GMPhase = s.GMPhase(imin);
   end
end
   
% Compute min phase margin
PM = s.PhaseMargin;
if isempty(PM)
   s.PhaseMargin = Inf;
   s.DelayMargin = Inf;
   s.PMFrequency = NaN;
   if EXTRA
      s.PMPhase = NaN;
   end
else
   [~,imin] = min(abs(PM));
   s.PhaseMargin = PM(imin);
   s.DelayMargin = s.DelayMargin(imin);
   s.PMFrequency = s.PMFrequency(imin);
   if EXTRA
      s.PMPhase = s.PMPhase(imin);
   end
end

if nargout==1
   varargout = {s};
else
   varargout = {s.GainMargin s.PhaseMargin s.DelayMargin ...
      s.GMFrequency s.PMFrequency s.Stable};
end   

