function sys = xelim(sys,elim,method)
%XELIM  Model simplification by state elimination.
%
%   RSYS = XELIM(SYS,ELIM) simplifies the state-space model SYS by 
%   discarding the states specified in the vector ELIM. The full state 
%   vector X is partitioned as X = [X1;X2] where Xr=X1 is the reduced
%   state vector and X2 is discarded.
%
%   ELIM can be a vector of indices or a logical vector commensurate
%   with X where TRUE values mark states to be discarded. If SYS has 
%   been balanced with BALREAL and the vector G of Hankel singular 
%   values has small entries, you can use XELIM to eliminate the 
%   corresponding states:
%      [sys,g] = balreal(sys)   % compute balanced realization
%      elim = (g<1e-8)          % small entries of g -> negligible states
%      rsys = xelim(sys,elim)   % remove negligible states
%
%   RSYS = XELIM(SYS,ELIM,METHOD) also specifies the state elimination
%   method. Available choices for METHOD include:
%      'matchdc'    Treats X2 as infinitely fast to enforce matching 
%                   DC gains (default)
%      'truncate'   Simply deletes X2.
%   The 'truncate' option tends to produce a better approximation in the
%   frequency domain, but the DC gains are not guaranteed to match.
%
%   Note: 
%     1) For faster and more accurate results, use REDUCESPEC for model 
%        reduction workflows.
%     2) With 'matchdc', XELIM may scale X1 and discard only part of X2
%        when full elimination is ill conditioned. Use FINDOP to compute
%        matching initial conditions for the reduced model.
%
%   See also BALREAL, REDUCESPEC, DYNAMICSYSTEM/FINDOP, SS.

%   Author(s): J.N. Little, P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc.
ni = nargin;
if ni<2
   error(message('Control:general:TwoOrMoreInputsRequired','xelim','xelim'))
elseif numsys(sys)~=1
   error(message('Control:general:RequiresSingleModel','xelim'))
elseif ni==3 && any(strncmpi(method,{'m','d','t'},1))
   % Make sure to trap old keywords 'mdc' and 'del'
   if strncmpi(method,'m',1)
      method = 'MatchDC';
   else
      method = 'Truncate';
   end
else
   method = 'MatchDC';  % default
end

% Get order and check ELIM
ns = order(sys);
if isa(elim,'logical')
   elim = find(elim);
end
elim = elim(:);
if any(diff(sort(elim))==0)
   error(message('Control:general:IndexRepeated','xelim(SYS,ELIM)','ELIM'))
elseif any(elim<0) || any(elim>ns)
   error(message('Control:general:IndexOutOfRange','xelim(SYS,ELIM)','ELIM'))
end

% Perform separation
try
   sys = xelim_(sys,elim,method);
catch E
   ltipack.throw(E,'command','xelim',class(sys))
end

% Clear notes, userdata, etc
sys.Name = '';  sys.Notes = {};  sys.UserData = [];
