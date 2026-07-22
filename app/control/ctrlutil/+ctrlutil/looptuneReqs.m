function [SoftReqs,HardReqs,Options] = looptuneReqs(wc,Reqs,Options,uNames,yNames)
% Converts LOOPTUNE specs into SYSTUNE specs.
%
% UNAMES and YNAMES are the control and measurement signal names (with 
% correct signal width in MIMO case).

%   Copyright 2003-2012 The MathWorks, Inc.
nu = numel(uNames);
ny = numel(yNames);
if nu>ny
   LoopID = yNames;
else
   LoopID = uNames;
end

% Crossover band spec
if isempty(wc)
   WCReq = [];
else
   WCReq = localCreateMainReq(wc);
   if nu>ny
      WCReq.Name = getString(message('Control:tuning:looptune15'));
   else
      WCReq.Name = getString(message('Control:tuning:looptune16'));
   end
end

% Stability margins
GM = Options.GainMargin;
PM = Options.PhaseMargin;
uMargin = TuningGoal.Margins(uNames,GM,PM);  % at plant inputs
uMargin.Name = getString(message('Control:tuning:looptune13'));
if nu>1 || ny>1
   yMargin = TuningGoal.Margins(yNames,GM,PM);  % at plant outputs
   yMargin.Name = getString(message('Control:tuning:looptune14'));
else
   yMargin = [];
end

% Error if there are no specs
SoftReqs = cat(1,WCReq,Reqs);
if isempty(SoftReqs)
   error(message('Control:tuning:looptune5'))
end
SoftReqs = [SoftReqs ; uMargin ; yMargin];

% Resolve undefined LOOPID for loop shaping requirements (for backward compatibility)
for ct=1:numel(SoftReqs)
   R = SoftReqs(ct);
   if isa(R,'TuningGoal.LoopShape') && isempty(R.Location)
      SoftReqs(ct).Location = LoopID;
   end
end

% Spectral radius (hard requirement)
if isfinite(Options.MaxFrequency)
   HardReqs = TuningGoal.Poles(0,0,Options.MaxFrequency);
else
   HardReqs = [];
end

% Convert options
Options = systuneOptions(Options);
Options.Hidden.Problem = 'Hinf';  % for progress display

end

%----------------- Local Functions ----------------------

function R = localCreateMainReq(wc)
% Creates loop shaping requirement based on crossover band spec WC
nwc = numel(wc);
if ~(isnumeric(wc) && isreal(wc) && (nwc==1 || nwc==2))
   error(message('Control:tuning:looptune8'))
elseif nwc==1
   wc = [wc wc];
end
if wc(1)<=0 || wc(1)>wc(2)
   error(message('Control:tuning:looptune9'))
end
R = TuningGoal.LoopShape(cell(0,1),wc);
end

