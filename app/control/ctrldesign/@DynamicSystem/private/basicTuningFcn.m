function LOG = basicTuningFcn(LOG,SYSDATA,SPECDATA,tInfo,x0,Options)
% Single min-max optimization.

%   Copyright 2010-2015 The MathWorks, Inc.
LOG.X = x0;
LOG.StartIter = LOG.Iter;  % for incremental count
% Stabilize
[LOG,SYSDATA] = ns_stab(LOG,SYSDATA,SPECDATA,tInfo,Options);
% Optimize performance
if ~Options.Hidden.StabilizeOnly && LOG.Fstab<0
   LOG = ns_perf(LOG,SYSDATA,SPECDATA,tInfo,Options);
end