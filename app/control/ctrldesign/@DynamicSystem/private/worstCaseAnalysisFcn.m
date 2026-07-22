function LOG = worstCaseAnalysisFcn(LOG,SYSDATA,SPECDATA,tInfo,wcGuess,Options)
% Compute worst-case DELTA.

%   Copyright 2010-2015 The MathWorks, Inc.
RELTOL = Options.SoftTol;
OPTS = struct(...
   'MinDecay',Options.MinDecay,...
   'MaxRadius',Options.MaxRadius,...
   'wStab',1,...
   'TolHinf',min(1e-6,1e-3*RELTOL),...
   'Rmax',TuningGoal.ConicSector.getRmax(),... % upper limit for R-index
   'Target',-Inf, ...   %  target for tr_solver
   'MaxIter',Options.MaxIter, ...
   'RELTOL',RELTOL);

% Fold tuned blocks and evaluate scalings
SYSDATA = localFoldK(SYSDATA,tInfo,LOG.X);
tInfo = NSOptUtil.evalScaling(tInfo,LOG.X);
tInfo.TunedBlocks = [];

% Robustness analysis
% Initialize with synthesis values
wcFstab = LOG.Fstab;  wcF = LOG.F;  wcG = LOG.G; 
% Stability
[fstab,wcDELTA] = wc_stab(SYSDATA,SPECDATA,tInfo,wcGuess,OPTS);
wcFstab = max(wcFstab,fstab);
if wcFstab>0
   % Not robustly stable
   wcF = Inf;   wcG = Inf;
elseif ~Options.Hidden.StabilizeOnly
   Soft = [SPECDATA.Soft];
   if any(~Soft)
      % Feasibility
      [g,wcDELTA] = wc_perf(SYSDATA,SPECDATA(~Soft,:),tInfo,wcGuess,OPTS);
      wcG = max(wcG,g);
   end
   if wcG>1+RELTOL
      % Not robustly feasible
      wcF = Inf;
   elseif any(Soft)
      [f,wcDELTA] = wc_perf(SYSDATA,SPECDATA(Soft,:),tInfo,wcGuess,OPTS);
      wcF = max(wcF,f);
   end
end

% Store WC values
LOG.wcFstab = wcFstab; 
LOG.wcDecay = Options.MinDecay-wcFstab;
LOG.wcG = wcG;
LOG.wcF = wcF;

% Add wcDELTA to perturbation set if not already there
DELTA = LOG.xDELTA;
nDELTA = size(DELTA,2);
if all(any(DELTA-wcDELTA(:,ones(1,nDELTA)),1))
   LOG.xDELTA = [DELTA , wcDELTA];
   LOG.iWC = [nDELTA+1 , LOG.iWC];
end

%-------------------
function SYSDATA = localFoldK(SYSDATA,tInfo,x)
% Fix tuned values and derive corresponding model with only uncertain
% blocks
p = tInfo.p0;
p(tInfo.iFree) = x;
Blocks = tInfo.TunedBlocks;

for ct=1:numel(SYSDATA)
   SD = SYSDATA(ct);
   if SD.Active
      nxB = SD.nxB;  % total number of block states
      nwB = SD.nwB;  % total number of block inputs
      nzB = SD.nzB;  % total number of block outputs
      BlockInfo = SD.TunedBlocks;
      
      % Form Ac(x),Bc(x),...
      Ac = zeros(nxB);
      Bc = zeros(nxB,nzB);
      Cc = zeros(nwB,nxB);
      Dc = zeros(nwB,nzB);
      ix = 0; iu = 0; iy = 0; ip = 0;
      for j=1:numel(Blocks)
         blk = Blocks(j);
         npj = blk.np;
         nr = BlockInfo(j).NRepeat;  % number of occurrences
         if nr>0
            % Evaluate block at pj = portion of P belonging to block j
            [acj,bcj,ccj,dcj] = p2ss(blk.Data,p(ip+1:ip+npj));
            nxj = size(acj,1);
            [nyj,nuj] = size(dcj);
            Offsets = BlockInfo(j).Offset;
            for k=1:nr
               Ac(ix+1:ix+nxj,ix+1:ix+nxj) = acj;
               Bc(ix+1:ix+nxj,iu+1:iu+nuj) = bcj;
               Cc(iy+1:iy+nyj,ix+1:ix+nxj) = ccj;
               Dc(iy+1:iy+nyj,iu+1:iu+nuj) = dcj - Offsets(:,:,k);
               ix = ix + nxj;   iu = iu + nuj;  iy = iy + nyj;
            end
         end
         ip = ip + npj;
      end
      
      % Compute closed-loop matrices
      A = SD.A;  B = SD.B;  C = SD.C;  D = SD.D;
      nx = size(A,1);
      ny = size(D,1)-nzB;
      nu = size(D,2)-nwB;
      auxB = [zeros(nx,nzB) B(:,nu+1:nu+nwB); Bc zeros(nxB,nwB) ; ...
         zeros(ny,nzB) D(1:ny,nu+1:nu+nwB)];
      auxC = [C(ny+1:ny+nzB,:) zeros(nzB,nxB) D(ny+1:ny+nzB,1:nu); ...
         zeros(nwB,nx) Cc zeros(nwB,nu)];
      D22 = D(ny+1:ny+nzB,nu+1:nu+nwB);
      if norm(D22,1)+norm(Dc,1)>0
         auxD = [eye(nzB) -D22;-Dc eye(nwB)];
         auxDC = auxD\auxC;
      else
         auxDC = auxC;
      end
      S = auxB * auxDC;
      nxcl = nx + nxB;
      SD.A = [A zeros(nx,nxB);zeros(nxB,nx) Ac] + S(1:nxcl,1:nxcl);
      SD.B = [B(:,1:nu) ; zeros(nxB,nu)] + S(1:nxcl,nxcl+1:nxcl+nu);
      SD.C = [C(1:ny,:) , zeros(ny,nxB)] + S(nxcl+1:nxcl+ny,1:nxcl);
      SD.D = D(1:ny,1:nu) + S(nxcl+1:nxcl+ny,nxcl+1:nxcl+nu);
      SYSDATA(ct) = SD;
   end
end
