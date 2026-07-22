function [g,baldata] = hsvd(sys,opt,optArgs)
%   HSVD is obsolete, use REDUCESPEC for all model reduction workflows.
%
%   See also REDUCESPEC.

%   Copyright 1986-2023 The MathWorks, Inc.
arguments
   sys
   opt = [];
   optArgs.?ltioptions.balred;
end

% Gather options
if isempty(opt)
   opt = initOptions(ltioptions.balred,namedargs2cell(optArgs));
else
   opt = initOptions(opt,namedargs2cell(optArgs));
end

try
   % Watch for REDUCESPEC supporting sparse
   sys = ss(sys);
catch
   error(message('Control:general:NotSupportedModelsofClass','hsvd',class(sys)))
end

try   
   % Perform ROM analysis
   R = reducespec(sys,'balanced');
   R.Options = mapOptions(R.Options,opt);
   R = process(R);
   % Access balancing data
   baldata = getBalredInfo(R);
   g = baldata.HSV;
catch ME
   throw(ME)
end