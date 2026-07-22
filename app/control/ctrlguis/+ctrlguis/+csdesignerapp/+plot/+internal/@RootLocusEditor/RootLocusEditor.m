classdef RootLocusEditor < ctrlguis.csdesignerapp.plot.internal.GraphicalEditor
    % GraphicalEditor Base Class
    
    % Copyright 2014-2022 The MathWorks, Inc.
    
    properties (Access = private)
        %% Dotted lines along X and Y axes
        AxisLine
        
        %% Unit Circle
        UnitCircle
        
        %% Widget for closed loop poles
        CLPolesWidget

        %% Time delay listener
        TimeDelayListeners

        GridListener
    end
    
    
    properties(SetObservable = true)
        AxisEqual = true;
    end
    
    properties 
        % Time units required by design constriants
        TimeUnits = 'seconds'
    end
    
    methods
        %% Constructor, public API and Getters and Setters
        function this = RootLocusEditor(Response, Preferences, EventManager, PZEditor, ConstraintEditor)

            % Create data object
            Data = ctrlguis.csdesignerapp.data.internal.RootLocusEditorData(Response, Preferences);
            tag = "RootLocusEditor_" + getName(Response) + "_" + matlab.lang.internal.uuid;
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.plot.internal.GraphicalEditor(Data, Preferences, EventManager, PZEditor, ConstraintEditor, tag);
            this.Type = 'RootLocus';
            if hasFRD(this.Data.getResponse)
                return;
            else
                this.Data.PadeOrder = this.Preferences.PadeOrder;

                % Add listener to pade order
                this.TimeDelayListeners = ...
                    addlistener(this.Preferences, 'PadeOrder',...
                    'PostSet', @(es,ed)updatePadeOrder(this,ed));
                % Create uncertain bounds object
                this.UncertainBounds = sisogui.RootLocusUncertain(this);
                
                % Set color and zlevel for multimodel display
                this.UncertainBounds.setZLevel(this.getZLevel('multimodel'));
                this.UncertainBounds.setColor(this.LineStyle.Color.ClosedLoop);
                
                % udpate data                
                update(this.Data);
                
                % Add menus
                initialize(this);
                
            end
        end

        function delete(this)
            delete(this.TimeDelayListeners);
        end
        
        function setVisible(this)
            this.EditMode = 'idle';
            
            this.Axes.Visible = 'on';
            initializeCompensatorTarget(this.Data);
            update(this.Data);
            this.setmenu('on');
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
            
            Constr = findconstr(this);
            for ct=1:numel(Constr)
                Constr(ct).Ts = this.Data.getResponse.getTs;
                update(Constr(ct));
            end
        end
        
        function refresh(this,Action,widget)
            switch Action
                case 'start'
                    % Find which widget it is
                    list = [this.PZViewWidget(:); this.ResponseViewWidget(:); this.CLPolesWidget(:)];
                    idx = arrayfun(@(x) isequaln(x,widget),list);
                    if any(idx)
                        this.OtherWidgets = list(~idx);
                        %             [this.Widgets(1:idx-1),this.Widgets(idx+1:end)];
                    end
                case 'move'
                    for ct = 1:numel(this.OtherWidgets)
                        refresh(this.OtherWidgets(ct));
                    end
                case 'all'
                    list = [this.PZViewWidget(:); this.ResponseViewWidget(:); this.CLPolesWidget(:)];
                    for ct = 1:numel(list)
                        refresh(list(ct));
                    end
                    
            end
        end
        
        function update(this,updateLimitsFlag)
            arguments
                this
                updateLimitsFlag = true
            end

            if strcmpi(this.Axes.Visible, 'on')
                % Update only if visible

                % Set the edit mode back to idle
                setEditModeAndData(this, 'idle', []);
                % Data
                update(this.Data);

                % Update Grid
                h = qeGetChart(this.Axes);
                if this.Data.Ts == 0
                    h.AxesStyle.GridType = "s-plane";
                elseif this.Data.Ts~=0
                    h.AxesStyle.GridType = "z-plane";
                end

                if ~strcmpi(this.RefreshMode,'normal')
                    if this.Preferences.RealTimePlotUpdateEnabled
                        refresh(this,'all',[])
                    end
                else


                    if this.Data.SingularLoop
                        clear(this); return;
                    end

                    % Check for ViewUpdateEnabled flag (Set by Response
                    % Optimization object)
                    if ~this.ViewUpdateEnabled
                        return
                    end

                    % Update widgets
                    Response = this.Data.getResponse;
                    if hasFRD(Response)
                        return;
                    else
                        %% Root locus lines

                        % Commenting out the showMessagePane as it is
                        % unsupported in uifigure. Will replace functionality
                        % in ctrluis.axesgrid.

                        %                     if hasDelay(Response) && isequal(Response.getTs,0)
                        %                         this.Axes.showMessagePane(true,localTimeDelayMessage(this));
                        %                     else
                        %                         this.Axes.showMessagePane(false);
                        %                     end
                        if ~isempty(this.ResponseViewWidget)
                            for ct = 1:size(this.ResponseViewWidget,1)
                                target(this.ModeManager, 'uninstall',this.ResponseViewWidget(ct,1));
                                update(this.ResponseViewWidget(ct));
                                target(this.ModeManager, 'install',this.ResponseViewWidget(ct,1));
                            end
                        end

                        %% Tunable poles and zeros
                        %                 Revisit: Method on Data to go through list of all blocks that
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
                                ctrlguis.csdesignerapp.widgets.internal.RootLocusPZView(this,this.Data, this.Axes, PZGroups(ct))];
                            target(this.ModeManager, 'install',[this.PZViewWidget(end,:)]);
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

                        %% Closed-loop poles
                        % Revisit: Method on Data to go through list of all blocks that
                        % can be edited
                        CLPoles = this.Data.ClosedPoles;

                        Nf = length(CLPoles);
                        Nc = size(this.CLPolesWidget,1);

                        % Delete extra groups
                        if Nc>Nf,
                            target(this.ModeManager, 'uninstall',this.CLPolesWidget(Nf+1:Nc,:));
                            delete(this.CLPolesWidget(Nf+1:Nc,:));
                            this.CLPolesWidget = this.CLPolesWidget(1:Nf,:);
                        end

                        % Add new groups
                        for ct=Nc+1:Nf,
                            this.CLPolesWidget = [this.CLPolesWidget; ...
                                ctrlguis.csdesignerapp.widgets.internal.RootLocusCLPolesView(this,this.Data, this.Axes, ct)];
                            target(this.ModeManager, 'install',[this.CLPolesWidget(end,:)]);
                        end

                        % Retarget existing views to appropriate pz groups
                        for ct = 1:Nf
                            setCLPoleIdx(this.CLPolesWidget(ct,1), ct);
                        end

                        % update clpoles
                        if ~isempty(this.CLPolesWidget)
                            % Unistall and reinstall to make sure new HG widgets are
                            % registered with mode manager
                            for ct = 1:size(this.CLPolesWidget,1)
                                target(this.ModeManager, 'uninstall',this.CLPolesWidget(ct,1));
                                update(this.CLPolesWidget(ct,1));
                                target(this.ModeManager, 'install',this.CLPolesWidget(ct,1));
                            end
                        end

                        % update multimodel data
                        if ~isempty(this.UncertainBounds) && this.Data.isUncertain && this.isMultiModelVisible
                            setColor(this.UncertainBounds,this.LineStyle.Color.ClosedLoop);
                        end

                        if strcmpi(this.RefreshMode,'normal')
                            % this.Axes.send('ViewChanged');
                        end

                        if updateLimitsFlag
                            updatelims(this);
                        end
                    end
                end
            end
        end
        
        function updatelims(this,varargin)
            %UPDATELIMS  Updates axes limits.
            
            if this.Data.SingularLoop
                % Editor is inactive or has no data (algebraic inner loop)
                return
            end
            
            % Sample time and editor modes
            Axes = this.Axes;
            PlotAxes = getAxes(Axes);
            
            % Always show unit circle in discrete time
            % RE: included in limits on purpose!
            if this.Data.Ts
                set(this.UnitCircle,'Visible','on')
            else
                set(this.UnitCircle,'Visible','off')
            end
            
            % Enforce limit modes in HG axes
            set(PlotAxes,'XlimMode',Axes.XLimitsMode{1},'YlimMode',Axes.YLimitsMode{1})
            
            % Acquire limits (automatically includes other objects such as constraints
            % and compensator poles and zeros)
            Xlim = get(PlotAxes,'XLim');
            Ylim = get(PlotAxes,'YLim');
            if strcmpi(Axes.YLimitsMode,'auto')
                Ylim = max(abs(Ylim)) * [-1,1];  % enforce symmetry wrt x-axis
            end
            
            % Adjust limits if equal aspect ratio is on
            if strcmpi(this.AxisEqual,'on')
                [Xlim,Ylim] = localAxisEqual(Xlim,Ylim,PlotAxes);
            end
            
            % Apply computed limits
            Axes.XLimitsFocus = {Xlim};
            Axes.YLimitsFocus = {Ylim};
            
            notify(this.Axes,'LimitsChanged');
        end
        
        function updatePadeOrder(this,ed)
            this.Data.PadeOrder = ed.AffectedObject.(ed.Source.Name);
            update(this);
        end
        
        % function Focus = getfocus(this)
        %     %GETFOCUS  Computes scale-aware X focus.
        %     % Conversion factors
        %     FreqConvert = funitconv('rad/s',this.Axes.FrequencyUnit);
        % 
        %     Ts = this.Data.Ts;
        %     if Ts
        %         NyqFreq = FreqConvert * pi/Ts;
        %     else
        %         NyqFreq = NaN;
        %     end
        % 
        %     % Resolve undetermined focus (quasi-integrator)
        %     if isempty(this.Data.FreqFocus)
        %         % Look for 0dB gain crossings to anchor focus
        %         UnitGain = unitconv(1,'abs','dB');
        %         idxc = find((this.Data.Magnitude(1:end-1)-UnitGain).*(this.Data.Magnitude(2:end)-UnitGain)<=0);
        %         if ~isempty(idxc)
        %             idxc = idxc(round(end/2));
        %             this.Data.FreqFocus = [this.Data.Frequency(idxc)/10 , 10*this.Data.Frequency(idxc+1)];
        %         elseif Ts
        %             this.Data.FreqFocus = NyqFreq * [0.05,1];
        %         else
        %             this.Data.FreqFocus = [0.1,1];
        %         end
        %     end
        % 
        %     Focus = this.Data.FreqFocus;
        % 
        %     if ~isempty(Focus)
        %         if strcmp(this.Axes.XScale,'log')
        %             % Round to entire decade in current units
        %             % RE: This avoids irritating Y clipping when X focus is extended to
        %             %     nearest decade
        %             Focus = Focus*funitconv('rad/s',this.Axes.XUnits);
        %             Focus = log10(Focus);
        %             Focus = 10.^[floor(Focus(1)),ceil(Focus(2))];
        %             Focus = Focus*funitconv(this.Axes.XUnits,'rad/s');
        %         end
        %     end
        % end
        
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
        function Lines = getHG_PZ(this)
            Lines = getHG_PZ(this.PZViewWidget);
        end
        
        function addPZ(this, PlotAxes)
            %ADDPZ  Adds pole or zero graphically.
            
            % Gather info about added root
            AddInfo =  this.EditModeData;
            
            % Determine which Compensator to add PZGroup to
            C = this.Data.AddPZCompensator;
            
            if isempty(C)
                % No valid compensators to add pzgroup to
                return
            end
            
            
            % Pointers
            Ts = this.Data.Ts;
            
            % Acquire new pole/zero position
            % RE: Adjust position based on pole/zero type
            CP = get(PlotAxes,'CurrentPoint');
            [Zeros,Poles,GroupType,Status,Action] = LocalGetRootValue(CP(1,1),CP(1,2),...
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
            
            setEditModeAndData(this, 'idle', []);
            warning(this.ModeManager.Warning.sw); lastwarn(this.ModeManager.Warning.lw, this.ModeManager.Warning.lwid)

        end
        
        %% Load/Save
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
                'ToolID','RootLocus',...
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
                'AxisEqual',this.AxisEqual);
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
            Axes.XLimitsMode = S.XlimMode;
            Axes.YLimitsMode = S.YlimMode;
            set(getAxes(Axes),'XLim',S.Xlim,'YLim',S.Ylim)            
            
            % Grid
            Axes.Style.Axes.XGrid = S.Grid;
            Axes.Style.Axes.YGrid = S.Grid;
            % Axes.GridOptions = S.GridOptions;
            this.AxisEqual = S.AxisEqual;
            
            
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
            end
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
            
            Preferences = this.Preferences;
            if isempty(this.Axes) || ~isvalid(this.Axes)
                Zlevel = this.getZLevel('backgroundline');
                
                % Create Figure Document
                figOptions.Title = Title;
                figOptions.DocumentGroupTag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag(...
                                                "RootLocusEditorDocumentGroup");
                this.Document = matlab.ui.internal.FigureDocument(figOptions);
                this.Document.Tag = this.ContextualTag;
                this.Document.Figure.AutoResizeChildren = 'off';
                fig = this.Document.Figure;
                fig.Tag = "CSDAppRootLocusEditor";
                
                
                h = controllib.chart.RLocusPlot(Parent=fig);
                h.TimeUnit = "seconds";
                h.FrequencyUnit = "rad/s";
                h.AxesStyle.GridVisible = Preferences.Grid;
                h.Title.String = Title;
                h.XLabel.String = getString(message('Control:compDesignTask:strRealAxis'));
                h.YLabel.String = getString(message('Control:compDesignTask:strImagAxis'));
                this.Axes = qeGetView(h);
                ag = qeGetAxesGrid(this.Axes);
                enableDisableAxesLimitModeListeners(ag);
                ax = getChartAxes(h);
                % Plot axes
                PlotAxes = ax(1);
                PlotAxes.Units = 'norm';
                PlotAxes.Box = 'on';
                PlotAxes.XLim = [-1 1];
                PlotAxes.YLim = [-1 1];
                PlotAxes.HelpTopicKey = 'sisorootlocusplot';
                disableDefaultInteractivity(PlotAxes);
                                
                this.Axes.XLimitsMode = "auto";
                this.Axes.YLimitsMode = "auto";

                if this.Data.Ts == 0
                    h.AxesStyle.GridType = "s-plane";
                else
                    h.AxesStyle.GridType = "z-plane";
                end
                this.GridListener = addlistener(h.AxesStyle,"AxesStyleChanged",@(es,ed) cbGridChanged(this));
                
                % Revisit: Take in controllib.ui.AppEventManager
                % this.Axes.EventManager = ctrluis.eventmgr(this.Axes);
                
                XYdata = infline(-Inf,Inf);
                npts = length(XYdata);
                
                this.AxisLine(1,1) = line(XYdata,zeros(1,npts),Zlevel(:,ones(1,npts)),...
                    'Color',Preferences.AxesForegroundColor,...
                    'LineStyle',':','Parent',PlotAxes,...
                    'HitTest','off','XlimInclude','off','YlimInclude','off');
                this.AxisLine(2,1) = line(zeros(1,npts),XYdata,Zlevel(:,ones(1,npts)),...
                    'Color',Preferences.AxesForegroundColor,...
                    'LineStyle',':','Parent',PlotAxes,...
                    'HitTest','off','XlimInclude','off','YlimInclude','off');
                this.Axes.Title = Title;
            end
        end
        
        function createGraphicalWidgets(this)
            % Axes
            this.AxesViewWidget = [this.AxesViewWidget; ctrlguis.csdesignerapp.widgets.internal.AxesView(this, this.Data, this.Axes)];
            target(this.ModeManager, 'install',this.AxesViewWidget);
            
            % RL
            this.ResponseViewWidget = [this.ResponseViewWidget; ctrlguis.csdesignerapp.widgets.internal.RootLocusResponseView(this, this.Data, this.Axes)];
            % Target response widgets
            target(this.ModeManager, 'install',this.ResponseViewWidget);
            
            % Unit circle
            theta = 0:0.062831:2*pi;
            this.UnitCircle = line(cos(theta),sin(theta),... Zlevel(:,ones(1,length(theta))),...
                'Color',this.Preferences.AxesForegroundColor,...
                'Parent',getAxes(this.Axes),'LineStyle',':','HitTest','off','Visible','off');
        end
        
        function Title = getTitle(this)
            Name = getName(this.Data);
            Title = getString(message('Control:compDesignTask:strRootLocusEditorTitle1',Name));
        end
        
        function clear(this)
            clear@ctrlguis.csdesignerapp.plot.internal.GraphicalEditor(this);
            for ct=1:numel(this.CLPolesWidget)
                HG = getHG(this.CLPolesWidget(ct));
                set(HG,'XData',NaN,'YData',NaN, 'ZData', NaN);
            end
            this.UncertainBounds.setData(NaN);
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
        
        % function Range = yextent(this,type)
        %     %YEXTENT  Finds Y extent of visible data.
        % 
        %     % Current X limits (in rad/sec)
        %     PlotAxes = getaxes(this.Axes);
        %     Xlims = get(PlotAxes(1),'Xlim')*funitconv(this.Axes.XUnits,'rad/s');
        %     W = this.Data.Frequency;
        % 
        %     % Find minimal non-empty coverage of Xlims
        %     idxs = max([1;find(W<Xlims(1))]);
        %     idxe = min([find(W>Xlims(2));length(W)]);
        % 
        %     switch type
        %         case 'mag'
        %             VisData = this.Data.Magnitude(idxs:idxe);
        %         case 'phase'
        %             VisData = this.Data.Phase(idxs:idxe);
        %             %                     phsMrgn = this.HG.PhaseMargin;
        %             phsMrgn = [];
        %             if ~isempty(phsMrgn),
        %                 % Include phase margin line
        %                 VisData = [VisData ; reshape(get(phsMrgn.vLine,'YData'),[2 1])];
        %             end
        %     end
        %     Range = [min(VisData) , max(VisData)];
        % end

        function cbGridChanged(this)
            h = qeGetChart(this.Axes);
            this.UnitCircle.Visible = ~h.AxesStyle.GridVisible && this.Data.Ts > 0;
        end
    end
    
    methods (Hidden = true)
        function CLPolesWidget = qeGetCLPolesWidget(this)
            CLPolesWidget = this.CLPolesWidget;
        end
        function unitCircle = qeGetUnitCircle(this)
            unitCircle = this.UnitCircle;
        end        
    end
