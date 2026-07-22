function view(Z,varargin)
%VIEW   Visualize data as a function of independent variables.
%
%   Arrays of generalized matrices can model quantities that vary as a
%   function of one or more independent variables. For example, GAINSURF
%   uses a GENMAT array to represent a gain value depending on one or more
%   scheduling variables. The VIEW function lets you visualize how this
%   gain varies as a function of the scheduling variables.
%
%   VIEW(M) takes a 1D or 2D array M of generalized matrices and graphs
%   the values of M on a 1D or 2D plot. This plot uses the independent
%   variable values in M.SamplingGrid when available, and otherwise uses
%   the indices along each array dimension as X and Y variables.
%
%   VIEW(M,XVAR) and VIEW(M,XVAR,YVAR) explicitly specify the names of the
%   X variable for 1D plots and X,Y variables for 2D plots. The strings
%   XVAR,YVAR must refer to sampling variables listed in M.SamplingGrid.
%
%   VIEW(M,XVAR,XDATA) and VIEW(M,XVAR,XDATA,YVAR,YDATA) also specify
%   the independent variable values XDATA and YDATA for 1D or 2D plots.
%   The SamplingGrid data is ignored in this case.
%
%   See also GAINSURF, GETVALUE, GENMAT.

%   Author(s): P. Gahinet
%   Copyright 1986-2024 The MathWorks, Inc.
if ~all(iosize(Z)==1)
    error(message('Control:lftmodel:genmatview1'))
end
ZName = inputname(1);
Z = squeeze(Z);
AS = getArraySize(Z);
if numel(AS)>2
    error(message('Control:lftmodel:genmatview2'))
end

% Parse and validate input list
ni = nargin;
XVar = '';  YVar = '';  XData = [];  YData = [];
if ni==4 || ni>5
    error(message('Control:lftmodel:genmatview3'))
elseif ni==3 && ischar(varargin{2})
    % Turn VIEW(Z,XVAR,YVAR) into VIEW(Z,XVAR,[],YVAR,[])
    ni = 5;
    varargin = {varargin{1},zeros(0,1),varargin{2},zeros(0,1)};
end
% Left with VIEW(Z), VIEW(Z,XVAR,XDATA), VIEW(Z,XVAR,XDATA,YVAR,YDATA)
if ni>1
    XVar = varargin{1};
    if ~ischar(XVar) || isempty(XVar)
        error(message('Control:lftmodel:genmatview4','X'))
    end
end
if ni>2
    XData = varargin{2};
    if ~(isnumeric(XData) && isreal(XData) && isvector(XData))
        error(message('Control:lftmodel:genmatview5','X'))
    end
end
if ni>3
    YVar = varargin{3};
    if ~ischar(YVar) || isempty(YVar)
        error(message('Control:lftmodel:genmatview4','Y'))
    end
    YData = varargin{4};
    if ~(isnumeric(YData) && isreal(YData) && isvector(YData))
        error(message('Control:lftmodel:genmatview5','Y'))
    end
end

% Create 1D or 2D plot
try
    if (ni==1 && any(AS==1)) || (ni>1 && isempty(YVar))
        localPlot1D(Z,ZName,XVar,XData)
    else
        localPlot2D(Z,ZName,XVar,XData,YVar,YData)
    end
catch ME
    throw(ME)
end

%-----------------------------------------------------------------------

function localPlot1D(Z,ZName,XVar,XData)
% Plot Z = F(X,Y) as a family of Z = F_Y(X) curves indexed by Y values.
% Note: The 1D case (Z is N-by-1 or 1-by-N) is treated as a single Y value.
AS = getArraySize(Z);

% Decompose sampling grid if any
[GX,GY] = ltipack.SamplingGrid.getGridVectors(Z.SamplingGrid);

% Swap dimensions so that X is always first array dimension of Z
if (isempty(XData) && ((isempty(XVar) && AS(2)>1) || isfield(GY,XVar))) || ...
        (~isempty(XData) && isequal(numel(XData)==AS,[false,true]))
    Z = permute(Z,[2 1]);
    AS = AS([2 1]);
    [GY,GX] = deal(GX,GY);
end

% Resolve XVAR
if isempty(XVar)
    % VIEW(Z) for 1D array
    F = fieldnames(GX);
    if isscalar(F)
        XVar = F{1};
    end
end

