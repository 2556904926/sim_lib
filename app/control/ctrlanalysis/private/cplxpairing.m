function [p,is]=cplxpairing(p)
% Sorts P so that complex eigenvalues come in pairs (a+j*b,a-j*b) 
% when P is symmetric with respect to the real axis.

%   Copyright 2018 The MathWorks, Inc.
n = numel(p);
b = imag(p);
ir = find(b==0);
icp = find(b>0);
icn = find(b<0);
[p1,is1] = sort(p(icp));
[p2,is2] = sort(conj(p(icn)));
if isequal(p1,p2)
   % P symmetric wrt real axis (see ISCONJUGATE)
   m = numel(p1);  % number complex pairs
   p = [zeros(2*m,1) ; p(ir,:)];
   is = [zeros(2*m,1) ; ir];
   p(1:2:2*m) = p1;
   p(2:2:2*m) = conj(p1);
   is(1:2:2*m) = icp(is1);
   is(2:2:2*m) = icn(is2);
else
   is = (1:n).';
end