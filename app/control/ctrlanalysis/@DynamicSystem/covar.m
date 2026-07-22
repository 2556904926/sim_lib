function [p,q] = covar(sys,w)
%COVAR  Covariance of LTI model response to white noise inputs.
%
%   P = COVAR(SYS,W) computes the output response covariance P = E[yy'] 
%   when the LTI model SYS is driven by Gaussian white noise inputs w. 
%   The noise intensity W is defined by
%
%      E[w(t)w(tau)'] = W delta(t-tau)  (delta(t) = Dirac delta)
%
%   in continuous time, and by
%
%      E[w(k)w(n)'] = W delta(k,n)  (delta(k,n) = Kronecker delta)
%
%   in discrete time.
%
%   [P,Q] = COVAR(SYS,W) also returns the state covariance Q = E[xx'] when 
%   SYS is a state-space model.
%
%   If SYS is an array of LTI models with size [NY NU S1 ... Sp], the array 
%   P has size [NY NY S1 ... Sp] and
%      P(:,:,k1,...,kp) = COVAR(SYS(:,:,k1,...,kp)) .
%
%   Note: Unstable systems have infinite state and output covariances, and
%   continuous-time systems with nonzero feedthrough have infinite output 
%   covariance.
%
%   See also LYAPCHOL, DLYAPCHOL, LTI.

%   Authors: Clay M. Thompson, Wes Wang, P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(2,2)
no = nargout;
if no>1 && ~isa(sys,'StateSpaceModel')
   % Set Q=[] if SYS is not state-space
   no = 1;
end

% Get dimensions
sizes = size(sys);
Nu = sizes(2);

% Check W input
sw = size(w);
if length(sw)>2 || ~isnumeric(w)
   error(message('Control:analysis:covar1'))
elseif all(sw==1)
   % Scalar expansion
   if w>=0
      rw = diag(sqrt(w) * ones(Nu,1));
      w = diag(w * ones(Nu,1));
   else
      error(message('Control:analysis:covar1'))
   end
else
   % Matrix case
   if any(sw~=Nu),
      error(message('Control:analysis:covar1'))
   end
   % Compute Cholesky factorization of W to check nonnegativity
   [rw,fail] = chol(w + eps * norm(w,1) * eye(Nu));
   if fail,
      error(message('Control:analysis:covar1'))
   end
end

% Convert to numerical state space
try
   sys = ss(sys);
catch%#ok<CTCH>
   error(message('Control:general:NotSupportedModelsofClass','covar',class(sys)))
end

% Compute covariance data
try
   if no>1
      % Check state dimension is uniform
      Nx = order(sys);
      if numel(Nx)>1 && any(Nx(:)~=Nx(1))
         error(message('Control:analysis:covar3'))
      end
      [p,q] = covar_(sys,w,rw);
   else
      p = covar_(sys,w,rw);
      q = [];
   end
catch E
   ltipack.throw(E,'command','covar',class(sys))
end

% Warn if any covariance is infinite
if ~(allfinite(p) && allfinite(q))
   if isct(sys)
      warning(message('Control:analysis:CovarInfiniteCT'))
   else
      warning(message('Control:analysis:CovarInfiniteDT'))
   end
end
