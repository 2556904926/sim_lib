function h0 = nicholsplot(varargin)
%NICHOLSPLOT  Nichols frequency response of linear systems.
%
%   NICHOLSPLOT, an extension of NICHOLS, provides a command line interface
%   for customizing the plot appearance.
%
%   NICHOLSPLOT(SYS) draws the Nichols plot of the dynamic system SYS.  The
%   frequency range and number of points are chosen automatically.  See
%   BODE for details on the notion of frequency in discrete-time.
%
%   NICHOLSPLOT(SYS,{WMIN,WMAX}) draws the Nichols plot for frequencies
%   between WMIN and WMAX (in radians/timeunit, where timeunit is specified
%   in SYS.TimeUnit).
%
%   NICHOLSPLOT(SYS,W) uses the user-supplied vector W of frequencies (in
%   radians/timeunit, where timeunit is specified in SYS.TimeUnit) at which
%   the Nichols response is to be evaluated. See LOGSPACE to generate
%   logarithmically spaced frequency vectors.
%
%   NICHOLSPLOT(SYS1,SYS2,...,W) plots the Nichols plot of multiple LTI
%   models SYS1,SYS2,... on a single plot.  The frequency vector W
%   is optional.  You can also specify a color, line style, and marker
%   for each system, as in
%      nicholsplot(sys1,'r',sys2,'y--',sys3,'gx').
%
%   NICHOLSPLOT(AX,...) plots into the axes with handle AX.
%
%   NICHOLSPLOT(..., PLOTOPTIONS) plots the Nichols chart with the options
%   specified in PLOTOPTIONS. See NICHOLSOPTIONS for more details.
%
%   H = NICHOLSPLOT(...) returns the handle to the Nichols plot. You can
%   use this handle to customize the plot with the GETOPTIONS and
%   SETOPTIONS commands.  See NICHOLSOPTIONS for a list of available plot
%   options.
%
%   Example:
%       sys = rss(5);
%       h = nicholsplot(sys);
%       % Change units to Hz
%       setoptions(h,'FreqUnits','Hz');
%
%   See also NICHOLS, NICHOLSOPTIONS, WRFC/SETOPTIONS, WRFC/GETOPTIONS, DYNAMICSYSTEM.

%   Authors: P. Gahinet, B. Eryilmaz
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
    [sysList,Extras,OptionsObject] = DynamicSystem.parseRespFcnInputs(varargin,ArgNames);
    if ~isempty(OptionsObject) && ~isa(OptionsObject,'plotopts.NicholsOptions')
        error('Controllib:plots:InvalidPlotOptions',...
            getString(message('Controllib:plots:InvalidPlotOptions','nicholsoptions')));
    end
    [sysList,w] = DynamicSystem.checkBodeInputs(sysList,Extras);
    TimeUnits = sysList(1).System.TimeUnit; % first system determines units
    % Warn about and skip empty systems
    isEmptySys = arrayfun(@(x) isempty(x.System),sysList);
    if all(isEmptySys)
        error(message('Controllib:plots:PlotAllEmptyModels'))
    elseif any(isEmptySys)
        warning(message('Control:analysis:PlotEmptyModel'))
    end
    sysList = sysList(~isEmptySys);
    % Check time unit consistency when specifying w or {wmin,wmax}
    if ~(isempty(w) || ltipack.hasMatchingTimeUnits(TimeUnits,sysList.System))
        error(message('Control:analysis:AmbiguousFreqSpec'))
    end

    % Create plot

    % Create nicholsplot using control charts
    if isa(hParent,'matlab.graphics.axis.Axes') || isa(hParent,'matlab.ui.control.UIAxes')
        gridLines = findall(hParent,'Tag','CSTgridLines');
        customGrid = ~isempty(gridLines);
        delete(gridLines);
    elseif isempty(hParent)
        customGrid = false;
        fig = get(groot,'CurrentFigure');
        if ~isempty(fig)
            ax = fig.CurrentAxes;
            if ~isempty(ax)
                gridLines = findall(ax,'Tag','CSTgridLines');
                customGrid = ~isempty(gridLines);
                delete(gridLines);
            end
        end
    else
        customGrid = false;
    end
    h = controllib.chart.internal.utils.ltiplot("nichols",hParent,...
        SystemData=sysList,Frequency=w,Options=OptionsObject);
    if customGrid
        ngrid();
    end
    if nargout
        h0 = h;
    end
catch ME
    throw(ME)
end
