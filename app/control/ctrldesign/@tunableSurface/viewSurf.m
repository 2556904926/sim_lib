function viewSurf(blk,varargin)
%VIEWSURF  Visualize gain surface.
%
%   VIEWSURF plots a gain surface (see tunableSurface) depending on one or
%   two scheduling variables. The gain must be scalar valued.
%
%   For a 1D gain surface GS:
%
%   VIEWSURF(GS) plots the gain as a function of the scheduling variable.
%   The gain is evaluated at the design points specified in GS.SamplingGrid.
%
%   VIEWSURF(GS,XVAR,XDATA) evaluates the gain formula at the scheduling
%   variable values XDATA. The string XVAR must match the scheduling
%   variable name as specified in GS.SamplingGrid.
%
%   For a 2D gain surface GS:
%
%   VIEWSURF(GS) creates a surface plot of the gain as a function of the
%   scheduling variables. The design points GS.SamplingGrid must lie on a
%   rectangular grid.
%
%   VIEWSURF(GS,XVAR,XDATA,YVAR,YDATA) evaluates the gain formula over the
%   grid NDGRID(XDATA,YDATA) of scheduling variable values. The strings
%   XVAR,YVAR must match the scheduling variable names in GS.SamplingGrid.
%   The design points need not lie on a rectangular grid.
%
%   VIEWSURF(GS,XVAR,XDATA) creates a 1D plot of the gain surface GS using
%   the scheduling variable XVAR and the values XDATA along the x-axis.
%   This plot shows a parametric family of curves with one curve per value
%   of the other scheduling variable. This option is available only when
%   the design points lie on a rectangular grid.
%
%   See also evalSurf, tunableSurface.

%   Copyright 1986-2024 The MathWorks, Inc.
narginchk(1,5)
ni = nargin-1;
if rem(ni,2)~=0
    error(message('Control:general:InvalidSyntaxForCommand','viewSurf','viewSurf'))
elseif ~all(iosize(blk)==1)
    error(message('Control:lftmodel:viewSurf1'))
end

GSVars = getVariable(blk.SamplingGrid_);
switch blk.nVar_
    case 1
        % 1-D gain surface
        switch ni
            case 0
                XVar = GSVars{1};
                XData = [];
            case 2
                XVar = varargin{1};
                XData = varargin{2};
            otherwise
                error(message('Control:lftmodel:viewSurf3'))
        end
        try
            localPlot1D(blk,XVar,XData)
        catch ME
            throw(ME)
        end

    case 2
        % 2-D gain surface
        switch ni
            case 0
                XVar = GSVars{1};  YVar = GSVars{2};
                XData = [];  YData = [];
            case 2
                XVar = varargin{1};   YVar = '';
                XData = varargin{2};
            case 4
                XVar = varargin{1};  YVar = varargin{3};
                XData = varargin{2};  YData = varargin{4};
        end
        try
            if isempty(YVar)
                localPlot1dot5D(blk,XVar,XData)
            else
                localPlot2D(blk,XVar,XData,YVar,YData)
            end
        catch ME
            throw(ME)
        end

    otherwise
        error(message('Control:lftmodel:viewSurf2'))
end

%------------------

function localPlot1D(blk,XVar,XData)
% 1D plot of 1D gain schedule
if ~strcmp(XVar,getVariable(blk.SamplingGrid_))
    error(message('Control:lftmodel:viewSurf4'))
elseif isempty(XData)
    XData = blk.SamplingGrid.(XVar);
elseif ~(isnumeric(XData) && isreal(XData) && isvector(XData))
    error(message('Control:lftmodel:viewSurf6'))
end
XData = sort(XData(:));
ZData = evalSurf(blk,XData);
cla(gca)
plot(XData,ZData);
xlabel(XVar)
ylabel(blk.Name)
title(sprintf('Gain %s(%s)',blk.Name,XVar))
grid on


function localPlot2D(blk,XVar,XData,YVar,YData)
% 2D plot of 2D gain schedule
[~,~,is] = intersect(getVariable(blk.SamplingGrid_),{XVar YVar},'stable');
if numel(is)<2
    error(message('Control:lftmodel:viewSurf4'))
end
% Fill in grid vectors
if isempty(XData)
    % GS must be defined on a rectangular grid
    GridInfo = ltipack.SamplingGrid.getGridStructure(blk.SamplingGrid);
    GV = GridInfo.GridVectors;
    if numel(GV)~=2
        error(message('Control:lftmodel:viewSurf5'))
    end
    % Note: GV always lists variables in same order as SamplingGrid
    GV(is,:) = cat(1,GV{:});
    XData = GV{1,2};   YData = GV{2,2};  % goes with XVar,YVar
elseif ~(isnumeric(XData) && isreal(XData) && isvector(XData) &&...
        isnumeric(YData) && isreal(YData) && isvector(YData))
    error(message('Control:lftmodel:viewSurf6'))
end
XData = sort(XData(:));
YData = sort(YData(:));
% Evaluate surface
XY = {XData,YData};
ZData = permute(evalSurf(blk,XY{is}),is);
% Plot surface
cla;
[XData,YData] = ndgrid(XData,YData);
surf(XData,YData,ZData);
xlabel(XVar)
ylabel(YVar)
zlabel(blk.Name)
title(sprintf('Gain %s(%s,%s)',blk.Name,XVar,YVar))
grid on

%-------------------
function localPlot1dot5D(blk,XVar,XData)
% 1D plot of 2D gain surface
isX = strcmp(XVar,getVariable(blk.SamplingGrid_));
if ~any(isX)
    error(message('Control:lftmodel:viewSurf4'))
end
% Verify the grid is rectangular
GridInfo = ltipack.SamplingGrid.getGridStructure(blk.SamplingGrid);
GV = GridInfo.GridVectors;
if numel(GV)~=2
    error(message('Control:lftmodel:viewSurf5'))
end
% Note: GV always lists variables in same order as SamplingGrid
GV = cat(1,GV{:});
if isempty(XData)
    XData = GV{isX,2};
elseif ~(isnumeric(XData) && isreal(XData) && isvector(XData))
    error(message('Control:lftmodel:viewSurf6'))
end
XData = sort(XData(:));
YVar = GV{~isX,1};
YData = GV{~isX,2};
YData = sort(YData(:));
% Evaluate gain, keeping XVar as first dimension
if isX(1)
    ZData = evalSurf(blk,XData,YData);
else
    ZData = evalSurf(blk,YData,XData)';
end
% Create plot
ax = gca;
cla(ax)
h = plot(XData,ZData);
xlabel(XVar)
ylabel(blk.Name)
title(sprintf('Gain %s(%s)',blk.Name,XVar))
grid on
for ct=1:numel(h)
    % Set DataTipTemplate on lines
    h(ct).DataTipTemplate.DataTipRows = dataTipTextRow(YVar,@(x) YData(ct),'%0.3g');

end

% Enable data tip interaction (only) on axes
ax.Interactions = dataTipInteraction(SnapToDataVertex='off');

% Add listener on axes to delete existing data tips (note that adding a
% ButtonDownFcn callback disables all interactions)
addlistener(ax,'Hit', @(x,y) localBDF(ax));

%-------------------
function localBDF(ax)
% Axes Hit Listener function
fig = ancestor(ax,'figure');
if strcmp(get(fig,'SelectionType'),'normal')
    % Find and delete all data tips
    allDataTips = findall(ax,'Type','datatip');
    delete(allDataTips);
end