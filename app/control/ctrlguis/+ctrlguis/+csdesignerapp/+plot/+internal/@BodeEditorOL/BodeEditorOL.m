classdef BodeEditorOL < ctrlguis.csdesignerapp.plot.internal.GraphicalEditor
    % GraphicalEditor Base Class
    
    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties (Access = private)
        %% Bode specific Graphical Objects
        MarginsViewWidget
        
        %% Bode specific style options
        UnwrapPhase
    end
    
    properties(Dependent = true,SetObservable = true)
        %% Bode specific style options
        MagVisible = 'on';
        PhaseVisible = 'on';
        MarginVisible = 'on';
    end
    
    methods
        %% Constructor, public API and Getters and Setters
        function this = BodeEditorOL(Response,Preferences, EventManager, PZEditor, ConstraintEditor)
            % Create data object
            Data = ctrlguis.csdesignerapp.data.internal.BodeEditorData(Response, Preferences);
            tag = "BodeEditor_" + getName(Response) + "_" + matlab.lang.internal.uuid;
            
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.plot.internal.GraphicalEditor(Data, Preferences, EventManager, PZEditor, ConstraintEditor, tag);
            this.Type = 'Bode';
            
            % Create uncertain bounds object
            this.UncertainBounds = sisogui.BodeUncertain(this);
            
            % Set color and zlevel for multimodel display
            this.UncertainBounds.setZLevel(this.getZLevel('multimodel'));
            this.UncertainBounds.setColor(this.LineStyle.Color.Response);
            
            % udpate data
            update(this.Data);
            
            % Add menus
            initialize(this);
            
            % Initialize preferences
            initializePreferences(this,Preferences);
        end
        
        function setVisible(this)
            this.EditMode = 'idle';
            
            this.Axes.Visible = 'on';
            
            this.setmenu('on');
            
            % List of tunable blocks can change
            initializeCompensatorTarget(this.Data);
            
            update(this.Data);
            % Turn on multi-model characteristics
            if this.Data.isUncertain
                % Enable Multi Model Menu
                setmenu(this,'on','multiplemodel');
                % If not visible show menu
                if ~this.UncertainBounds.isVisible
                    this.UncertainBounds.Visible = 'on';
                end
            else
                % Disable Multi Model Menu
                setmenu(this,'off','multiplemodel')
                this.UncertainBounds.Visible = 'off';
            end
            
            if strcmp(this.Axes.XLimitsMode,'auto') && all(strcmp(this.Axes.YLimitsMode(:),{'auto';'auto'}))
                setmenu(this,'off','fullview');
            else
                setmenu(this,'on','fullview');
            end
            
            update(this);
        end
        
        function refresh(this,Action,widget)
            switch Action
                case 'start'
                    % Find which widget it is
                    list = [this.PZViewWidget(:); this.ResponseViewWidget(:); this.MarginsViewWidget(:)];
                    idx = arrayfun(@(x) isequaln(x,widget),list);
                    if any(idx)
                        this.OtherWidgets = list(~idx);
                        %             [this.Widgets(1:idx-1),this.Widgets(idx+1:end)];
                    end
                case 'move'
                    for ct = 1:numel(this.OtherWidgets)
                        refresh(this.OtherWidgets(ct));
                    end
            end
        end
        
        function update(this,updateLimitsFlag)
            arguments
                this
                updateLimitsFlag = true
            end

            % Revisit: SingularLoop
            if strcmpi(this.Axes.Visible, 'on')
                % Update only if visible
                % Set the edit mode back to idle
                setEditModeAndData(this, 'idle', []);
                
                % Data
                update(this.Data);

                if this.Data.SingularLoop
                    clear(this); return;
                end
                
                % Check for ViewUpdateEnabled flag (Set by Response
                % Optimization object)
                if ~this.ViewUpdateEnabled
                    return
                end
                
                % Update widgets
                if ~isempty(this.ResponseViewWidget)
                    for ct = 1:size(this.ResponseViewWidget,1)
                        update(this.ResponseViewWidget(ct));
                    end
                end
                
                % Tunable poles and zeros
                % Revisit: Method on Data to go through list of all blocks that
                % can be edited
                PZGroups = [];
                Compensators = getTunedFactors(this.Data.getResponse);
                for ct = 1:numel(Compensators)
                    if isTunable(Compensators(ct))
                        PZGroups = [PZGroups; Compensators(ct).PZGroup];
                    end
                end
                
                Nf = length(PZGroups);
                Nc = size(this.PZViewWidget,1);
                
                % Delete extra groups
                if Nc>Nf,
                    target(this.ModeManager, 'uninstall',this.PZViewWidget(Nf+1:Nc,:));
                    delete(this.PZViewWidget(Nf+1:Nc,:));
                    this.PZViewWidget = this.PZViewWidget(1:Nf,:);
                end
                
                % Add new groups
                for ct=Nc+1:Nf,
                    this.PZViewWidget = [this.PZViewWidget; ...
                        ctrlguis.csdesignerapp.widgets.internal.BodePZView(this,this.Data, this.Axes, PZGroups(ct)),...
                        ctrlguis.csdesignerapp.widgets.internal.BodePZView(this,this.Data,this.Axes, PZGroups(ct), true)];
                    target(this.ModeManager, 'install',[this.PZViewWidget(end,:)]);
                end
                
                % Retarget existing views to appropriate pz groups
                for ct = 1:Nf
                    setPZGroup(this.PZViewWidget(ct,1), PZGroups(ct));
                    setPZGroup(this.PZViewWidget(ct,2), PZGroups(ct));
                end
                
                % update pz groups
                if ~isempty(this.PZViewWidget)
                    % Unistall and reinstall to make sure new HG widgets are
                    % registered with mode manager
                    for ct = 1:size(this.PZViewWidget,1)
                        target(this.ModeManager, 'uninstall',this.PZViewWidget(ct,1));
                        update(this.PZViewWidget(ct,1));
                        target(this.ModeManager, 'install',this.PZViewWidget(ct,1));
                        
                        
                        target(this.ModeManager, 'uninstall',this.PZViewWidget(ct,2));
                        update(this.PZViewWidget(ct,2));
                        target(this.ModeManager, 'install',this.PZViewWidget(ct,2));
                    end
                end
                
                % update multimodel data
                if ~isempty(this.UncertainBounds) && this.Data.isUncertain && this.isMultiModelVisible
                    GainMag = getGain(this.Data);
                    UMagnitude = this.Data.UncertainData.Magnitude;
                    UPhase = this.Data.UncertainData.Phase;
                    uw = this.Data.UncertainData.Frequency;
                    this.UncertainBounds.setData(GainMag*UMagnitude,UPhase,uw(:));
                    setColor(this.UncertainBounds,this.LineStyle.Color.Response);
                end
                
                % update margins
                if isLoopTransfer(this.Data.getResponse)
                    if ~isempty(this.MarginsViewWidget) && isvalid(this.MarginsViewWidget)
                        update(this.MarginsViewWidget);
                    end
                end

                if strcmpi(this.RefreshMode,'normal')
                    % this.Axes.send('ViewChanged');
                end
                
                if updateLimitsFlag
                    updatelims(this);
                end
            end
        end
        
        function updatelims(this)
            %UPDATELIMS  Limit picker for Bode editors.
            
            if this.Data.SingularLoop
                % Editor is inactive or has no data (algebraic inner loop)
                return
            end
            Ax = this.Axes;
            PlotAxes = getAxes(Ax);
            
            % Enforce limit modes at HG axes level
            if Ax.MagnitudeVisible
                set(PlotAxes(1),'XlimMode',Ax.XLimitsMode,'YlimMode',Ax.YLimitsMode{1})
                if Ax.PhaseVisible
                    set(PlotAxes(2),'XlimMode',Ax.XLimitsMode,'YlimMode',Ax.YLimitsMode{2})
                end
            elseif Ax.PhaseVisible
                set(PlotAxes(2),'XlimMode',Ax.XLimitsMode,'YlimMode',Ax.YLimitsMode{1});
            end
            
            focus = getfocus(this);
            this.Axes.XLimitsFocus = {focus; focus};
            
            % Acquire Y limits
            YlimP = get(PlotAxes(2),'Ylim');

            %             Adjust phase ticks and limits for units = degrees
            if ~Ax.PhaseVisible
                phaseLimitsMode = PlotAxes(2).YLimMode;
            else
                if Ax.MagnitudeVisible
                    phaseLimitsMode = Ax.YLimitsMode{2};
                else
                    phaseLimitsMode = Ax.YLimitsMode{1};
                end
            end

            set(PlotAxes(2),'YtickMode','auto')
            if strcmpi(Ax.PhaseUnit,'deg')
                Yticks = get(PlotAxes(2),'YTick');
                if strcmp(phaseLimitsMode,'auto')
                    % Auto mode. Check tight phase extent (limit picker may round up 180 to 200)
                    NewTicks = phaseticks(Yticks,YlimP,this.yextent('phase'));
                else
                    % Fixed limits
                    NewTicks = phaseticks(Yticks,YlimP);
                end
                set(PlotAxes(2),'YTick',NewTicks)
            end            
            
            if ~isempty(this.MarginsViewWidget) && isvalid(this.MarginsViewWidget)
                update(this.MarginsViewWidget);
                adjustDisplay(this.MarginsViewWidget);
            end

            notify(this.Axes,'LimitsChanged');
        end
        
        function Focus = getfocus(this)
            %GETFOCUS  Computes scale-aware X focus.
            % Conversion factors
            FreqConvert = funitconv('rad/s',this.Axes.FrequencyUnit);
            
            Ts = this.Data.Ts;
            if Ts
                NyqFreq = FreqConvert * pi/Ts;
            else
                NyqFreq = NaN;
            end
            
            % Resolve undetermined focus (quasi-integrator)
            if any(isnan(this.Data.FreqFocus))
                % Look for 0dB gain crossings to anchor focus
                UnitGain = unitconv(1,'abs','dB');
                idxc = find((this.Data.Magnitude(1:end-1)-UnitGain).*(this.Data.Magnitude(2:end)-UnitGain)<=0);
                if ~isempty(idxc)
                    idxc = idxc(round(end/2));
                    this.Data.FreqFocus = [this.Data.Frequency(idxc)/10 , 10*this.Data.Frequency(idxc+1)];
                elseif Ts
                    this.Data.FreqFocus = NyqFreq * [0.05,1];
                else
                    this.Data.FreqFocus = [0.1,1];
                end
            end
            
            Focus = this.Data.FreqFocus;
            
            if ~isempty(Focus)
                if strcmp(this.Axes.FrequencyScale,'log')
                    % Round to entire decade in current units
                    % RE: This avoids irritating Y clipping when X focus is extended to
                    %     nearest decade
                    Focus = Focus*funitconv('rad/s',this.Axes.FrequencyUnit);
                    Focus = log10(Focus);
                    Focus = 10.^[floor(Focus(1)),ceil(Focus(2))];
                    Focus = Focus*funitconv(this.Axes.FrequencyUnit,'rad/s');
                end
            end
        end
        
        function zdata = getZLevel(this,ObjectType,TargetSize)
            %ZLEVEL  Generates Z data for Z layering of objects.
            
            switch ObjectType
                case 'constraint'
                    zdata = -7;
                case 'backgroundline'
                    zdata = -6;
                case 'multimodel'
                    zdata = -5;
                case 'curve'
                    zdata = -4;
                case 'system'
                    zdata = -3;
                case 'margin'
                    zdata = -2;
                case 'compensator'
                    zdata = -1;
                case 'margintext'
                    zdata = 0;
                otherwise
                    zdata = 0;
            end
            
            if nargin==3
                zdata = repmat(zdata,TargetSize);
            end
            
        end
        
        % Getters and Setters
        function bool = get.MagVisible(this)
            bool = this.Axes.MagnitudeVisible;
        end
        
        function set.MagVisible(this,bool)
            % this.Axes.LimitManager = 'off';
            this.Axes.Visible = 'on';
            this.Axes.MagnitudeVisible = bool;
            % this.Axes.LimitManager = 'on';
            updatelims(this);
            % Set X/Y label visibility according to internal states (conditioned by layout)
            % xylabelvis(this)
            
        end
        
        function bool = get.PhaseVisible(this)
            bool = this.Axes.PhaseVisible;
        end
        
        function set.PhaseVisible(this,bool)
            % this.Axes.LimitManager = 'off';
            this.Axes.Visible = 'on';
            this.Axes.PhaseVisible = bool;
            % this.Axes.LimitManager = 'on';
            
            % Set X/Y label visibility according to internal states (conditioned by layout)
            % xylabelvis(this)
        end
        
        function bool = get.MarginVisible(this)
            if isempty(this.MarginsViewWidget)
                % Could get in here with emtpy margins view widget while
                % loading a closed loop bode plot
                bool = false;
            else
                bool = isMarginsVisible(this.MarginsViewWidget);
            end
        end
        
        function set.MarginVisible(this,bool)
            if ~isempty(this.MarginsViewWidget)
                % Could get in here with emtpy margins view widget while
                % loading a closed loop bode plot
                toggleVisibility(this.MarginsViewWidget,bool);
            end
        end
        
        function Lines = getHG_PZ(this)
            Lines = getHG_PZ(this.PZViewWidget);
        end
        
        function addPZ(this, PlotAxes)
            % Gather info about added root
            AddInfo =  this.EditModeData;
            
            this.EventManager.postActionStatus('off',getString(message('Control:compDesignTask:msgReleaseMouseAddPZ')));
            
            % Determine which Compensator to add PZGroup to
            %                     C = addPZDialog(Editor, AddInfo.Group, AddInfo.Root);
            
            %                     if isempty(C)
            %                         % No valid compensators to add pzgroup to
            %                         return
            %                     end
            %             C = this.Data.EditedBlock;
            C = this.Data.AddPZCompensator;
            % Pointers
            Ts = this.Data.Ts;
            % EventMgr = Editor.EventManager;
            
            % Acquire new pole/zero position
            % RE: Adjust position based on pole/zero type
            CP = get(PlotAxes,'CurrentPoint');
            
            % LocalGetRootValue expects X to be in rad/s
            X = CP(1,1)*funitconv(this.Axes.FrequencyUnit,'rad/s');
            [Zeros,Poles,GroupType,Status,Action] = LocalGetRootValue(X,...
                AddInfo.Group,AddInfo.Root,Ts,C.getIdentifier);
            
            % Start transaction
            Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction(Action);
            
            % Add new pole/zero group to database
            % Set undo function
            S = saveSession(C);
            Transaction.UndoFcn = {@loadSession C S};
            
            C.addPZ(GroupType,Zeros,Poles);
            
            % Set redo function
            S = saveSession(C);
            Transaction.RedoFcn = {@loadSession C S};
            
            % Register transaction
            this.EventManager.record(Transaction);
            
            this.EventManager.postActionStatus('off',Status);
            this.EventManager.add2Hist(Status);
            
            % Reset warnings
            warning(this.ModeManager.Warning.sw); lastwarn(this.ModeManager.Warning.lw, this.ModeManager.Warning.lwid)
            
            setEditModeAndData(this,'idle', []);
        end
        
        % Load/Save
        function S = saveSession(this, ResponseList,CompensatorList)
            Response = getResponse(this.Data);
            ResponseIdx = find(Response==ResponseList);
            Axes = this.Axes;
            PlotAxes = getAxes(Axes);
            if ~isempty(this.Data.GainTargetBlock)
                GainTargetBlock = find(this.Data.GainTargetBlock==CompensatorList);
            else
                GainTargetBlock = [];
            end
            
            stylesToSave = ['Title';"XLabel";"YLabel"];
            stylePropsToSave = ["FontSize";"FontWeight";"FontAngle";"FontName";"Color";"Interpreter";"Rotation"];
            styleStruct = struct.empty;
            for ii = 1:length(stylesToSave)
                for jj = 1:length(stylePropsToSave)
                    styleStruct(ii).(stylePropsToSave(jj)) = Axes.Style.(stylesToSave(ii)).(stylePropsToSave(jj));
                end
            end
            S = struct(...
                'ToolID','Bode',...
                'Response', ResponseIdx, ...
                'EditedBlock',find(this.Data.EditedBlock==CompensatorList),...
                'GainTargetBlock',  GainTargetBlock,...
                'Constraints',this.saveconstr,...
                'Grid',Axes.Style.Axes.XGrid,...
                'Title',Axes.Title,...
                'TitleStyle',styleStruct(1),...
                'XlabelStyle',styleStruct(2),...
                'YlabelStyle',styleStruct(3),...
                'Xlabel',Axes.XLabel,...
                'Xlim',{get(PlotAxes(1),'Xlim')},...
                'XlimMode',{Axes.XLimitsMode},...
                'Ylabel',{Axes.YLabel},...
                'Ylim',{get(PlotAxes,'Ylim')},...
                'YlimMode',{Axes.YLimitsMode},...
                'MagVisible',this.MagVisible,...
                'MarginVisible',this.MarginVisible,...
                'PhaseVisible',this.PhaseVisible);
        end
        
        function loadSession(this,S)
            %LOAD  Restores saved Bode Editor settings.
            %
            %   See also SISOTOOL.
            
            % RE: 1) Editor should be made invisible prior to calling this
            %        function to avoid multiple updates
            %     2) Only set properties that may differ from tool prefs
            EditedBlock = S.EditedBlock;
            GainTargetBlock = S.GainTargetBlock;
            setEditedBlock(this.Data,EditedBlock);
            this.Data.GainTargetBlock = GainTargetBlock;
            
            Axes = this.Axes;
            %             SavedData = loadconvert(this,SavedData,Version);
            % Labels
            Axes.Title = S.Title;
            Axes.XLabel = S.Xlabel;
            
            % Limits
            % Beware of reloading stale units (see geck 113670)
            set(getAxes(Axes),'Xlim',S.Xlim,{'Ylim'},S.Ylim)
            Axes.XLimitsMode = S.XlimMode;
            Axes.YLimitsMode = S.YlimMode;
            
            % Grid
            Axes.Style.Axes.XGrid = S.Grid;
            Axes.Style.Axes.YGrid = S.Grid;
            
            % Plot visibility
            this.MagVisible = S.MagVisible;
            this.PhaseVisible = S.PhaseVisible;
            if isLoopTransfer(this.Data.getResponse)
                this.MarginVisible = S.MarginVisible;
            end
            % Constraints
            this.loadconstr(S.Constraints);
        end
        
        % Preferences
        function setunits(this,Type,NewValue)
            % Sets editor units.
            
            %   Copyright 1986-2003 The MathWorks, Inc.
            Axes = this.Axes;
            switch Type
                case 'FrequencyUnits'
                    Axes.FrequencyUnit = NewValue;
                case 'MagnitudeUnits'
                    % RE: Not affecting Nichols editor
                    % When going to dB with yscale = log, set Yscale='linear' to prevent
                    % Negative Data Ignored warnings
                    % REVISIT: condense lines below
                    if strcmpi(NewValue, 'dB')
                        Axes.MagnitudeScale = 'linear';
                    end
                    Axes.MagnitudeUnit = NewValue;
                case 'PhaseUnits'
                    Axes.PhaseUnit = NewValue;
            end
            for k = 1:length(this.ResponseViewWidget)
                refresh(this.ResponseViewWidget(k));
            end

            for k = 1:length(this.MarginsViewWidget)
                refresh(this.MarginsViewWidget(k));
            end

            for k = 1:length(this.PZViewWidget)
                refresh(this.PZViewWidget(k));
            end

            updatelims(this);
        end
        
        function setscale(this,Type,NewValue)
            % Sets editor scale
            
            %   Copyright 1986-2003 The MathWorks, Inc.
            Axes = this.Axes;
            switch Type
                case 'FrequencyScale'
                    Axes.FrequencyScale = NewValue;
                case 'MagnitudeScale'
                    Axes.MagnitudeScale = NewValue;
            end
        end
        
        function document = getDocument(this)
            document = this.Document;
        end
        
        function documentGroup = getDocumentGroup(this)
            documentGroup = this.DocumentGroup;
        end
    end
    methods (Access = protected)
        % Called by super-class
        function configureAxes(this)
            % Set the title
            Title = getTitle(this);
            
            if isempty(this.Axes) || ~isvalid(this.Axes)
                % get default preferences:
                Preferences = this.Preferences;
                % Create Figure Document
                figOptions.Title = Title;
                figOptions.DocumentGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                                                    "BodeEditorDocumentGroup");
                this.Document = matlab.ui.internal.FigureDocument(figOptions);
                this.Document.Figure.AutoResizeChildren = 'off';
                this.Document.Tag = this.ContextualTag;
                fig = this.Document.Figure;
                fig.Tag = "CSDAppBodeEditor";
                
                h = controllib.chart.BodePlot(Parent=fig);
                h.FrequencyUnit = Preferences.FrequencyUnits;
                h.MagnitudeUnit = Preferences.MagnitudeUnits;
                h.PhaseUnit = Preferences.PhaseUnits;
                h.FrequencyScale = Preferences.FrequencyScale;
                h.MagnitudeScale = Preferences.MagnitudeScale;
                h.AxesStyle.GridVisible = Preferences.Grid;
                h.Title.String = Title;
                h.XLabel.String = getString(message('Control:compDesignTask:strFrequency'));
                h.YLabel.String = {getString(message('Control:compDesignTask:strMagnitude'));...
                        getString(message('Control:compDesignTask:strPhase'))};
                this.Axes = qeGetView(h);
                ag = qeGetAxesGrid(this.Axes);
                enableDisableAxesLimitModeListeners(ag);
                ax = getChartAxes(h);
                % Magnitude axes
                MagAxes = ax(1);
                MagAxes.Units = 'norm';
                MagAxes.Box = 'on';
                MagAxes.XLim = [0.1 10];
                MagAxes.XTickLabel = [];
                MagAxes.YLim = round(unitconv([-20,20],'dB',Preferences.MagnitudeUnits));
                MagAxes.ContextMenu = [];
                disableDefaultInteractivity(MagAxes);
                % Phase axes
                PhaseAxes = ax(2);
                PhaseAxes.Units = 'norm';
                PhaseAxes.Box = 'on';
                PhaseAxes.XLim = [0.1 10];
                PhaseAxes.XTickLabel = [];
                PhaseAxes.YLim = round(unitconv([-90 90],'deg',Preferences.PhaseUnits));
                PhaseAxes.ContextMenu = [];
                disableDefaultInteractivity(PhaseAxes);

                this.Axes.XLimitsSharing = "column";
                this.Axes.YLimitsSharing = "row";
                this.Axes.XLimitsMode = "auto";
                this.Axes.YLimitsMode = "auto";
            end
        end
        
        function createGraphicalWidgets(this)
            % Axes
            
            % Magnitude
            this.AxesViewWidget = [this.AxesViewWidget; ctrlguis.csdesignerapp.widgets.internal.AxesView(this, this.Data, this.Axes)];
            target(this.ModeManager, 'install',this.AxesViewWidget);
            
            % Phase
            this.AxesViewWidget = [this.AxesViewWidget; ctrlguis.csdesignerapp.widgets.internal.AxesView(this, this.Data, this.Axes, true)];
            target(this.ModeManager, 'install',this.AxesViewWidget(end));
            
            % Magnitude
            this.ResponseViewWidget = [this.ResponseViewWidget; ctrlguis.csdesignerapp.widgets.internal.BodeResponseView(this, this.Data, this.Axes)];
            
            % Phase
            this.ResponseViewWidget = [this.ResponseViewWidget; ctrlguis.csdesignerapp.widgets.internal.BodeResponseView(this, this.Data, this.Axes, true)];
            
            % Target response widgets
            target(this.ModeManager, 'install',this.ResponseViewWidget);
            
            % Margins
            
            if isLoopTransfer(this.Data.getResponse)
                this.MarginsViewWidget = ctrlguis.csdesignerapp.widgets.internal.MarginsView(this, this.Data, this.Axes);
            end
            %             this.MarginsViewWidget = ctrlguis.csdesignerapp.widgets.internal.MarginsView(this, this.Data, this.Axes);
            
            update(this.Data);
            updatelims(this);
        end
        
        function Title = getTitle(this)
            Name = getName(this.Data);
            Title = getString(message('Control:compDesignTask:strBodeEditorTitle1',Name));
        end
        
        function clear(this)
            clear@ctrlguis.csdesignerapp.plot.internal.GraphicalEditor(this);
            if ~isempty(this.MarginsViewWidget)
                HG = getHG(this.MarginsViewWidget);
                for ct=1:numel(HG)
                    if isa(HG(ct),'matlab.graphics.primitive.Text')
                        HG(ct).String = '';
                    else
                        s = size(HG(ct).XData);
                        set(HG(ct),'XData', NaN(s),'YData',NaN(s),'ZData',HG(ct).ZData);
                    end
                end
            end
            this.UncertainBounds.setData(NaN,NaN,NaN);
        end
        
    end
    
    methods (Access = private)
        function initializePreferences(this, Preferences)
            this.LineStyle = Preferences.LineStyle;
            this.ShowSystemPZ = Preferences.ShowSystemPZ;
            this.UnwrapPhase = Preferences.UnwrapPhase;
        end
        
        function Range = yextent(this,type)
            %YEXTENT  Finds Y extent of visible data.
            
            % Current X limits (in rad/sec)
            PlotAxes = getAxes(this.Axes);
            Xlims = get(PlotAxes(1),'Xlim')*funitconv(this.Axes.FrequencyUnit,'rad/s');
            W = this.Data.Frequency;
            
            % Find minimal non-empty coverage of Xlims
            idxs = max([1;find(W<Xlims(1))]);
            idxe = min([find(W>Xlims(2));length(W)]);
            
            switch type
                case 'mag'
                    VisData = this.Data.Magnitude(idxs:idxe);
                case 'phase'
                    VisData = this.Data.Phase(idxs:idxe);
                    %                     phsMrgn = this.HG.PhaseMargin;
                    phsMrgn = [];
                    if ~isempty(phsMrgn),
                        % Include phase margin line
                        VisData = [VisData ; reshape(get(phsMrgn.vLine,'YData'),[2 1])];
                    end
            end
            Range = [min(VisData) , max(VisData)];
        end
    end
    
    
    methods (Hidden = true)
        %% QE Methods
        function MarginsViewWidget = qeGetMarginsViewWidget(this)
            MarginsViewWidget = this.MarginsViewWidget;
        end
    end
