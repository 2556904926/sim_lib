function View = createView(this,PlotType,varargin)
%CREATEVIEW  Creates one of the built-in LTI plots.

%   Authors: Craig Buhr
%   Copyright 2015 The MathWorks, Inc.

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

% Set requirement color consistency
View.Options.RequirementColor = [250   250   210]/255;

% Add listeners tracking imports and changes in System pool
% L = [handle.listener(this,'SystemChanged',{@LocalSystemChanged View varargin{:}});...
%     handle.listener(this,'ModelImport',{@LocalCheckException View})];
% View.addlisteners(L)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     LISTENER CALLBACKS                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%
% LocalSystemChanged
%%%%%%%%%%%%%%%%%%%%%%
function LocalSystemChanged(~,eventdata,View,varargin)
% Callback for 'SystemChanged' event.
this = eventdata.source;
Info = eventdata.data;
outNames  = Info.OutNames;
inNames   = Info.InNames;

% Delete responses associated with deleted sources
if ~isempty(Info.DelSys)
    r = find(View.Responses,'-not','DataSrc',[]);
    src = get(r,{'DataSrc'});
    [~,~,ib] = intersect(Info.DelSys,cat(1,src{:}));
    View.AxesGrid.LimitManager = 'off';
    for rr=r(ib)',
        View.rmresponse(rr);
    end
    View.AxesGrid.LimitManager = 'on';
end

% Adjust new I/O size to include user-added responses
NewSize = [length(outNames),length(inNames)];
LocalSize = NewSize;
for r=View.Responses'
    rSize = [length(r.RowIndex),length(r.ColumnIndex)];
    if any(rSize>NewSize)
        LocalSize = max(LocalSize,rSize);
        % Move to upper left corner
        r.RowIndex = 1:rSize(1);
        r.ColumnIndex = 1:rSize(2);
    end
end
if any(LocalSize>NewSize)
    % Increase I/O size computed from Systems list
    outNames(end+1:LocalSize(1)) = {''};
    inNames(end+1:LocalSize(2)) = {''};
end

% Resize plot
View.resize(outNames,inNames);

% If all the current responses are @ss data sources with the same
% initial state vector, then set the initial condition of any new
% responses with matching number of states equal to the common existing
% state vector. Otherwise set it to empty.
if strcmp(View.Tag,'lsim') || strcmp(View.Tag,'initial')
    x0 = [];
    for k=1:length(View.Responses)
        thisX0 = View.Responses(k).Context.IC;
        if ~isempty(thisX0) && isempty(x0)
            x0 = thisX0;
        elseif ~isempty(x0) && ~isequal(x0,thisX0)
            x0 = [];
            break
        end
    end
    % x0 will be passed to createResponse to assign the initial state
    % of the added responses
    varargin{2} = x0;
end

% Create responses for added systems
this.createResponse(View,Info.AddSys,Info.AddSysStyle,varargin{:});

% Special processing
if strcmp(View.Tag,'lsim')
    % Determine which subset of the input channels drives each response
    View.Input.ChannelName = this.InputNames; %Update channel names
    localizeInputs(View)
end

% Redraw view
draw(View)


%%%%%%%%%%%%%%%%%%%%%%
% LocalCheckException
%%%%%%%%%%%%%%%%%%%%%%
function LocalCheckException(~,eventdata,View,varargin)
% Creates warning when some imported systems cannot be plotted
if isempty(View.Responses)
    return
end
ImportedSystems = eventdata.data;  % new or modified data sources
% Find responses with these data sources
r = find(View.Responses,'-not','DataSrc',[]);
src = get(r,{'DataSrc'});
[~,ia,ib] = intersect(cat(1,src{:}),ImportedSystems);
% Issue warning if some of these responses have exceptions
Exception = false;
for ct=1:length(ia)
    if ~isempty(find(r(ia(ct)).Data,'Exception',true))
        Exception = true;  break
    end
end
if Exception
   WarnHeader = getString(message('Control:designerapp:warnSystemsCannotBeShown1',View.AxesGrid.Title));
   WarnDetails = [];
   switch View.Tag
      case {'step','impulse'}
         WarnDetails = getString(message('Control:designerapp:warnSystemsCannotBeShown2'));
      case 'initial'
         % Don't display the warning if the lsim GUI (initial form) has opened because no
         % inputs have been specified. This happens when
         % ltiview('lsim',sys1,sys2,...,sysn) initially sends a 'modelimport'
         % event
         if isempty(View.InputDialog) || ~ishandle(View.InputDialog) || ...
                 strcmp(View.InputDialog.Visible,'off')
             WarnDetails = getString(message('Control:designerapp:warnSystemsCannotBeShown5'));
         else
             return
         end
      case 'lsim'
         % Don't display the warning if the lsim GUI has opened because no
         % inputs have been specified. This happens when
         % ltiview('lsim',sys1,sys2,...,sysn) initially sends a 'modelimport' event
         if isempty(View.InputDialog) || ~ishandle(View.InputDialog) || ...
               strcmp(View.InputDialog.Visible,'off')
            WarnDetails = getString(message('Control:designerapp:warnSystemsCannotBeShown6'));
         else
            return
         end
      case {'pzmap','iopzmap'}
         WarnDetails = getString(message('Control:designerapp:warnSystemsCannotBeShown4'));
   end
   uialert(this.Document.Figure,sprintf('%s\n%s',WarnHeader,WarnDetails),...
       getString(message('Control:designerapp:strCSDWarning')),'Icon','warning');
end

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


