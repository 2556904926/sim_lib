function ob = obsv(sys)
%OBSV  Compute the observability matrix.
%
%   OB = OBSV(A,C) returns the observability matrix [C; CA; CA^2 ...]
%
%   CO = OBSV(SYS) returns the observability matrix of the
%   state-space model SYS with realization (A,B,C,D).  This is
%   equivalent to OBSV(sys.a,sys.c).
%
%   For ND arrays of state-space models SYS, OB is an array with N+2
%   dimensions where OB(:,:,j1,...,jN) contains the observability
%   matrix of the state-space model SYS(:,:,j1,...,jN).
%
%   See also OBSVF, SS.

%   Copyright 1986-2011 The MathWorks, Inc.
if numel(size(sys,'order'))>1
   ctrlMsgUtils.error('Control:general:RequiresUniformNumberOfStates','obsv')
end

% Extract data
try
   [a,~,c] = ssdata(sys);
catch %#ok<CTCH>
   ctrlMsgUtils.error('Control:general:NotSupportedImproperSys','obsv')
end

% Compute controllability matrix for each model
nx = size(a,1);
cs = size(c);
ob = zeros([cs(1)*nx nx cs(3:end)]);
for k=1:prod(cs(3:end)),
   ob(:,:,k) = obsv(a(:,:,k),c(:,:,k));
end