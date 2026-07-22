function M = setTunedValue(M,varargin)
%setTunedValue  Modify the current value of tuned variable.
%
%   setTunedValue is equivalent to setBlockValue for generalized models.
%
%   See also setBlockValue.

%   Copyright 1986-2015 The MathWorks, Inc.
try
   M = setBlockValue(M,varargin{:});
catch ME
   throw(ME)
end