end

%----------------- Local functions -----------------


function r = c2d(r,Ts)
% Get equivalent root value in discrete-time domain
if Ts
    r = exp(Ts*r);
end
end

%-------------------- Local Functions ---------------------------------

%%%%%%%%%%%%%%%%%%
% localAxisEqual %
%%%%%%%%%%%%%%%%%%
function [Xlim,Ylim] = localAxisEqual(Xlim,Ylim,Ax)
% Update limits to show equal aspect ratio
units = get(Ax,'Units');
if ~strcmpi(units,'pixels')
    set(Ax,'Units','pixels');
    p = get(Ax,'Position');
    set(Ax,'Units',units);
else
    p = get(Ax,'Position');
end
%---Pixel extent
px = p(3);
py = p(4);
%---Data extent
dx = abs(diff(Xlim));
dy = abs(diff(Ylim));
%---Effective extent
xf = dx*py;
yf = dy*px;
%---Update limits
if xf>yf
    %---Effective Xlim is larger, adjust Ylim
    dd = xf/px-dy;
    Ylim = [Ylim(1)-dd/2 Ylim(2)+dd/2];
    set(Ax,'Ylim',Ylim);
elseif yf>xf
    %---Effective Ylim is larger, adjust Xlim
    dd = yf/py-dx;
    Xlim = [Xlim(1)-dd/2 Xlim(2)+dd/2];
    set(Ax,'Xlim',Xlim);
