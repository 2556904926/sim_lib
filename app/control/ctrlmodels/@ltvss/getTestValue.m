function [t0,p0] = getTestValue(sys)
%getTestValue  Access test values for validating data function.
%
%   T0 = getTestValue(SYS) returns the test time T0 used to validate the
%   data function.
%
%   [T0,P0] = getTestValue(SYS) returns the test time T0 and parameter
%   values P0 used to validate the data function of LPV models.
%
%   See also LTVSS, LPVSS.

%   Copyright 2022 The MathWorks, Inc.
t0 = sys.t0_;
p0 = [];
