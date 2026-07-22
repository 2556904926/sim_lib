function Info = looptuneInfo(systuneInfo,SoftReqs,varargin)
% Constructs INFO output of LOOPTUNE from counterpart for SYSTUNE.

%   Copyright 2003-2014 The MathWorks, Inc.
[~,iBest] = min([systuneInfo.f]);
DS = systuneInfo(iBest).LoopScaling;
if isempty(DS) % failed to stabilize
   Di = [];  Do = [];
elseif nargin<4
   % Call from MATLAB or slTunable
   Blocks = varargin{1};
   uNames = Blocks.APU_.Location;
   Di = DS(uNames,uNames);
   yNames = Blocks.APY_.Location;
   Do = DS(yNames,yNames);
else
   % Call from slTuner
   iu = ltipack.resolveSignalID(varargin{1},DS.InputName,true);
   Di = DS(iu,iu);
   iy = ltipack.resolveSignalID(varargin{2},DS.OutputName,true);
   Do = DS(iy,iy);
end
Info = struct('Di',Di,'Do',Do,'Specs',SoftReqs,'Runs',systuneInfo);