end
end


%%%%%%%%%%%%%%%%%%%%%
% LocalGetRootValue %
%%%%%%%%%%%%%%%%%%%%%
function [Zeros,Poles,GroupType,Status,Action] = LocalGetRootValue(X,Y,GroupType,PZType,Ts,CompID)
% Infers specified root value from mouse location

if Ts
    DomainVar = 'z';
else
    DomainVar = 's';
end
CompID = sprintf('%s(%s)',CompID,DomainVar);

switch GroupType
    case 'Real'
        % Real pole/zero
        if strcmpi(PZType,'Zero')
            Zeros = X;  Poles = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedRealZero',...
                CompID,DomainVar,sprintf('%.3g',X)));
            Action = getString(message('Control:compDesignTask:strAddZero'));
        else
            Poles = X;  Zeros = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedRealPole',...
                CompID,DomainVar,sprintf('%.3g',X)));
            Action = getString(message('Control:compDesignTask:strAddPole'));
        end
        
    case 'Complex'
        % Complex pole/zero
        Y = abs(Y);
        if strcmpi(PZType,'Zero')
            Zeros = [X + 1i*Y ; X - 1i*Y];  Poles = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedComplexZeros',...
                CompID,DomainVar,sprintf('%.3g %s %.3gi',X,'+/-',Y)));
            Action = getString(message('Control:compDesignTask:strAddZeros'));
        else
            Poles = [X + 1i*Y ; X - 1i*Y];  Zeros = zeros(0,1);
            Status = getString(message('Control:compDesignTask:msgAddedComplexPoles',...
                CompID,DomainVar,sprintf('%.3g %s %.3gi',X,'+/-',Y)));
            Action = getString(message('Control:compDesignTask:strAddPoles'));
        end
        
        
    case {'Lead','Lag'}
        % Lead or lag network (s+tau1)/(s+tau2)
        % Compute factor F such that the frequencies of the added pole and
        % its companion are Wn and F*Wn
        F = 1.5^(-1+2*strcmpi(GroupType,'Lag'));
        
        % Enforce stability and separate pair to facilitate adjustments
        if Ts
            % Natural frequency constrained to [1e-3,pi/Ts]
            wmin = 1.01 * exp(-pi);
            wmax = exp(-0.001*Ts);
            X = max(wmin,min(X,wmax));
            Poles = X;   Zeros = max(wmin,X^F);
        else
            X = min(X,-0.001);
            Poles = X;   Zeros = F*X;
        end
        
        if strcmpi(GroupType,'Lag')
            Status = getString(message('Control:compDesignTask:msgAddedLag',...
                CompID,DomainVar,sprintf('%.3g',Zeros),DomainVar,sprintf('%.3g',Poles)));
            Action = getString(message('Control:compDesignTask:strAddLag'));
        else
            Status = getString(message('Control:compDesignTask:msgAddedLead',...
                CompID,DomainVar,sprintf('%.3g',Zeros),DomainVar,sprintf('%.3g',Poles)));
            Action = getString(message('Control:compDesignTask:strAddLead'));
        end
        
        % Set @pzgroup type
        GroupType = 'LeadLag';
        
    case 'Notch'
        % Notch filter. Mouse position is the pole position. Place the zero to
        % achieve 20 dB drop
        r2 = X + 1i * abs(Y);      % pole position
        [Wn,Z2] = damp(r2,Ts);    % corresponding damping and natural freq
        Z1 = 0.1 * Z2;            % zero damping
        if Ts
            r1 = exp(Ts * Wn * (-Z1 + 1i * sqrt(1-Z1^2)));
        else
            r1 = Wn * (-Z1 + 1i * sqrt(1-Z1^2));
        end
        Zeros = [r1;conj(r1)];
        Poles = [r2;conj(r2)];
        Status = getString(message('Control:compDesignTask:msgAddedNotch',...
            CompID,DomainVar,sprintf('%.3g %s %.3gi',real(Zeros(1)),'+/-',abs(imag(Zeros(1)))),...
            DomainVar,sprintf('%.3g %s %.3gi',real(Poles(1)),'+/-',abs(imag(Poles(1))))));
        Action = getString(message('Control:compDesignTask:strAddNotch'));
