function H = getTunedDynamics(T,Openings,Models)
%getTunedDynamics  Computes tunable portion of closed-loop dynamics.
%
%   H = getTunedDynamics(T) takes a generalized state-space model T of the 
%   control system and computes the portion H of the closed-loop dynamics
%   that depend on the tunable blocks in T. States that are structurally
%   unaffected by the tuned blocks are ignored. H is a state-space model  
%   with no inputs and no outputs.
%
%   H = getTunedDynamics(T,OPENINGS) further specifies which feedback loops 
%   to open when evaluating the closed-loop dynamics. States that become
%   "open-loop" as a result are ignored as well.
%
%   Example: Consider the cascaded feedback loops below where C1,C2 are 
%   tunable compensators and X1,X2 are loop opening locations.
%
%       r -->O-->[C1]-->O--->[C2]-->[G2]---+--[G1]--+--> y
%          - |        - |                  |        |
%            |          +--------[X2]------+        |
%            +---------------[X1]-------------------+
%
%   Model the overall control system as a generalized state-space model T:
%      G1 = tf(10,[1 10])
%      G2 = tf([1 2],[1 0.2 10])
%      C1 = tunablePID('C','pi')
%      C2 = tunableGain('G',1)
%      X1 = AnalysisPoint('X1')
%      X2 = AnalysisPoint('X2')
%      T = feedback(G1*feedback(G2*C2,X2)*C1,X1)
%   The closed-loop dynamics of the entire system are given by
%      H = getTunedDynamics(T)
%   while the closed-loop dynamics of the inner loop only are given by
%      H2 = getTunedDynamics(T,'X1')
%
%   See also AnalysisPoint, getPoints, getLoopTransfer, genss, getValue,
%   slTuner, systune.

%   Author(s): P. Gahinet
%   Copyright 2009-2013 The MathWorks, Inc.
narginchk(1,3)
ni = nargin;
if ni<2 || isempty(Openings)
   Openings = strings(0,1);
end
if ni<3
   Models = NaN;   % all models
end

% Validate inputs
if (ischar(Openings) && isrow(Openings)) || iscellstr(Openings)
   Openings = string(Openings);
elseif ~isstring(Openings)
   error(message('Control:lftmodel:getTransfer3'))
end

% Handle loop openings
if ~isempty(Openings)
   % Get global list of switch blocks and collect corresponding size and
   % channel name info (before selecting models in case some switches get
   % dropped)
   BlockSet = getBlocks(T);
   BN = fieldnames(BlockSet);  % sorted alphabetically
   BV = struct2cell(BlockSet);
   iSW = find(cellfun(@(x) isa(x,'AnalysisPoint'),BV));
   nSW = numel(iSW);
   SWName = BN(iSW,:);
   SWData = BV(iSW,:);
   chID = cell(nSW,1);
   chOpen = cell(nSW,1);
   ich = 0;
   for ct=1:nSW
      blk = SWData{ct};
      nch = size(blk,1);
      chID{ct} = blk.Location;
      chOpen{ct} = blk.Open;
      ich = ich + nch;
   end
   sNames = cat(1,chID{:});  % loop channel IDs
   sOpen = cat(1,chOpen{:}); % open loop channels
   nL = numel(sNames);
   
   % Check each loop opening site identifier is unique
   [~,iu,ju] = unique(sNames);
   if numel(iu)<nL
      ju = sort(ju);
      ju = ju(ju(1:end-1)==ju(2:end));
      error(message('Control:lftmodel:getTransfer5',sNames{ju(1)}))
   end
   
   % Locate specified openings
   [iOpen,MisMatch] = ltipack.resolveSignalID(Openings,sNames,true);
   error(genlti.resolveSignalError('Control:lftmodel:getTransfer9',MisMatch,sNames))
   
   % Update loop switch configuration to reflect openings
   sOpen(iOpen) = true;
   ich = 0;
   for ct=1:nSW
      nch = numel(chID{ct});
      SWData{ct}.Open = sOpen(ich+1:ich+nch);
      ich = ich + nch;
   end
   BlockSet = cell2struct(SWData,SWName,1);
end
   
% Select models
if ~isequaln(Models,NaN)
   try
      T = T(:,:,Models);
   catch ME
      error(message('Control:lftmodel:getTransfer11'))
   end
end
[nz,nw,nsys] = size(T);

% Reduce interconnection to LFT(P,diag(LSC,C1(x),...,CN(x)))
% where LSC is the loop switch configuration.
Data = T.Data_;
DH = createArray(size(Data),'ltipack.ssdata');
for ct=1:nsys
   D = Data(ct);
   B = D.Blocks;
   % Locate AnalysisPoint blocks and update their configuration
   isSwitch = logicalfun(@(blk) isa(blk,'AnalysisPoint'),B);
   iS = find(isSwitch);
   if ~isempty(Openings)
      for ctB=1:numel(iS)
         B(iS(ctB)) = setBlockValue(B(iS(ctB)),BlockSet);
      end
   end
   % Locate tuned blocks
   isTunable = logicalfun(@isParametric,B);
   iT = find(isTunable);
   % Permute blocks to bring AnalysisPoint blocks upfront followed by tunable
   % blocks
   iN = find(~(isSwitch | isTunable));
   bperm = [iS ; iT ; iN];
   [rperm,cperm] = getRowColPerm(B,bperm);
   D.IC = ioperm(D.IC,[1:nz nz+cperm],[1:nw nw+rperm]);
   D.Blocks = B(bperm);
   % Fold blocks that are neither switches nor tunable
   nFold = numel(iN);
   if nFold>0
      D = foldBlocks(D,[false(numel(B)-nFold,1) ; true(nFold,1)]);
   end
   % Evaluate closed-loop
   IC = D.IC;  B = D.Blocks;
   DB = ltipack_ssdata(B);
   [nwBL,nzBL] = iosize(DB);
   iwBL = nw+1:nw+nwBL;
   izBL = nz+1:nz+nzBL;
   CL = lft(IC,DB,iwBL,izBL,1:nzBL,1:nwBL);
   % Determine which states are "tunable"
   Ts = CL.Ts;
   [nL,~] = iosize(B(1:numel(iS)));
   xTuned = getControlledStates(IC.a,IC.b(:,iwBL),IC.c(izBL,:),IC.d(izBL,iwBL),...
      DB.a,DB.b(:,nL+1:nzBL),DB.c(nL+1:nwBL,:),DB.d(nL+1:nwBL,nL+1:nzBL),...
      DB.d(1:nL,1:nL),Ts);
   nx = numel(xTuned);
   % Construct H
   DH(ct) = ltipack.ssdata(CL.a(xTuned,xTuned),zeros(nx,0),zeros(0,nx),[],[],Ts);
   if ~isempty(CL.StateName)
      DH(ct).StateName = CL.StateName(xTuned,:);
   end
   if ~isempty(CL.StateUnit)
      DH(ct).StateUnit = CL.StateUnit(xTuned,:);
   end
end

H = ss.make(DH);
H.TimeUnit = T.TimeUnit;
H.SamplingGrid = T.SamplingGrid;