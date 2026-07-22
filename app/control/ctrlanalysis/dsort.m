function [p,is]=dsort(p)
%DSORT  Sort complex discrete eigenvalues in descending order.
%
%   S = DSORT(P) sorts the complex eigenvalues in the vector P in 
%   descending order by magnitude.  The unstable eigenvalues (in
%   the discrete-time sense) will appear first.
%
%   [S,NDX] = DSORT(P) also returns the vector NDX containing the 
%   indexes used in the sort.
%
%   See also ESORT, SORT.

%   Clay M. Thompson  7-23-90, AFP 6-1-94, PG 6-21-96,6-11-97
%   Copyright 1986-2018 The MathWorks, Inc.
narginchk(1,1)
p = p(:);

% Pair up complex eigs with their conjugate when P is symmetric wrt real axis
[p,is] = cplxpairing(p);

% Sort by decreasing magnitude
[pabs,is2] = sort(-abs(p));
p = p(is2);  is = is(is2);

% Find clusters with same magnitude and sort them by real parts
ic = [0 ; find(diff(pabs)) ; length(p)];
for ct=1:length(ic)-1
   ix = ic(ct)+1:ic(ct+1);
   if length(ix)>1
      [p(ix),is(ix)] = localSortByRealPart(p(ix),is(ix));
   end
end
   
%---- local functions ------------

function [p,ind] = localSortByRealPart(p,ind)
% Sorts p by increasing real parts
[~,is] = sort(real(p));
p = p(is);  ind = ind(is);