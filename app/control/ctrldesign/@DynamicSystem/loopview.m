function loopview(G,C,Info)
%LOOPVIEW  Graphically analyze MIMO feedback loops.
%
%   LOOPVIEW shows key characteristics of MIMO feedback loops such as 
%   open-loop response and MIMO stability margins. It can be used in
%   conjunction with LOOPTUNE to validate the tuned control system.
%
%   LOOPVIEW(G,C) shows the open-loop response of the positive feedback 
%   loop with plant G and controller C:
%
%                  +-------+
%            +---->|   G   |-----+
%            |     +-------+     |
%         u  |                   | y
%            |     +-------+     |
%            +-----|   C   |<----+
%                  +-------+
%
%   LOOPVIEW(G,C,INFO) takes the INFO structure returned by LOOPTUNE and
%   shows the desired and actual values of each requirement used for tuning
%   the controller parameters. This helps with troubleshooting when LOOPTUNE
%   fails to meet all requirements.
%
%   See also slTuner/loopview, TuningGoal, looptune, diskmargin.

%   Author(s): P. Gahinet
%   Copyright 2010-2013 The MathWorks, Inc.
narginchk(2,3)

% Validate G and C
if ~(isa(G,'DynamicSystem') && isa(C,'DynamicSystem'))
   error(message('Control:tuning:loopview1'))
end
try
   [G,C] = matchSamplingTime(G,C);
catch ME
   error(message('Control:tuning:loopview3'))
end

% Get portion involved in feedback loop
try
   [G,C,nu,ny] = ltipack.getFeedbackPath(G,C);
catch ME
   throw(ME)
end

if nargin<3
   % LOOPVIEW(G,C): Show open-loop responses
   [nzy,nwu] = iosize(G);
   G = ss(G);
   C = ss(C);
   Gfb = G(nzy-ny+1:nzy,nwu-nu+1:nwu);
   Cfb = C(1:nu,1:ny);
   GC = Gfb * Cfb;
   CG = Cfb * Gfb;
   ctrlutil.loopviewPlot(CG,GC)
else
   % Validate Info structure
   if ~(isstruct(Info) && isfield(Info,'Specs') && ...
         isfield(Info,'Runs') && isa(Info.Specs,'TuningGoal.Generic'))
      error(message('Control:tuning:loopview2'))
   end
   % Construct closed-loop model
   inC = C.InputName;
   outC = C.OutputName;
   APU = AnalysisPoint('APU_',nu);  APU.Location = outC(1:nu);
   APY = AnalysisPoint('APY_',ny);  APY.Location = inC(1:ny);
   [nout,nin] = iosize(C);
   CLS = blkdiag(APU,eye(nout-nu))*C*blkdiag(APY,eye(nin-ny));
   CLS.InputName = inC;
   CLS.OutputName = outC;
   T = lft(G,CLS,nu,ny);
   % Show requirement
   viewSpec(Info.Specs,T,Info.Runs);
end

