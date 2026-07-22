function [Dsys,INFO] = processLPVData(asys,sysNominal,Fixed)
% Validates, formats, and analyzes LPV data provided to ssInterpolant or 
% the LPV block. 
%
% This returns:
%   Dsys     ltipack.ssdata array containing the A,B,C,D,E data, the 
%            dx0,x0,u0,y0 offsets, and the delays.
%   INFO     struct containing info about
%              * fixed and varying entries of all interpolated quantities
%              * sampling grid structure, dimensionality, and grid vectors 
%                (for rectangular grids).
%              * interpolation and extrapolation methods.

%   Copyright 2023 The MathWorks, Inc.
ni = nargin;

% INFO.A fields:
%   * Nominal: first value
%   * nf: number of fixed entries
%   * nv: number of variable entries
%   * iv: indices of variable entries in A
%   * jv: indices of variable entries in vectorization of interpolated data
%         (see ltipack.interp.vectorizeData)
INFO = struct('A',[],'B',[],'C',[],'D',[],'E',[],'dx',[],'x',[],'u',[],'y',[],...
   'uDelay',[],'yDelay',[],'xDelay',[],'DELAY',[],'CT',isct(asys),...
   'pdim',[],'Grid',[],'GridVectors',[],'Interpolation',[],'Extrapolation',[]);

% Consistency checks
nsys = nmodels(asys);
if nsys<2
   error(message('Control:ltiobject:ssInterpolant2'))
end

% Analyze sampling grid
% Note: OFFSETS is [] or struct array with nsys elements
[asys,INFO.pdim,INFO.GridVectors] = localCheckGrid(asys);
INFO.Grid = asys.SamplingGrid;

% Separate fixed and varying entries of A,B,C,D,E and delays
Dsys = asys.Data_;
A0 = Dsys(1).a;  B0 = Dsys(1).b;  C0 = Dsys(1).c;  D0 = Dsys(1).d;  E0 = Dsys(1).e;
Tu0 = Dsys(1).Delay.Input;   maxTu = Tu0;
Ty0 = Dsys(1).Delay.Output;   maxTy = Ty0;
Tx0 = Dsys(1).Delay.Internal;   maxTx = Tx0;  minTx = min(Tx0);
EXPLICIT = isempty(E0);
nx = size(A0,1);
[nyz,nuw] = size(D0);
nfd = numel(Tx0);
nu = nuw-nfd;  ny = nyz-nfd;
VA = false(nx);  VE = false(size(E0));
VB = false(nx,nuw); VC = false(nyz,nx);  VD = false(nyz,nuw);
VU = false(nu,1);  VY = false(ny,1);  VX = false(nfd,1);
for ct=2:nsys
   Dct = Dsys(ct);
   Delay = Dsys(ct).Delay;
   A = Dct.a;   E = Dct.e;
   if size(A,1)~=nx
      error(message('Control:ltiobject:ssInterpolant3'))
   elseif numel(Delay.Internal)~=nfd
      error(message('Control:ltiobject:ssInterpolant17'))
   end
   if EXPLICIT && ~isempty(E)
      EXPLICIT = false;  E0 = eye(nx);  VE = false(nx);
   elseif ~EXPLICIT && isempty(E)
      E = eye(nx);
   end
   VA = VA | (A~=A0);
   VB = VB | (Dct.b~=B0);
   VC = VC | (Dct.c~=C0);
   VD = VD | (Dct.d~=D0);
   if ~EXPLICIT
      VE = VE | (E~=E0);
   end      
   VU = VU | (Delay.Input~=Tu0);
   VY = VY | (Delay.Output~=Ty0);
   VX = VX | (Delay.Internal~=Tx0);
   maxTu = max(maxTu ,Delay.Input);
   maxTy = max(maxTy,Delay.Output);
   maxTx = max(maxTx,Delay.Internal);
   minTx = min([minTx ; Delay.Internal]);
