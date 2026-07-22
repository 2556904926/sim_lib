classdef GraphicalEditor < handle & matlab.mixin.Heterogeneous
    % GraphicalEditor Base Class

    % Copyright 2014-2023 The MathWorks, Inc.
    properties (Access = public)
        % ctrluis.AxesGrid object
        Axes                % Needed by uncertain objects

        %  Class that handles uncertain data
        UncertainBounds     % Needed by widgets during drag

        % Class that manages events - undo and redo
        EventManager        % Needed by widgets

        % Preferences
        Preferences         % Needed by widgets

        % Refresh mode
        RefreshMode = 'normal'

        ModeManager         % Manager of mouse motion according to edit mode
    end
    
    properties(GetAccess = protected,SetAccess = ?srocsdgui.sropnl)
        ViewUpdateEnabled = true
    end

    properties (Access = protected)
        %% Data
        Data            % Data object that manages the response and the edited block

        %% Graphical Objects
        AxesViewWidget      % Graphical widgets - Axes itself
        ResponseViewWidget  % Graphical widgets - Response lines
        PZViewWidget        % Graphical widgets - Pole/zero lines
        OtherWidgets        % Widgets that need to refresh when something moves

        Document
        DocumentGroup
        PropertyEditorDialog
    end

    properties (SetObservable = true)

        % Required by design constraints
        FrequencyUnits
    end

    properties (Access = private)
        DataListeners       % Listen to data changes
        PlotDeleteListener
        ViewListeners       % Listen to view changes

        %% Editors
        ConstraintEditor   % Handle to constraint editor
        PropertyEditor     % Property Editor handle
        PZEditor           % Compensator editor handle

        LineStyle_I
        ShowSystemPZ_I
    end


    properties (GetAccess = public, SetAccess = protected, SetObservable = true, Dependent = true)
        % Public get access for widgets to access the mode)
        %% Modes.
        EditMode
        EditModeData    %     EditMode:     [idle|addpz|deletepz|zoom]
        %     EditModeData: addpz --> Root  = [pole|zero]
        %                             Group = [real|complex|lead|lag|notch]
        %                    zoom --> Type  = [in-x|in-y|x-y]
    end

    properties(GetAccess = public, SetAccess = protected)
        Type
        ContextualTag
        IsPlotDeleted = false
        IsDataDeleted = false
    end

    properties (Access = public)
        %% Style properties
        % Preferences set these properties on the Graphical Editor
        % directly. Listen to changes in these properties to update the
        % plot.
        LabelColor
    end

    properties (Dependent)
        LineStyle
        ShowSystemPZ
    end

    methods
        %% Constructor and public API
        function this = GraphicalEditor(Data,Preferences, EventManager, PZEditor, ConstraintEditor, varargin)
            % Cache data
            this.Data = Data;

            % Cache preferences
            this.Preferences = Preferences;

            % Set event manager
            this.EventManager = EventManager;

            % Set constraint editor
            this.ConstraintEditor = ConstraintEditor;

            % Tag
            if nargin > 5
                this.ContextualTag = varargin{1};
            end

            % Create axes
            configureAxes(this);
            configureAxesStyle(this);

            if this.Data.isUncertain
                setmenu(this,'on','multiplemodel');
            else
                setmenu(this,'off','multiplemodel');
            end
            % Create mode manager
            createModeManager(this);

            % Add preference listeners
            %             addPreferenceListeners(this);
            this.LineStyle_I = this.Preferences.LineStyle;
            this.LabelColor = this.Preferences.AxesForegroundColor;
            this.ShowSystemPZ_I = this.Preferences.ShowSystemPZ;
            
            % Create widgets
            createGraphicalWidgets(this);

            % Cache handle to PZEditor
            this.PZEditor = PZEditor;

            % Add data listeners
            addDataListeners(this);

            % Add view listeners
            addViewListeners(this);
        end

        function fig = getHGParent(this)
            % Get Figure for editor
            ax = getAxes(this.Axes);
            fig = ancestor(ax(1),'figure');
        end

        function setEditModeAndData(this,EditMode, EditModeData)
            % Turn of zoom and pan modes
            ax = getAxes(this.Axes);
            for kax = 1:length(ax)
                zoom(ax(kax),'off');
                pan(ax(kax),'off');
            end
            if strcmpi(EditMode, 'addpz')
                % addpz
                try
                    C = addPZDialog(this,EditModeData.Group,EditModeData.Root);
                    if isempty(C)
                        error(message('Controllib:general:UnexpectedError','Operation Cancelled'));
                    end
                    this.Data.AddPZCompensator = C;
                catch ME
                    EditMode = 'idle';
                    EditModeData = [];
                    if ~strcmpi(ME.message,getString(message('Controllib:general:UnexpectedError','Operation Cancelled')))
                        appContainer = getAppContainer(this.EventManager);
                        uialert(appContainer,ME.message,...
                            getString(message('Control:compDesignTask:strAddPoleZero')));
                    end
                end
            end
            setEditModeAndData(this.ModeManager, EditMode, EditModeData);
            if strcmp(EditMode,'zoom') && strcmp(EditModeData,'out')
                zoomout(this);
            end
            this.EditMode = EditMode;
        end


        % Requested by graphical widgets
        function b = isMultiModelVisible(this)
            b = this.UncertainBounds.isVisible;
        end

        function axes = getaxes(this,varargin)
            axes = getAxes(this.Axes);
        end

        function setRefreshMode(this, RM)
            % Branch for two types of RM value and event data
            if ~ischar(RM)
                RM = RM.Data;
            end
            if ~strcmpi(this.RefreshMode,RM);
                this.RefreshMode = RM;
                Comp = this.Data.EditedBlock;
                if strcmpi(RM,'normal')
                    this.update;
                end
                setRefreshMode(Comp,RM)
            end

        end

        function FrequencyUnits = get.FrequencyUnits(this)
            FrequencyUnits = this.Preferences.FrequencyUnits;
        end

        % Signatures
        % Required by constraints
        addconstr(this,constr);
        SavedData = saveconstr(this);
        loadconstr(this,S);
        rbundle = constrresbundle(this, rbundle);
    end

    methods (Access = public, Hidden = true)
        function R = getResponse(this)
            R = getResponse(this.Data);
        end
    end

    methods
        %% Getters and Setters
        function set.EditModeData(this,EditModeData)
        end

        function set.EditMode(this,EditMode)
        end

        function Mode = get.EditMode(this)
            Mode = this.ModeManager.Mode;
        end

        function ModeData = get.EditModeData(this)
            ModeData = this.ModeManager.ModeData;
        end

        function lineStyle = get.LineStyle(this)
            lineStyle = this.LineStyle_I;
        end

        function set.LineStyle(this, LineStyle)
            this.LineStyle_I = LineStyle;
            update(this,false);
        end

        function set.LabelColor(this, Color)
            setLabelColor(this, Color);
            this.LabelColor = Color;
        end

        function setLabelColor(this, Color)
            
        end

        function showSystemPZ = get.ShowSystemPZ(this)
            showSystemPZ = this.ShowSystemPZ_I;
        end

        function set.ShowSystemPZ(this, ShowSystemPZ)
            this.ShowSystemPZ_I = ShowSystemPZ;
            setShowSystemPZ(this, ShowSystemPZ);
        end

        function setShowSystemPZ(this, ShowSystemPZ)
            if ~isempty(this.ResponseViewWidget)
                for ct = 1:numel(this.ResponseViewWidget)
                    this.ResponseViewWidget(ct).ShowSystemPZ = ShowSystemPZ;
                end
            end
            update(this,false);
        end
    end

    methods (Access = protected)
        %% Methods needed by sub-classes
        h = addmenu(this, Anchor, MenuType);
        inticonstr(this, constr);
        setmenu(this, OnOff, Tag);
        xylabelvis(Editor,Xvis,Yvis);

        function clear(this)
            setmenu(this, 'off');
            % Clear all HG objects
            for ct=1:numel(this.ResponseViewWidget)
                HG = getHG(this.ResponseViewWidget(ct));
                set(HG,'XData',NaN,'YData',NaN, 'ZData', NaN);
            end

            for ct=1:numel(this.PZViewWidget)
                HG = getHG(this.PZViewWidget(ct));
                set(HG,'XData',NaN,'YData',NaN, 'ZData', NaN);
            end
        end

        function configureAxesStyle(this)
            this.Axes.Style.Title.FontSize = this.Preferences.TitleFontSize;
            this.Axes.Style.Title.FontWeight = this.Preferences.TitleFontWeight;
            this.Axes.Style.Title.FontAngle = this.Preferences.TitleFontAngle;
            this.Axes.Style.XLabel.FontSize = this.Preferences.XYLabelsFontSize;
            this.Axes.Style.XLabel.FontWeight = this.Preferences.XYLabelsFontWeight;
            this.Axes.Style.XLabel.FontAngle = this.Preferences.XYLabelsFontAngle;
            this.Axes.Style.YLabel.FontSize = this.Preferences.XYLabelsFontSize;
            this.Axes.Style.YLabel.FontWeight = this.Preferences.XYLabelsFontWeight;
            this.Axes.Style.YLabel.FontAngle = this.Preferences.XYLabelsFontAngle;
        end
    end

    methods (Access = public, Hidden = true)
        %% Methods needed by design optimization
        h = findconstr(this);
    end

    methods (Access = private)
        %% Private methods

        function createModeManager(this)
            if isempty(this.ModeManager)
                this.ModeManager = ctrlguis.csdesignerapp.managers.internal.ModeManager(getHGParent(this), this.Axes, this.EventManager);
            end
        end

        function addDataListeners(this)
            delete(this.DataListeners)
            this.DataListeners = addlistener(this.Data.getResponse, 'DefinitionChanged', @(es,ed)cbDefinitionChanged(this,ed));
            this.DataListeners = [this.DataListeners; addlistener(this.Data, 'DataChanged', @(es,ed)update(this))];
            this.DataListeners = [this.DataListeners; ...
                addlistener(this.Data.getResponse,'ObjectBeingDestroyed',@(es,ed) cbResponseDeleted(this))];
            this.DataListeners = [this.DataListeners; ...'
                addlistener(this.Data.getResponse,'PlantValueChanged',@(es,ed)setVisible(this))];
            this.DataListeners = [this.DataListeners; ...
                addlistener(this.Preferences, 'MultiModelFrequencySelectionData',...
                'PostSet', @(es,ed)updateMultiModelFrequency(this.Data,ed))];
            this.DataListeners = [this.DataListeners; ...
                addlistener(this.Data.getResponse,'RefreshModeChanged',@(es,ed) setRefreshMode(this,ed))];
            
            ax = getAxes(this.Axes);
            this.PlotDeleteListener = event.listener(ancestor(ax(1),'figure'), ...
                'ObjectBeingDestroyed', @(es,ed) cbPlotDeleted(this));
        end

        function addViewListeners(this)
            % Send ViewChanged event if size of parent changes
            % this.ViewListeners = [this.ViewListeners; ...
                % addlistener(this.Axes.AxesGridParent,'SizeChanged',@(es,ed) send(this.Axes,'ViewChanged'))];
        end

        function cbResponseDeleted(this)
            this.IsDataDeleted = true;
            delete(this);
        end

        function cbPlotDeleted(this)
            this.IsPlotDeleted = true;
            delete(this);
        end

        function delete(this)
            if ishandle(this.Axes)
                uic = this.Axes.UIContextMenu;
                hmenu = findobj(get(uic,'Children'),'Tag','GainTargetMenu');
                if ~isempty(hmenu) && ~isempty(hmenu.UserData)
                    delete(hmenu.UserData);
                    hmenu.UserData = [];
                end
                if ~isempty(uic) && isvalid(uic)
                    delete(uic);
                end
                if ishandle(this.getHGParent)
                    if this.IsDataDeleted
                        this.PlotDeleteListener.Enabled = false;
                    end
                    delete(this.getHGParent);
                    this.PlotDeleteListener.Enabled = true;
                end
            end

            for ct = numel(this.DataListeners):-1:1
                delete(this.DataListeners(ct));
                this.DataListeners(ct) = [];
            end
            notify(this,'GraphicalEditorDeleted');
            delete(this);
        end

        function cleanup(this)
            delete(this);
        end

        function cbDefinitionChanged(this,ed)
            if isvalid(this) && issiso(this.Data.getResponse)
                Figure = getHGParent(this);
                Figure.Name = getTitle(this);
                this.Axes.Title = getTitle(this);
                setVisible(this);
            else
                delete(this);
            end
        end

        % Signatures
        checkmenu(this, MenuMode,hMenu);
        edit(this, PropEditor);
        hgset_visible(this, varargin);
        designConstr(this,ActionType);
    end

    methods (Abstract = true, Access = protected)
        configureAxes(this);
        createGraphicalWidgets(this);
        getTitle(this);
    end

    events
        GraphicalEditorDeleted
        RequirementAdded
        LimitsChanged
    end

    methods (Hidden = true)
        %% QE Methods
        function Data = qeGetData(this)
            Data = this.Data;
        end

        function AxesViewWidget = qeGetAxesViewWidget(this)
            AxesViewWidget = this.AxesViewWidget;
        end

        function ResponseViewWidget = qeGetResponseViewWidget(this)
            ResponseViewWidget = this.ResponseViewWidget;
        end

        function PZViewWidget = qeGetPZViewWidget(this)
            PZViewWidget = this.PZViewWidget;
        end

        function ModeManager = qeGetModeManager(this)
            ModeManager = this.ModeManager;
        end

        function PZEditor = qeGetPZEditor(this)
            PZEditor = this.PZEditor;
        end

        function CE = qeGetConstraintEditor(this)
            CE = this.ConstraintEditor;
        end
        
        function qeOpenDesignConstraintDialog(this,ActionType)
            % Open design constraint dialog to edit existing requirement or create a new one
            %
            % qeOpenDesignConstraintDialog(Editor,'new')
            % qeOpenDesignConstraintDialog(Editor,'edit')
            designConstr(this,ActionType);
        end

        function qeDoubleClickAxes(this)
            % This is a method to simulate the double clock on the axes of
            % a Graphical Editor. This notifies the axes object of a 'Hit'
            % event, and the figure object of a 'WindowMouseRelease' event.
            ax = getaxes(this);
            f = ancestor(ax(1),'figure');
            if ~isempty(ax(1).ButtonDownFcn)
                notify(ax(1),'Hit');
                notify(f,'WindowMouseRelease');
                notify(ax(1),'Hit');
                notify(f,'WindowMouseRelease');
            end
        end

        function dlg = qeGetPropertyEditorDialog(this)
            dlg = this.PropertyEditorDialog;
        end
    end
end

