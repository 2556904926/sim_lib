function [op,SINGULAR] = findop_(sys,tk,p,opspec)
% Compute operating condition.

%   Copyright 2023 The MathWorks, Inc.
DF = sys.DataFunction_;
if nargin(DF)>1
   if numel(p)~=nparam(sys)
      error(message('Control:analysis:findop9',nparam(sys)))
   end
   [A,B,C,D,E,dx0,x0,uw0,yz0,Delays] = DF(tk,p);
else
   [A,B,C,D,E,dx0,x0,uw0,yz0,Delays] = DF(tk);
end
nx = size(A,1);
if isempty(E)
   E = eye(nx);
end
[ny,nu] = size(D);
if isempty(Delays) || ~isfield(Delays,'Internal')
   nfd = 0;
else
   nfd = numel(Delays.Internal);
   nu = nu-nfd;  ny = ny-nfd;
end

% Validate spec
opspec = validate_x(opspec,nx,ny,nu,nfd);

% Compute offsets f,g
if isempty(dx0)
   f = zeros(nx,1);
else
   f = dx0;
end
if isempty(yz0)
   g = zeros(ny+nfd,1);
else
   g = yz0;
end
if ~isempty(x0)
   f = f-A*x0;   g = g-C*x0;
end
if ~isempty(uw0)
   f = f-B*uw0;   g = g-D*uw0;
end
   
% Adjust for dx=x[k+1]-x[k] in DT
DISCRETE = isdt(sys);
if DISCRETE
   A = A-E;
end

% Compute operating condition
[op,SINGULAR] = ltipack.numerics.findop(A,B,C,D,E,f,g,...
   opspec.x,opspec.u,opspec.w,opspec.dx,opspec.y,opspec.dw);

% Return OP.DX=x[k+1]
if DISCRETE
   op.dx = op.dx+op.x;
end

% Add time and parameter info
op.t = tk;
op.p = p;

