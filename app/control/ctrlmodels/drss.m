function sys = drss(varargin)
%DRSS  Generate random discrete-time state-space models.
%
%   SYS = DRSS(N) generates an Nth-order SISO state-space model SYS.
%   The poles of SYS are random and stable with the possible exception
%   of poles at z=1 (integrators).
%
%   SYS = DRSS(N,P) generates a single-input Nth-order model with 
%   P outputs.
%
%   SYS = DRSS(N,P,M) generates an Nth-order model with P outputs
%   and M inputs.
%
%   SYS = DRSS(N,P,M,S1,...,Sk) generates a S1-by-...-by-Sk array of
%   state-space models with N states, P outputs, and M inputs.
%
%   SYS = DRSS(...,"legacy") recreates the model generated prior to
%   R2023a. The result may vary across platforms.
%
%   The sample time Ts is left unspecified (set to -1). To generate 
%   random discrete TF or ZPK models, convert the result SYS to the 
%   appropriate model type with the functions TF or ZPK.
%
%   See also RSS, TF, ZPK.

%   Copyright 1986-2022 The MathWorks, Inc.
ni = nargin;
if ni>0 && ~isnumeric(varargin{ni})
   % Legacy version uses ORTH whose result can vary with MKL implementation
   LEGACY = true;
   ni = ni-1;  varargin = varargin(:,1:ni);
else
   % Introduced in R2023a, this version produces consistent results across 
   % platforms and MKL versions
   LEGACY = false;
end

% Sizing
if ni==0
   n=max([1,round(abs(10*randn(1,1)))]);
   p=max([1,round(4*randn(1,1))]);
   m=max([1,round(4*randn(1,1))]);
else
   n = varargin{1};
   if ni>1
      p = varargin{2};
   else
      p = 1;
   end
   if ni>2
      m = varargin{3};
   else
      m = 1;
   end
end
arraydims= [varargin{:,4:ni}];

% Check all inputs are positive integers
sizes = [m n p arraydims];
if ~(allfinite(sizes) && isequal(sizes,round(sizes)) && all(sizes>=0)) 
   error(message('Control:ltiobject:rss1','drss'))
end

% Prob of an integrator is 0.10 for the first and 0.01 for all others
nint = (rand(1,1)<0.10)+sum(rand(n-1,1)<0.01);

% Generate random A matrix
a = zeros([n n arraydims]);
for k=1:prod(arraydims)
   % Prob of repeated roots is 0.05
   nrepeated = floor(sum(rand(n-nint,1)<0.05)/2);
   
   % Prob of complex roots is 0.5
   ncomplex = floor(sum(rand(n-nint-2*nrepeated,1)<0.5)/2);
   nreal = n-nint-2*nrepeated-2*ncomplex;
   
   % Determine random poles
   rep = 2*rand(nrepeated,1)-1;
   mag = rand(ncomplex,1);
   cplx = mag.*exp(complex(0,pi*rand(ncomplex,1)));
   re = real(cplx);
   im = imag(cplx);
   
   % Generate random state space model
   ak = zeros(n);
   for i=1:ncomplex
      ndx = [2*i-1,2*i];
      ak(ndx,ndx) = [re(i),im(i);-im(i),re(i)];
   end
   ndx = 2*ncomplex+1:n;
   if ~isempty(ndx)
      ak(ndx,ndx) = diag([ones(nint,1);rep;rep;2*rand(nreal,1)-1]);
   end
   if LEGACY
      T = orth(rand(n));
   else
      T = randn(n);
   end
   a(:,:,k) = T\ak*T;
end

b = randn([n,m,arraydims]);
c = randn([p,n,arraydims]);
d = randn([p,m,arraydims]);
bnz = (rand(size(b))<0.75);      % mask for nonzero entries in B
zerob = all(all(~bnz,1),2);    % resulting zero B matrices
b = b .* (bnz+repmat(zerob,[n m]));
cnz = (rand(size(c))<0.75);
zeroc = all(all(~cnz,1),2);
c = c .* (cnz+repmat(zeroc,[p n]));
d = d .* (rand(size(d))<0.5);

sys = ss(a,b,c,d,-1);

