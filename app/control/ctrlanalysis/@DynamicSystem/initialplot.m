function h0 = initialplot(varargin)
%INITIALPLOT  Initial condition response of state-space models.
%
%   INITIALPLOT, an extension of INITIAL, provides a command line interface
%   for customizing the plot appearance.
%
%   INITIALPLOT(SYS,XINIT) plots the unforced response from the initial
%   state XINIT. The time range and number of points are chosen automatically.
%
%   INITIALPLOT(SYS,XINIT,TFINAL) simulates the time response from t=0 to
%   the final time t=TFINAL (expressed in the time units specified in
%   SYS.TimeUnit). INITIALPLOT(SYS,XINIT,[T0 TFINAL]) simulates from t=T0
%   to t=TFINAL.
%
%   INITIALPLOT(SYS,XINIT,T) uses the time vector T for simulation (expressed
%   in the time units of SYS). T must be equisampled of the form tS:dt:tF
%   with dt equal to the sample time Ts for discrete-time models.
%
%   INITIALPLOT(SYS,XINIT,T,P) specifies the parameter trajectory P for
%   LPV models. See INITIAL for details.
%
%   INITIALPLOT(SYS1,SYS2,...,XINIT,T,P) plots the response of multiple LTI
%   models SYS1,SYS2,... on a single plot. The last two arguments are
%   optional. You can also specify a color, line style, and marker for each
%   system, as in
%      initialplot(sys1,'r',sys2,'y--',sys3,'gx',x0).
%
%   INITIALPLOT(AX,...) plots into the axes with handle AX.
%
%   INITIALPLOT(..., PLOTOPTIONS) plots the initial condition response
%   with the options specified in PLOTOPTIONS. See TIMEOPTIONS for
%   more detail.
%
%   H = INITIALPLOT(...) returns the handle to the initial condition
%   response plot. You can use this handle to customize the plot with
%   the GETOPTIONS and SETOPTIONS commands. See TIMEOPTIONS for a list
%   of available plot options.
%
%   Example:
%       sys = rss(3);
%       h = initialplot(sys,[1,1,1]);
%       p = getoptions(h); % get options for plot
%       p.Title.String = 'My Title'; % change title in options
%       setoptions(h,p); % apply options to plot
%
%   See also INITIAL, TIMEOPTIONS, WRFC/SETOPTIONS, WRFC/GETOPTIONS,
%   SS, SPARSS, LTVSS, LPVSS, DYNAMICSYSTEM.

%   Copyright 1986-2024 The MathWorks, Inc.

% Get argument names
for ct = length(varargin):-1:1
    ArgNames(ct,1) = {inputname(ct)};
end

% Parse input list
% Check for axes argument
if ishghandle(varargin{1})
    hParent = varargin{1};
    varargin(1) = [];
    ArgNames(1) = [];
else
    hParent = [];
end

try
    [sysList,ParamList,PlotOptions] = DynamicSystem.parseRespFcnInputs(varargin,ArgNames);
    if ~isempty(PlotOptions) && ~isa(PlotOptions,'plotopts.TimeOptions')
        error(getString(message('Controllib:plots:InvalidPlotOptions','timeoptions')));
    end
    [sysList,t,p,Config] = DynamicSystem.checkInitialInputs(sysList,ParamList,true);
    TimeUnits = sysList(1).System.TimeUnit;
    % Warn about and skip systems with no outputs or no models
    isEmptySys = arrayfun(@(x) isEmptySystem(x.System),sysList);
    if all(isEmptySys)
        error(message('Controllib:plots:PlotAllEmptyModels'))
    elseif any(isEmptySys)
        warning(message('Control:analysis:PlotEmptyModel'))
    end
    sysList = sysList(~isEmptySys);
    % Check time unit consistency when specifying T or Tf
    if ~(isempty(t) || ltipack.hasMatchingTimeUnits(TimeUnits,sysList.System))
        error(message('Control:analysis:AmbiguousTimeSpec'))
    end

    % Create plot

    % Create initialplot using control charts
        h = controllib.chart.internal.utils.ltiplot("initial",hParent,...
            SystemData=sysList,Time=t,Parameter=p,Config=Config,...
            Options=PlotOptions);
        if nargout
            h0 = h;
        end
catch ME
    throw(ME)
end


%-------------- local functions -----------
function boo = isEmptySystem(sys)
s = size(sys);
boo = any(s([1 3:end])==0);
