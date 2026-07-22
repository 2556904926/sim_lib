function [svout,w] = sigma(varargin)
%SIGMA  Singular value plot of dynamic systems.
%
%   SIGMA(SYS) produces a singular value (SV) plot of the frequency response
%   of the dynamic system SYS. The frequency range and number of points are 
%   chosen automatically. See BODE for details on the notion of frequency 
%   in discrete time.
%
%   SIGMA(SYS,{WMIN,WMAX}) draws the SV plot for frequencies ranging between
%   WMIN and WMAX in radians/TimeUnit (relative to the time units specified in 
%   SYS.TimeUnit, the default being seconds).
%
%   SIGMA(SYS,W) uses the vector W of frequencies (in radians/TimeUnit) to
%   evaluate the frequency response. See LOGSPACE to generate logarithmically 
%   spaced frequency vectors.
%
%   SIGMA(SYS,W,TYPE) or SIGMA(SYS,[],TYPE) draws the following modified 
%   SV plots depending on the value of TYPE:
%          TYPE = 1     -->     SV of  inv(SYS)
%          TYPE = 2     -->     SV of  I + SYS
%          TYPE = 3     -->     SV of  I + inv(SYS) 
%   SYS should be a square system when using this syntax.
%
%   SIGMA(SYS1,SYS2,...,W,TYPE) draws the SV response of several systems
%   SYS1,SYS2,... on a single plot. The arguments W and TYPE are optional.
%   You can also specify a color, line style, and marker for each system, 
%   for example, 
%      sigma(sys1,'r',sys2,'y--',sys3,'gx').
%   
%   SV = SIGMA(SYS,W) and [SV,W] = SIGMA(SYS) return the singular values SV
%   of the frequency response (along with the frequency vector W if 
%   unspecified). No plot is drawn on the screen. The matrix SV has length(W) 
%   columns and SV(:,k) gives the singular values (in descending order) at 
%   the frequency W(k). The frequencies W are in rad/TimeUnit.
%
%   For additional graphical options for singular value plots, see SIGMAPLOT.
%
%   See also SIGMAPLOT, WCSIGMAPLOT, BODE, NICHOLS, NYQUIST, FREQRESP, LTIVIEW, DYNAMICSYSTEM.

%   Copyright 1986-2010 The MathWorks, Inc.

% Handle various calling sequences
if nargout>0
   % Call with output arguments
   try
      [sysList,Extras,PlotOptions] = DynamicSystem.parseRespFcnInputs(varargin);
      if ~isempty(PlotOptions)
         error(message('Control:analysis:NoPlotOptions'));
      end
      [sysList,wspec,type] = DynamicSystem.checkSigmaInputs(sysList,Extras);
   catch E
      throw(E)
   end
   sys = sysList(1).System;
   if (numel(sysList)>1 || numsys(sys)~=1)
      error(message('Control:analysis:RequiresSingleModelWithOutputArgs','sigma'))
   end
   
   % Compute frequency response
   [svout,w,FocusInfo] = sigmaresp_(sys,type,wspec);
   
   % For auto-generated W, make W(1) and W(end) entire decades
   if isempty(wspec) || iscell(wspec)
      userFocus = ltipack.getFreqFocus(wspec,sys.Ts,'log');
      [w,isel] = ltipack.util.roundFreqFocus(userFocus,FocusInfo.Focus,w);
      svout = svout(:,isel);
   end
   
else
   % Singular Values plot
   ni = nargin;
   ArgNames = cell(ni,1);
   for ct=1:ni
      ArgNames(ct) = {inputname(ct)};
   end
   % Assign vargargin names to systems if systems do not have a name
   varargin = argname2sysname(varargin,ArgNames);
   try
      sigmaplot(varargin{:});
   catch E
      throw(E)
   end
end
