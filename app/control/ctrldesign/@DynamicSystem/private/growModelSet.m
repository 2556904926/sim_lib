function [SYSDATA_S,SPECDATA_S,tInfo_S] = growModelSet(...
   SYSDATA_S,SPECDATA_S,tInfo_S,SYSDATA,SPECDATA,tInfo,DELTA)
% Grows model set for multi-model synthesis by adding model corresponding
% to worst-case DELTA found by analysis.

%   Copyright 2010-2015 The MathWorks, Inc.
nsys = size(SYSDATA_S,1);

% Add new models
N = size(DELTA,2);
SYSDATA_S = [SYSDATA_S ; localFoldDelta(SYSDATA,tInfo,DELTA(:,N),N)];

% Replicate uncertain portion of SPECDATA
if nsys>0
   nspec = numel(SPECDATA_S);
   SD = SPECDATA([SPECDATA.Config] & [SPECDATA.Uncertain],:);
   for ct=1:numel(SD)
      SD(ct).Model = SD(ct).Model + nsys;  % point to added model
      SD(ct).Uncertain = false;
   end
   SPECDATA_S = [SPECDATA_S ; SD];
   tInfo_S.SpecEvalOrder = [tInfo_S.SpecEvalOrder , nspec+1:nspec+numel(SD)];
   
   % Sort by tuning goal index (required to derive fSoft/gHard value for
   % each tuning goal
   [~,is] = sort([SPECDATA_S.Goal]);
   SPECDATA_S = SPECDATA_S(is);
else
   tInfo_S = tInfo;
   tInfo_S.UncertainBlocks = [];
   SPECDATA_S = SPECDATA;
end

%------------------------------------------------------------------------

function SYSDATA = localFoldDelta(SYSDATA,tInfo,delta,iDELTA)
% Fix uncertainty value and derive corresponding model with only tunable
% blocks
UB = tInfo.UncertainBlocks;
nblk = numel(UB);
for ct=1:numel(SYSDATA)
   SD = SYSDATA(ct);
   if SD.Active
      if SD.nwU>0
         % Build DELTA value
         nr = [SD.UncertainBlocks.NRepeat];
         nwB = SD.nwB;  nzB = SD.nzB;
         if SD.nxU>0
            % REVISIT
         else
            nU = SD.nwU;   % number of DELTA channels
            DU = zeros(nU,1);
            iu = 0;
            for k=1:nblk
               DU(iu+1:iu+nr(k)) = delta(k);
               iu = iu+nr(k);
            end
            DU = diag(DU);
            % Close LFT around DELTA
            A = SD.A;  B = SD.B;  C = SD.C;  D = SD.D;
            nx = size(A,1);
            [rs,cs] = size(D);
            nz = rs-nU-nzB;
            nw = cs-nU-nwB;
            ir1 = [1:nz nz+nU+1:nz+nU+nzB];
            ic1 = [1:nw nw+nU+1:nw+nU+nwB];
            auxB = [zeros(nx+rs-nU,nU) , [B(:,nw+1:nw+nU) ; D(ir1,nw+1:nw+nU)]];  % [0 B2;0 D12]
            auxC = [[C(nz+1:nz+nU,:) , D(nz+1:nz+nU,ic1)] ; zeros(nU,nx+cs-nU)];  % [C2,D21;0 0]
            D22 = D(nz+1:nz+nU,nw+1:nw+nU);
            S = auxB * ([eye(nU) -D22;-DU eye(nU)]\auxC);
            SD.A = A + S(1:nx,1:nx);
            SD.B = B(:,ic1) + S(1:nx,nx+1:end);
            SD.C = C(ir1,:) + S(nx+1:end,1:nx);
            SD.D = D(ir1,ic1) + S(nx+1:end,nx+1:end);
         end
      end
      SD.iDelta = iDELTA;
      SYSDATA(ct) = SD;
   end
end
