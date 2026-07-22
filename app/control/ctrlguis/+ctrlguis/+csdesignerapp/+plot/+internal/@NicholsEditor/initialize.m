function initialize(this)
% Build right-click menu
ax = getAxes(this.Axes);
f = ancestor(ax(1),'figure');
U = uicontextmenu(f);
set(ax,'ContextMenu',U);
LocalCreateMenus(this,U);
set(get(U,'children'),'Enable','off')
end

%%%%%%%%%%%%%%%%%%%%%
%%% LocalAddMenus %%%
%%%%%%%%%%%%%%%%%%%%%
function LocalCreateMenus(Editor,MenuAnchor)
% Builds right-click menus
% 
% Edit pole/zero group
addmenu(Editor,MenuAnchor,'add');
addmenu(Editor,MenuAnchor,'delete');
addmenu(Editor,MenuAnchor,'edit');

% Specifies target gain for editor
Editor.addmenu(MenuAnchor,'GainTarget');

% Show menu 
h = Editor.addmenu(MenuAnchor,'show');
set(h,'Separator','on')
LocalAddMarginMenu(Editor,h);
% Editor.addmenu(h,'snapshot');
h = Editor.addmenu(MenuAnchor,'multiplemodel');
set(h,'Separator','on')
LocalAddUncertaintyMenu(Editor,h);
Editor.addmenu(MenuAnchor, 'constraint');

% Design Constraints/Grid/Zoom
h = Editor.addmenu(MenuAnchor, 'grid');
set(h, 'Separator', 'on');
set(h, 'Checked', Editor.Axes.Style.Axes.XGrid);
Editor.addmenu(MenuAnchor, 'zoom');

% Properties
h = Editor.addmenu(MenuAnchor,'property');
set(h,'Separator','on')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalAddUncertaintyMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalAddUncertaintyMenu(this,h)
% Adds menu items to Uncertainty menu
hb = uimenu(h,'Label',ctrlMsgUtils.message('Control:compDesignTask:strMultiModelBounds'), ...
    'Callback',@(es,ed)LocalToggleBoundsMenu(es,this));
if isVisible(this.UncertainBounds,'Bounds')
    set(hb,'Checked','on')
else
    set(hb,'Checked','off')
end

hs = uimenu(h,'Label',ctrlMsgUtils.message('Control:compDesignTask:strMultiModelIndividualResponses'), ...
    'Callback',@(es,ed)LocalToggleSystemsMenu(es,this));
if isVisible(this.UncertainBounds,'Systems')
    set(hs,'Checked','on')
else
    set(hs,'Checked','off')
end

m = struct(...
    'BoundsMenu',hb,...
    'SystemsMenu',hs);
    

L = addlistener(this.UncertainBounds, {'Visible','UncertainType'}, ...
    'PostSet',@(es,ed) LocalUncertainSetCheck(this, m));
set(hb,'UserData',L)  % Anchor listeners for persistency
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleBoundsMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalToggleBoundsMenu(hSrc,this)
% Callbacks for Stability Margins submenu (hSrc = menu handle)
if strcmp(get(hSrc,'Checked'),'on')
    this.UncertainBounds.Visible = 'off';
else
    this.UncertainBounds.UncertainType = 'Bounds';
    this.UncertainBounds.Visible = 'on';
    this.update;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleSystemsMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalToggleSystemsMenu(hSrc,this)
% Callbacks for Stability Margins submenu (hSrc = menu handle)
if strcmp(get(hSrc,'Checked'),'on')
    this.UncertainBounds.Visible = 'off';
else
    this.UncertainBounds.UncertainType = 'Systems';
    this.UncertainBounds.Visible = 'on';
    this.update;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalUncertainSetCheck %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalUncertainSetCheck(this,m)
if isVisible(this.UncertainBounds,'Bounds')
    set(m.BoundsMenu,'Checked','on')
else
    set(m.BoundsMenu,'Checked','off')
end

if isVisible(this.UncertainBounds,'Systems')
    set(m.SystemsMenu,'Checked','on')
else
    set(m.SystemsMenu,'Checked','off')
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalAddMarginMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalAddMarginMenu(this,h)
% Adds Stability Margins item to Show menu
hs = uimenu(h,'Label',getString(message('Control:compDesignTask:strStabilityMargins')), ...
    'Checked','On',...
    'Callback',@(es,ed)LocalToggleMarginMenu(es,this));
L = addlistener(this,'MarginVisible',...
    'PostSet',@(es,ed)LocalSetCheck(es,hs,this));
set(h,'UserData',[get(h,'UserData');L])  % Anchor listeners for persistency
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalToggleMarginMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalToggleMarginMenu(hSrc,this)
% Callbacks for Stability Margins submenu (hSrc = menu handle)
if strcmp(get(hSrc,'Checked'),'on')
    this.MarginVisible = 'off';
else
    this.MarginVisible = 'on';
end
end

function LocalSetCheck(es,hMenu,this)
% Callbacks for property listeners
set(hMenu,'Checked',this.(es.Name));
end