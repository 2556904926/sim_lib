classdef LinearSimulationTool < controllib.ui.internal.dialog.AbstractDialog & ...
                                    matlab.mixin.SetGet
    % Linear Simulation Tool (LSIM UI)
    
    % Copyright 2020 The MathWorks, Inc.
    properties
        Type {mustBeMember(Type,{'lsim','initial'})} = 'lsim'
    end
    properties (GetAccess = public, SetAccess = private)
        Data
    end
    
    properties (Access = private)
        FileMenu
        LoadMenu
        SaveMenu
        EditMenu
        CutMenu
        CopyMenu
        PasteMenu
        InsertMenu
        DeleteMenu
        HelpMenu
        AboutToolMenu
        TabGroup
        InputSignalsTab
        InitialStatesTab
        InputWidget
        TimeWidget
        InitialWidget
        InterpolationDropDown
        SimulateButton
        CloseButton
    end
    
    events
        SimulateButtonPushed
    end
    
    methods
        function this = LinearSimulationTool(data)
            arguments
                data lsimgui.internal.LinearSimulationData = lsimgui.internal.LinearSimulationData
            end
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.Title = m('Controllib:gui:strLinearSimulationTool');
            this.Name = 'LinearSimulationTool';
            this.Data = data;
            
            registerUIListeners(this,...
                addlistener(this,'CloseEvent',@(es,ed) cbCloseEvent(this)),'CloseEventListener');
        end
        
        function updateUI(this)
            if this.IsWidgetValid
                if strcmp(this.Type,'lsim')
                    updateUI(this.InputWidget);
                    updateUI(this.TimeWidget);
                    this.InterpolationDropDown.Value = this.Data.Interpolation;
                end
                updateUI(this.InitialWidget);
            end
        end
        
        function pack(this,varargin)
            % Set InputTable and InitialStatesTable to fixed size
            if strcmp(this.Type,'lsim')
                setFixedTableSize(this.InputWidget);
            end
            setFixedTableSize(this.InitialWidget);
            % Turn scrollable off
            if strcmp(this.Type,'lsim')
                this.InputSignalsTab.Scrollable = 'off';
            end
            this.InitialStatesTab.Scrollable = 'off';
            % Pack
            pack@controllib.ui.internal.dialog.AbstractDialog(this,varargin{:});
            % Set table to auto size
            if strcmp(this.Type,'lsim')
                setAutoTableSize(this.InputWidget);
            end
            setAutoTableSize(this.InitialWidget);
            % Turn scrollable on
            if strcmp(this.Type,'lsim')
                this.InputSignalsTab.Scrollable = 'on';
            end
            this.InitialStatesTab.Scrollable = 'on';
        end
        
        function updateData(this,data)
            arguments
                this
                data lsimgui.internal.LinearSimulationData
            end
            this.Data = data;
            updateUI(this);
        end
        
        function delete(this)
            delete(this.InputWidget);
            delete(this.TimeWidget);
            delete(this.InitialWidget);
        end
        
        function selectTab(this,mode)
            arguments
                this
                mode {mustBeMember(mode,{'lsiminp','lsimdata','lsiminit'})}
            end
            if strcmp(this.Type,'lsim')
                switch mode
                    case {'lsimdata','lsiminp'}
                        this.TabGroup.SelectedTab = this.InputSignalsTab;
                    case 'lsiminit'
                        this.TabGroup.SelectedTab = this.InitialStatesTab;
                end
            end
            cbTabSelectionChanged(this,this.TabGroup);
        end
        
        function loadSession(this,session)
            this.Data.StartTime = session.savedStartTime;
            this.Data.SimulationSamples = session.savedsimsamples;
            this.Data.Interval = session.savedStepLength;
            inputSignals = repmat(lsimgui.utils.internal.createEmptySignal(),...
                                [1,length(session.savedInputSignals)]);
            this.Data.NumberOfInputs = length(session.savedInputSignals);
            for k = 1:length(inputSignals)
                inputSignals(k).Value = session.savedInputSignals(k).values;
                inputSignals(k).Source = session.savedInputSignals(k).source;
                inputSignals(k).SubSource = session.savedInputSignals(k).subsource;
                inputSignals(k).Column = session.savedInputSignals(k).column;
                inputSignals(k).Name = session.savedInputSignals(k).name;
                inputSignals(k).Interval = session.savedInputSignals(k).interval;
                inputSignals(k).Size = session.savedInputSignals(k).size;
                inputSignals(k).Transposed = session.savedInputSignals(k).transposed;
                inputSignals(k).Construction = session.savedInputSignals(k).construction;
            end
            updateInputSignals(this.Data,inputSignals);
            updateUI(this);
        end
        
        function session = saveSession(this)
            session.savedStartTime = this.Data.StartTime;
            session.savedsimsamples = this.Data.SimulationSamples;
            session.savedStepLength = this.Data.Interval;
            for k = 1:length(this.Data.InputSignals)
                signal = this.Data.InputSignals(k);
                session.savedInputSignals(k).values = signal.Value;
                session.savedInputSignals(k).source = signal.Source;
                session.savedInputSignals(k).subsource = signal.SubSource;
                session.savedInputSignals(k).column = signal.Column;
                session.savedInputSignals(k).name = signal.Name;
                session.savedInputSignals(k).size = signal.Size;
                session.savedInputSignals(k).transposed = signal.Transposed;
                session.savedInputSignals(k).construction = signal.Construction;
                session.savedInputSignals(k).interval = signal.Interval;
            end
            tableData = getSignalsTableData(this.InputWidget);
            session.savedCellData = tableData{:,:};
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            % Tab Group
            parentGrid = uigridlayout(this.UIFigure);
            parentGrid.RowHeight = {'1x','fit'};
            parentGrid.ColumnWidth = {'1x'};
            parentGrid.Padding = 0;
            parentGrid.RowSpacing = 10;
            parentGrid.Scrollable = 'on';
            this.TabGroup = uitabgroup(parentGrid);
            this.TabGroup.Layout.Row = 1;
            this.TabGroup.Layout.Column = 1;
            this.TabGroup.SelectionChangedFcn = ...
                @(es,ed) cbTabSelectionChanged(this,es);
            if strcmp(this.Type,'lsim')
                % Input Signals Tab
                this.InputSignalsTab = uitab(this.TabGroup);
                this.InputSignalsTab.Title = m('Controllib:gui:strInputSignals');
                this.InputSignalsTab.Scrollable = 'off';
                inputGrid = uigridlayout(this.InputSignalsTab);
                inputGrid.RowHeight = {'fit','1x'};
                inputGrid.ColumnWidth = {'1x'};
                inputGrid.Padding = 0;
                inputGrid.RowSpacing = 0;
                % Time Widget
                this.TimeWidget = lsimgui.widgets.internal.TimeParameters(inputGrid,this.Data);
                w = getWidget(this.TimeWidget);
                w.Layout.Row = 1;
                % Input Signals Widget
                this.InputWidget = lsimgui.widgets.internal.InputTable(inputGrid,this.Data);
                w = getWidget(this.InputWidget);
                w.Layout.Row = 2;
                createTableContextMenu(this.InputWidget);
            end
            % Initial States Tab
            this.InitialStatesTab = uitab(this.TabGroup);
            this.InitialStatesTab.Title = m('Controllib:gui:strInitialStates');
            this.InitialStatesTab.Scrollable = 'off';
            initialGrid = uigridlayout(this.InitialStatesTab);
            initialGrid.RowHeight = {'1x'};
            initialGrid.ColumnWidth = {'1x'};
            initialGrid.Padding = 0;
            initialGrid.RowSpacing = 0;
            this.InitialWidget = lsimgui.widgets.internal.InitialTable(initialGrid,this.Data);
            % Buttons and Interpolation Method
            buttonGrid = uigridlayout(parentGrid);
            buttonGrid.Layout.Row = 2;
            buttonGrid.Layout.Column = 1;
            buttonGrid.RowHeight = {'fit'};
            buttonGrid.ColumnWidth = {'fit','fit','1x','fit','fit'};
            buttonGrid.Padding = [10 10 10 0];
            % Interpolation
            if strcmp(this.Type,'lsim')
                % Label
                label = uilabel(buttonGrid,'Text',m('Controllib:gui:strInterpolationMethodLabel'));
                label.Layout.Row = 1;
                label.Layout.Column = 1;
                % DropDown
                dropdown = uidropdown(buttonGrid);
                dropdown.Layout.Row = 1;
                dropdown.Layout.Column = 2;
                dropdown.Items = {m('Controllib:gui:strAutomatic'),...
                    m('Controllib:gui:strZeroOrderHold'),...
                    m('Controllib:gui:strFirstOrderHold')};
                dropdown.ItemsData = {'auto','zoh','foh'};
                dropdown.Value = this.Data.Interpolation;
                dropdown.ValueChangedFcn = ...
                    @(es,ed) cbInterpolationDropDownValueChanged(this,es,ed);
                this.InterpolationDropDown = dropdown;
            end
            % Simulate Button
            button = uibutton(buttonGrid,'Text',m('Controllib:gui:strSimulate'));
            button.Layout.Row = 1;
            button.Layout.Column = 4;
            button.ButtonPushedFcn = @(es,ed) notify(this,'SimulateButtonPushed');
            this.SimulateButton = button;
            % Cancel Button
            button = uibutton(buttonGrid,'Text',m('Controllib:gui:strClose'));
            button.Layout.Row = 1;
            button.Layout.Column = 5;
            button.ButtonPushedFcn = @(es,ed) cbCancelButtonPushed(this,es,ed);
            this.CloseButton = button;
            % Menu
            buildMenu(this);
            % Size the dialog
            this.UIFigure.Position(3:4) = [640 490];
            % Add Tags
            lsimgui.utils.internal.addTagsToWidgets(this);
            
            this.UIFigure.Position(3:4) = [640 535];
        end
        
        function connectUI(~)

        end
    end
    
    methods (Access = private)
        function buildMenu(this)
            % File
            this.FileMenu = uimenu(this.UIFigure,'Text',m('Controllib:gui:strFile'));
            this.LoadMenu = uimenu(this.FileMenu,'Text',m('Controllib:gui:strLoadInputTable'));
            this.LoadMenu.MenuSelectedFcn = @(es,ed) cbLoadInputTable(this);
            this.SaveMenu = uimenu(this.FileMenu,'Text',m('Controllib:gui:strSaveInputTable'));
            this.SaveMenu.MenuSelectedFcn = @(es,ed) cbSaveInputTable(this);
            % Edit
            this.EditMenu = uimenu(this.UIFigure,'Text',m('Controllib:gui:strEdit'));
            this.EditMenu.MenuSelectedFcn = @(es,ed) openContextMenu(this.InputWidget,es,ed);
            this.CutMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strCutSignal'),...
                                      'Tag','CutSignal');
            this.CutMenu.MenuSelectedFcn = @(es,ed) cutSignal(this.InputWidget);
            this.CopyMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strCopySignal'),...
                                       'Tag','CopySignal');
            this.CopyMenu.MenuSelectedFcn = @(es,ed) copySignal(this.InputWidget);
            this.PasteMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strPasteSignal'),...
                                        'Tag','PasteSignal');
            this.PasteMenu.MenuSelectedFcn = @(es,ed) pasteSignal(this.InputWidget);
            this.InsertMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strInsertSignal'),...
                                         'Tag','InsertSignal');
            this.InsertMenu.MenuSelectedFcn = @(es,ed) insertSignal(this.InputWidget);
            this.DeleteMenu = uimenu(this.EditMenu,'Text',m('Controllib:gui:strDeleteSignal'),...
                                         'Tag','DeleteSignal');
            this.DeleteMenu.MenuSelectedFcn = @(es,ed) deleteSignal(this.InputWidget);
            % createTableContextMenu(this.InputWidget);
            % Help
            this.HelpMenu = uimenu(this.UIFigure,'Text',m('Controllib:gui:strHelp'));
            this.AboutToolMenu = uimenu(this.HelpMenu,'Text',m('Controllib:gui:strAboutLinearSimulationTool'));
            this.AboutToolMenu.MenuSelectedFcn = @(es,ed) callbackHelp(this);
        end
        
        function cbInterpolationDropDownValueChanged(this,es,~)
            this.Data.Interpolation = es.Value;
        end
        
        function cbTabSelectionChanged(this,es)
            if isequal(es.SelectedTab,this.InputSignalsTab)
                this.FileMenu.Enable = true;
                this.EditMenu.Enable = true;
            else
                this.FileMenu.Enable = false;
                this.EditMenu.Enable = false;
            end
        end
        
        function callbackHelp(~)
            ctrlguihelp('lsim_overview');
        end
        
        function cbCancelButtonPushed(this,~,~)
            close(this);
            cbCloseEvent(this);
        end
        
        function cbCloseEvent(this)
            if strcmp(this.Type,'lsim')
                closeDialogs(this.InputWidget);
                closeDialogs(this.TimeWidget);
            end
            closeDialogs(this.InitialWidget);
            close(this);
        end
        
        function cbLoadInputTable(this)
            filename = uigetfile;
            session = load(filename);
            loadSession(this,session);
        end
        
        function cbSaveInputTable(this)
            session = saveSession(this);
            [filename,pathname] = uiputfile('lsimGUI.mat', ...
                m('Controllib:gui:LsimSelectConditionsFile'));
            if filename
                save(fullfile(pathname,filename),'-struct','session');
            end
        end
        
       
    end
    
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.TabGroup = this.TabGroup;
            widgets.InputSignalsTab = this.InputSignalsTab;
            widgets.InitialStatesTab = this.InitialStatesTab;
            widgets.InputWidget = this.InputWidget;
            widgets.TimeWidget = this.TimeWidget;
            widgets.InitialWidget = this.InitialWidget;
            widgets.InterpolationDropDown = this.InterpolationDropDown;
            widgets.SimulateButton = this.SimulateButton;
            widgets.CloseButton = this.CloseButton;
            widgets.FileMenu = this.FileMenu;
            widgets.LoadMenu = this.LoadMenu;
            widgets.SaveMenu = this.SaveMenu;
            widgets.EditMenu = this.EditMenu;
            widgets.CutMenu = this.CutMenu;
            widgets.CopyMenu = this.CopyMenu;
            widgets.PasteMenu = this.PasteMenu;
            widgets.InsertMenu = this.InsertMenu;
            widgets.DeleteMenu = this.DeleteMenu;
            widgets.HelpMenu = this.HelpMenu;
            widgets.AboutToolMenu = this.AboutToolMenu;
        end
    end
end

function str = m(id,varargin)
str = getString(message(id,varargin{:}));
end