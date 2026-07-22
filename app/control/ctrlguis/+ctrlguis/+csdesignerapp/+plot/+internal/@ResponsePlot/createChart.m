function hChart = createChart(this,PlotType,varargin)
% createChart  Creates one of the built-in controllib.chart

%   Copyright 2023 The MathWorks, Inc.

%% REVISIT
style = controllib.chart.internal.options.ResponseStyle;
style.SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;

%%
[nominalSys,sys] = getResponseValue(this);
nominalIndex = getNominalIndex(this.Response);

% Create seed axes
Ax = axes('Parent',this.Figure);
this.Figure.AutoResizeChildren = 'off';

%Create plot object
hChart = controllib.chart.internal.utils.ltiplot(PlotType,Ax,NInputs=length(nominalSys.InputName),...
    NOutputs=length(nominalSys.OutputName),Visible='off');
hChart.ResponseDataExceptionMessage = "none";


% Add one response per system
addResponseToChart(this,hChart,sys,NominalIndex=nominalIndex);
hChart.Visible = 'on';

response = hChart.Responses(1);
if response.NResponses > 1 
    if any(strcmp(hChart.Type,{'step','impulse'}))
        this.IsMultiModel = true;
        dataFcn = @controllib.chart.internal.data.characteristics.TimeBoundaryRegionData;
        viewFcn = @controllib.chart.internal.view.characteristic.TimeInputOutputBoundaryRegionView;
        registerCustomCharacteristic(hChart,dataFcn,viewFcn);
    elseif strcmp(hChart.Type,'bode')
        this.IsMultiModel = true;
        dataFcn = @controllib.chart.internal.data.characteristics.BodeBoundaryRegionData;
        viewFcn = @controllib.chart.internal.view.characteristic.BodeBoundaryRegionView;
        registerCustomCharacteristic(hChart,dataFcn,viewFcn);
    end
end

% Requirements menu
if issiso(this.Response)
    hMenu = uimenu(Parent=[], ...
                   Label=getString(message('Control:designerapp:menuDesignRequirements')),...
                   Tag='DesignRequirement');
    if strcmp(hChart.Type,"pzmap") || strcmp(hChart.Type,"iopzmap")
        menuTag = "systems";
    else
        menuTag = "characteristics";
    end
    addMenu(hChart,hMenu,Below=menuTag,CreateNewSection=true);
    
    % Constraint submenus
    uimenu(hMenu, ...
           Label=getString(message('Control:designerapp:menuNewEllipsis')), ...
           Tag='NewRequirement', ...
           MenuSelectedFcn=@(es,ed) LocalDesignConstr(this,hChart,'new'));
    uimenu(hMenu, ...
           Label=getString(message('Control:designerapp:menuEditEllipsis')), ...
           Tag='EditRequirement', ...
           MenuSelectedFcn=@(es,ed) LocalDesignConstr(this,hChart,'edit'));
    
    %Hide menu if view does not support requirements
    if isempty(getRequirementList(hChart))
        set(hMenu,'Visible','off')
    else
        set(hMenu,'Visible','on')
    end
end

% Multi-model menu
if any(strcmp(PlotType,{'step','impulse','bode'}))
    hMenu = localCreateMultiModelMenu(this,hChart);
    addMenu(hChart,hMenu,Below="characteristics");
    this.MultiModelMenu = hMenu;
elseif any(strcmp(PlotType,{'pzmap'}))
    hMenu = localCreateSingleMultiModelMenu(this,hChart);
    addMenu(hChart,hMenu,Below="systems");
    this.MultiModelMenu = hMenu;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     UTILITIES                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hMenu = localCreateMultiModelMenu(this,hChart)
hMenu = uimenu(Parent=[],...
           Label=ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
           Tag='MultiModel');
hb = uimenu(hMenu,Label=ctrlMsgUtils.message('Control:compDesignTask:strMultiModelBounds'));
hs = uimenu(hMenu,Label=ctrlMsgUtils.message('Control:compDesignTask:strMultiModelIndividualResponses'));

m = struct(...
    'BoundsMenu',hb,...
    'SystemsMenu',hs);

% Set Callbacks
hb.MenuSelectedFcn = @(es,ed)localToggleBoundsMenu(es,hChart,m,getNominalIndex(this.Response));
hs.MenuSelectedFcn = @(es,ed)LocalToggleIndividualSystemsMenu(es,hChart,m,getNominalIndex(this.Response));

% Show only nominal response
arrayVisible = false(size(hChart.Responses(1).ArrayVisible));
arrayVisible(getNominalIndex(this.Response)) = true;
set(hChart.Responses,"ArrayVisible",arrayVisible);
set(hChart.Responses,"NominalIndex",getNominalIndex(this.Response));
end

function hMenu = localCreateSingleMultiModelMenu(this,hChart)
hMenu = uimenu(Parent=[],...
   Label=ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
   Tag='MultiModel');


% Adds menu items to Multimodel menu
hb = uimenu(hMenu,'Label',ctrlMsgUtils.message('Control:compDesignTask:strShow'));
m = struct('ShowMenu',hb);
    
hb.MenuSelectedFcn = @(es,ed) LocalToggleShowMenu(es,hChart,m,getNominalIndex(this.Response));

LocalShowMenuSetCheck(this, m, hChart)

