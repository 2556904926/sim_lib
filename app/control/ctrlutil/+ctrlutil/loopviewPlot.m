function loopviewPlot(CG,GC)
% Constructs INFO output of LOOPTUNE from counterpart for SYSTUNE.

%   Copyright 2003-2014 The MathWorks, Inc.
ny = size(GC,1);
nu = size(CG,1);

% Sensitivity functions
if nu>ny
   % Output sensitivity
   S = feedback(eye(ny),GC,+1);
   T = S-eye(ny);
else
   % Input sensitivity
   S = feedback(eye(nu),CG,+1);
   T = S-eye(nu);
end

% Determine the crossover range and set frequency range
[sv,w] = sigma(blkdiag(GC,CG));
sv = sv(max(sv,[],2)>1 & min(sv,[],2)<1,:);
if isempty(sv)
   wcmin = 1;   wcmax = 1;
else
   wcmin = w(find(sv(end,:)<1,1));
   wcmax = w(find(sv(1,:)<1,1));
end
fmin = 10^floor(log10(wcmin)-1.5);
fmax = 10^ceil(log10(wcmax)+1.5);

% Open-loop view
f = gcf;
h = sigmaplot(f,GC,CG,'--',S,T);
for ct=1:numel(h.Responses)
   h.Responses(ct).LineWidth = 1.75;
end
h.Responses(1).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
h.Responses(2).SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
h.Responses(3).SemanticColor = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
h.Responses(4).SemanticColor = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
h.LegendVisible = true;
h.LegendLocation = 'northeast';

% Grid and limits
h.AxesStyle.GridVisible = true;
if nu>ny
   h.Title.String = getString(message('Control:tuning:strLoopView4'));
else
   h.Title.String = getString(message('Control:tuning:strLoopView3'));
end
h.XLimits = [fmin,fmax];
h.YLimits(1) = max(h.YLimits(1),-60);
h.YLimits(2) = min(h.YLimits(2),60);
