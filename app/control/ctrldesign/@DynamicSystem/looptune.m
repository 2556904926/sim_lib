function [G,C,gam,Info] = looptune(G0,C0,varargin)
%LOOPTUNE  Tuning of MIMO feedback loops.
%
%   LOOPTUNE tunes SISO or MIMO feedback loops using a loop shaping approach.
%   To use LOOPTUNE you must separate the plant from the controller, but
%   the controller itself can have any structure and parameterization.
%   LOOPTUNE uses SYSTUNE to tune the controller parameters (see SYSTUNE
%   and LOOPTUNESETUP). Use slTuner/looptune to tune feedback loops modeled 
%   in Simulink, and use SYSTUNE for multi-objective tuning of fixed-structure 
%   control systems.
%
%   [G,C,GAM] = LOOPTUNE(G0,C0,WC) tunes the plant/controller feedback loop
%
%                  +--------+
%            +---->|   G    |-----+
%            |     +--------+     |
%         u  |                    | y
%            |     +--------+     |
%            +-----|   C    |<----+
%                  +--------+
%
%   to meet the following requirements:
%      * Performance: Integral action at low frequency
%      * Bandwidth: Gain crossover in the frequency interval WC
%      * Robustness: Adequate stability margins and gain roll-off past WC.
%   The sensor signals y (measurements) and actuator signals u (controls)
%   mark the boundary between the physical plant G and the controller C.
%
%   The tunable model C0 specifies the controller architecture, parameters, 
%   and initial value (see GENSS). The plant model G0 can be a numeric LTI 
%   model or a tunable GENSS model when co-tuning the plant and controller.
%   Use CONNECT to build G0 and C0 from individual fixed/tunable components.
%   The 1-by-2 vector WC specifies the crossover region [WCMIN,WCMAX]. A 
%   scalar value WC is interpreted as the crossover region [WC/2,2*WC]. 
%   LOOPTUNE returns the tuned plant G and controller C and the success 
%   indicator GAM. A value GAM<=1 means all requirements were satisfied 
%   while GAM>>1 indicates failure to meet some requirement.
%
%   [G,C,GAM] = LOOPTUNE(G0,C0,WC,REQ1,REQ2,...) specifies additional design 
%   requirements REQ1,REQ2,... Type "help TuningGoal" for a list of available
%   design requirements. Omit WC to drop the default performance/bandwidth/
%   roll-off requirements and use REQ1,REQ2,... instead. All signals 
%   referenced by REQ1,REQ2,... must appear as I/O names in G or C.
%
%   [G,C,GAM] = LOOPTUNE(G0,C0,...,OPTIONS) specifies options for the tuning
%   algorithm, see LOOPTUNEOPTIONS for details.
%
%   [G,C,GAM,INFO] = LOOPTUNE(G0,C0,...) also returns a structure INFO with
%   the following fields:
%     * Di,Do: Optimal plant I/O scalings. The scaled plant is Do\G*Di.
%     * Specs: Vector of design requirements used for tuning
%     * Runs: Results from each optimization run (see SYSTUNEINFO).
%   Use LOOPVIEW(G,C,INFO) to validate the tuned controller against all
%   design requirements.
%
%   Type "demo toolbox control" and look under "Control System Tuning" for 
%   examples.
%
%   Reference: P. Apkarian and D. Noll, "Nonsmooth H-infinity Synthesis,"
%   IEEE Transactions on Automatic Control, 51(1), pp. 71-86, 2006.
%
%   See also looptuneOptions, loopview, systuneInfo, TuningGoal, tunableBlock, 
%   genss, connect, showTunable, getBlockValue, slTuner/looptune, 
%   looptuneSetup, systune.

%   Author(s): P. Gahinet
%   Copyright 2010-2013 The MathWorks, Inc.
ni = nargin;
if ni<2
   error(message('Control:tuning:looptune1'))
end
NeedInfo = (nargout>3);

try
   % Build SYSTUNE problem
   [T0,SoftReqs,HardReqs,Options] = looptuneSetup(G0,C0,varargin{:});
   
   % Resolve Ts=-1
   if G0.Ts~=C0.Ts
      G0.Ts = T0.Ts;
      C0.Ts = T0.Ts;
   end

   % Optimize tunable parameters
   if NeedInfo
      [T,fBest,gBest,TuningInfo] = systune(T0,SoftReqs,HardReqs,Options);
   else
      [T,fBest,gBest] = systune(T0,SoftReqs,HardReqs,Options);
   end
   gam = max(fBest);
   if any(gBest>1)
      % Could not satisfy MaxFrequency constraint
      warning(message('Control:tuning:looptune12'))
   end
   
   % Return tuned plant and controller
   Blocks = T.Blocks;
   G = inheritBlockValue_(G0,Blocks);
   C = inheritBlockValue_(C0,Blocks);
   
   % Build INFO struct
   if NeedInfo
      Info = ctrlutil.looptuneInfo(TuningInfo,SoftReqs,Blocks);
   end
catch ME
   throw(ME)
end
