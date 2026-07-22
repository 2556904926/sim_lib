function H = getDynamics(T,Openings,Models)
%getDynamics  Compute closed-loop dynamics.
%
%   H = getDynamics(T) takes a generalized state-space model T of the 
%   control system and returns the closed-loop state matrix as a 
%   state-space model H with no inputs and no outputs. The closed-loop 
%   state vector includes all plant and controller states.
%
%   H = getDynamics(T,OPENINGS) further specifies which feedback loops 
%   to open when evaluating the closed-loop dynamics. The resulting
%   state matrix still contains all plant and controller states but its 
%   value reflects the specified loop openings.
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
%      H = getDynamics(T)
%   while the closed-loop dynamics of the inner loop only are given by
%      H2 = getDynamics(T,'X1')
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
   % Get global list of analysis points and collect corresponding size and
   % channel name info (before selecting models in case some analysis points
   % get dropped)
   BlockSet = getBlocks(T);
   BN = fieldnames(BlockSet);  % sorted alphabetically
   BV = struct2cell(BlockSet);
   iAP = find(cellfun(@(x) isa(x,'AnalysisPoint'),BV));
   nAP = numel(iAP);
   APName = BN(iAP,:);
   APData = BV(iAP,:);
   chID = cell(nAP,1);
   chOpen = cell(nAP,1);
   ich = 0;
   for ct=1:nAP
      blk = APData{ct};
      nch = size(blk,1);
      chID{ct} = blk.Location;
      chOpen{ct} = blk.Open;
      ich = ich + nch;
   end
   aNames = cat(1,chID{:});  % loop channel IDs
   aOpen = cat(1,chOpen{:}); % open loop channels
   nL = numel(aNames);
   
   % Check each loop opening site identifier is unique
   [~,iu,ju] = unique(aNames);
   if numel(iu)<nL
      ju = sort(ju);
      ju = ju(ju(1:end-1)==ju(2:end));
      error(message('Control:lftmodel:getTransfer5',aNames{ju(1)}))
   end
   
   % Locate specified openings
   [iOpen,MisMatch] = ltipack.resolveSignalID(Openings,aNames,true);
   error(genlti.resolveSignalError('Control:lftmodel:getTransfer9',MisMatch,aNames))
   
   % Update analysis point's open/closed configuration to reflect openings
   aOpen(iOpen) = true;
   ich = 0;
   for ct=1:nAP
      nch = numel(chID{ct});
      APData{ct}.Open = aOpen(ich+1:ich+nch);
      ich = ich + nch;
   end
   BlockSet = cell2struct(APData,APName,1);
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

% Reduce interconnection to LFT(P,diag(APC,C1(x),...,CN(x)))
% where APC is the analysis point configuration.
Data = T.Data_;
DH = createArray(size(Data),'ltipack.ssdata');
for ct=1:nsys
   D = Data(ct);
   B = D.Blocks;
   % Locate AnalysisPoint blocks and update their configuration
   isAP = logicalfun(@(blk) isa(blk,'AnalysisPoint'),B);
   iAP = find(isAP);
   if ~isempty(Openings)
      for ctB=1:numel(iAP)
         B(iAP(ctB)) = setBlockValue(B(iAP(ctB)),BlockSet);
      end
   end
   % Locate tuned blocks
   isTunable = logicalfun(@isParametric,B);
   iT = find(isTunable);
   % Permute blocks to bring AnalysisPoint blocks upfront followed by tunable
   % blocks
   iN = find(~(isAP | isTunable));
   bperm = [iAP ; iT ; iN];
   [rperm,cperm] = getRowColPerm(B,bperm);
   D.IC = ioperm(D.IC,[1:nz nz+cperm],[1:nw nw+rperm]);
   D.Blocks = B(bperm);
   % Fold blocks that are neither for analysis nor tuning
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
   % Construct H
   nx = size(CL.a,1);
   DH(ct) = ltipack.ssdata(CL.a,zeros(nx,0),zeros(0,nx),[],[],CL.Ts);
   DH(ct).StateName = CL.StateName;
   DH(ct).StateUnit = CL.StateUnit;
end

H = ss.make(DH);
H.TimeUnit = T.TimeUnit;
H.SamplingGrid = T.SamplingGrid;
