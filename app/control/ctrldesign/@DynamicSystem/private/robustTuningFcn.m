function [LOG,BestDesign] = robustTuningFcn(LOG,BestDesign,...
   SYSDATA,SPECDATA,tInfo,SYSDATA_S,SPECDATA_S,tInfo_S,Options)
% Robustify single design.
% BestDesign = [wcFstab,wcG,wcF] for best robust design so far

%   Copyright 2010-2015 The MathWorks, Inc.
RELTOL = Options.SoftTol;
StopFcn = Options.Hidden.StopFcn;
StabilizeOnly = Options.Hidden.StabilizeOnly;
nUB = numel(tInfo.UncertainBlocks);
Ts = tInfo.Ts;

% Slow progress tracking
hPtr = 1;  hWindow = 3;
fHist = Inf(hWindow,1);
gHist = Inf(hWindow,1);
sHist = Inf(hWindow,1);

% Initialize worst-case analysis
SPECDATA_U = SPECDATA([SPECDATA.Uncertain],:);
LOG.xDELTA = zeros(nUB,1);
LOG.iWC = 1;

% DELTA-K iterations
for ctSyn=1:30
   % Worst-case analysis (limited to goals with uncertainty)
   LOG = worstCaseAnalysisFcn(LOG,...
      SYSDATA,SPECDATA_U,tInfo,LOG.xDELTA(:,LOG.iWC),Options);
   showRobust(LOG,Options,Ts)
   
   % Slow progress tracking
   wcF = LOG.wcF;  wcG = LOG.wcG;  wcFstab = LOG.wcFstab;
   fVar = max(abs(fHist-wcF));  % variability over last FWINDOW iter
   gVar = max(abs(gHist-wcG));
   sVar = max(abs(sHist-wcFstab));
   hPtr = mod(hPtr,hWindow)+1;
   fHist(hPtr) = wcF;
   gHist(hPtr) = wcG;
   sHist(hPtr) = wcFstab;

   % Termination checks
   STOL = max(Options.MinDecay,RELTOL*abs(wcFstab));
   if wcFstab>0
      % Not robustly stable
      if LOG.Fstab>0 || sVar<STOL
         break
      end
   elseif StabilizeOnly
      % Robust stability is good enough
      break
   elseif wcG>1+RELTOL
      % Not robustly feasible
      if LOG.G>wcG*(1-RELTOL) || gVar<RELTOL*wcG
         break
      end
   else
      if wcF<=Options.SoftTarget
         % Robustly feasible and achieved target value for soft goals 
         showTarget(LOG,Options,wcF)
         break
      elseif LOG.F>wcF*(1-RELTOL) || fVar<RELTOL*wcF
         % Robustly feasible + robust performance
         break
      end
   end
   
   % Add worst-case to set of synthesis models
   [SYSDATA_S,SPECDATA_S,tInfo_S] = growModelSet(...
      SYSDATA_S,SPECDATA_S,tInfo_S,SYSDATA,SPECDATA,tInfo,LOG.xDELTA);
   
   % Repeat tuning for larger model set
   LOG = basicTuningFcn(LOG,SYSDATA_S,SPECDATA_S,tInfo_S,LOG.X,Options);
   
   % Rank DELTA perturbations by severity (LOG.iWC)
   FD = LOG.FinalData;
   if LOG.Fstab>0 || StabilizeOnly
      tau = max(0.1*abs(LOG.Fstab),1e-4);
      FD = FD([FD.Config]>0 & [FD.fStab]>LOG.Fstab-tau,:);
      [~,iS] = sort([FD.fStab],'descend'); % from most to least severe
      iM = [FD(iS,:).Model];
   else
      % Select "90% active" goals
      if LOG.G>1
         f0 = Inf;  g0 = LOG.G;
      else
         f0 = LOG.F;  g0 = 1;
      end
      fObj = [FD.fObj];  Soft = [FD.Soft];
      fObj(Soft) = fObj(Soft)/f0;
      fObj(~Soft) = fObj(~Soft)/g0;
      iAct = find([FD.Config]>0 & fObj>0.9);
      [~,iS] = sort(fObj(iAct),'descend'); % from most to least active
      iM = [FD(iAct(iS),:).Model];
   end
   LOG.iWC = unique([SYSDATA_S(iM,1).iDelta],'stable');
   
   % Abort conditions
   if StopFcn()
      % Abort signal
      break
   elseif ctSyn>1 && localRelEdge(BestDesign,[LOG.Fstab LOG.G LOG.F])>=1
      % Terminate if multi-model design has substantially worse performance
      % than best robust design so far.
      % NOTE: Beware that results from multi-model synthesis can suddenly 
      %       improve during the first few iterations
      showAbort(LOG,Options)
      return
   end
end

% Display final result
showFinal(LOG,Options,Ts)

% Update best robust design so far
% Note: Watch for goals that do not depend on the uncertainty
NewDesign = [LOG.wcFstab LOG.wcG LOG.wcF];
if NSOptLog.gradeDesign(NewDesign)<NSOptLog.gradeDesign(BestDesign)
   BestDesign = NewDesign;
end

%----------------------------

function tau = localRelEdge(Design1,Design2)
% Computes relative edge of Design1 over Design 2, where
% Design = [wcFstab,wcG,wcF].
if Design2(1)>=0
   % Design2 unstable
   if Design1(1)<Design2(1)
      tau = (Design2(1)-Design1(1))/abs(Design1(1));
   else 
      tau = 0;
   end
elseif Design2(2)>1
   % Design2 stable but infeasible
   tau = Design2(2)/Design1(2)-1;
else
   % Design2 stable and feasible
   tau = Design2(3)/Design1(3)-1;
end
