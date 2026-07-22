function initialize(this)
% Build right-click menu
ax = getAxes(this.Axes);
f = ancestor(ax(1),'figure');
U = uicontextmenu(f);
set(ax,'ContextMenu',U);
LocalCreateMenus(this,U);
set(get(U,'children'),'Enable','off')
end

%-------------------------- Local Functions ------------------------

%%%%%%%%%%%%%%%%%%%%%
%%% LocalAddMenus %%%
%%%%%%%%%%%%%%%%%%%%%
function LocalCreateMenus(Editor,MenuAnchor)
% Builds right-click menus

% Edit pole/zero group
addmenu(Editor,MenuAnchor,'add');
addmenu(Editor,MenuAnchor,'delete');
addmenu(Editor,MenuAnchor,'edit');

% Specifies target gain for editor
Editor.addmenu(MenuAnchor,'GainTarget');

% Show menu 
% h = Editor.addmenu(MenuAnchor,'show');
% set(h,'Separator','on')
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
hb = uimenu(h,'Label',ctrlMsgUtils.message('Control:compDesignTask:strShow'), ...
    'Callback',{@LocalToggleShowMenu this});
if isVisible(this.UncertainBounds)
    set(hb,'Checked','on')
else
    set(hb,'Checked','off')
end

m = struct('ShowMenu',hb);
    

L = addlistener(this.UncertainBounds, {'Visible'}, ...
    'PostSet',@(es,ed) LocalUncertainSetCheck(this, m));
set(hb,'UserData',L)  % Anchor listeners for persistency
end

function LocalUncertainSetCheck(this,m)
if isVisible(this.UncertainBounds)
    set(m.ShowMenu,'Checked','on')
else
    set(m.ShowMenu,'Checked','off')
end
end

function LocalToggleShowMenu(hSrc,~,this)
% Callbacks for Stability Margins submenu (hSrc = menu handle)
if strcmp(get(hSrc,'Checked'),'on')
    this.UncertainBounds.Visible = 'off';
else
    this.UncertainBounds.Visible = 'on';
    this.update;
end
end

