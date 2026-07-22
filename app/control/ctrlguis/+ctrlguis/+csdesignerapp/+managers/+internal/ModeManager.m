classdef ModeManager < handle
    %WINDOWMOTIONMANAGER Manages figure and line mouse motion callbacks.
    
    % Copyright 2013-2023 The MathWorks, Inc
    
    properties
        % Handle to figure for hover
        Figure
        % Handle to axes for ViewChanged during uninstall of widgets
        Axes
        
        % Widgets that have to be interacted with
        Widgets
        HG_Widgets
        
        % Cached button down functions
        BDFcns = cell(0,0);
        
        % Cached button motion functions
        WBFcns = struct(...
            'WindowButtonUpFcn',    [],...
            'WindowButtonMotionFcn',[]);
        
        UIModeManager
        CurrentModeListener
        ModeChangedListener
        
        EventManager
                % Cache warnings to enable again during finish
        Warning
        
        PointerType = ''
    end
    
    properties (SetObservable = true)
        % Mode
        Mode
        ModeData
    end
    
    properties (Access = private)
        YLimitsModeAtStart
        XLimitsModeAtStart
    end
    
    methods
        function obj = ModeManager(Figure, Axes, EventManager)
            obj.Figure = Figure;
            obj.Axes = Axes;
            obj.UIModeManager = uigetmodemanager(obj.Figure);
            set(obj.Figure,'WindowButtonMotionFcn',  @(hSrc,hData) hover(obj));
            weakObj = matlab.lang.WeakReference(obj);
            obj.CurrentModeListener = addlistener(obj.UIModeManager, 'CurrentMode','PostSet', ...
                @(es, ed)cbCurrentMode(weakObj.Handle));
            obj.EventManager = EventManager;
            obj.Mode = 'idle';
        end
        
        function set.Mode(this, NewMode)
            this.Mode = NewMode;
            setMode(this, NewMode);
        end
        
        function setMode(this,NewMode)
            %           if strcmp(NewMode, 'idle')
            %               set(this.Figure,'Pointer','arrow');
            %           end
            %           hover(this);
        end
        
        function target(this,action,widgets)
            %INIT
            % Input argument target must be a valid nonempty handle.
            % Input arguments:
            %     action:  'install' or 'uninstall'
            %     widget:  object that facilitates the callback routines
            %              Move, Hover, Stop and Start.
            
            
            % REVISIT: Use matlab.uitools.internal.uimodemanager to manage the
            %          mode
            
            if strcmp(action,'install')
                for ct = 1:numel(widgets)
                    HG_Object = getHG(widgets(ct));
                    % Some widgets are only constructed during update - dont
                    % install such widgets
                    if ~isempty(HG_Object)
                        this.BDFcns{end+1,1} = get(HG_Object,'ButtonDownFcn');
                        set(HG_Object,'ButtonDownFcn', @(hSrc,hData) start(this,widgets(ct)));
                        this.HG_Widgets = [this.HG_Widgets;HG_Object];
                        this.Widgets{end+1} = widgets(ct);
                    end
                end
            else
                %
                for ct = 1:numel(widgets)
                    idx = cellfun(@(x)isequal(x, widgets(ct)), this.Widgets);
                    idx = find(idx == 1);
                    if idx
                        Fig = this.Figure;
                        set(Fig,'WindowButtonUpFcn',     this.WBFcns.WindowButtonUpFcn);
                        set(Fig,'WindowButtonMotionFcn',  @(hSrc,hData) hover(this));
                        this.WBFcns.WindowButtonUpFcn = [];
                        this.WBFcns.WindowButtonMotionFcn = [];
                        setptr(Fig,'Arrow');
                        HG_Widgets = getHG(widgets(ct));
                        set(HG_Widgets,'ButtonDownFcn','');
                        this.Widgets{idx} = [];
                        this.Widgets = [this.Widgets(1:idx-1),this.Widgets(idx+1:end)];
                        this.HG_Widgets(idx) = [];
                        this.BDFcns = [this.BDFcns(1:idx-1,1);this.BDFcns(idx+1:end,1)];
                    end
                end
            end
        end
        
        function setEditModeAndData(this,Mode,ModeData)
            if ~strcmpi(this.Mode,Mode) || ~isequal(this.ModeData,ModeData)
                this.CurrentModeListener.Enabled = false;
                if strcmpi(Mode, 'zoom')
                    switch ModeData
                        case 'out'
                            this.Axes.CurrentInteractionMode = "none";
                            this.ModeData = [];
                            this.Mode = 'idle';
                        case {'in-x','in-y','in-xy'}
                            this.Axes.CurrentInteractionMode = "zoom";
                            this.ModeData = ModeData;
                            this.Mode = 'zoom';
                    end
                elseif strcmpi(Mode, 'pan')
                    this.Axes.CurrentInteractionMode = "pan";
                    this.ModeData = ModeData;
                    this.Mode = 'pan';                    
                else
                    this.Axes.CurrentInteractionMode = "none";
                    this.ModeData = ModeData;
                    this.Mode = Mode;
                end
                this.CurrentModeListener.Enabled = true;                
            end
        end
    end
    
    methods(Access = protected)
        function start(this,widget)
            % Cache current mode
            % Initialize WMM properties
            Fig = this.Figure;
            cPt = get(Fig,'CurrentPoint');
            if ~any(strcmpi(this.Mode, {'zoom','pan'}))
                % Store LimitsMode
                this.XLimitsModeAtStart = {};
                this.YLimitsModeAtStart = {};

                ax = getAxes(this.Axes);
                for k = 1:length(ax)
                    this.XLimitsModeAtStart{k} = ax(k).XLimMode;
                    this.YLimitsModeAtStart{k} = ax(k).YLimMode;
                end

                % Set Limits to manual
                set(ax,'XLimMode','manual');
                set(ax,'YLimMode','manual');

                % Disable warnings
                % Disable all warnings
                this.Warning.sw = warning('off'); [this.Warning.lw, this.Warning.lwid] = lastwarn;
                % Take over window mouse events
                WBMU = get(Fig,{'WindowButtonMotionFcn','WindowButtonUpFcn'});
                this.WBFcns.WindowButtonMotionFcn = WBMU{1};
                this.WBFcns.WindowButtonUpFcn = WBMU{2};
                set(Fig(1),'WindowButtonUpFcn',     @(hSrc,hData) stop(this, widget));
                set(Fig(1),'WindowButtonMotionFcn', @(hSrc,hData) move(this, widget));
                % Set the refresh mode of associated plots to quick
