%VIEWGOAL  View tuning goal and validate design against tuning goals.
%
%   VIEWGOAL(R) shows a graphical view of the requirement R. The input
%   R can be any tuning goal object (see TuningGoal). You can also
%   specify a vector of tuning goal objects, in which case all goals
%   are shown in a single figure.
%
%   VIEWGOAL(R,CL) validates the design CL against the tuning goal(s) R.
%   CL is a @genss or @slTuner model of the control system and is
%   typically the result of tuning the control system parameters with
%   SYSTUNE.
%
%   Note: For MIMO feedback loops, the LoopShape, MinLoopGain, MaxLoopGain,
%   Margins, Sensitivity, and Rejection goals are sensitive to the relative
%   scaling of each SISO loop. SYSTUNE tries to balance the overall loop
%   transfer matrix while enforcing such goals. The optimal loop scaling
%   is cached in the tuned closed-loop model CL returned by SYSTUNE. For
%   consistency, VIEWGOAL(R,CL) takes this scaling into account and plots
%   the scaled open-loop response or sensitivity. To omit this scaling, use
%      VIEWGOAL(R,clearTuningInfo(CL))
%   Note that modifying CL may compromise the scaling validity.
%
%   See also evalGoal, TuningGoal, systune, genss, slTuner.

%   Copyright 2009-2017 The MathWorks, Inc.
error(message('Control:tuning:TuningReq13','viewGoal'))
