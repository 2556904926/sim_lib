function varargout = getTunedValue(varargin)
%getTunedValue  Get the current value of tuned variable.
%
%   getTunedValue is equivalent to getBlockValue for generalized models.
%
%   See also getBlockValue.

%   Copyright 1986-2015 The MathWorks, Inc.
try
   [varargout{1:max(1,nargout)}] = getBlockValue(varargin{:});
catch ME
   throw(ME)
end