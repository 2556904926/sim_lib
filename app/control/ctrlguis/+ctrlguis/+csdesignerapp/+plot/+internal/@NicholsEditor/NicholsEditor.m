classdef NicholsEditor < ctrlguis.csdesignerapp.plot.internal.GraphicalEditor
    % GraphicalEditor Base Class
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (Access = private)
        %% Bode specific Graphical Objects
        MarginsViewWidget
        
        %% 0 dB Axis Line
        AxisLine
        
    end
    
    
    properties(Dependent = true,SetObservable = true)
        %% Bode specific style options
        MagVisible = 'on';
        PhaseVisible = 'on';
        MarginVisible = 'on';
    end
    
    methods
        %% Constructor, public API and Getters and Setters
        function this = NicholsEditor(Response,Preferences, EventManager, PZEditor, ConstraintEditor)
            
            % Create data object
            Data = ctrlguis.csdesignerapp.data.internal.NicholsEditorData(Response, Preferences);
            tag = "NicholsEditor_" + getName(Response) + "_" + matlab.lang.internal.uuid;
            
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.plot.internal.GraphicalEditor(Data, Preferences, EventManager, PZEditor, ConstraintEditor,tag);
            this.Type = 'Nichols';
            
            % Create uncertain bounds object
            this.UncertainBounds = sisogui.NicholsUncertain(this);
            
            % Set color and zlevel for multimodel display
            if ~isempty(this.UncertainBounds) && isvalid(this.UncertainBounds)
                this.UncertainBounds.setZLevel(this.getZLevel('multimodel'));
                this.UncertainBounds.setColor(this.LineStyle.Color.Response);
            end
            
            % update data
            update(this.Data);
            
            % Add menus
            initialize(this);
            
        end
        
        function setVisible(this)
            this.EditMode = 'idle';
            this.setmenu('on');
            this.Axes.Visible = 'on';
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
            
            if strcmp(this.Axes.XLimitsMode{1},'auto') && all(strcmp(this.Axes.YLimitsMode{1},'auto'))
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

            % if this.Document.Showing

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
                        ctrlguis.csdesignerapp.widgets.internal.NicholsPZView(this,this.Data, ...
                        this.Axes, PZGroups(ct))];
                    target(this.ModeManager, 'install',this.PZViewWidget(end,:));
                end
                
                % Retarget existing views to appropriate pz groups
                for ct = 1:Nf
                    setPZGroup(this.PZViewWidget(ct,1), PZGroups(ct));
                end
                
                % update pz groups
                if ~isempty(this.PZViewWidget)
                    % Unistall and reinstall to make sure new HG widgets are
                    % registered with mode manager
                    for ct = 1:size(this.PZViewWidget,1)
                        target(this.ModeManager, 'uninstall',this.PZViewWidget(ct,1));
                        update(this.PZViewWidget(ct,1));
                        target(this.ModeManager, 'install',this.PZViewWidget(ct,1));
                    end
                end
                
                % update multimodel data
                if ~isempty(this.UncertainBounds) && this.Data.isUncertain && this.isMultiModelVisible
                    GainMag = getGain(this.Data);
                    UMagnitude = this.Data.UncertainData.Magnitude;
                    UPhase = this.Data.UncertainData.Phase;
                    uw = this.Data.UncertainData.Frequency;
                    this.UncertainBounds.setData(GainMag*UMagnitude,UPhase,uw(:));
                end
                %
                %                 % update margins
                if ~isempty(this.MarginsViewWidget) && strcmp(this.MarginVisible,'on')
                    update(this.MarginsViewWidget);
                end

                if updateLimitsFlag
                    updatelims(this);
                end
            end
            % end
        end
        
        function updatelims(Editor)
            %UPDATELIMS  Resets axis limits.
            
            % Return if Editor is inactive
            if Editor.Data.SingularLoop
                return;
            end
            
            Axes = Editor.Axes;
            PlotAxes = getAxes(Axes);
            AutoX = strcmp(Axes.XLimitsMode{1},'auto');
            
            % Enforce limit modes at HG axes level
            set(PlotAxes,'XlimMode',Axes.XLimitsMode{1},'YlimMode',Axes.YLimitsMode{1})
            
            % Acquire limits (automatically includes other objects such as constraints
            % and compensator poles and zeros)
            Xlim = get(PlotAxes,'XLim');
            Ylim = get(PlotAxes,'YLim');
            
            % Adjust limits if grid is on (show full 180 degree sections)
            PhaseExtent = Editor.xyextent('phase');
            if strcmp(Axes.Style.Axes.XGrid,'on')
                if AutoX
                    Xlim = niclims('phase', Xlim, Axes.PhaseUnit);
                    PhaseExtent = niclims('phase', PhaseExtent, Axes.PhaseUnit);
                    if false %RE: hasDelay(Editor.Data.getResponse)
                        % Limit windings when system has delays to N revolutions or
                        % value set by highest frequency tunable pole/zero
                        effectivePi = unitconv(pi,'rad',Axes.PhaseUnit);
                        maxgap = 10*effectivePi;
                        if (Xlim(2)-Xlim(1))> maxgap
                            Xlim(1) = Xlim(1) + 2*effectivePi* floor(abs((Xlim(2)- Xlim(1) - maxgap))/ (2*effectivePi));
                            % Determine if phase should be extended based on tunable
                            % dynamics
                            L = -this.Data.getOpenLoop;
                            [Z,P] = getTunedPZ(L);
                            ZP = [Z(:);P(:)];
                            if ~isempty(ZP)
                                wn = max(damp(ZP,L.Ts));
                                if L.Ts
                                    wn = min(wn,pi/L.Ts);
                                end
                                MinPhaseZP = min(Editor.Phase(1:find(wn<Editor.Frequency,1)));
                                if unitconv(MinPhaseZP,'deg',Axes.PhaseUnit)<Xlim(1)
                                    Xlim(1) = unitconv(MinPhaseZP,'deg',Axes.PhaseUnit);% unitconv(MinPhaseZP,'rad',Axes.PhaseUnit);
                                end
                            end
                        end
                        
                        
                    end
                end
                if strcmp(Axes.YLimitsMode{1},'auto')
                    Ylim = niclims('mag', Ylim, 'dB');
                end
            end
            
            % Adjust phase ticks for units = degree
            set(PlotAxes, 'XtickMode', 'auto')
            if strcmpi(Axes.PhaseUnit, 'deg')
                % set(PlotAxes, 'Xlim', Xlim)
                Axes.XLimitsFocus = {Xlim};
                Xticks = get(PlotAxes, 'XTick');
                if AutoX
                    % Auto mode. Adjust limits taking into account true extent of phase data
                    [NewTicks, Xlim] = phaseticks(Xticks, Xlim, PhaseExtent);
                else
                    % Fixed limit mode
                    NewTicks = phaseticks(Xticks, Xlim);
                end
                set(PlotAxes, 'XTick', NewTicks)
            end
            
            % All low-level limit modes are manual
            Axes.XLimitsFocus = {Xlim};
            Axes.YLimitsFocus = {Ylim};
            % set(PlotAxes, 'Xlim', Xlim, 'Ylim', Ylim)
            if ~isempty(Editor.MarginsViewWidget) && isvalid(Editor.MarginsViewWidget)
                adjustDisplay(Editor.MarginsViewWidget);
            end
        end
        
        function Focus = getfocus(this)
            %GETFOCUS  Computes scale-aware X focus.
            % Conversion factors
            Ts = this.Data.Ts;
            if Ts
                NyqFreq = pi/Ts;
            else
                NyqFreq = NaN;
            end

            % Resolve undetermined focus (quasi-integrator)
            if any(isnan(this.Data.FreqFocus))
                MagData = mag2db(getGain(this.Data) * this.Data.Magnitude);
                % for 0dB gain crossings to anchor focus
                idxc = find(MagData(1:end-1).*MagData(2:end)<=0);
                if ~isempty(idxc)
                    this.Data.FreqFocus = [this.Data.Frequency(idxc(1))/10 , 10*this.Data.Frequency(idxc(1)+1)];
                elseif Ts
                    this.Data.FreqFocus = NyqFreq * [0.05,1];
                else
                    this.Data.FreqFocus = [0.1,1];
                end

            end

            Focus = this.Data.FreqFocus;

            % if ~isempty(Focus)
            %     if strcmp(this.Axes.FrequencyScale,'log')
            %         % Round to entire decade in current units
            %         % RE: This avoids irritating Y clipping when X focus is extended to
            %         %     nearest decade
            %         Focus = Focus*funitconv('rad/s',this.Axes.FrequencyUnit);
            %         Focus = log10(Focus);
            %         Focus = 10.^[floor(Focus(1)),ceil(Focus(2))];
            %         Focus = Focus*funitconv(this.Axes.FrequencyUnit,'rad/s');
            %     end
            % end
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
            bool = this.Axes.RowVisible{1};
        end
        
        function set.MagVisible(this,bool)
            this.Axes.LimitManager = 'off';
            this.Axes.Visible = 'on';
            this.Axes.RowVisible = {bool ; this.PhaseVisible};
            this.Axes.LimitManager = 'on';
            
            % Set X/Y label visibility according to internal states (conditioned by layout)
            xylabelvis(this)
            
        end
        
        function bool = get.PhaseVisible(this)
            bool = this.Axes.RowVisible{2};
        end
        
        function set.PhaseVisible(this,bool)
            this.Axes.LimitManager = 'off';
            this.Axes.Visible = 'on';
            this.Axes.RowVisible = {this.MagVisible ; bool};
            this.Axes.LimitManager = 'on';
            
            % Set X/Y label visibility according to internal states (conditioned by layout)
            xylabelvis(this)
        end
        
        function bool = get.MarginVisible(this)
            bool = isMarginsVisible(this.MarginsViewWidget);
        end
        
        function set.MarginVisible(this,bool)
            toggleVisibility(this.MarginsViewWidget,bool);
        end
        
        function Lines = getHG_PZ(this)
            Lines = getHG_PZ(this.PZViewWidget);
        end
        
        function addPZ(this, ~)
            % Gather info about added root
            AddInfo =  this.EditModeData;
            
            this.EventManager.postActionStatus('off',getString(message('Control:compDesignTask:msgReleaseMouseAddPZ')));
            
            % Determine which Compensator to add PZGroup to
            %                     C = addPZDialog(Editor, AddInfo.Group, AddInfo.Root);
            
            %                     if isempty(C)
            %                         % No valid compensators to add pzgroup to
            %                         return
            %                     end
            
            C = this.Data.AddPZCompensator;
            % Pointers
            Ts = this.Data.Ts;
            % EventMgr = Editor.EventManager;
            PlotAxes = getAxes(this.Axes);
            Gain = getGain(this.Data);
            % Set the YData in current YUnits of Axes(1)
            Magnitude = mag2db(Gain * this.Data.Magnitude);
            Phase = unitconv(this.Data.Phase, 'deg', this.Axes.PhaseUnit);
            Frequency = this.Data.Frequency*funitconv('rad/s', this.Preferences.FrequencyUnits);
            
            % Acquire new pole/zero position
            % RE: Adjust position based on pole/zero type
            CP = get(PlotAxes,'CurrentPoint');
            X = max(min(Phase), min(CP(1,1), max(Phase)));
            Y = max(min(Magnitude), min(CP(1,2), max(Magnitude)));
            
            % Find the frequency of the closest (visually) point on the Nichols curve.
            FreqPZ = this.project(X, Y, Phase, Magnitude, Frequency);
            
            % Convert Pole/Zero frequency to rad/s
            W = FreqPZ*funitconv(this.Preferences.FrequencyUnits, 'rad/s');
            
            
            % LocalGetRootValue expects X to be in rad/s
            [Zeros,Poles,GroupType,Status,Action] = LocalGetRootValue(W,...
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
            warning(this.ModeManager.Warning.sw); lastwarn(this.ModeManager.Warning.lw, this.ModeManager.Warning.lwid)

            setEditModeAndData(this, 'idle', []);
        end
        
        %% Load/Save
        function S = saveSession(this, ResponseList, CompensatorList)
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
                'ToolID','Nichols',...
                'Response', ResponseIdx, ...
                'EditedBlock',find(this.Data.EditedBlock==CompensatorList),...
                'GainTargetBlock',  GainTargetBlock,...
                'Constraints',this.saveconstr,...
                'Grid',Axes.Style.Axes.XGrid,...
                'Title',Axes.Title,...
                'TitleStyle',styleStruct(1),...
                'XlabelStyle',styleStruct(2),...
                'YlabelStyle',styleStruct(3),...
                'Xlabel',{Axes.XLabel},...
                'Xlim',{get(PlotAxes(1),'Xlim')},...
                'XlimMode',{Axes.XLimitsMode},...
                'Ylabel',{Axes.YLabel},...
                'Ylim',{get(PlotAxes,'Ylim')},...
                'YlimMode',{Axes.YLimitsMode},...
                'MarginVisible',this.MarginVisible);
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
            Axes.YLabel = S.Ylabel;
            % set(Axes.TitleStyle,S.TitleStyle);
            % set(Axes.XlabelStyle,S.XlabelStyle);
            % set(Axes.YlabelStyle,S.YlabelStyle);
            
            % Limits
            % Beware of reloading stale units (see geck 113670)
            set(getAxes(Axes),'XLim',S.Xlim,'YLim',S.Ylim)
            Axes.XLimitsMode = S.XlimMode;
            Axes.YLimitsMode = S.YlimMode;
            
            % Margins visible
            this.MarginVisible = S.MarginVisible;
            
            % Grid
            Axes.Style.Axes.XGrid = S.Grid;
            Axes.Style.Axes.YGrid = S.Grid;
            % if isfield(S,'GridOptions')
                % not available from CETM sessions
                % Axes.GridOptions = S.GridOptions;
            % end
            
            % Constraints
            this.loadconstr(S.Constraints);
        end
        
        % Preferences
        function setunits(this,Type,NewValue)
            % Sets editor units.
            
            %   Copyright 1986-2003 The MathWorks, Inc.
            switch Type
                case 'FrequencyUnits'
                    this.FrequencyUnits = NewValue;
                case 'PhaseUnits'
                    this.Axes.PhaseUnit = NewValue;
            end
            this.update;
        end
        
        function setscale(this,Type,NewScale)
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
                                                    "NicholsEditorDocumentGroup");
                this.Document = matlab.ui.internal.FigureDocument(figOptions);
                this.Document.Figure.AutoResizeChildren = 'off';
                this.Document.Tag = this.ContextualTag;
                fig = this.Document.Figure;
                fig.Tag = "CSDAppNicholsEditor";
                
                h = controllib.chart.NicholsPlot(Parent=fig);
                h.FrequencyUnit = "rad/s";
                h.PhaseUnit = Preferences.PhaseUnits;
                h.AxesStyle.GridVisible = Preferences.Grid;
                h.Title.String = Title;
                h.XLabel.String = getString(message('Control:compDesignTask:strOpenLoopPhase'));
                h.YLabel.String = getString(message('Control:compDesignTask:strOpenLoopGain'));
                this.Axes = qeGetView(h);
                ag = qeGetAxesGrid(this.Axes);
                enableDisableAxesLimitModeListeners(ag);
                ax = getChartAxes(h);
                % Magnitude axes
                MagAxes = ax(1);
                MagAxes.Units = 'norm';
                MagAxes.Box = 'on';
                MagAxes.XLim = round(unitconv([-90 90],'deg',Preferences.PhaseUnits));
                MagAxes.YLim = [.1 10];
                MagAxes.ContextMenu = [];
                disableDefaultInteractivity(MagAxes);
                
                % Create wrappers and corresponding listeners
                % RE: Set YlimMode to manual for proper limit conversion when changing units before loading data

                this.Axes.XLimitsSharing = "column";
                this.Axes.YLimitsSharing = "row";
                this.Axes.XLimitsMode = "auto";
                this.Axes.YLimitsMode = "auto";
                
                Zlevel = this.getZLevel('backgroundline');
                XYdata = infline(-Inf,Inf);
                npts = length(XYdata);
                this.AxisLine = line(XYdata,zeros(1,npts),Zlevel(:,ones(1,npts)),...
                    'XlimInclude','off','YlimInclude','off','HitTest', 'off', ...
                    'Color', Preferences.AxesForegroundColor,'LineStyle', '-.', ...
                    'Parent', getAxes(this.Axes));   
            end
            
            % Revisit: Take in controllib.ui.AppEventManager
            % this.Axes.EventManager = ctrluis.eventmgr(this.Axes);
            
            % set(this.Axes,'XLimitsMode','auto','YLimitsMode','auto')
            
            this.Axes.Title = Title;
        end
        
        function createGraphicalWidgets(this)
            % Axes
            
            % Nichols Axes
            this.AxesViewWidget = [this.AxesViewWidget; ctrlguis.csdesignerapp.widgets.internal.AxesView(this, this.Data, this.Axes)];
            target(this.ModeManager, 'install',this.AxesViewWidget);
            
            % Response Line
            this.ResponseViewWidget = [this.ResponseViewWidget; ctrlguis.csdesignerapp.widgets.internal.NicholsResponseView(this, this.Data, this.Axes)];
            % Target response widgets
            target(this.ModeManager, 'install',this.ResponseViewWidget);
            
            % Margins
            this.MarginsViewWidget = ctrlguis.csdesignerapp.widgets.internal.NicholsMarginsView(this, this.Data, this.Axes);
        end
        
        function Title = getTitle(this)
            Name = getName(this.Data);
            Title = getString(message('Control:compDesignTask:strNicholsEditorTitle1',Name));
        end
        
        function clear(this)
            clear@ctrlguis.csdesignerapp.plot.internal.GraphicalEditor(this);
            HG = getHG(this.MarginsViewWidget);
            for ct=1:numel(HG)
                if isa(HG(ct),'matlab.graphics.primitive.Text')
                    HG(ct).String = '';
                else
                    s = size(HG(ct).XData);
                    set(HG(ct),'XData', NaN(s),'YData',NaN(s),'ZData',HG(ct).ZData);
                end
            end
            
            this.UncertainBounds.setData(NaN,NaN,NaN);
        end
    end
    
    methods (Access = private)
        function initializePreferences(this, Preferences)
            this.LineStyle = Preferences.LineStyle;
            this.LabelColor = Preferences.LabelColor;
            
            this.FrequencyScale = Preferences.FrequencyScale;
            this.MagnitudeUnits = Preferences.MagnitudeUnits;
            this.MagnitudeScale = Preferences.MagnitudeScale;
            this.PhaseUnits = Preferences.PhaseUnits;
            
            this.ShowSystemPZ = Preferences.ShowSystemPZ;
            this.UnwrapPhase = Preferences.UnwrapPhase;
        end
        
        function Range = xyextent(Editor, type)
            %XYEXTENT  Finds X or Y extent of visible data.
            
            %   Author(s): P. Gahinet, Bora Eryilmaz
            %   Copyright 1986-2006 The MathWorks, Inc.
            
            PlotAxes = getAxes(Editor.Axes);
            
            % Get comp. gain (zpk gain magnitude)
            C = Editor.Data.EditedBlock;
            Gain = getZPKGain(C,'mag');
            
            [VisX,VisY] = getConstraintBounds(Editor);
            
            switch type
                case 'mag'
                    Lims = 10.^(get(PlotAxes, 'Ylim')/20);  % abs limits
                    Lims = Lims/Gain;
                    VisData = Editor.Data.Magnitude(Editor.Data.Magnitude >= Lims(1) & Editor.Data.Magnitude <= Lims(2));
                    VisData = [VisData; VisY];
                case 'phase'
                    Lims = unitconv(get(PlotAxes, 'Xlim'), Editor.Axes.PhaseUnit, 'deg');
                    VisData = Editor.Data.Phase(Editor.Data.Phase >= Lims(1) & Editor.Data.Phase <= Lims(2));
                    VisData = [VisData; VisX];
            end
            
            if length(VisData)>1
                Range = [min(VisData),max(VisData)]; % in abs or deg units !
            else
                % Plot jumps over X or Y band
                Range = Lims;
            end
        end
        
        function [VisX,VisY] = getConstraintBounds(Editor)
            % find extents of constraints
            Constraints = Editor.findconstr;
            ConstrExtents = zeros(0,4);
            for ct =1:length(Constraints)
                ConstrExtents = [ConstrExtents;Constraints(ct).extent];
            end
            VisX = [min(ConstrExtents(:,1));max(ConstrExtents(:,2))];
            VisY = [min(ConstrExtents(:,3));max(ConstrExtents(:,4))];
        end
        
        
        function zp = project(this, x, y, xline, yline, zline)
            % Project point (x,y) on polyline (xline,yline) at (xp,yp) and
            % find the corresponding zp on zline.
            
            %   Author(s): Bora Eryilmaz
            %   Revised:
            %   Copyright 1986-2002 The MathWorks, Inc.
            
            % Handles
            PlotAxes = getAxes(this.Axes);
            
            %---If line is single point, just return the point
            if length(xline) == 1
                xp = xline;
                yp = yline;
                zp = zline;
                ip = 1;
                return;
            end
            
            %---Transform log-scale data for linear scanning
            IsLogX = strcmpi(get(PlotAxes, 'XScale'), 'log');
            IsLogY = strcmpi(get(PlotAxes, 'YScale'), 'log');
            if IsLogX
                x = log2(x);
                xline = log2(xline);
            end
            if IsLogY
                y = log2(y);
                yline = log2(yline);
            end
            
            % Perform 'XY' tracking (good for data which crosses back on itself in x)
            [xp, yp, ip] = lproject(x, y, xline, yline, PlotAxes);
            
            % Reconvert for log scale data
            if IsLogX
                xp = pow2(xp);
            end
            if IsLogY
                yp = pow2(yp);
            end
            
            % Assumes ip lies within valid range of data (zline)
            i1 = floor(ip);
            i2 = ip-i1;
            
            % Prevents indexing error for case i1 = size(zline,1);
            if i2
                zp = zline(i1) * (1-i2) + zline(i1+1) * i2;
            else
                zp = zline(i1);
            end
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
function GridHandles = LocalPlotGrid(this)
% Plots Nichols chart
GridHandles = this.Axes.plotgrid('ngrid');
end
%%%%%%%%%%%%%%%%%%%%%
% LocalGetRootValue %
%%%%%%%%%%%%%%%%%%%%%% ----------------------------------------------------------------------------%
% Local Functions
% ----------------------------------------------------------------------------%

