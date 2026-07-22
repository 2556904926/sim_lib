function [T,SoftReqs,HardReqs,Options] = looptuneSetup(G,C,varargin)
%LOOPTUNESETUP  Constructs equivalent SYSTUNE problem.
%
%   LOOPTUNESETUP provides a bridge between LOOPTUNE and SYSTUNE by 
%   taking the argument list for LOOPTUNE and constructing an equivalent
%   argument list for SYSTUNE. You can use this function to probe into
%   the tuning requirements enforced by LOOPTUNE, or to switch from 
%   LOOPTUNE to SYSTUNE to take advantage of additional functionality.
%
%   [T,SOFT,HARD,OPT] = looptuneSetup(G,C,...) takes the LOOPTUNE inputs
%   G,C,... and constructs equivalent inputs for SYSTUNE so that
%       LOOPTUNE(G,C,...)
%       SYSTUNE(T,SOFT,HARD,OPT)
%   produce the same results. The output arguments are as follows:
%     * T is a tunable model of the closed-loop system (see GENSS)
%     * SOFT and HARD are the soft and hard tuning requirements implicitly 
%       enforced by LOOPTUNE
%     * OPT is the corresponding option set for SYSTUNE.
%
%   See also looptune, systune, slTuner/looptuneSetup, genss.

%   Author(s): P. Gahinet
%   Copyright 2010-2013 The MathWorks, Inc.
ni = nargin;
if ni<2
   error(message('Control:tuning:looptune1'))
end

% Validate G,C and convert to GENSS
if ~(isa(G,'DynamicSystem') && isa(C,'DynamicSystem'))
   error(message('Control:tuning:looptune2'))
elseif ~(isParametric(G) || isParametric(C))
   error(message('Control:tuning:looptune4'))
elseif issparse(G) || issparse(C)
   error(message('Control:tuning:looptune19'))
else
   try
      G = genss(G);
      C = genss(C);
   catch ME
      error(message('Control:tuning:looptune3'))
   end
end

% Sample time compatibility
try
   [G,C] = matchSamplingTime(G,C);
catch ME
   error(message('Control:tuning:looptune17'))
end

% Construct closed-loop model for SYSTUNE
try
   [G,C,nu,ny] = ltipack.getFeedbackPath(G,C);
catch ME
   throw(ME)
end
inC = C.InputName;     yNames = inC(1:ny);
outC = C.OutputName;   uNames = outC(1:nu);
APU = AnalysisPoint('APU_',nu);  APU.Location = uNames;
APY = AnalysisPoint('APY_',ny);  APY.Location = yNames;
[nout,nin] = iosize(C);
CLS = blkdiag(APU,eye(nout-nu))*C*blkdiag(APY,eye(nin-ny));
CLS.InputName = inC;
CLS.OutputName = outC;
T = lft(G,CLS,nu,ny);

% Construct requirements and translate options
try
   [wc,Reqs,Opt] = ctrlutil.looptuneParser(varargin{:});
   if any(wc>pi/abs(G.Ts))
      error(message('Control:tuning:looptune18'))
   end
   [SoftReqs,HardReqs,Options] = ...
      ctrlutil.looptuneReqs(wc,Reqs,Opt,uNames,yNames);
catch ME
   throw(ME)
end
