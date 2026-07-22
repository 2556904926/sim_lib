function [gm,pm,alpha] = dm2gmPlot(alpha,sigma)
% Calculates disk-based gain and phase margin shows on disk margin plot.
%
%   SIGMA must be scalar and ALPHA can be a vector.
%
%   See also DM2GM, DISKMARGINPLOT.

%   Copyright 2020 The MathWorks, Inc.

% Enforce alpha*|1+sigma|<2 (e.g., for L=tf([1 1 1],[1 2 3]), sigma=0)
alpha = min(alpha,1.999999/abs(1+sigma),'includenan');
[gm,pm] = dm2gm(alpha,sigma);
gm = min(gm(:,2),1./max(0,gm(:,1)),'includenan');  % abs
pm = min(pm(:,2),180,'includenan');  % degrees