% ----------------------------------------------------------------------------%
% Function: LocalGetRootValue
% Infers specified root value from mouse location
% RE: * Uses only the natural frequency info (W = Wn)
%     * W is in rad/s
% ----------------------------------------------------------------------------%
function [Zeros, Poles, GroupType, Status, Action] = ...
    LocalGetRootValue(W, GroupType, PZType, Ts, CompID)
% System type
if Ts
    DomainVar = 'z';
else
    DomainVar = 's';
end
CompID = sprintf('%s(%s)', CompID, DomainVar);

switch GroupType
    case 'Real'
        % Real pole/zero. RE: Assume stability
        R = LocalRootValue(-W, Ts);
        if strcmpi(PZType, 'Zero')
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
        R = LocalRootValue(-W,Ts);
        if strcmpi(PZType,'Zero')
            Zeros = [R; R];  Poles = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedComplexZeros',...
                CompID,DomainVar,sprintf('%.3g %s %.3gi',real(R),'+/-',0)));
            Action = getString(message('Control:compDesignTask:strAddZeros'));
        else
            Poles = [R; R];  Zeros = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedComplexPoles',...
                CompID,DomainVar,sprintf('%.3g %s %.3gi',real(R),'+/-',0)));
            Action = getString(message('Control:compDesignTask:strAddPoles'));
        end
        
        
    case 'Lead'
        % Lead network (s+tau1)/(s+tau2)  where tau1<tau2
        Zeros = LocalRootValue(-W/1.5, Ts);
        Poles = LocalRootValue(-W, Ts);
        GroupType = 'LeadLag';
        Status = getString(message('Control:compDesignTask:msgAddedLead',...
            CompID,DomainVar,sprintf('%.3g',Zeros),DomainVar,sprintf('%.3g',Poles)));
        Action = getString(message('Control:compDesignTask:strAddLead'));
        
    case 'Lag'
        % Lag network (s+tau1)/(s+tau2)  where tau1>tau2
        Zeros = LocalRootValue(-1.5*W, Ts);
        Poles = LocalRootValue(-W, Ts);
        GroupType = 'LeadLag';
        Status = getString(message('Control:compDesignTask:msgAddedLag',...
            CompID,DomainVar,sprintf('%.3g',Zeros),DomainVar,sprintf('%.3g',Poles)));
        Action = getString(message('Control:compDesignTask:strAddLag'));
        
    case 'Notch'
        % Notch filter:
        % default is zeta1 = 0.05, zeta2 = 0.5 (1/2 max width and 20dB depth)
        z1 = 0.05;   z2 = 0.5;
        r1 = W * (-z1 + 1i*sqrt(1-z1^2));
        r2 = W * (-z2 + 1i*sqrt(1-z2^2));
        Zeros = LocalRootValue([r1; conj(r1)], Ts);
        Poles = LocalRootValue([r2; conj(r2)], Ts);
        Status = getString(message('Control:compDesignTask:msgAddedNotch',...
            CompID,DomainVar,sprintf('%.3g %s %.3gi',real(Zeros(1)),'+/-',abs(imag(Zeros(1)))),...
            DomainVar,sprintf('%.3g %s %.3gi',real(Poles(1)),'+/-',abs(imag(Poles(1))))));
        Action = getString(message('Control:compDesignTask:strAddNotch'));
end
end
% ----------------------------------------------------------------------------%
% Function: LocalRootValue
% Convert to discrete time values if necessary
% ----------------------------------------------------------------------------%
function R = LocalRootValue(R, Ts)
if Ts,
    R = exp(Ts*R);
end
end



function r = c2d(r,Ts)
% Get equivalent root value in discrete-time domain
if Ts
    r = exp(Ts*r);
end
end
