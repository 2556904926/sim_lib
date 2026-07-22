function View = createView(this,PlotType,varargin)
%CREATEVIEW  Creates one of the built-in LTI plots.

%   Copyright 2015-2020 The MathWorks, Inc.

%% REVISIT
Preferences = cstprefs.tbxprefs;
Style = wavepack.wavestyle;
setstyle(Style,'LineStyle','-','Color','b');

%%
[NomValue,Value] = getResponseValue(this);
Systems = resppack.ltisource(NomValue, 'Name', NomValue.Name);
Systems.UncertainModel = Value;


% Create seed axes
Ax = axes('Parent',this.Figure);
disableDefaultInteractivity(Ax);
this.Figure.AutoResizeChildren = 'off';

% Create @respplot instance
PlotOptions = [];
Options = {};

%Create Plotoptions object
View = ltiplot(Ax,PlotType,NomValue.InputName,NomValue.OutputName,...
   PlotOptions,Preferences,Options{:});
% View.AxesGrid.EventManager = this.EventManager;
% View.AxesGrid.LayoutManager = 'off';
View.DataExceptionWarning = 'off';

%Info for multi-model display
View.Options.MultiModelDisplayType = 'Systems';

% Add one response per system
% RE: Define Viewer-specific DataFcn to derive data from lti sources
this.createResponse(View,Systems,Style,varargin{:});

% Add right-click menus
Menus = ltiplotmenu(View,PlotType);

PosInc = 2;
if any(strcmp(PlotType,{'step','impulse','bode'}))
    MMMenu = LocalAddMultiModelMenu(this,View);
    set(MMMenu,'Position',length(Menus.Group1)+PosInc)
    PosInc = PosInc+1;
elseif any(strcmp(PlotType,{'pzmap'}))
    MMMenu = LocalAddSingleMultiModelMenu(this,View);
    set(MMMenu,'Position',length(Menus.Group1)+PosInc)
    PosInc = PosInc+1;
end

% Requirements menu
if issiso(this.Response)
    hMenu = uimenu('Parent',View.AxesGrid.UIContextMenu, ...
        'Label', getString(message('Control:designerapp:menuDesignRequirements')),...
        'Tag', 'DesignRequirement');
    set(hMenu,'Position',length(Menus.Group1)+PosInc)
    % Constraint submenus
    uimenu(hMenu, ...
        'Label', getString(message('Control:designerapp:menuNewEllipsis')), ...
        'Tag','NewRequirement', ...
        'Callback', {@LocalDesignConstr this View 'new'});
    uimenu(hMenu, ...
        'Label', getString(message('Control:designerapp:menuEditEllipsis')), ...
        'Tag','EditRequirement', ...
        'Callback', {@LocalDesignConstr this View 'edit'});
    %Hide menu if view does not support requirements
    if isempty(View.newconstr)
        set(hMenu,'Visible','off')
    else
        set(hMenu,'Visible','on')
    end
end
% Set requirement color consistency
View.Options.RequirementColor = [250   250   210]/255;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     UTILITIES                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalDesignConstr %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalDesignConstr(~, ~, Viewer, View, ActionType)
% Opens dialogs to add/edit design constraints
designConstr(Viewer,View,ActionType)


%%%%%%%%%%%%%%%%%%%%%%
% LocalAddMultiModelMenu
%%%%%%%%%%%%%%%%%%%%%%
function  h = LocalAddMultiModelMenu(this,View)
% LocalAddMultiModelMenu adds the multi model menu
% to the right click menus of all the plots.

h = uimenu('Parent', View.AxesGrid.UIContextMenu,...
   'Label',ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
   'Tag','MultiModel');


% Adds menu items to Multimodel menu
hb = uimenu(h,'Label',ctrlMsgUtils.message('Control:compDesignTask:strMultiModelBounds'));
hs = uimenu(h,'Label',ctrlMsgUtils.message('Control:compDesignTask:strMultiModelIndividualResponses'));


m = struct(...
    'BoundsMenu',hb,...
    'SystemsMenu',hs);

% Set Callbacks
set(hb,'Callback',{@LocalToggleBoundsMenu View m})
set(hs,'Callback',{@LocalToggleSystemsMenu View m})
    
LocalUncertainSetCheck(this, m, View)

L = handle.listener(View, ...
    View.findprop('CharacteristicManager'),'PropertyPostSet', ...
    @(x,y) LocalUncertainSetCheck(this,m,View));

set(hb,'UserData',L)  % Anchor listeners for persistency


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleBoundsMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalToggleBoundsMenu(hSrc,~,View,m)
% Callbacks for Stability Margins submenu (hSrc = menu handle)
if strcmp(get(hSrc,'Checked'),'on')
    View.hideCharacteristic('MultipleModelView');
else
    View.Options.MultiModelDisplayType = 'Bounds';
    if LocalIsMultiModelVisible(View)
        LocalUncertainSetCheck([], m, View)
    else
        if hasCharacteristic(View,'MultipleModelView')
            View.showCharacteristic('MultipleModelView');
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleSystemsMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalToggleSystemsMenu(hSrc,~,View,m)
% Callbacks for Stability Margins submenu (hSrc = menu handle)
if strcmp(get(hSrc,'Checked'),'on')
    View.hideCharacteristic('MultipleModelView');
else
    View.Options.MultiModelDisplayType = 'Systems';
    if LocalIsMultiModelVisible(View)
        LocalUncertainSetCheck([], m, View)
    else
        if hasCharacteristic(View,'MultipleModelView')
            View.showCharacteristic('MultipleModelView');
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

function isVisible = LocalIsMultiModelVisible(View)

[b,idx] = hasCharacteristic(View,'MultipleModelView');

if b
    isVisible = View.CharacteristicManager(idx).Visible;
else
    isVisible = false;
end


%%%%%%%%%%%%%%%%%%%%%%
% LocalAddSingleMultiModelMenu
%%%%%%%%%%%%%%%%%%%%%%
function  h = LocalAddSingleMultiModelMenu(this,View)
% LocalAddMultiModelMenu adds the multi model menu
% to the right click menus of all the plots.

h = uimenu('Parent', View.AxesGrid.UIContextMenu,...
   'Label',ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
   'Tag','MultiModel');


% Adds menu items to Multimodel menu
hb = uimenu(h,'Label',ctrlMsgUtils.message('Control:compDesignTask:strShow'));
m = struct('ShowMenu',hb);
    
set(hb,'Callback',{@LocalToggleShowMenu, View, m});

LocalShowMenuSetCheck(this, m, View)

L = handle.listener(View, ...
    View.findprop('CharacteristicManager'),'PropertyPostSet', ...
    @(x,y) LocalShowMenuSetCheck(this,m,View));
set(hb,'UserData',L)  % Anchor listeners for persistency


function LocalShowMenuSetCheck(~,m,View)
isVisible = LocalIsMultiModelVisible(View);
if isVisible
    set(m.ShowMenu,'Checked','on')
else
    set(m.ShowMenu,'Checked','off')
end

function LocalToggleShowMenu(hSrc,~,View,m)
if strcmp(get(hSrc,'Checked'),'on')
    View.hideCharacteristic('MultipleModelView');
else
    if LocalIsMultiModelVisible(View)
        LocalShowMenuSetCheck([], m, View);
    else
        if hasCharacteristic(View,'MultipleModelView')
            View.showCharacteristic('MultipleModelView');
        end
    end
end


