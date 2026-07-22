function [xSpec,FixedUnstable] = getControlledStates(A,B,C,D,Ac,Bc,Cc,Dc,LSC,Ts)
% Given the feedback interconnection
%    LFT(P,diag(LSC,C1(x),...,CN(x)))
% and
%  * a realization (A,B,C,D) of the plant P(s)
%  * a realization (Ac,Bc,Cc,Dc) of the controller diag(C1(x),...,CN(x))
%  * the loop switch configuration LSC
% this function determines which portion XSPEC of the overall state vector
% is structurally manipulated by feedback. The complement of XSPEC
% corresponds to structurally feedback-invariant dynamics that should be
% excluded from all spectral constraint evaluations. In other words,
% spectral constraints should be evaluated for the portion Acl(XSPEC,XSPEC)
% of the closed-loop matrix.

%   Copyright 1986-2013 The MathWorks, Inc.
[nyP,nuP] = size(D);
[nuC,nyC] = size(Dc);
nxP = size(A,1);
nxC = size(Ac,1);
nL = size(LSC,1);
nw = nuP-(nL+nuC);
nz = nyP-(nL+nyC);
% Contruct a model of the open loop P22 * diag(LSC,C1(x),...,CN(x))
% Note: Plant states should come first for consistency with evalLFT
[Aol,Bol,Col,Dol] = ltipack.ssops('mult',...
   A,B(:,nw+1:nuP),C(nz+1:nyP,:),D(nz+1:nyP,nw+1:nuP),[],...
   Ac,[zeros(nxC,nL) Bc],[zeros(nL,nxC) ; Cc],blkdiag(LSC,Dc),[]);
% Determine which states are affected by feedback and which states are
% feedback invariant
xmf = smfreal(Aol,Bol,Col,Dol,[]);
% Ignore feedback-invariant states of the plant
% NOTE: When all loops are closed, keep all controller modes to enforce 
% stability of open-loop components such as prefilters (cf mLoopTune1 
% in tAPI_LOOPTUNE_SL2)
if all(diag(LSC))
   xmf(nxP+1:end) = true;
   % Throw warning if there are unstable feedback-invariant modes in plant
   Afi = Aol(~xmf,~xmf);
   FixedUnstable = (Ts==0 && any(real(eig(Afi))>=0)) || ...
      (Ts~=0 && any(abs(eig(Afi))>=1));
else
   FixedUnstable = false;
end
xSpec = find(xmf);
