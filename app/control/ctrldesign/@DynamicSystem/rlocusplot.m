function h0 = rlocusplot(varargin)
%RLOCUSPLOT  Evans root locus.
%
%   RLOCUSPLOT, an extension of RLOCUS, provides a command line interface
%   for customizing the plot appearance.
%
%   RLOCUSPLOT(SYS) computes and plots the root locus of the single-input,
%   single-output system system SYS.  The root locus plot is used to
%   analyze the negative feedback loop
%
%                     +-----+
%         ---->O----->| SYS |----+---->
%             -|      +-----+    |
%              |                 |
%              |       +---+     |
%              +-------| K |<----+
%                      +---+
%
%   and shows the trajectories of the closed-loop poles when the feedback
%   gain K varies from 0 to Inf.  RLOCUS automatically generates a set of
%   positive gain values that produce a smooth plot.
%
%   RLOCUSPLOT(SYS,K) uses a user-specified vector K of gain values.
%
%   RLOCUSPLOT(SYS1,SYS2,...) draws the root loci of multiple LTI models
%   SYS1, SYS2,... on a single plot.  You can specify a color, line style,
%   and marker for each model, as in
%      rlocusplot(sys1,'r',sys2,'y:',sys3,'gx').
%
%   RLOCUSPLOT(AX,...) plots into the axes with handle AX.
%
%   RLOCUSPLOT(..., PLOTOPTIONS) plots root locus with the options
%   specified in PLOTOPTIONS. See PZOPTIONS for more detail.
%
%   H = RLOCUSPLOT(...) returns the handle to the root locus plot.
%   You can use this handle to customize the plot with the GETOPTIONS and
%   SETOPTIONS commands.  See PZOPTIONS for a list of available plot
%   options.
%
%   Example:
%       sys = rss(3);
%       h = rlocusplot(sys);
%       p = getoptions(h); % get options for plot
%       p.Title.String = 'My Title'; % change title in options
%       setoptions(h,p); % apply options to plot
%
%   See also RLOCUS, PZOPTIONS, WRFC/SETOPTIONS, WRFC/GETOPTIONS.

%   Author(s): J.N. Little, A.C.W.Grace, P. Gahinet, A. DiVergilio
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
    if ~isempty(OptionsObject) && ~isa(OptionsObject,'plotopts.PZOptions')
        error('Controllib:plots:InvalidPlotOptions',...
            getString(message('Controllib:plots:InvalidPlotOptions','pzoptions')));
    end
    [sysList,GainVector] = DynamicSystem.checkRootLocusInputs(sysList,Extras);
    % Warn about and skip empty systems
    isEmptySys = arrayfun(@(x) isempty(x.System),sysList);
    if all(isEmptySys)
        error(message('Controllib:plots:PlotAllEmptyModels'))
    elseif any(isEmptySys)
        warning(message('Control:analysis:PlotEmptyModel'))
    end
    sysList = sysList(~isEmptySys);

    % Create axes if needed

    % Create rlocusplot using control charts
        if isa(hParent,'matlab.graphics.axis.Axes') || isa(hParent,'matlab.ui.control.UIAxes')
            gridLines = findall(hParent,'Tag','CSTgridLines');
            customGrid = ~isempty(gridLines);
            if customGrid
                gridOptions = gridLines(1).UserData.Options;
                gridType = gridLines(1).UserData.Type;
            end
            delete(gridLines);
        elseif isempty(hParent)
            customGrid = false;
            fig = get(groot,'CurrentFigure');
            if ~isempty(fig)
                ax = fig.CurrentAxes;
                if ~isempty(ax)
                    gridLines = findall(ax,'Tag','CSTgridLines');
                    customGrid = ~isempty(gridLines);
                    if customGrid
                        gridOptions = gridLines(1).UserData.Options;
                        gridType = gridLines(1).UserData.Type;
                    end
                    delete(gridLines);
                end
            end
        else
            customGrid = false;
        end
        h = controllib.chart.internal.utils.ltiplot("rlocus",hParent,...
            SystemData=sysList,Parameter=GainVector,Options=OptionsObject);
        if customGrid
            switch gridType
                case "s-plane"
                    sgrid(gridOptions.Damping,gridOptions.Frequency);
                case "z-plane"
                    zgrid(gridOptions.Damping,gridOptions.Frequency,gridOptions.SampleTime);
            end
        end
        if nargout
            h0 = h;
        end
catch ME
    throw(ME)
end

