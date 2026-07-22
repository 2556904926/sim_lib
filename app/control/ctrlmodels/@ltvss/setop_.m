function op = setop_(sys,tk,p,opspec)
% Sets operating condition.
% Version of FINDOP_ that records x,u,y,w values and skips computation of 
% dx and dw (always set to zero).

%   Copyright 2024 The MathWorks, Inc.
[ny,nu] = size(sys);
nx = sys.Nx_;
nfd = sys.Nfd_;
opspec = validate_x(opspec,nx,ny,nu,nfd);
op = ltipack.OperatingPoint(opspec.x,opspec.u,opspec.w);
op.dx = zeros(nx,1);
op.y = opspec.y;
op.dw = zeros(nfd,1);
% Residuals just reflect lack of any calculation
op.rx = ones(nx,1);  
op.ry = ones(ny,1);  
op.rw = ones(nfd,1);  
% Add time and parameter info
op.t = tk;
op.p = p;