end
end

%-------------------------- Local Functions ------------------------

%%%%%%%%%%%%%%%%%
% LocalPlotGrid %
%%%%%%%%%%%%%%%%%
function GridHandles = LocalPlotGrid(this)
% Plots S or Z grid
Ts = this.Data.Ts;
Axes = this.Axes;

% Update grid options
% REVISIT: simplify
Options = Axes.GridOptions;
% Options.FrequencyUnits = Editor.FrequencyUnits;
% Options.GridLabelType = Editor.GridOptions.GridLabelType;
Options.SampleTime = Ts;
Axes.GridOptions = Options;

% Generate and plot new grid
if Ts==0
    GridHandles = Axes.plotgrid('sgrid');
else
    GridHandles = Axes.plotgrid('zgrid');
    set(this.UnitCircle,'Visible','off');
end
end


function MessageTextPane = localTimeDelayMessage(this)

Msg = ctrlMsgUtils.message('Control:compDesignTask:strNotificationRootLocusTimeDelay');
MessageTextPane = ctrluis.PopupPanel.createMessageTextPane(Msg,get(0,'DefaultTextFontName'),11);
h = handle(MessageTextPane, 'callbackproperties');
h.HyperlinkUpdateCallback = {@localPrefCallback, this};
end

function localPrefCallback(es,ed,this) %#ok<INUSL>

if strcmp(ed.getEventType.toString, 'ACTIVATED')
    % Determine Hyperlink Description
    Description = char(ed.getDescription);
    switch Description
        case 'Pref'
            % Open Preference Editor to the Options tab.
            this.Preferences.edit;
            this.Preferences.selecttab('TimeDelays');
    end
end
end