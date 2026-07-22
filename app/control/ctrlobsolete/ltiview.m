function [ViewFig,ViewObj] = ltiview(varargin)
%LTIVIEW  Opens the LTI Viewer GUI.
%
%   LTIVIEW opens an empty LTI Viewer.  The LTI Viewer is an interactive
%   graphical user interface (GUI) for analyzing the time and frequency
%   responses of linear systems and comparing such systems.  See LTIMODELS
%   for details on how to model linear systems in the Control System Toolbox.
%
%   LTIVIEW(SYS1,SYS2,...,SYSN) opens an LTI Viewer containing the step
%   response of the LTI models SYS1,SYS2,...,SYSN.  You can specify a
%   distinctive color, line style, and marker for each system, as in
%      sys1 = rss(3,2,2);
%      sys2 = rss(4,2,2);
%      ltiview(sys1,'r-*',sys2,'m--');
%
%   LTIVIEW(PLOTTYPE,SYS1,SYS2,...,SYSN) further specifies which responses
%   to plot in the LTI Viewer.  PLOTTYPE may be any of the following strings
%   (or a combination thereof):
%        1) 'step'           Step response
%        2) 'impulse'        Impulse response
%        3) 'lsim'           Linear simulation plot
%        4) 'initial'        Initial condition plot
%        5) 'bode'           Bode diagram
%        6) 'bodemag'        Bode Magnitude diagram
%        7) 'nyquist'        Nyquist plot
%        8) 'nichols'        Nichols plot
%        9) 'sigma'          Singular value plot
%       10) 'pzmap'          Pole/Zero map
%       11) 'iopzmap'        I/O Pole/Zero map
%   For example,
%      ltiview({'step';'bode'},sys1,sys2)
%   opens an LTI Viewer showing the step and Bode responses of the LTI
%   models SYS1 and SYS2.
%
%   LTIVIEW(PLOTTYPE,SYS,EXTRAS) allows you to specify the additional
%   input arguments supported by the various response types.
%   See the HELP text for each response type for more details on the
%   format of these extra arguments. Note that specifying plot or data
%   options is not supported. Use the Preferences dialog to modify plots
%   after launching the Linear System Analyzer.If an LSIM plot is specified
%   without additional input arguments, the Linear Simulation Tool
%   automatically opens so that initial states and/or driving inputs
%   can be assigned interactively.
%
%   H = LTIVIEW(...) opens an LTI Viewer and returns the handle to the 
%   LTI Viewer figure.
%
%   Two additional options are available for manipulating previously
%   opened LTI Viewers:
%
%   LTIVIEW('clear',VIEWERS) clears the plots and data from the LTI
%   Viewers with handles VIEWERS.
%
%   LTIVIEW('current',SYS1,SYS2,...,SYSN,VIEWERS) adds the responses
%   of the systems SYS1,SYS2,... to the LTI Viewers with handles VIEWERS.
%
%   See also STEP, IMPULSE, LSIM, INITIAL, LTI/IOPZMAP, PZMAP,
%            BODE, LTI/BODEMAG, NYQUIST, NICHOLS, SIGMA.

%   Authors: Kamesh Subbarao
%   Copyright 1986-2014 The MathWorks, Inc.
ni = nargin;
ArgNames = cell(ni,1);
for ct=1:ni
   ArgNames(ct) = {inputname(ct)};
end
% Assign vargargin names to systems if systems do not have a name
varargin = argname2sysname(varargin,ArgNames);
if nargout
   [ViewFig,ViewObj] = linearSystemAnalyzer(varargin{:});
else
   linearSystemAnalyzer(varargin{:});
end