end

%----------------- Local functions -----------------

%%%%%%%%%%%%%%%%%%%%%
% LocalGetRootValue %
%%%%%%%%%%%%%%%%%%%%%
function [Zeros,Poles,GroupType, Status, Action] = LocalGetRootValue(X,GroupType,PZType,Ts,CompID)
% Infers specified root value from mouse location
% X is in rad/s.

% RE: * Uses only the natural frequency info (X = Wn)
%     * X is in rad/sec
if Ts
    DomainVar = 'z';
else
    DomainVar = 's';
end
CompID = sprintf('%s(%s)',CompID,DomainVar);


switch GroupType
    case 'Real'
        % Real pole/zero. RE: Assume stability
        R = c2d(-X,Ts);
        if strcmpi(PZType,'Zero')
            Zeros = R;  Poles = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedRealZero',...
                CompID,DomainVar,sprintf('%.3g',R)));
            Action = getString(message('Control:compDesignTask:strAddZero'));
        else
            Poles = R;  Zeros = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedRealPole',...
                CompID,DomainVar,sprintf('%.3g',R)));
            Action = getString(message('Control:compDesignTask:strAddPole'));
        end
        
        
    case 'Complex'
        % Complex pole zero: assume stability + damping = 1.0
        R = c2d(-X,Ts);
        if strcmpi(PZType,'Zero')
            Zeros = [R;R];  Poles = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedComplexZeros',...
                CompID,DomainVar,sprintf('%.3g %s %.3gi',real(R),'+/-',0)));
            Action = getString(message('Control:compDesignTask:strAddZeros'));
        else
            Poles = [R;R];  Zeros = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedComplexPoles',...
                CompID,DomainVar,sprintf('%.3g %s %.3gi',real(R),'+/-',0)));
            Action = getString(message('Control:compDesignTask:strAddPoles'));
        end
        
        
    case 'Lead'
        % Lead network (s+tau1)/(s+tau2)  tau1<tau2
        Zeros = c2d(-X/1.5,Ts);
        Poles = c2d(-X,Ts);
        GroupType = 'LeadLag';
        Status = getString(message('Control:compDesignTask:msgAddedLead',...
            CompID,DomainVar,sprintf('%.3g',Zeros),DomainVar,sprintf('%.3g',Poles)));
        Action = getString(message('Control:compDesignTask:strAddLead'));
        
    case 'Lag'
        % Lag network (s+tau1)/(s+tau2)  tau1>tau2
        Zeros = c2d(-1.5*X,Ts);
        Poles = c2d(-X,Ts);
        GroupType = 'LeadLag';
        Status = getString(message('Control:compDesignTask:msgAddedLag',...
            CompID,DomainVar,sprintf('%.3g',Zeros),DomainVar,sprintf('%.3g',Poles)));
        Action = getString(message('Control:compDesignTask:strAddLag'));
        
    case 'Notch'
        % Notch filter: default is zeta1=0.05,zeta2=0.5 (1/2 max width and 20dB depth)
        z1 = 0.05;   z2 = 0.5;
        r1 = X * (-z1 + 1i*sqrt(1-z1^2));
        r2 = X * (-z2 + 1i*sqrt(1-z2^2));
        Zeros = c2d([r1;conj(r1)],Ts);
        Poles = c2d([r2;conj(r2)],Ts);
        Status = getString(message('Control:compDesignTask:msgAddedNotch',...
            CompID,DomainVar,sprintf('%.3g %s %.3gi',real(Zeros(1)),'+/-',abs(imag(Zeros(1)))),...
            DomainVar,sprintf('%.3g %s %.3gi',real(Poles(1)),'+/-',abs(imag(Poles(1))))));
        Action = getString(message('Control:compDesignTask:strAddNotch'));
end
end


function r = c2d(r,Ts)
% Get equivalent root value in discrete-time domain
if Ts
    r = exp(Ts*r);
end
end