% Resolve XData
if isempty(XData)
    if isempty(XVar)
        % VIEW(Z) with unresolved XVAR: Use index as X values
        XData = 1:AS(1);
    elseif isfield(GX,XVar)
        % VIEW(Z,XVAR) with XVAR referencing a grid variable
        XData = GX.(XVar);
    else
        % VIEW(Z,XVAR) with XVAR not matching any grid variable
        error(message('Control:lftmodel:genmatview6',XVar))
    end
end
nx = numel(XData);
if nx<2 || nx~=AS(1)
    error(message('Control:lftmodel:genmatview7','X','X'))
end

% Sorting
Mv = reshape(getValue(Z),AS);
[XData,is] = sort(XData);
Mv = Mv(is,:);

% Create plot
ax = gca;
cla(ax)
h = plot(XData,Mv);
xlabel(XVar)
ylabel(ZName)
grid on
if AS(2)>1
    % Add data tips
    if isequal(GY,struct)
        GY = struct('Y',1:AS(2));
    end
    for ct=1:AS(2)
        h(ct).DataTipTemplate.DataTipRows = localGetDataTipTextRow(GY,ct);
    end

    % Enable data tip interaction (only) on axes
    ax.Interactions = dataTipInteraction(SnapToDataVertex='off');

    % Add listener on axes to delete existing data tips (note that adding a
    % ButtonDownFcn callback disables all interactions)
    addlistener(ax,'Hit', @(x,y) localBDF(ax));
end

%--------------

function localPlot2D(Z,ZName,XVar,XData,YVar,YData)
% Plot Z = F(X,Y) as a surface
AS = getArraySize(Z);
NoData = (isempty(XData) && isempty(YData));

% Decompose sampling grid if any
[GX,GY] = ltipack.SamplingGrid.getGridVectors(Z.SamplingGrid);

% Swap dimensions so that X is always first array dimension of Z
if (NoData && isfield(GY,XVar) && isfield(GX,YVar)) || ...
        (~NoData && isequal([numel(YData) numel(XData)],AS))
    Z = permute(Z,[2 1]);
    AS = AS([2 1]);
    [GY,GX] = deal(GX,GY);
end

% Resolve XVAR and YVAR
if isempty(XVar)
    % VIEW(Z) for 2D array
    F = fieldnames(GX);
    if isscalar(F)
        XVar = F{1};
    end
    F = fieldnames(GY);
    if isscalar(F)
        YVar = F{1};
    end
end

% Resolve XData and YData
if NoData
    if isempty(XVar)
        % VIEW(Z) with unresolved XVAR: Use index as X values
        XData = 1:AS(1);
    elseif isfield(GX,XVar)
        % VIEW(Z,XVAR,YVAR) with XVAR referencing a grid variable
        XData = GX.(XVar);
    else
        % VIEW(Z,XVAR,YVAR) with XVAR not matching any grid variable
        error(message('Control:lftmodel:genmatview6',XVar))
    end
    if isempty(YVar)
        % VIEW(Z) with unresolved YVAR: Use index as Y values
        YData = 1:AS(2);
    elseif isfield(GY,YVar)
        % VIEW(Z,XVAR,YVAR) with YVAR referencing a grid variable
        YData = GY.(YVar);
    else
        % VIEW(Z,XVAR,YVAR) with YVAR not matching any grid variable
        error(message('Control:lftmodel:genmatview6',YVar))
    end
end
nx = numel(XData);
if nx<2 || nx~=AS(1)
    error(message('Control:lftmodel:genmatview7','X','X'))
end
ny = numel(YData);
if ny<2 || ny~=AS(2)
    error(message('Control:lftmodel:genmatview7','Y','Y'))
end

% Sorting
Mv = reshape(getValue(Z),AS);
[XData,isX] = sort(XData);
[YData,isY] = sort(YData);
[XData,YData] = ndgrid(XData,YData);
Mv = Mv(isX,isY);
cla;
surf(XData,YData,Mv);
xlabel(XVar)
ylabel(YVar)
zlabel(ZName)
grid on


%-----------------------
function row = localGetDataTipTextRow(GY,m)
f = fieldnames(GY);
nf = numel(f);
for ct = 1:nf
    row(ct) = dataTipTextRow(f{ct},@(x) GY.(f{ct})(m),'%0.3g'); %#ok<AGROW>
end

function localBDF(ax)
% Axes Hit Listener function
fig = ancestor(ax,'figure');
if strcmp(get(fig,'SelectionType'),'normal')
    % Find and delete all data tips
    allDataTips = findall(ax,'Type','datatip');
    delete(allDataTips);
end