function h = addmenu(this,Anchor,MenuType)
%ADDMENU  Creates generic editor context menus.
%
%   H = ADDMENU(EDITOR,ANCHOR,MENUTYPE) creates a menu item, related
%   submenus, and associated listeners.  The menu is attached to the
%   parent object with handle ANCHOR.

%   Author(s): P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc.

switch MenuType
    
    case 'add'
        % Add Pole/Zero menu
        h = uimenu(Anchor,'Label', ...
            getString(message('Control:compDesignTask:strAddPoleZero')));
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strRealPole')),...
            'Callback',{@LocalAddPZ this 'Real' 'Pole'},...
            'Tag','AddRealPole');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strComplexPole')),...
            'Callback',{@LocalAddPZ this 'Complex' 'Pole'},...
            'Tag','AddComplexPole');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strIntegrator')),...
            'Callback',{@LocalAddInt this},...
            'Tag','AddIntegrator');
        uimenu(h,'Label',...
            getString(message('Control:compDesignTask:strRealZero')),...
            'Callback',{@LocalAddPZ this 'Real' 'Zero'}, ...
            'Separator','on',...
            'Tag','AddRealZero');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strComplexZero')),...
            'Callback',{@LocalAddPZ this 'Complex' 'Zero'},...
            'Tag','AddComplexZero');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strDifferentiator')),...
            'Callback',{@LocalAddDiff this},...
            'Tag','AddDifferentiator');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strLead')),...
            'Callback',{@LocalAddPZ this 'Lead' ''}, ...
            'Separator','on',...
            'Tag','AddLead');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strLag')),...
            'Callback',{@LocalAddPZ this 'Lag' ''},...
            'Tag','AddLag');
        uimenu(h,'Label', ...
            getString(message('Control:compDesignTask:strNotch')),...
            'Callback',{@LocalAddPZ this 'Notch' ''},...
            'Tag','AddNotch');
        
        % Add listeners to edit mode changes
        lsnr = addlistener(this.ModeManager,'Mode',...
            'PostSet',@(es,ed)LocalModeChanged('add', h, this));
        set(h,'UserData',lsnr)  % Anchor listeners for persistency
        
    case 'constraint'
        % Constraints menu
        h = uimenu(Anchor, 'Label',  ...
            getString(message('Control:compDesignTask:strDesignRequirements')), ...
            'Tag','DesignRequirement');
        % Constraint submenus
        uimenu(h, 'Label', ...
            getString(message('Control:compDesignTask:lblNewEllipsis')), ...
            'Callback', {@LocalDesignConstr this 'new'}, ...
            'Tag','NewRequirement');
        uimenu(h, 'Label', ...
            getString(message('Control:compDesignTask:lblEditEllipsis')), ...
            'Callback', {@LocalDesignConstr this 'edit'}, ...
            'Tag','EditRequirement');
        %Hide menu if view does not support requirements
        if isempty(this.newconstr)
            set(h,'Visible','off')
        else
            set(h,'Visible','on');
        end
    case 'delete'
        % Delete Pole/Zero menu
        h = uimenu(Anchor,'Label', ...
            getString(message('Control:compDesignTask:strDeletePoleZero')), ...
            'Callback',{@LocalDeletePZ this});
        
        % Add listeners to edit mode changes
        lsnr = addlistener(this.ModeManager,'Mode',...
            'PostSet',@(es,ed)LocalModeChanged('delete', h, this));
        set(h,'UserData',lsnr)  % Anchor listeners for persistency
        
    case 'edit'
        % Edit Compensator
        h = uimenu(Anchor,'Label',...
            getString(message('Control:compDesignTask:lblEditCompensatorEllipsis')),...
            'Callback',{@LocalShowEditor this});
        
    case 'grid'
        % Grid
        h = uimenu(Anchor,'Label',...
            getString(message('Control:compDesignTask:strGrid')),...
            'Callback',{@LocalSetGrid this});
        chart = qeGetChart(this.Axes);
        L = addlistener(chart.AxesStyle,'AxesStyleChanged',...
            @(es,ed) GridMenuState(this,h));
        % Anchor listeners for persistency
        set(h,'UserData',L)
        
    case 'property'
        % Properties
        h = uimenu(Anchor,'Label',...
            getString(message('Control:compDesignTask:lblPropertiesEllipsis')),...
            'Callback',{@LocalOpenEditor this});
        
    case 'snapshot'
        % Show menu
        h = uimenu(Anchor,'Label',...
            getString(message('Control:compDesignTask:strDesignSnapshots')));
        
    case 'show'
        % Show menu
        h = uimenu(Anchor,'Label', ...
            getString(message('Control:compDesignTask:strShow')));
        
    case 'multiplemodel'
        % Show menu
        h = uimenu(Anchor,'Label', ...
            ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'),...
            'Tag','multiplemodel');
        
    case 'zoom'
        % Zoom
        hout = uimenu(Anchor,'label',...
            getString(message('Control:compDesignTask:strFullView')),...
            'Enable','off',...
            'Tag', 'fullview', ...
            'Callback',{@LocalZoomOut this});
        
        % Add listener to enable/disable full view menu
        ax = getAxes(this.Axes);
        for k = 1:length(ax)
            L1 = addlistener(ax,'XLimMode','PostSet',@(es,ed) LocalZoomOutEnable(es,ed,this,hout));
            L2 = addlistener(ax,'YLimMode','PostSet',@(es,ed) LocalZoomOutEnable(es,ed,this,hout));
            set(hout,'UserData',L1);
            set(hout,'UserData',L2)  % Anchor listeners for persistency
        end        
    case 'Compensator'
        % Closed loop bode compensator selector
        h = uimenu(Anchor,'Label',...
            getString(message('Control:compDesignTask:strSelectCompensator')));
        LocalUpdataCompensatorTargetMenu([],[],this,h)
        
    case 'GainTarget'
        % Target for which compensator gain should be modified during
        % graphical drags
        h = uimenu(Anchor,'Label',...
            getString(message('Control:compDesignTask:strGainTarget')),...
            'Tag', 'GainTargetMenu');
        LocalUpdataGainTargetMenu([],[],this, h)
        this.DataListeners = [this.DataListeners; ...
            addlistener(this.Data.getResponse,'DefinitionChanged', ...
            @(es,ed)LocalUpdataGainTargetMenu([],[],this, h)); ...
            addlistener(this.Data.getResponse,'PlantValueChanged', ...
            @(es,ed)LocalUpdataGainTargetMenu([],[],this, h))];
