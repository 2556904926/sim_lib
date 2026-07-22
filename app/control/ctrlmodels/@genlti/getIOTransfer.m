function H = getIOTransfer(T,Inputs,Outputs,Openings,Models)
%getIOTransfer  Computes input/output transfer function.
%
%   This function is useful to compute input/output responses given a
%   generalized model of the overall control system (for example, in the
%   context of tuning the control system parameters with SYSTUNE).
%
%   H = getIOTransfer(T,IN,OUT) takes a generalized model T of the control
%   system and computes the closed-loop transfer function H from inputs IN
%   to outputs OUT. The strings or cell arrays of strings IN and OUT select
%   signals by name among:
%      * The inputs and outputs of T (T.InputName and T.OutputName)
%      * The internal signals marked by analysis points (see AnalysisPoint).
%        Use getPoints(T) to get the list of such signals.
%
%   H = getIOTransfer(T,IN,OUT,OPENINGS) further specifies which feedback
%   loops to open when evaluating the I/O transfer H. The string or cell
%   array of strings OPENINGS must contain a subset of the loop opening
%   locations marked by analysis points (see AnalysisPoint). Use getPoints(T)
%   to get the list of such locations.
%
%   The output H is a generalized GENSS/GENFRD model of the requested I/O
%   transfer function. This model retains all states and Control Design
%   blocks that contribute to the specified transfer function. Use SS/FRD
%   or GETVALUE to compute its current/nominal value.
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
%      T.InputName = 'r';  T.OutputName = 'y';
%   You can now use getIOTransfer to obtain various transfer functions, for
%   example
%      H1 = getIOTransfer(T,'r','y','X2')
%   gives the transfer from r to y with the inner loop open and the outer
%   loop closed, and
%      H2 = getIOTransfer(T,'X1','y')
%   gives the transfer from a disturbance entering at X1 to y.
%
%   See also AnalysisPoint, getPoints, getLoopTransfer, genss, genfrd, 
%   getValue, slTuner/getIOTransfer, systune.

%   Author(s): P. Gahinet
%   Copyright 2009-2012 The MathWorks, Inc.

% Note: getIOTransfer just selects I/Os and adjusts the loop openings. It
% does not evaluate or fold any block. It does however eliminate states 
% and blocks that do not contribute to the specified I/O transfer.
narginchk(3,5)
ni = nargin;
if ni<4 || isempty(Openings)
   Openings = strings(0,1);
end
if ni<5
   Models = NaN;   % all models
end

% Validate inputs
if (ischar(Inputs) && isrow(Inputs)) || iscellstr(Inputs)
   Inputs = string(Inputs);
elseif ~isstring(Inputs)
   error(message('Control:lftmodel:getTransfer1'))
end
if (ischar(Outputs) && isrow(Outputs)) || iscellstr(Outputs)
   Outputs = string(Outputs);
elseif ~isstring(Outputs)
   error(message('Control:lftmodel:getTransfer2'))
end
if (ischar(Openings) && isrow(Openings)) || iscellstr(Openings)
   Openings = string(Openings);
elseif ~isstring(Openings)
   error(message('Control:lftmodel:getTransfer3'))
end

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
APIndex = cell(nAP,1);
chID = cell(nAP,1);
chOpen = cell(nAP,1);
ich = 0;
for ct=1:nAP
   blk = APData{ct};
   nch = size(blk,1);
   chID{ct} = blk.Location;
   chOpen{ct} = blk.Open;
   APIndex{ct} = ich+1:ich+nch;
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

% Update open/closed configuration of analysis points based on specified Openings
if ~isempty(Openings)
   % Locate openings
   [iOpen,MisMatch] = ltipack.resolveSignalID(Openings,aNames,true);
   error(genlti.resolveSignalError('Control:lftmodel:getTransfer9',MisMatch,aNames))
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

% Locate I/Os
if isempty(Inputs)
   % For slTunable.getIOTransfer()
   indU = [];   InNames = strings(0,1);
