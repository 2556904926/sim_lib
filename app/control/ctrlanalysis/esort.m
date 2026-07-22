function [p,is] = esort(p)
%ESORT  Sort complex continuous eigenvalues in descending order.
%
%   S = ESORT(P)  sorts the complex eigenvalues in the vector P in
%   descending order by real part.  The unstable eigenvalues (in
%   the continuous-time sense) will appear first.
%
%   [S,NDX] = ESORT(P) also returns the vector NDX containing the 
%   indexes used in the sort.
%
%   See also DSORT, SORT.

%   Clay M. Thompson  7-12-90, AFP 6-1-94, PG 4-9-96, 6-11-97
%   Copyright 1986-2012 The MathWorks, Inc.
narginchk(1,1)
p = p(:);

% Pair up complex eigs with their conjugate when P is symmetric wrt real axis
[p,is] = cplxpairing(p);

% Sort by decreasing real parts
[rp,is2] = sort(-real(p));
p = p(is2);  is = is(is2);

% Find clusters with same real part and sort them by imaginary parts
ic = [0 ; find(diff(rp)) ; length(p)];
for ct=1:length(ic)-1
   ix = ic(ct)+1:ic(ct+1);
   if length(ix)>1
      [p(ix),is(ix)] = localSortByImagPart(p(ix),is(ix));
   end
end
   
%---- local functions ------------

function [p,ind] = localSortByImagPart(p,ind)
% Sorts p by increasing absolute imaginary parts
[~,is] = sort(abs(imag(p)));
p = p(is);  ind = ind(is);