end
end

%----------------------------- Listener callbacks ----------------------------

%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalModeChanged %%%
%%%%%%%%%%%%%%%%%%%%%%%%
function LocalModeChanged(MenuMode,hMenu,this)
% Update state of right-click menu (check mark)
this.checkmenu(MenuMode,hMenu);
end

%%%%%%%%%%%%%%%%%%%%%
%%% GridMenuState %%%
%%%%%%%%%%%%%%%%%%%%%
function GridMenuState(this,hMenu)
% Updates grid menu state
chart = qeGetChart(this.Axes);
set(hMenu,'Checked',logical(chart.AxesStyle.GridVisible))
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalZoomOutEnable %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalZoomOutEnable(~,~,Editor,hZoomOut)
% Disable Zoom:Out menu when XlimMode=YlimMode=auto
% yLimMode = get(Editor.Axes.getAxes,'YLimMode');
xLimMode = Editor.Axes.XLimitsMode;
if ~iscell(xLimMode)
    xLimMode = {xLimMode};
end
yLimMode = Editor.Axes.YLimitsMode;
if ~iscell(yLimMode)
    yLimMode = {yLimMode};
end
isAuto = true;
for ii = 1:numel(xLimMode)
    isAuto = isAuto && strcmp(xLimMode{ii},"auto");
end
for ii = 1:numel(yLimMode)
    isAuto = isAuto && strcmp(yLimMode{ii},"auto");
end
set(hZoomOut,'Enable',~isAuto)
end

function LocalZoomOut(~,~,Editor)
% Zoom out callback (hSrc = submenu handle)
Editor.zoomout;
end
%----------------------------- Callback actions ----------------------------

