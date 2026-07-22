function out = validateArchitecture(Architecture)
% Compiles the current Architecture.

% Copyright 2014 The MathWorks, Inc.

if isa(Architecture,'slTuner') || isa(Architecture,'slTunable')
    out = genss(Architecture);
else % MATLAB case, do nothing
    out = Architecture;
end
    