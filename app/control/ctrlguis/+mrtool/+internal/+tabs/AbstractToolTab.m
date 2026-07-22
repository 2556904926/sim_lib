classdef (Abstract,Hidden) AbstractToolTab < controllib.ui.internal.figuretool.FigureTool
    % Abstract Tab of Tool in Model Reduction App
    % compatible with MATLAB Online

    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.

    properties (Access=protected)
        Widgets
    end

    properties (Dependent,SetAccess=private)
        TargetList
        TargetListNames
    end

    properties (Access=protected,Transient)
        ComputingReducedSystemListener
        TargetNameChangedListener
        ToolDataChangedListener
        ComparisonPlotChangedListener
        AnalysisPlotChangedListener
        ModelsUpdatedListener
    end

    properties (Access=protected,WeakHandle)
        App (1,1) mrtool.internal.ModelReducerApp
        Data (1,1) handle = matlab.lang.invalidHandle('matlab.lang.HandlePlaceholder')
    end

    %% Constructor/destructor
    methods
        function this = AbstractToolTab(data,toolplot,app,tag,title)
            arguments
                data (1,1) mrtool.data.AbstractData
                toolplot (1,1) mrtool.internal.plots.toolplot.AbstractToolPlot
                app (1,1) mrtool.internal.ModelReducerApp
                tag (1,1) string
                title (1,1) string
            end
            this = this@controllib.ui.internal.figuretool.FigureTool(tag);
            this.Data = data;
            this.App = app;

            % create tab
            tab =  matlab.ui.internal.toolstrip.Tab(title);
            tab.Tag = tag;
            this.Tabs = tab;

            this.Document = toolplot;
        end
        function delete(this)
            delete(this.ComputingReducedSystemListener);
            delete(this.TargetNameChangedListener);
            delete(this.ToolDataChangedListener);
            delete(this.ComparisonPlotChangedListener);
            delete(this.AnalysisPlotChangedListener);
            delete(this.ModelsUpdatedListener);
        end
    end

    %% Get/Set
    methods
        % TargetList
        function TargetList = get.TargetList(this)
            arguments (Output)
                TargetList (:,1) mrtool.data.ModelWrapper
            end
            TargetList = getTargetList(this);
        end

        % TargetListNames
        function TargetListNames = get.TargetListNames(this)
            TargetListNames = arrayfun(@(x) char(x.Name),this.TargetList,UniformOutput=false);
        end
    end

    %% Public methods
    methods
        function build(this)
            createWidgets(this);
            addListeners(this);
            update(this);
        end

        function update(this)
            %% System section
            this.Widgets.SystemSection.TypeStrLabel.Text = mrtool.util.getSystemType(this.Data.TargetSystem);
            this.Widgets.SystemSection.OrderNumberLabel.Text = sprintf('%d %s',order(this.Data.TargetSystem),...
                getString(message('Control:mrtool:States')));
            replaceAllItems(this.Widgets.SystemSection.SystemDropDown,this.TargetListNames);
            this.Widgets.SystemSection.SystemDropDown.Value = this.Data.TargetName;
            clearActionStatus(this.App.EventManager)
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createWidgets(this,Name)
            import matlab.ui.internal.toolstrip.*
            %% SYSTEM SECTION
            % Strings
            SystemStr = getString(message('Control:mrtool:SystemLabel'));
            SystemTooltip = getString(message('Control:mrtool:SystemTooltip'));
            % Labels
            SystemLabel = Label(sprintf('%s ',SystemStr));
            OrderLabel = Label(sprintf('%s ',getString(message('Control:mrtool:Order'))));
            TypeLabel = Label(sprintf('%s ',getString(message('Control:mrtool:Type'))));
            OrderNumberLabel = Label(sprintf('%d %s',order(this.Data.TargetSystem),...
                getString(message('Control:mrtool:States'))));
            TypeStrLabel = Label(mrtool.util.getSystemType(this.Data.TargetSystem));

            SystemDropDown = DropDown(this.TargetListNames);
            SystemDropDown.Value = this.Data.TargetName;
            SystemDropDown.Description = SystemTooltip;

            % Layout
            % section
            SystemSection = Section(getString(message('Control:mrtool:SystemSection')));
            SystemSection.Tag = 'SystemSection';
            % column 1
            column = Column();
            add(SystemSection,column)
            add(column,SystemLabel);
            add(column,TypeLabel);
            add(column,OrderLabel);

            % spacing column
            column = Column('Width',5);
            add(SystemSection,column)

            % column 2
            column = Column('Width',80);
            add(SystemSection,column)
            add(column,SystemDropDown);
            add(column,TypeStrLabel);
            add(column,OrderNumberLabel);

            % Store widgets
            this.Widgets.SystemSection =  struct(...
                'Section',SystemSection,...
                'SystemLabel',SystemLabel,...
                'SystemDropDown',SystemDropDown,...
                'TypeLabel',TypeLabel,...
                'TypeStrLabel',TypeStrLabel,...
                'OrderLabel',OrderLabel,...
                'OrderNumberLabel',OrderNumberLabel);

            %% VISUALIZATIONS SECTION
            % Strings
            VisualizationsSectionStr = getString(message('Control:mrtool:VisualizationsSection'));

            % Section, and column
            VisualizationsSection = Section(VisualizationsSectionStr);
            VisualizationsSection.Tag = 'VisualizationsSection';

            % Column 1
            labelColumn = Column();
            add(VisualizationsSection,labelColumn);

            % spacing column
            column = Column('Width',5);
            add(VisualizationsSection,column)

            % Column 2
            dropDownColumn = Column('Width',160);
            add(VisualizationsSection,dropDownColumn)

            % Store widgets
            this.Widgets.VisualizationsSection = struct('Section', VisualizationsSection);

            addComparisonPlots(this,labelColumn,dropDownColumn)
            addAnaylsisPlots(this,labelColumn,dropDownColumn)

            %% SAVE SECTION
            % Strings
            SaveSectionStr = getString(message('Control:mrtool:SaveSection'));
            SaveStr = getString(message('Control:mrtool:SaveLabel'));
            SaveTooltip = getString(message('Control:mrtool:SaveTooltip'));
            % Icon
            SaveButtonIcon = Icon('greenCheck');

            % Section and column
            SaveSection = Section(SaveSectionStr);
            SaveSection.Tag = 'SaveSection';
            column = Column();
            add(SaveSection,column);
            % create button
            SaveButton = SplitButton(SaveStr,SaveButtonIcon);
            SaveButton.Description = SaveTooltip;
            add(column,SaveButton);
            % create popup for button
            popup = PopupList();
            popup.Tag = 'SaveSplitButtonPopup';
            item1 = ListItem(getString(message('Control:mrtool:SaveReducedModelTitle')),Icon('greenCheck'));
            item1.Tag = ['SaveModel' Name];
            item1.Description = getString(message('Control:mrtool:SaveReducedModelDescription'));
            item2 = ListItem(getString(message('Control:mrtool:CodegenGenerateMATLABCodeScriptTitle')),Icon('generateScript_matlab'));
            item2.Tag = ['CreateCode' Name];
            item2.Description = getString(message('Control:mrtool:CodegenGenerateMATLABCodeDescription'));
            popup.add(item1);
            popup.add(item2);
            SaveButton.Popup = popup;

            this.Widgets.SaveSection =  struct(...
                'SaveButton',SaveButton,...
                'SaveModelButton',item1,...
                'CreateCodeButton',item2,...
                'Section',SaveSection);
        end

        function addListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            this.Widgets.SystemSection.SystemDropDown.ValueChangedFcn = @(es,ed) setTarget(weakThis.Handle,ed.EventData);
            this.Widgets.SaveSection.SaveButton.ButtonPushedFcn = @(es,ed) createReducedSystem(this.Data);
            this.Widgets.SaveSection.SaveModelButton.ItemPushedFcn = @(es,ed) createReducedSystem(this.Data);
            this.Widgets.SaveSection.CreateCodeButton.ItemPushedFcn = @(es,ed) cbGenerateMATLABCode(weakThis.Handle);
            % Listeners
            this.ToolDataChangedListener = addlistener(this.Data, ...
                'ToolDataChanged',@(es,ed) update(weakThis.Handle));
            this.ComparisonPlotChangedListener = addlistener(this.Data, ...
                'ComparisonPlot','PostSet',@(es,ed) update(weakThis.Handle));
            this.AnalysisPlotChangedListener = addlistener(this.Data, ...
                'AnalysisPlot','PostSet',@(es,ed) update(weakThis.Handle));
            this.ModelsUpdatedListener = addlistener(this.App,...
                'ModelsUpdated', @(es,ed) update(weakThis.Handle));
            this.TargetNameChangedListener = addlistener(this.Data, 'ToolNameChanged', @(es,ed) update(weakThis.Handle));

            this.ComputingReducedSystemListener = addlistener(this.Data,'ComputingReducedSystem',@(es,ed) postActionStatus(...
                this.App.EventManager, 'on',getString(message('Control:mrtool:StatusMessageComputingReducedModel'))));
        end

        function TargetList = getTargetList(this)
            TargetList = this.App.Models;
        end

        function cbGenerateMATLABCode(this)
            if issiso(this.Data.TargetSystem)
                plotCommand = "bodeplot";
            else
                plotCommand = "sigmaplot";
            end
            generateMATLABCode(this.Data,PlotCommand=plotCommand);
        end
    end

    %% Abstract protected methods
    methods (Abstract, Access=protected)
        addComparisonPlots(this,labelColumn,dropDownColumn)
        addAnaylsisPlots(this,labelColumn,dropdownColumn)
        setTarget(this,ed)
    end

    %% Hidden methods
    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets = this.Widgets;
        end
    end
end