%%%%%%%%%%%%%%%%%%%
%%% LocalAddInt %%%
%%%%%%%%%%%%%%%%%%%
function LocalAddInt(~,~,Editor)
% Add integrator
Data = Editor.Data;
% EventMgr = Editor.EventManager;

% Return to idle (aborts global modes)
Editor.EditMode = 'idle';

% Add integrator
if Data.Ts ~= 0,
    intvalue = 1;
else
    intvalue = 0;
end

% Determine which Compensator to add PZGroup to
% C = addPZDialog(Editor, 'Real', 'Pole');
C = Data.EditedBlock;

if isempty(C)
    % No valid compensators to add pzgroup to
    return
end

% Start transaction
% T = ctrluis.transaction(LoopData,...
%     'Name',getString(message('Control:compDesignTask:strAddIntegrator')),...
%    'OperationStore','on','InverseOperationStore','on');

C.addPZ('Real',zeros(0,1),(intvalue));

% Register transaction
% EventMgr.record(T);

% Notify of loop data change
Data.notify('DataChanged');
% Update status and history
% Status = getString(message('Control:compDesignTask:msgAddedIntegrator',C.describe(true)));
% EventMgr.newstatus(Status);
% EventMgr.recordtxt('history',Status);

end
%%%%%%%%%%%%%%%%%%%%
%%% LocalAddDiff %%%
%%%%%%%%%%%%%%%%%%%%
function LocalAddDiff(~,~,Editor)
% Add differentiator
Data = Editor.Data;
% EventMgr = Editor.EventManager;

% Return to idle (aborts global modes)
Editor.EditMode = 'idle';


% Add differentiator
if Data.Ts ~= 0,
    difvalue = 1;
else
    difvalue = 0;
end

% Determine which Compensator to add PZGroup to
C = Data.EditedBlock;

if isempty(C)
    % No valid compensators to add pzgroup to
    return
end

C.addPZ('Real',(difvalue),zeros(0,1));

% Register transaction
% EventMgr.record(T);

% Notify of loop data change
Data.notify('DataChanged');

% Update status and history
% Status = getString(message('Control:compDesignTask:msgAddedDifferentiator',C.describe(true)));
% EventMgr.newstatus(Status);
% EventMgr.recordtxt('history',Status);

end
%%%%%%%%%%%%%%%%%%
%%% LocalAddPZ %%%
%%%%%%%%%%%%%%%%%%
function LocalAddPZ(~,~,Editor,Type,ID)
% Starts Add Pole/Zero operation (hSrc = submenu handle)

AddInfo = struct('Root',ID,'Group',Type);

% Exiting Add mode? (unchecking menu)
ExitingMode = strcmp(Editor.EditMode,'addpz') & ...
    isequal(Editor.EditModeData,AddInfo);

% Return to idle (properly resets menu and pointer when switching mode, aborts global modes)
Editor.EditMode = 'idle';

% Enter 'addpz' mode
if ~ExitingMode
    % RE: Updating EditMode triggers menu update and resets pointer
    Editor.setEditModeAndData('addpz', AddInfo);
    % Evaluate WBM function once to set correct pointer
end

end
%%%%%%%%%%%%%%%%%%%%%
%%% LocalDeletePZ %%%
%%%%%%%%%%%%%%%%%%%%%
function LocalDeletePZ(~,~,Editor)
% Starts Delete Pole/Zero operation

% Exiting Delete mode? (unchecking menu)
ExitingMode = strcmp(Editor.EditMode,'deletepz');

% Return to idle (properly resets menu and pointer when switching mode, aborts global modes)
Editor.setEditModeAndData('idle',[]);

% Enter 'deletepz' mode
if ~ExitingMode
    % Enter 'delete' mode (triggers menu update and resets pointer)
    Editor.setEditModeAndData('deletepz',[]);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalDesignConstr %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalDesignConstr(~, ~, Editor, ActionType)
% Opens dialogs to add/edit design constraints
designConstr(Editor,ActionType)
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalShowEditor %%%
%%%%%%%%%%%%%%%%%%%%%%%
function LocalShowEditor(~,~,Editor)
% Bring up PZ editor
feval(Editor.PZEditor,Editor.Data.EditedBlock);
end

