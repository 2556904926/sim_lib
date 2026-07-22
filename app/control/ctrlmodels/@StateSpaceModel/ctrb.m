function co = ctrb(sys)
%CTRB  Compute the controllability matrix.
%
%   CO = CTRB(A,B) returns the controllability matrix [B AB A^2B ...].
%
%   CO = CTRB(SYS) returns the controllability matrix of the
%   state-space model SYS with realization (A,B,C,D).  This is
%   equivalent to CTRB(sys.a,sys.b).
%
%   For ND arrays of state-space models SYS, CO is an array with N+2
%   dimensions where CO(:,:,j1,...,jN) contains the controllability
%   matrix of the state-space model SYS(:,:,j1,...,jN).
%
%   See also CTRBF, SS.

%   Copyright 1986-2011 The MathWorks, Inc.
if numel(size(sys,'order'))>1
   ctrlMsgUtils.error('Control:general:RequiresUniformNumberOfStates','ctrb')
end

% Extract data
try
   [a,b] = ssdata(sys);
catch %#ok<CTCH>
   ctrlMsgUtils.error('Control:general:NotSupportedImproperSys','ctrb')
end

% Compute controllability matrix for each model
nx = size(a,1);
bs = size(b);
co = zeros([nx bs(2)*nx bs(3:end)]);
for k=1:prod(bs(3:end)),
   co(:,:,k) = ctrb(a(:,:,k),b(:,:,k));
end