end


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalDesignConstr %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalDesignConstr(Viewer, View, ActionType)
% Opens dialogs to add/edit design constraints
designConstr(Viewer,View,ActionType)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleBoundsMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function localToggleBoundsMenu(hSrc,hChart,m,nominalIndex)
% Callbacks for showing/hiding bounds for multi-model display
if controllib.chart.internal.utils.isChart(hChart)
    if hSrc.Checked
        % Hide all individual responses and bounds (note that 'Checked'
        % shows previous value and has been toggled)
        m.BoundsMenu.Checked = 'off';
        arrayVisible = false(size(hChart.Responses(1).ArrayVisible));
        arrayVisible(nominalIndex) = true;
        set(hChart.Responses,"ArrayVisible",arrayVisible);
        set(hChart.Responses,"NominalIndex",nominalIndex);
        setCharacteristicVisibility(hChart,"BoundaryRegion",Visible=false);
    else
        % Hide individual responses (only show nominal)
        m.SystemsMenu.Checked = 'off';
        arrayVisible = false(size(hChart.Responses(1).ArrayVisible));
        arrayVisible(nominalIndex) = true;
        hChart.Responses(1).ArrayVisible = arrayVisible;
        set(hChart.Responses,"NominalIndex",nominalIndex);
        
        % Show bounds
        m.BoundsMenu.Checked = 'on';
        setCharacteristicVisibility(hChart,"BoundaryRegion",Visible=true);
    end
else
    if hSrc.Checked
        hChart.hideCharacteristic('MultipleModelView');
    else
        hChart.Options.MultiModelDisplayType = 'Bounds';
        if LocalIsMultiModelVisible(hChart)
            LocalUncertainSetCheck([], m, hChart)
        else
            if hasCharacteristic(hChart,'MultipleModelView')
                hChart.showCharacteristic('MultipleModelView');
            end
        end
    end

end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleSystemsMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalToggleIndividualSystemsMenu(hSrc,hChart,m,nominalIndex)
% Callbacks for showing/hiding individual responses for multi-model display
if controllib.chart.internal.utils.isChart(hChart)
    if hSrc.Checked
        % Hide all individual responses and bounds (note that 'Checked'
        % shows previous value and has been toggled)
        m.SystemsMenu.Checked = 'off';
        arrayVisible = false(size(hChart.Responses(1).ArrayVisible));
        arrayVisible(nominalIndex) = true;
        set(hChart.Responses,"ArrayVisible",arrayVisible);
        set(hChart.Responses,"NominalIndex",nominalIndex);
        setCharacteristicVisibility(hChart,"BoundaryRegion",Visible=false);
    else
        % Show individual responses
        m.SystemsMenu.Checked = 'on';
        set(hChart.Responses,"ArrayVisible",true(size(hChart.Responses(1).ArrayVisible)));
        set(hChart.Responses,"NominalIndex",nominalIndex);

        % Hide bounds
        m.BoundsMenu.Checked = 'off';
        setCharacteristicVisibility(hChart,"BoundaryRegion",Visible=false);
    end
else
    if strcmp(get(hSrc,'Checked'),'on')
        hChart.hideCharacteristic('MultipleModelView');
    else
        hChart.Options.MultiModelDisplayType = 'Systems';
        if LocalIsMultiModelVisible(hChart)
            LocalUncertainSetCheck([], m, hChart)
        else
            if hasCharacteristic(hChart,'MultipleModelView')
                hChart.showCharacteristic('MultipleModelView');
            end
        end
    end

end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalUncertainSetCheck %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalUncertainSetCheck(~, m, View)

isVisible = LocalIsMultiModelVisible(View);

if isVisible && strcmpi(View.Options.MultiModelDisplayType,'Bounds')
    set(m.BoundsMenu,'Checked','on')
else
    set(m.BoundsMenu,'Checked','off')
end

if isVisible  && strcmpi(View.Options.MultiModelDisplayType,'Systems')
    set(m.SystemsMenu,'Checked','on')
else
    set(m.SystemsMenu,'Checked','off')
end
end

function isVisible = LocalIsMultiModelVisible(View)

if controllib.chart.internal.utils.isChart(View)
    isVisible = ~isscalar(View.Responses.ArrayVisible);
else
    [b,idx] = hasCharacteristic(View,'MultipleModelView');

    if b
        isVisible = View.CharacteristicManager(idx).Visible;
    else
        isVisible = false;
    end
end
end


function LocalShowMenuSetCheck(~,m,View)
isVisible = LocalIsMultiModelVisible(View);
if isVisible
    set(m.ShowMenu,'Checked','on')
else
    set(m.ShowMenu,'Checked','off')
end
end

function LocalToggleShowMenu(hSrc,hChart,m,nominalIndex)
if strcmp(get(hSrc,'Checked'),'on')
    arrayVisible = false(size(hChart.Responses(1).ArrayVisible));
    arrayVisible(nominalIndex) = true;
    hChart.Responses(1).ArrayVisible = arrayVisible;
    m.ShowMenu.Checked = 'off';
else
    hChart.Responses(1).ArrayVisible = true(size(hChart.Responses(1).ArrayVisible));
    hChart.Responses(1).NominalIndex = nominalIndex;
    m.ShowMenu.Checked = 'on';
end
end