end
% Apply user-specified "fixed" entries (LPV block only)
if ni>2 && ~isempty(Fixed)
   if isempty(sysNominal)
      Dnom = Dsys(1);  % nominal model
   else
      Dnom = sysNominal.Data_;
   end
   fspec = localCheckFixed(Fixed.A,[nx nx],'LPVMask31');
   VA(fspec) = false;
   A0(fspec) = Dnom.a(fspec);
   fspec = localCheckFixed(Fixed.B,[nx nuw],'LPVMask32');
   VB(fspec) = false;
   B0(fspec) = Dnom.b(fspec);
   fspec = localCheckFixed(Fixed.C,[nyz nx],'LPVMask33');
   VC(fspec) = false;
   C0(fspec) = Dnom.c(fspec);
   fspec = localCheckFixed(Fixed.D,[nyz nuw],'LPVMask34');
   VD(fspec) = false;
   D0(fspec) = Dnom.d(fspec);
   fspec = localCheckFixed(Fixed.uDelay,[nu,1],'LPVMask35');
   VU(fspec) = false;
   Tu0(fspec) = Dnom.Delay.Input(fspec);
   fspec = localCheckFixed(Fixed.yDelay,[ny,1],'LPVMask36');
   VY(fspec) = false;
   Ty0(fspec) = Dnom.Delay.Output(fspec);
   fspec = localCheckFixed(Fixed.xDelay,[nfd 1],'LPVMask37');
   VX(fspec) = false;
   Tx0(fspec) = Dnom.Delay.Internal(fspec);
end
% Log nominal values and varying/fixed entries
iv = find(VA);  nv = numel(iv);
INFO.A = struct('Nominal',A0,'nf',numel(A0)-nv,'nv',nv,'iv',iv);
iv = find(VB);  nv = numel(iv);
INFO.B = struct('Nominal',B0,'nf',numel(B0)-nv,'nv',nv,'iv',iv);
iv = find(VC);  nv = numel(iv);
INFO.C = struct('Nominal',C0,'nf',numel(C0)-nv,'nv',nv,'iv',iv);
iv = find(VD);  nv = numel(iv);
INFO.D = struct('Nominal',D0,'nf',numel(D0)-nv,'nv',nv,'iv',iv);
iv = find(VE);  nv = numel(iv);
INFO.E = struct('Nominal',E0,'nf',numel(E0)-nv,'nv',nv,'iv',iv);
iv = find(VU);  nv = numel(iv);
Tu0(Tu0==0 & ~VU) = NaN;
INFO.uDelay = struct('Nominal',Tu0,'nf',nu-nv,'nv',nv,'iv',iv,'MaxDelay',maxTu);
iv = find(VY);  nv = numel(iv);
Ty0(Ty0==0 & ~VY) = NaN;
INFO.yDelay = struct('Nominal',Ty0,'nf',ny-nv,'nv',nv,'iv',iv,'MaxDelay',maxTy);
iv = find(VX);  nv = numel(iv);
INFO.xDelay = struct('Nominal',Tx0,'nf',nfd-nv,'nv',nv,'iv',iv,'MinDelay',minTx,'MaxDelay',maxTx);
INFO.DELAY = (any(maxTu) || any(maxTy) || any(maxTx));

% Separate fixed and varying entries of dx,x,u,y
% dx
dx0s = cat(2,Dsys.dx0);
if any(dx0s,'all')
   dx0 = dx0s(:,1);
   iv = find(any(dx0s~=dx0,2));  nv = numel(iv);
   INFO.dx = struct('Nominal',dx0,'nf',nx-nv,'nv',nv,'iv',iv);
else
   % Ensure data function returns dx0=[]
   INFO.dx = struct('Nominal',[],'nf',0,'nv',0,'iv',zeros(0,1));
end
% x
x0s = cat(2,Dsys.x0);
if any(x0s,'all')
   x0 = x0s(:,1);
   iv = find(any(x0s~=x0,2));  nv = numel(iv);
   INFO.x = struct('Nominal',x0,'nf',nx-nv,'nv',nv,'iv',iv);