%%%%%%%%%%%%%%%%%%%%
%%% LocalZoomOut %%%
%%%%%%%%%%%%%%%%%%%%
% function LocalZoomOut(~,~,Editor)
% % Zoom out callback (hSrc = submenu handle)
% Editor.zoomout;
% end

%%%%%%%%%%%%%%%%%%%%
%%% LocalSetGrid %%%
%%%%%%%%%%%%%%%%%%%%
function LocalSetGrid(hSrc,~,Editor)
% Grid menu callback (hSrc = menu handle)
chart = qeGetChart(Editor.Axes);
chart.AxesStyle.GridVisible = ~hSrc.Checked;
end

%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalOpenEditor %%%
%%%%%%%%%%%%%%%%%%%%%%%
function LocalOpenEditor(~,~,Editor)
% Properties menu callback (hSrc = menu handle)
PropEdit = PropEditor(Editor);
PropEdit.setTarget(Editor)
Editor.PropertyEditorDialog = PropEdit;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalSetTunedFactor %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function LocalSetTunedFactor(hSrc,~,Editor, C)
%
% set(hSrc,'Checked','on');
% items = get(get(hSrc,'Parent'),'Children');
% set(items(hSrc~= items),'Checked','off');
%
% Editor.LoopData.L(Editor.EditedLoop).TunedFactor = C;
% Editor.setEditedBlock(C);
% Editor.GainTargetBlock = C;
% Editor.LoopData.dataevent('all')
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalSetGainTarget  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalSetGainTarget(hSrc,~,Editor, C)

set(hSrc,'Checked','on');
items = get(get(hSrc,'Parent'),'Children');
set(items(hSrc~= items),'Checked','off');

Editor.Data.GainTargetBlock = C;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalUpdataGainTargetMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalUpdataGainTargetMenu(~,~,Editor,h)
if isvalid(Editor) && issiso(Editor.Data.getResponse)
    ValidIdx = getValidGainTargets(Editor.Data);
    if ~isempty(ValidIdx)
        nC = max(length(ValidIdx),1);
        
        SubMenus = flipud(get(h,'Children')); %SubMenus(:,:) = [];
        if length(SubMenus)<nC
            % Add submenus
            for ct=length(SubMenus):nC
                uimenu('Parent',h);
            end
            SubMenus = flipud(get(h,'Children')); %SubMenus(1,:) = [];
        end
        
        if ~isempty(ValidIdx)
            ischecked = false;
            for ct = 1:length(ValidIdx)
                C = ValidIdx(ct);
                set(SubMenus(ct),'Label',sprintf('%s',C.Name),...
                    'Callback',{@LocalSetGainTarget Editor C});
                if Editor.Data.GainTargetBlock == C
                    set(SubMenus(ct),'Checked','on');
                    ischecked = true;
                else
                    set(SubMenus(ct),'Checked','off');
                end
            end
            if ~ischecked
                set(SubMenus(1),'Checked','on');
            end
        else
            set(SubMenus(1),'Label', ...
                getString(message('Control:compDesignTask:msgLoopGainNotTunable')),...
                'Callback','','Checked','off');
        end
        
        % Adjust visibility and labels
        for ct=1:nC
            set(SubMenus(ct),'Visible','on')
        end
        for ct=nC+1:length(SubMenus)
            set(SubMenus(ct),'Visible','off')
        end
        
    end
end
end
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalUpdataCompensatorTargetMenu %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalUpdataCompensatorTargetMenu(~,~,Editor,h)

% if ~isequal(Editor.EditedLoop,-1) % update only if editor has an edited loop
%     % Clear submenus
%     ch = get(h,'children');
%     delete(ch(ishandle(ch)));
%     set(h,'children',[]);
%     % Update menus
%     C = Editor.LoopData.C;
%     for idx = 1:length(C)
%         if isa(C(idx),'sisodata.TunedZPK');
%             tmpmenu = uimenu(h,'Label',sprintf('%s(%s)',C(idx).Name,C(idx).Identifier),...
%                 'Callback',{@LocalSetTunedFactor Editor C(idx)});
%             if Editor.LoopData.L(Editor.EditedLoop).TunedFactor == C(idx)
%                 set(tmpmenu,'Checked','on');
%             end
%         end
%     end
% end
end