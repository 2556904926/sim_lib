function [L,iX] = getLoopTransfer(T,LocID,FSign,Openings,Models)
%getLoopTransfer  Computes open-loop transfer function.
%
%   This function is useful to compute open-loop responses given a
%   generalized model of the overall control system (for example, in the
%   context of tuning the control system parameters with SYSTUNE).
%
%   L = getLoopTransfer(CL,LOC) takes a generalized model CL of the
%   closed-loop system and computes the positive-feedback loop transfer
%   function L measured at the location LOC. The string LOC refers to one
%   of the locations marked by analysis points (see AnalysisPoint). Use
%   getPoints(CL) to get the list of such locations. Use a cell array of
%   strings LOC to specify multiple locations and compute MIMO loop
%   transfer functions.
%
%   L = getLoopTransfer(CL,LOC,SIGN) specifies the feedback sign SIGN. Set
%   SIGN=-1 to compute the negative-feedback loop transfer function. By
%   default, L is the positive-feedback loop transfer function (SIGN=+1).
%   The closed-loop sensitivity function measured at the same location is
%   S = FEEDBACK(1,L,SIGN).
%
%   L = getLoopTransfer(CL,LOC,SIGN,OPENINGS) further specifies which
%   feedback loops to open when evaluating the loop transfer L. For example,
%   you can ask for the inner loop transfer with the outer loop open in a
%   cascaded loop configuration. The string or cell array of strings
%   OPENINGS must contain a subset of the loop opening locations marked by
%   analysis points (use getPoints(T) to get a list of such locations).
%
%   The output L is a generalized GENSS/GENFRD model of the requested loop 
%   transfer function. Use SS/FRD or GETVALUE to get its current/nominal 
%   value.
%
%   Example: Build a closed-loop model CL of the following SISO loop with a
%   tunable PI controller C:
%
%              r --->O--->[ C ]--[x]-->[ G ]---+---> y
%                  - |                         |
%                    +-------------------------+
%
%        G = tf([1 2],[1 0.2 10])
%        C = tunablePID('C','pi')
%        X = AnalysisPoint('x')  % loop opening location
%        CL = feedback(G*X*C,1)
%   To compute the open-loop transfer L=C*G at the location "x", type
%        L = getLoopTransfer(CL,'x',-1)
%
%   See also AnalysisPoint, getPoints, getIOTransfer, genss, genfrd, 
%   getValue, slTuner/getLoopTransfer, systune.

%   Author(s): P. Gahinet
%   Copyright 2009-2012 The MathWorks, Inc.

% NOTE: Must also support L = getLoopTransfer(CL,LOC,OPENINGS)
narginchk(2,5)
ni = nargin;
if ni<3 || isempty(FSign)
   FSign = +1;
end
if ni<4 || isempty(Openings)
   Openings = strings(0,1);
end
if ni<5
   Models = NaN;   % all models
end

% Support L = getLoopTransfer(CL,LOC,OPENINGS{,SIGN},...) because 
% slTunable version used to
if ni>2 && ~isnumeric(FSign)
   if ni==3
      Openings = FSign;   FSign = +1;
   elseif isnumeric(Openings)
      % Swap the two
      tmp = Openings;   Openings = FSign;   FSign = tmp;
   end
end

% Validate inputs
if (ischar(LocID) && isrow(LocID)) || iscellstr(LocID)
   LocID = string(LocID);
elseif ~isstring(LocID)
   error(message('Control:lftmodel:getTransfer4'))
end
if ~(isequal(FSign,1) || isequal(FSign,-1))
   error(message('Control:lftmodel:getTransfer6'))
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

% Check each loop opening location identifier is unique
[~,iu,ju] = unique(aNames);
if numel(iu)<nL
   ju = sort(ju);
   ju = ju(ju(1:end-1)==ju(2:end));
   error(message('Control:lftmodel:getTransfer5',aNames{ju(1)}))
end

% Identify loop channels of interest
[iLoop,MisMatch,LoopNames] = ltipack.resolveSignalID(LocID,aNames,true);
error(genlti.resolveSignalError('Control:lftmodel:getTransfer9',MisMatch,aNames))
aOpen(iLoop) = true;

% Identify loop openings
iX = [];
if ~isempty(Openings)
   % Locate openings
   [iOpen,MisMatch] = ltipack.resolveSignalID(Openings,aNames,true);
   error(genlti.resolveSignalError('Control:lftmodel:getTransfer9',MisMatch,aNames))
   aOpen(iOpen) = true;
   % iX = subset of locations LOC that are also flagged as loop openings
   % (used by getSensitivity)
   [~,iX] = intersect(iLoop,iOpen);
end

% Update loop switch configuration
ich = 0;
for ct=1:nAP
   nch = numel(chID{ct});
   APData{ct}.Open = aOpen(ich+1:ich+nch);
   ich = ich + nch;
end
BlockSet = cell2struct(APData,APName,1);

% Select models
if ~isequaln(Models,NaN)
   try
      T = T(:,:,Models);
   catch ME
      error(message('Control:lftmodel:getTransfer11'))
   end
end
[nz,nw,nsys] = size(T);

% Update open/close configuration for analysis points and expose 
% analysis point channels if referenced as I/Os, and remove w,z 
% from I/O list
%
%                               +-------+
%     wL (nL) ----->O---------->|       |----------+----> zL (nL)
%                   |           |   P   |          |
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
Data = T.Data_;
for ct=1:nsys
   D = Data(ct);
   % Find analysis points and locate them in master list
   B = D.Blocks;
   isAP = logicalfun(@(blk) isa(blk,'AnalysisPoint'),B);
   jAP = find(isAP);
   [~,~,iAP] = intersect(getBlockName(B(jAP)),APName,'stable');
   if numel(iAP)<numel(jAP)
      % Check analysis point blocks appear only once
      error(message('Control:tuning:Tuning2'))
   end
   % Update their configuration
   for ctB=1:numel(jAP)
      B(jAP(ctB)) = setBlockValue(B(jAP(ctB)),BlockSet);
   end
   D.Blocks = B;
   % Add loop channels wL,zL and get rid of w,z
   [rSW,cSW] = getRowColSelection(B,jAP);
   ich1 = cat(2,APIndex{iAP});      % loop channels present in D
   ich2 = 1:nL;  ich2(:,ich1) = []; % loop channels missing in D
   IC = D.IC;
   [nr,nc] = iosize(IC);
   % REVISIT: Input duplication is not input offset safe!
   IC = getsubsys(IC,[nz+cSW,nz+1:nr],[nw+rSW,nw+1:nc]);
   if ~isempty(ich2)
      % Add zeros or NaNs for missing loop switch channels
      if isfinite(D.IC)
         IC = append(createGain(IC,zeros(numel(ich2))),IC); %#ok<MNUML>
      else
         IC = append(createGain(IC,NaN(numel(ich2))),IC);
      end
   end
   D.IC = IC;
   % Reorder channels to conform with aNames and select specified loops
   [~,Lperm] = sort([ich2,ich1]);
   D = getsubsys(D,Lperm(iLoop),Lperm(iLoop),'smin');
   if FSign==1
      Data(ct) = D;
   else
      % REVISIT: (-1)*L vs L*(-1) somewhat arbitrary, matters with offsets
      Data(ct) = uminus(D);
   end
end

L = feval(sprintf('%s.make',class(T)),Data);
L.InputName_ = LoopNames;
L.OutputName_ = LoopNames;
L.TimeUnit = T.TimeUnit;
L.SamplingGrid = T.SamplingGrid;
