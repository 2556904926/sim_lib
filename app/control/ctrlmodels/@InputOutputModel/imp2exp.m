function [M,SingularFlag] = imp2exp(M,yidx,uidx,varargin)
%IMP2EXP  Converts implicit linear relationship to explicit I/O model.
%
%   B = IMP2EXP(A,YIDX,UIDX) transforms a linear constraint on variables
%   Y and U of the form
%      A(:,[YIDX UIDX]) * [Y;U] = 0
%   into an explicit input/output relationship
%      Y = B*U.
%   The index vectors YIDX and UIDX specify how to partition the input
%   channels of A into Y and U signals. The model A can be any static or
%   dynamic input/output model (see InputOutputModel).
%
%   If [YIDX,UIDX] does not include all inputs of A, the missing Y channels
%   are dropped from B. This amounts to keeping only a subset B(I,:) of the 
%   outputs/rows of B and does not affect how the explicit model is computed.
%
%   For SS/GENSS/USS models, B is given in implicit (DAE) form by default.
%   When A(:,YIDX) has a proper inverse, you can use
%      B = IMP2EXP(A,YIDX,UIDX,'min')
%   to eliminate the extra states and obtain a model B with as many states
%   as A. This option is ignored for sparse models because it typically
%   destroys sparsity.
%
%   See also INV, INPUTOUTPUTMODEL.

%   Copyright 1986-2020 The MathWorks, Inc.
narginchk(3,4)
[nOut,nIn] = iosize(M);

% Validate YIDX, UIDX
if ~(localIsValidIndex(yidx) && localIsValidIndex(uidx))
   error(message('Control:transformation:imp2exp1'))
elseif max(yidx)>nIn || max(uidx)>nIn
   error(message('Control:transformation:imp2exp4'))
end
[yidx,yidx0] = localRemoveDuplicates(yidx);
nU = numel(uidx);
nY = numel(yidx);
uidx = reshape(uidx,[1 nU]);
yidx = reshape(yidx,[1 nY]);
iYU = unique([yidx,uidx]);
if numel(iYU)<nU+nY
   error(message('Control:transformation:imp2exp2'))
elseif nIn~=nOut+nU
   error(message('Control:transformation:imp2exp3',nIn-nOut))
end

% Compute the complement ZIDX of UIDX in the inputs of G
aux = 1:nIn;  aux(iYU) = [];
zidx = [yidx , aux];  % nOut entries

% Derive explicit model mapping the inputs UIDX to the outputs ZIDX
try
   [M,SingularFlag] = imp2exp_(M,zidx,uidx,varargin{:});
   if nargout<2 && SingularFlag
      warning(message('Control:transformation:imp2exp8'))
   end
catch ME
   ltipack.throw(ME,'command','imp2exp',class(M))
end
M = imp2expMetaData(M,zidx,uidx);
M.IOSize_ = [nOut , nU];

% Keep only first P inputs if YIDX is a subset of ZIDX
if ~isequal(zidx,yidx0)
   [~,isel] = ismember(yidx0,zidx);
   M = M(isel,:);
end

%----------------------------------------------
function pf = localIsValidIndex(idx)
% Validates index vector
pf = ~isempty(idx) && isnumeric(idx) && isreal(idx) && ...
   all(isfinite(idx) & rem(idx,1)==0) && min(idx)>0;

function [idx,idx0] = localRemoveDuplicates(idx0)
% Removes duplicate entries while preserving order
[~,iu] = unique(idx0,'first');
idx = idx0(sort(iu));
