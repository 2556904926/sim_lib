%EVALGOAL  Evaluates tuning goal for a given design.
%
%   [HSPEC,FVAL] = EVALGOAL(R,CL) evaluates the requirement R for the control
%   system design CL. The first input R can be any TuningGoal object and the
%   second input CL is a @genss or @slTuner model of the control system
%   (typically the result of tuning the control system parameters with
%   SYSTUNE). EVALGOAL returns the normalized value FVAL of the requirement
%   and the transfer function HSPEC used to compute this value. For example,
%   if R limits the gain of some transfer function H(s) according to
%       || H(jw) || <= | gmax(jw) |
%   then HSPEC(s) is related to H(s) and the max gain profile gmax(s) by
%       HSPEC(s) = (1/gmax(s)) H(s)
%   and FVAL is the peak gain of HSPEC. The goal R is met if and only if
%   FVAL<=1.
%
%   Note: For MIMO feedback loops, the LoopShape, MinLoopGain, MaxLoopGain,
%   Margins, Sensitivity, and Rejection goals are sensitive to the relative
%   scaling of each SISO loop. SYSTUNE tries to balance the overall loop
%   transfer matrix while enforcing such goals. The optimal loop scaling
%   is cached in the tuned closed-loop model CL returned by SYSTUNE. For
%   consistency, EVALGOAL(R,CL) applies the same scaling when evaluating
%   the goals above. To ignore this scaling, use
%      [HSPEC,FVAL] = EVALGOAL(R,clearTuningInfo(CL))
%   Note that modifying CL may compromise the scaling validity.
%
%   See also viewGoal, TuningGoal, systune, genss, slTuner.

%   Copyright 2009-2017 The MathWorks, Inc.
error(message('Control:tuning:TuningReq13','evalGoal'))