else
   [NameList,ix] = unique([T.InputName ; aNames],'stable');
   [indU,MisMatch,InNames] = ltipack.resolveSignalID(Inputs,NameList,true);
   error(genlti.resolveSignalError('Control:lftmodel:getTransfer7',MisMatch,NameList))
   indU = ix(indU);
end

if isempty(Outputs)
   indY = [];   OutNames = strings(0,1);
else
   [NameList,ix] = unique([T.OutputName ; aNames],'stable');
   [indY,MisMatch,OutNames] = ltipack.resolveSignalID(Outputs,NameList,true);
   error(genlti.resolveSignalError('Control:lftmodel:getTransfer8',MisMatch,NameList))
   indY = ix(indY);
end

% Update open/close configuration for analysis points and expose 
% analysis point channels if referenced as I/Os
%
%                               +-------+
%      w (nw) ----------------->|       |---------------> z (nz)
%                               |       |
%     wL (nL) ----->O---------->|   P   |----------+----> zL (nL)
%                   |           |       |          |
%                   |     +---->|       |----+     |
%                   |     |     +-------+    |     |
%                   |  wB |                  | zB  |
%                   |     |     +-------+    |     |
%                   |     +-----|  TB   |<---+     |
%                   |           +-------+          |
%                   |                              |
%                   |           +-------+          |
%                   +-----------|  AP   |<---------+
%                               +-------+
%
AddLoopChannels = (any(indU>nw) || any(indY>nz));
Data = T.Data_;
for ct=1:nsys
   D = Data(ct);
   B = D.Blocks;
   % Find analysis points and locate them in master list
   isAP = logicalfun(@(blk) isa(blk,'AnalysisPoint'),B);
   jAP = find(isAP);
   [~,~,iAP] = intersect(getBlockName(B(jAP)),APName,'stable');
   if numel(iAP)<numel(jAP)
      % Check analysis point blocks appear only once
      error(message('Control:tuning:Tuning2'))
   end
   % Update their configuration
   if ~isempty(Openings)
      for ctB=1:numel(jAP)
         B(jAP(ctB)) = setBlockValue(B(jAP(ctB)),BlockSet);
      end
      D.Blocks = B;
   end
   % Construct desired I/O transfer
   if AddLoopChannels
      % Add loop channels wL and zL
      [rSW,cSW] = getRowColSelection(B,jAP);
      ich1 = cat(2,APIndex{iAP});      % loop channels present in D
      ich2 = 1:nL;  ich2(:,ich1) = []; % loop channels missing in D
      IC = D.IC;
      [nr,nc] = iosize(IC);
      % Beware the block outputs are IC inputs and vice versa!
      IC = getsubsys(IC,[nz+cSW,1:nr],[nw+rSW,1:nc]);
      if ~isempty(ich2)
         % Add zeros for missing analysis point channels
         if isfinite(D.IC)
            IC = append(createGain(IC,zeros(numel(ich2))),IC);
         else
            IC = append(createGain(IC,NaN(numel(ich2))),IC);
         end
      end
      D.IC = IC;
      % Reorder I/O channels to conform with picture above (inputs are
      % [uNames;aNames] and outputs are [yNames;aNames]), select I/Os,
      % and eliminate non-contributing blocks/states 
      [~,Lperm] = sort([ich2,ich1]);
      rperm = [nL+1:nL+nz,Lperm];
      cperm = [nL+1:nL+nw,Lperm];
      Data(ct) = getsubsys(D,rperm(indY),cperm(indU),'smin');
   else
      % Select I/Os and eliminate non-contributing blocks/states
      Data(ct) = getsubsys(D,indY,indU,'smin');
   end
end
         
H = feval(sprintf('%s.make',class(T)),Data);
H.InputName_ = InNames;
H.OutputName_ = OutNames;
H.TimeUnit = T.TimeUnit;
H.SamplingGrid = T.SamplingGrid;