else
   INFO.x = struct('Nominal',[],'nf',0,'nv',0,'iv',zeros(0,1));
end
% u
u0s = cat(2,Dsys.u0);
if any(u0s,'all')
   u0 = u0s(:,1);
   iv = find(any(u0s~=u0,2));  nv = numel(iv);
   INFO.u = struct('Nominal',u0,'nf',nuw-nv,'nv',nv,'iv',iv);
else
   INFO.u = struct('Nominal',[],'nf',0,'nv',0,'iv',zeros(0,1));
end
% y
y0s = cat(2,Dsys.y0);
if any(y0s,'all')
   y0 = y0s(:,1);
   iv = find(any(y0s~=y0,2));  nv = numel(iv);
   INFO.y = struct('Nominal',y0,'nf',nyz-nv,'nv',nv,'iv',iv);
else
   INFO.y = struct('Nominal',[],'nf',0,'nv',0,'iv',zeros(0,1));
end


%---------------------------------
function [asys,pdim,gvec] = localCheckGrid(asys)
% Check grid and delineate structure
% NDIM = number of varying parameters
% GDIM = number of grid dimensions (always 1 for scattered data)
SG = asys.SamplingGrid;
if isequal(SG,struct)
   error(message('Control:ltiobject:ssInterpolant8'))
elseif ~all(structfun(@isreal,SG))
   error(message('Control:ltiobject:ssInterpolant14'))
end
% Eliminate constant variables (e.g., time when no explicit time dependence)
VARYING = structfun(@(x) any(diff(x(:))),SG);
pdim = sum(VARYING);
if pdim==0
   error(message('Control:ltiobject:ssInterpolant9'))
end
F = fieldnames(SG);
SG = rmfield(SG,F(~VARYING));
asys.SamplingGrid = SG;
% Analyze grid structure
GridInfo = ltipack.SamplingGrid.getGridStructure(SG);
if GridInfo.Duplicate
   error(message('Control:ltiobject:ssInterpolant10'))
end
gsize = GridInfo.GridSize;
asys = asys(:,:,GridInfo.SamplePerm);
% Turn into rectangular or scattered problem
gdim = nnz(gsize>1);
if gdim==pdim
   % Rectangular grid
   gvec = cell(1,pdim);
   for ct=1:pdim
      gvec{ct} = GridInfo.GridVectors{ct}{2};
   end
else
   % Scattered data points
   gvec = {};
end
asys = reshape(asys,gsize);

%---------------------
function fspec = localCheckFixed(fspec,varSize,promptID)
% Note: Specific to LPV block
if isempty(fspec)
   fspec = [];
else
   n = prod(varSize);
   if ~isequal(fspec,1) && all(fspec==0 | fspec==1,'all')
      % Support [0 1 1 0] as alias [false true true false] but do not replace
      % the index fspec=1 by fspec=true (which fixes ALL entries)
      fspec = logical(fspec);
   end
   promptStr = getString(message(['Control:simulink:',promptID]));
   if islogical(fspec)
      if isscalar(fspec)
         fspec = repmat(fspec,[n 1]);
      elseif numel(fspec)~=n
         if all(varSize>1)
            error(message('Control:simulink:LPVCheck21b',promptStr,mat2str(varSize),n))
         else
            error(message('Control:simulink:LPVCheck21a',promptStr,n,n))
         end
      end
   elseif isnumeric(fspec)
      if ~(isvector(fspec) && isreal(fspec) && all(fspec==round(fspec) & fspec>=1 & fspec<=n))
         if all(varSize>1)
            error(message('Control:simulink:LPVCheck21b',promptStr,mat2str(varSize),n))
         else
            error(message('Control:simulink:LPVCheck21a',promptStr,n,n))
         end
      end
   else
      error(message('Control:simulink:LPVCheck7'))
   end
   fspec = fspec(:);
end