%                 setRefreshMode(widget, 'quick');
                %Call target start-specific code
                try
                    start(widget);
                catch ME
                    uialert(getAppContainer(this.EventManager),ME.message,...
                        getString(message('Control:designerapp:strToolTitleShort')));
                end
            end
        end
        
        function move(this,widget)
            %MOVE
            
            %Call target move-specific code
            if ~strcmpi(this.Mode, 'zoom')
                try
                    move(widget);
                catch ME
                    uialert(getAppContainer(this.EventManager),ME.message,...
                        getString(message('Control:designerapp:strToolTitleShort')));
                end
            end
        end
        
        function stop(this,widget)
            %Call target stop-specific code
            if ~any(strcmpi(this.Mode, {'zoom','pan'}))
                if isvalid(widget)
                    % Reset LimitsMode
                    ax = getAxes(this.Axes);
                    for k = 1:length(ax)
                        ax(k).XLimMode = this.XLimitsModeAtStart{k};
                        ax(k).YLimMode = this.YLimitsModeAtStart{k};
                    end

                    Fig = this.Figure;
                    set(Fig(1),'WindowButtonUpFcn',     this.WBFcns.WindowButtonUpFcn);
                    set(Fig(1),'WindowButtonMotionFcn', this.WBFcns.WindowButtonMotionFcn);
                    this.WBFcns.WindowButtonUpFcn = [];
                    this.WBFcns.WindowButtonMotionFcn = [];
                    
                    % Set the refresh mode of associated plots to normal
                    setRefreshMode(widget, 'normal');
                    try
                        stop(widget);
                    catch ME
                        uialert(getAppContainer(this.EventManager),ME.message,...
                            getString(message('Control:designerapp:strToolTitleShort')));
                    end
                    this.Mode = 'idle';
                    this.ModeData = [];
                end
                % Reset warnings
                warning(this.Warning.sw); lastwarn(this.Warning.lw, this.Warning.lwid)
            end
        end
        
        function hover(this)
            HoverStatus = '';
            if ~any(strcmpi(this.Mode, {'zoom','pan'}))
                HitObject = hittest(this.Figure);
                PointerType = 'arrow'; %#ok<*PROP>
                
                switch this.Mode
                    case 'idle'
                        b = (HitObject == this.HG_Widgets);
                        
                        if any(b) && ~isa(this.HG_Widgets(b),'matlab.graphics.axis.Axes')
                            [PointerType,HoverStatus] = hover(getappdata(this.HG_Widgets(b),'Widget'),this.HG_Widgets(b));
                        else
                            HoverStatus = '';
                            PointerType = 'arrow';
                        end
                    case 'addpz'
                        switch this.ModeData.Group
                            case {'Real','Complex'}
                                PointerType = sprintf('add%s',lower(this.ModeData.Root));
                                if strcmpi(this.ModeData.Root,'pole')
                                    HoverStatus = getString(message('Control:compDesignTask:msgLeftClickToAddPole'));
                                else
                                    HoverStatus = getString(message('Control:compDesignTask:msgLeftClickToAddZero'));
                                end
                            case 'Lead'
                                PointerType = 'addpole';  % default
                                HoverStatus = getString(message('Control:compDesignTask:msgLeftClickToAddLead'));
                            case 'Lag'
                                PointerType = 'addpole';  % default
                                HoverStatus = getString(message('Control:compDesignTask:msgLeftClickToAddLag'));
                            case 'Notch'
                                PointerType = 'addpole';  % default
                                HoverStatus = getString(message('Control:compDesignTask:msgLeftClickToAddNotch'));
                            otherwise
                                PointerType = 'addpole';  % default
                                HoverStatus = getString(message('Control:compDesignTask:msgLeftClickToAddPZ'));
                        end
                        
                    case 'deletepz'
                        PointerType = 'eraser';
                        HoverStatus = getString(message('Control:compDesignTask:msgLeftClickDeletePZ'));
                end
                
                if ~strcmp(PointerType,this.PointerType)
                    setptr(this.Figure,PointerType);
                    if ~strcmp(PointerType,'arrow')
                        if isempty(HoverStatus)
                            this.EventManager.clearActionStatus;
                        else
                            this.EventManager.postActionStatus('off',HoverStatus);
                        end
                    end
                    this.PointerType = PointerType;
                end
                
            end
        end
        
        function cbCurrentMode(this)
            %Toggle button status according to current mdoe
            CurrentMode = get(this.UIModeManager.CurrentMode);
            
            if isempty(CurrentMode)
                this.Mode = 'idle';
                this.ModeData = [];
            else
                if strcmp(CurrentMode.Name,'Exploration.Zoom') && ...
                        strcmp(CurrentMode.ModeStateData.Direction, 'in')
                    switch CurrentMode.ModeStateData.Constraint
                        case 'horizontal'
                            this.ModeData = 'in-x';
                        case 'vertical'
                            this.ModeData = 'in-y';
                        case 'none'
                            this.ModeData = 'in';
                    end
                    this.Mode = 'zoom';
                elseif strcmp(CurrentMode.Name,'Exploration.Zoom') && ...
                        strcmp(CurrentMode.ModeStateData.Direction, 'out')
                    this.ModeData = 'out';
                    this.Mode = 'zoom';
                elseif strcmp(CurrentMode.Name,'Exploration.Pan')
                    this.ModeData = [];
                    this.Mode = 'pan';
                end
            end
        end
    end
end