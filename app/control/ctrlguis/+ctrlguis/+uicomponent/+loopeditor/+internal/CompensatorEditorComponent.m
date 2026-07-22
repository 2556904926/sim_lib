classdef CompensatorEditorComponent < matlab.ui.componentcontainer.ComponentContainer & ...
        controllib.chart.internal.foundation.MixInListeners
    % Compensator Editor UI Component
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc.    
    
    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        Compensator DynamicSystem
        DisplayFormat (1,1) string {mustBeMember(DisplayFormat,["TimeConstant","NaturalFrequency","ZPK"])}
    end

    properties (Access=protected,Transient,NonCopyable)
        GridLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        CompensatorPanel matlab.ui.container.Panel {mustBeScalarOrEmpty}
        CompensatorPanelLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        DisplayFormatAccordian matlab.ui.container.internal.Accordion {mustBeScalarOrEmpty}
        DisplayFormatPanel matlab.ui.container.internal.AccordionPanel {mustBeScalarOrEmpty}
        DisplayFormatLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        DisplayFormatDropDown matlab.ui.control.DropDown {mustBeScalarOrEmpty}
        DisplayFormatLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        CompensatorLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        CompensatorGainEditField matlab.ui.control.NumericEditField {mustBeScalarOrEmpty}
        CompensatorPZLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        DynamicsPanel matlab.ui.container.Panel {mustBeScalarOrEmpty}
        DynamicsLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        DynamicsTablePanel matlab.ui.container.Panel {mustBeScalarOrEmpty}
        DynamicsTableLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        DynamicsTable matlab.ui.control.Table {mustBeScalarOrEmpty}
        DynamicsTableLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        DynamicsTableContextMenu matlab.ui.container.ContextMenu {mustBeScalarOrEmpty}
        EditDynamicsPanel matlab.ui.container.Panel {mustBeScalarOrEmpty}
        EditDynamicsLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}
        EditDynamicsLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        PZLocationLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        PZLocationEditField matlab.ui.control.NumericEditField {mustBeScalarOrEmpty}
        ComplexConjugatePZFrequencyLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        ComplexConjugatePZFrequencyEditField matlab.ui.control.NumericEditField {mustBeScalarOrEmpty}
        ComplexConjugatePZDampingLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        ComplexConjugatePZDampingEditField matlab.ui.control.NumericEditField {mustBeScalarOrEmpty}
        ComplexConjugatePZRealLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        ComplexConjugatePZRealEditField matlab.ui.control.NumericEditField {mustBeScalarOrEmpty}
        ComplexConjugatePZImagLabel matlab.ui.control.Label {mustBeScalarOrEmpty}
        ComplexConjugatePZImagEditField matlab.ui.control.NumericEditField {mustBeScalarOrEmpty}
    end

    properties (Access=private)
        Compensator_I
        DisplayFormat_I
    end

    properties (Access=private,Transient,NonCopyable,UsedInUpdate=false)
        DynamicsTablePZMap
        SelectedPZValue
    end

    %% Events
    events (HasCallbackProperty,NotifyAccess=private)
        CompensatorChanged
    end

    %% Destructor
    % Note: constructor is intentionally left as default to take advantage
    % of ComponentContainer
    methods
        function delete(this)
            delete@controllib.chart.internal.foundation.MixInListeners(this);
            delete@matlab.ui.componentcontainer.ComponentContainer(this);
        end
    end

    %% Get/Set
    methods
        % Compensator
        function Compensator = get.Compensator(this)
            Compensator = this.Compensator_I;
        end

        function set.Compensator(this,Compensator)
            arguments
                this (1,1) ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorComponent
                Compensator (1,1) DynamicSystem {ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorComponent.validateCompensator(Compensator)}
            end
            this.Compensator_I = zpk(Compensator);
        end

        % DisplayFormat
        function DisplayFormat = get.DisplayFormat(this)
            DisplayFormat = this.DisplayFormat_I;
        end

        function set.DisplayFormat(this,DisplayFormat)
            arguments
                this (1,1) ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorComponent
                DisplayFormat (1,1) string {mustBeMember(DisplayFormat,["TimeConstant","NaturalFrequency","ZPK"])}
            end
            this.DisplayFormat_I = DisplayFormat;
        end
    end

    %% Public methods
    methods
        function reset(this)
            for ii = 1:numel(this)
                setup(this(ii));
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function setup(this)
            this.Position = [10 10 800 400];
            this.Compensator_I = zpk(1);
            this.DisplayFormat_I = "TimeConstant";
            this.Type = "compensatoreditor";

            if isempty(this.GridLayout) || ~isvalid(this.GridLayout)
                buildUI(this);
                connectUI(this);
            end
        end

        function update(this)
            % Parent context menu
            if ~isempty(this.DynamicsTableContextMenu) && isvalid(this.DynamicsTableContextMenu)
                this.DynamicsTableContextMenu.Parent = ancestor(this,'figure');
            end
            % Apply background color
            this.GridLayout.BackgroundColor = this.BackgroundColor;
            this.CompensatorPanel.BackgroundColor = this.BackgroundColor;
            this.CompensatorPanelLayout.BackgroundColor = this.BackgroundColor;
            this.DisplayFormatPanel.BackgroundColor = this.BackgroundColor;
            this.DisplayFormatLayout.BackgroundColor = this.BackgroundColor;
            this.DisplayFormatLabel.BackgroundColor = this.BackgroundColor;
            this.CompensatorLabel.BackgroundColor = this.BackgroundColor;
            this.CompensatorPZLabel.BackgroundColor = this.BackgroundColor;
            this.DynamicsPanel.BackgroundColor = this.BackgroundColor;
            this.DynamicsLayout.BackgroundColor = this.BackgroundColor;
            this.DynamicsTablePanel.BackgroundColor = this.BackgroundColor;
            this.DynamicsTableLayout.BackgroundColor = this.BackgroundColor;
            this.DynamicsTableLabel.BackgroundColor = this.BackgroundColor;
            this.EditDynamicsPanel.BackgroundColor = this.BackgroundColor;
            this.EditDynamicsLayout.BackgroundColor = this.BackgroundColor;
            this.EditDynamicsLabel.BackgroundColor = this.BackgroundColor;
            this.PZLocationLabel.BackgroundColor = this.BackgroundColor;
            this.ComplexConjugatePZFrequencyLabel.BackgroundColor = this.BackgroundColor;
            this.ComplexConjugatePZDampingLabel.BackgroundColor = this.BackgroundColor;
            this.ComplexConjugatePZRealLabel.BackgroundColor = this.BackgroundColor;
            this.ComplexConjugatePZImagLabel.BackgroundColor = this.BackgroundColor;
            % Update gain display
            switch this.DisplayFormat
                case "ZPK"
                    this.CompensatorGainEditField.Value = this.Compensator.K(1,1);
                otherwise
                    % DC ingoring integrators/differentiators
                    comp = this.Compensator;
                    if comp.Ts
                        comp.Z{1,1} = comp.Z{1,1}(comp.Z{1,1}~=1);
                        comp.P{1,1} = comp.P{1,1}(comp.P{1,1}~=1);
                    else
                        comp.Z{1,1} = comp.Z{1,1}(comp.Z{1,1}~=0);
                        comp.P{1,1} = comp.P{1,1}(comp.P{1,1}~=0);
                    end
                    this.CompensatorGainEditField.Value = dcgain(comp);
            end
            % Update components
            this.DisplayFormatDropDown.Value = this.DisplayFormat;            
            updateFormatDisplay(this);
            updatePZDisplay(this);
            updateDynamicsTable(this);
            updateEditDynamicsPanel(this);
        end
    end

    %% Private methods
    methods (Access=private)        
        function buildUI(this)
            % GridLayout
            this.GridLayout = uigridlayout(this,[3 1]);
            this.GridLayout.RowHeight = {'fit','1x','fit'};

            % Compensator panel
            this.CompensatorPanel = uipanel(this.GridLayout,Title=getString(message('Control:design:compEditorCompensator')),...
                BorderType="none",FontWeight="bold");
            this.CompensatorPanel.Layout.Row = 1;
            this.CompensatorPanel.Layout.Column = 1;

            % Compensator display
            this.CompensatorPanelLayout = uigridlayout(this.CompensatorPanel,[2 3]);
            this.CompensatorPanelLayout.RowHeight = {'fit','fit'};
            this.CompensatorPanelLayout.ColumnWidth = {'fit','fit','1x'};
            this.DisplayFormatAccordian = matlab.ui.container.internal.Accordion(Parent=this.CompensatorPanelLayout);
            this.DisplayFormatAccordian.Layout.Row = 1;
            this.DisplayFormatAccordian.Layout.Column = [1 3];
            this.DisplayFormatPanel = matlab.ui.container.internal.AccordionPanel(Parent=this.DisplayFormatAccordian);
            this.DisplayFormatPanel.Title = "Format";
            this.DisplayFormatPanel.Collapsed = true;
            this.DisplayFormatLayout = uigridlayout(this.DisplayFormatPanel,[1 2]);
            this.DisplayFormatLayout.ColumnWidth = {'fit','1x'};
            this.DisplayFormatDropDown = uidropdown(this.DisplayFormatLayout);
            this.DisplayFormatDropDown.Layout.Column = 1;
            this.DisplayFormatDropDown.Items = {getString(message('Control:design:compEditorTimeConstant')),...
                getString(message('Control:design:compEditorNaturalFrequency')),...
                getString(message('Control:design:compEditorZPK'))};
            this.DisplayFormatDropDown.ItemsData = {'TimeConstant','NaturalFrequency','ZPK'};
            this.DisplayFormatLabel = uilabel(this.DisplayFormatLayout,Interpreter="latex",VerticalAlignment="center");
            this.DisplayFormatLabel.Layout.Column = 2;

            this.CompensatorLabel = uilabel(this.CompensatorPanelLayout,Text="C = ");
            this.CompensatorLabel.Layout.Row = 2;
            this.CompensatorLabel.Layout.Column = 1;
            this.CompensatorGainEditField = uieditfield(this.CompensatorPanelLayout,"numeric");
            this.CompensatorGainEditField.Layout.Row = 2;
            this.CompensatorGainEditField.Layout.Column = 2;
            this.CompensatorGainEditField.LowerLimitInclusive = false;
            this.CompensatorGainEditField.UpperLimitInclusive = false;
            this.CompensatorPZLabel = uilabel(this.CompensatorPanelLayout,Interpreter="latex",VerticalAlignment="center");
            this.CompensatorPZLabel.Layout.Row = 2;
            this.CompensatorPZLabel.Layout.Column = 3;

            % Dynamics table
            this.DynamicsPanel = uipanel(this.GridLayout,BorderType="none");
            this.DynamicsPanel.Layout.Row = 2;
            this.DynamicsLayout = uigridlayout(this.DynamicsPanel,[1 2]);
            this.DynamicsLayout.ColumnWidth = {'3x','2x'};
            this.DynamicsTablePanel = uipanel(this.DynamicsLayout,Title=getString(message('Control:design:compEditorDynamics')),...
                BorderType="none",FontWeight="bold");
            this.DynamicsTablePanel.Layout.Column = 1;
            this.DynamicsTableLayout = uigridlayout(this.DynamicsTablePanel,[2 1]);
            this.DynamicsTableLayout.RowHeight = {'1x','fit'};
            this.DynamicsTable = uitable(this.DynamicsTableLayout);
            this.DynamicsTable.Layout.Row = 1;
            this.DynamicsTable.RowName = {};
            this.DynamicsTable.ColumnName = {getString(message('Control:design:compEditorType')),...
                getString(message('Control:design:compEditorLocation')),...
                getString(message('Control:design:compEditorDamping')),...
                getString(message('Control:design:compEditorFrequency'))};
            this.DynamicsTable.SelectionType = "row";
            this.DynamicsTable.Multiselect = false;
            this.DynamicsTableContextMenu = uicontextmenu(Parent=ancestor(this,'figure'));
            addMenu = uimenu(this.DynamicsTableContextMenu,Text=getString(message('Control:design:compEditorAddPole')),Tag='addPZ');
            uimenu(addMenu,Text=getString(message('Control:design:compEditorRealPole')),Tag="Pole");
            uimenu(addMenu,Text=getString(message('Control:design:compEditorInt')),Tag="Integrator");
            uimenu(addMenu,Text=getString(message('Control:design:compEditorCCPole')),Tag="CCPole");
            uimenu(addMenu,Text=getString(message('Control:design:compEditorRealZero')),Separator="on",Tag="Zero");
            uimenu(addMenu,Text=getString(message('Control:design:compEditorDiff')),Tag="Differentiator");
            uimenu(addMenu,Text=getString(message('Control:design:compEditorCCZero')),Tag="CCZero");
            uimenu(this.DynamicsTableContextMenu,Text=getString(message('Control:design:compEditorDeletePole')),Tag='removePZ');
            this.DynamicsTable.ContextMenu = this.DynamicsTableContextMenu;
            this.DynamicsTableLabel = uilabel(this.DynamicsTableLayout,Text=getString(message('Control:design:compEditorContextMenuLabel')));
            this.DynamicsTableLabel.Layout.Row = 2;

            % Edit dynamics
            this.EditDynamicsPanel = uipanel(this.DynamicsLayout,Title=getString(message('Control:design:compEditorEditDynamics')),...
                BorderType="none",FontWeight="bold");
            this.EditDynamicsPanel.Layout.Column = 2;
            this.EditDynamicsLayout = uigridlayout(this.EditDynamicsPanel,[6 2]);
            this.EditDynamicsLayout.RowHeight = {'fit',0,0,0,0,0};
            this.EditDynamicsLayout.ColumnWidth = {'fit','1x'};
            this.EditDynamicsLabel = uilabel(this.EditDynamicsLayout,Text=getString(message('Control:design:compEditorTableLabel')));
            this.EditDynamicsLabel.Layout.Row = 1;
            this.EditDynamicsLabel.Layout.Column = [1 2];
            % Real
            this.PZLocationLabel = uilabel(this.EditDynamicsLayout,Text=getString(message('Control:design:compEditorLocation')));
            this.PZLocationLabel.Layout.Row = 2;
            this.PZLocationLabel.Layout.Column = 1;
            this.PZLocationEditField = uieditfield(this.EditDynamicsLayout,"numeric",Visible=false);
            this.PZLocationEditField.Layout.Row = 2;
            this.PZLocationEditField.Layout.Column = 2;
            % Complex-conjugate
            this.ComplexConjugatePZFrequencyLabel = uilabel(this.EditDynamicsLayout,Text=getString(message('Control:design:compEditorNaturalFrequency')));
            this.ComplexConjugatePZFrequencyLabel.Layout.Row = 3;
            this.ComplexConjugatePZFrequencyLabel.Layout.Column = 1;
            this.ComplexConjugatePZFrequencyEditField = uieditfield(this.EditDynamicsLayout,"numeric",Visible=false);
            this.ComplexConjugatePZFrequencyEditField.Limits = [0 Inf];
            this.ComplexConjugatePZFrequencyEditField.LowerLimitInclusive = false;
            this.ComplexConjugatePZFrequencyEditField.UpperLimitInclusive = false;
            this.ComplexConjugatePZFrequencyEditField.Layout.Row = 3;
            this.ComplexConjugatePZFrequencyEditField.Layout.Column = 2;
            this.ComplexConjugatePZDampingLabel = uilabel(this.EditDynamicsLayout,Text=getString(message('Control:design:compEditorDamping')));
            this.ComplexConjugatePZDampingLabel.Layout.Row = 4;
            this.ComplexConjugatePZDampingLabel.Layout.Column = 1;
            this.ComplexConjugatePZDampingEditField = uieditfield(this.EditDynamicsLayout,"numeric",Visible=false);
            this.ComplexConjugatePZDampingEditField.Limits = [-1 1];
            this.ComplexConjugatePZDampingEditField.LowerLimitInclusive = false;
            this.ComplexConjugatePZDampingEditField.UpperLimitInclusive = false;
            this.ComplexConjugatePZDampingEditField.Layout.Row = 4;
            this.ComplexConjugatePZDampingEditField.Layout.Column = 2;
            this.ComplexConjugatePZRealLabel = uilabel(this.EditDynamicsLayout,Text=getString(message('Control:design:compEditorRealPart')));
            this.ComplexConjugatePZRealLabel.Layout.Row = 5;
            this.ComplexConjugatePZRealLabel.Layout.Column = 1;
            this.ComplexConjugatePZRealEditField = uieditfield(this.EditDynamicsLayout,"numeric",Visible=false);
            this.ComplexConjugatePZRealEditField.Layout.Row = 5;
            this.ComplexConjugatePZRealEditField.Layout.Column = 2;
            this.ComplexConjugatePZImagLabel = uilabel(this.EditDynamicsLayout,Text=getString(message('Control:design:compEditorImagPart')));
            this.ComplexConjugatePZImagLabel.Layout.Row = 6;
            this.ComplexConjugatePZImagLabel.Layout.Column = 1;
            this.ComplexConjugatePZImagEditField = uieditfield(this.EditDynamicsLayout,"numeric",Visible=false);
            this.ComplexConjugatePZImagEditField.Layout.Row = 6;
            this.ComplexConjugatePZImagEditField.Layout.Column = 2;
        end
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            this.DisplayFormatDropDown.ValueChangedFcn = @(es,ed) cbDisplayFormatChanged(weakThis.Handle);
            this.CompensatorGainEditField.ValueChangedFcn = @(es,ed) cbGainChanged(weakThis.Handle);
            this.DynamicsTable.SelectionChangedFcn = @(es,ed) updateEditDynamicsPanel(weakThis.Handle);
            this.DynamicsTableContextMenu.ContextMenuOpeningFcn = @(es,ed) updateContextMenu(weakThis.Handle,ed);
            this.DynamicsTableContextMenu.Children(1).MenuSelectedFcn = @(es,ed) removePZ(weakThis.Handle);
            for ii = 1:numel(this.DynamicsTableContextMenu.Children(2).Children)
                this.DynamicsTableContextMenu.Children(2).Children(ii).MenuSelectedFcn = @(es,ed) addPZ(weakThis.Handle,ed);
            end
            this.PZLocationEditField.ValueChangedFcn = @(es,ed) cbPZLocationChanged(weakThis.Handle,ed);
            this.ComplexConjugatePZFrequencyEditField.ValueChangedFcn = @(es,ed) cbCCPZFrequencyChanged(weakThis.Handle,ed);
            this.ComplexConjugatePZDampingEditField.ValueChangedFcn = @(es,ed) cbCCPZDampingChanged(weakThis.Handle,ed);
            this.ComplexConjugatePZRealEditField.ValueChangedFcn = @(es,ed) cbCCPZRealChanged(weakThis.Handle,ed);
            this.ComplexConjugatePZImagEditField.ValueChangedFcn = @(es,ed) cbCCPZImagChanged(weakThis.Handle,ed);
        end

        function cbDisplayFormatChanged(this)
            this.DisplayFormat = this.DisplayFormatDropDown.Value;
        end

        function cbGainChanged(this)
            comp = this.Compensator;
            switch this.DisplayFormat
                case "ZPK"
                    comp.K(1,1) = this.CompensatorGainEditField.Value;
                otherwise
                    % DC ingoring integrators/differentiators
                    dccomp = comp;
                    if dccomp.Ts
                        dccomp.Z{1,1} = dccomp.Z{1,1}(dccomp.Z{1,1}~=1);
                        dccomp.P{1,1} = dccomp.P{1,1}(dccomp.P{1,1}~=1);
                    else
                        dccomp.Z{1,1} = dccomp.Z{1,1}(dccomp.Z{1,1}~=0);
                        dccomp.P{1,1} = dccomp.P{1,1}(dccomp.P{1,1}~=0);
                    end
                    comp.K(1,1) = this.CompensatorGainEditField.Value/dcgain(dccomp);
            end
            setCompensatorAndNotify(this,comp);
        end

        function addPZ(this,ed)
            % Add poles/zeros at default values. Assume stability.
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            switch ed.Source.Tag
                case "Pole"
                    if Ts
                        comp.P{1,1}(end+1) = 0;
                    else
                        comp.P{1,1}(end+1) = -1;
                    end
                case "Integrator"
                    if Ts
                        comp.P{1,1}(end+1) = 1;
                    else
                        comp.P{1,1}(end+1) = 0;
                    end
                case "CCPole"
                    if Ts                        
                        comp.P{1,1}(end+1:end+2) = roots([1 -0.5 0.5]);
                    else
                        comp.P{1,1}(end+1:end+2) = roots([1 1 1]);
                    end
                case "Zero"
                    if Ts
                        comp.Z{1,1}(end+1) = 0;
                    else
                        comp.Z{1,1}(end+1) = -1;
                    end
                case "Differentiator"
                    if Ts
                        comp.Z{1,1}(end+1) = 1;
                    else
                        comp.Z{1,1}(end+1) = 0;
                    end
                case "CCZero"
                    if Ts
                        comp.Z{1,1}(end+1:end+2) = roots([1 -0.5 0.5]);
                    else
                        comp.Z{1,1}(end+1:end+2) = roots([1 1 1]);
                    end
            end
            setCompensatorAndNotify(this,comp);
        end

        function removePZ(this)
            % Remove selected pole/zero
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            row = this.DynamicsTable.Selection;
            data = this.DynamicsTable.Data(row,:);
            idx = this.DynamicsTablePZMap{row};  
            comp = this.Compensator;
            if strcmp(data(1),getString(message('Control:design:compEditorRealZero'))) ||...
                    strcmp(data(1),getString(message('Control:design:compEditorDiff'))) ||...
                    strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                val = comp.Z{1,1}(idx);
                comp.Z{1,1}(idx) = [];
                if isscalar(val)
                    if Ts
                        if val ~= 1
                            comp.K(1,1) = comp.K(1,1)*(1-val);
                        end
                    else
                        if val ~= 0
                            comp.K(1,1) = -comp.K(1,1)*val;
                        end
                    end
                else
                    val = val(1);
                    if Ts
                        comp.K(1,1) = comp.K(1,1)*abs(1-val)^2;
                    else
                        comp.K(1,1) = comp.K(1,1)*abs(val)^2;
                    end
                end
            else
                val = comp.P{1,1}(idx);
                comp.P{1,1}(idx) = [];
                if isscalar(val)
                    if Ts
                        if val ~= 1
                            comp.K(1,1) = comp.K(1,1)/(1-val);
                        end
                    else
                        if val ~= 0
                            comp.K(1,1) = -comp.K(1,1)/val;
                        end
                    end
                else
                    val = val(1);
                    if Ts
                        comp.K(1,1) = comp.K(1,1)/abs(1-val)^2;
                    else
                        comp.K(1,1) = comp.K(1,1)/abs(val)^2;
                    end
                end
            end
            setCompensatorAndNotify(this,comp);
        end

        function cbPZLocationChanged(this,ed)
            % Update location of real pole/zero
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            row = this.DynamicsTable.Selection;
            data = this.DynamicsTable.Data(row,:);
            idx = this.DynamicsTablePZMap{row};  
            if strcmp(data(1),getString(message('Control:design:compEditorRealZero'))) ||...
                    strcmp(data(1),getString(message('Control:design:compEditorDiff'))) %Zero
                val = comp.Z{1,1}(idx);
                comp.Z{1,1}(idx) = ed.Value;
                if Ts
                    if val ~= 1
                        comp.K(1,1) = comp.K(1,1)*(1-val);
                    end
                    if ed.Value ~= 1
                        comp.K(1,1) = comp.K(1,1)/(1-ed.Value);
                    end
                else
                    if val ~= 0
                        comp.K(1,1) = -comp.K(1,1)*val;
                    end
                    if ed.Value ~= 0
                        comp.K(1,1) = -comp.K(1,1)/ed.Value;
                    end
                end
            else %Pole
                val = comp.P{1,1}(idx);
                comp.P{1,1}(idx) = ed.Value;
                if Ts
                    if val ~= 1
                        comp.K(1,1) = comp.K(1,1)/(1-val);
                    end
                    if ed.Value ~= 1
                        comp.K(1,1) = comp.K(1,1)*(1-ed.Value);
                    end
                else
                    if val ~= 0
                        comp.K(1,1) = -comp.K(1,1)/val;
                    end
                    if ed.Value ~= 0
                        comp.K(1,1) = -comp.K(1,1)*ed.Value;
                    end
                end
            end
            setCompensatorAndNotify(this,comp);
            if strcmp(data(1),getString(message('Control:design:compEditorRealZero'))) ||...
                    strcmp(data(1),getString(message('Control:design:compEditorDiff'))) %Zero
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if (strcmp(data(1),getString(message('Control:design:compEditorRealZero'))) ||...
                            strcmp(data(1),getString(message('Control:design:compEditorDiff')))) &&...
                            ed.Value == str2double(data(2))
                        this.DynamicsTable.Selection = ii;
                        updateEditDynamicsPanel(this);
                        break;
                    end
                end
            else %Pole
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if (strcmp(data(1),getString(message('Control:design:compEditorRealPole'))) ||...
                            strcmp(data(1),getString(message('Control:design:compEditorInt')))) &&...
                            ed.Value == str2double(data(2))
                        this.DynamicsTable.Selection = ii;
                        updateEditDynamicsPanel(this);
                        break;
                    end
                end
            end
        end

        function cbCCPZFrequencyChanged(this,ed)
            % Update frequency of complex-conjugate pole/zero
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            row = this.DynamicsTable.Selection;
            data = this.DynamicsTable.Data(row,:);
            idx = this.DynamicsTablePZMap{row};  
            zeta = str2double(data(3));
            zr = -zeta*ed.Value;
            zi = sqrt(ed.Value^2-zr^2);
            loc = zr+zi*1j;
            if Ts
                loc = log(loc)/Ts;
            end
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                val = comp.Z{1,1}(idx(1));
                comp.Z{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-val)^2/abs(1-loc)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(val)^2/abs(loc)^2;
                end
            else %Pole
                val = comp.P{1,1}(idx(1));
                comp.P{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-loc)^2/abs(1-val)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(loc)^2/abs(val)^2;
                end
            end
            setCompensatorAndNotify(this,comp);
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) &&...
                            zeta == str2double(data(3)) && ed.Value == str2double(data(4))
                        this.DynamicsTable.Selection = ii;
                        updateEditDynamicsPanel(this);
                        break;
                    end
                end
            else %Pole
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCPole'))) &&...
                            zeta == str2double(data(3)) && ed.Value == str2double(data(4))
                        this.DynamicsTable.Selection = ii;
                        updateEditDynamicsPanel(this);
                        break;
                    end
                end
            end
        end

        function cbCCPZDampingChanged(this,ed)
            % Update damping of complex-conjugate pole/zero
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            row = this.DynamicsTable.Selection;
            data = this.DynamicsTable.Data(row,:);
            idx = this.DynamicsTablePZMap{row};  
            wn = str2double(data(4));
            zr = -ed.Value*wn;
            zi = sqrt(wn^2-zr^2);
            loc = zr+zi*1j;
            if Ts
                loc = log(loc)/Ts;
            end
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                val = comp.Z{1,1}(idx(1));
                comp.Z{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-val)^2/abs(1-loc)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(val)^2/abs(loc)^2;
                end
            else %Pole
                val = comp.P{1,1}(idx(1));
                comp.P{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-loc)^2/abs(1-val)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(loc)^2/abs(val)^2;
                end
            end
            setCompensatorAndNotify(this,comp);
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) &&...
                            ed.Value == str2double(data(3)) && wn == str2double(data(4))
                        this.DynamicsTable.Selection = ii;
                        updateEditDynamicsPanel(this);
                        break;
                    end
                end
            else %Pole
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCPole'))) &&...
                            ed.Value == str2double(data(3)) && wn == str2double(data(4))
                        this.DynamicsTable.Selection = ii;
                        updateEditDynamicsPanel(this);
                        break;
                    end
                end
            end
        end

        function cbCCPZRealChanged(this,ed)
            % Update real component of complex-conjugate pole/zero
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            row = this.DynamicsTable.Selection;
            data = this.DynamicsTable.Data(row,:);
            idx = this.DynamicsTablePZMap{row};  
            zr = ed.Value;
            c = char(data(2));
            ind = strfind(c,'±');
            zi = str2double(c(ind+1:end-1));
            loc = zr+zi*1j;
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                val = comp.Z{1,1}(idx(1));
                comp.Z{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-val)^2/abs(1-loc)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(val)^2/abs(loc)^2;
                end
            else %Pole
                val = comp.P{1,1}(idx(1));
                comp.P{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-loc)^2/abs(1-val)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(loc)^2/abs(val)^2;
                end
            end
            setCompensatorAndNotify(this,comp);
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCZero')))
                        c = char(data(2));
                        ind = strfind(c,'±');
                        dzr = str2double(c(1:ind-1));
                        dzi = str2double(c(ind+1:end-1));
                        if zr == dzr && zi == dzi
                            this.DynamicsTable.Selection = ii;
                            updateEditDynamicsPanel(this);
                            break;
                        end
                    end
                end
            else %Pole
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCPole')))
                        c = char(data(2));
                        ind = strfind(c,'±');
                        dzr = str2double(c(1:ind-1));
                        dzi = str2double(c(ind+1:end-1));
                        if zr == dzr && zi == dzi
                            this.DynamicsTable.Selection = ii;
                            updateEditDynamicsPanel(this);
                            break;
                        end
                    end
                end
            end
        end

        function cbCCPZImagChanged(this,ed)
            % Update imaginary component of complex-conjugate pole/zero
            comp = this.Compensator;
            Ts = abs(comp.Ts);
            row = this.DynamicsTable.Selection;
            data = this.DynamicsTable.Data(row,:);
            idx = this.DynamicsTablePZMap{row};  
            zi = ed.Value;
            c = char(data(2));
            ind = strfind(c,'±');
            zr = str2double(c(1:ind-1));
            loc = zr+zi*1j;
            if zi == 0
                fig = ancestor(this,'figure');
                if ~isempty(fig)
                    uialert(fig,getString(message('Control:design:compEditorErrorImagPart')),...
                        getString(message('Control:design:compEditorErrorLocation')),Icon="error")
                end
                ed.Source.Value = ed.PreviousValue;
                return;
            end
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                val = comp.Z{1,1}(idx(1));
                comp.Z{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-val)^2/abs(1-loc)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(val)^2/abs(loc)^2;
                end
            else %Pole
                val = comp.P{1,1}(idx(1));
                comp.P{1,1}(idx) = [loc conj(loc)];
                if Ts
                    comp.K(1,1) = comp.K(1,1)*abs(1-loc)^2/abs(1-val)^2;
                else
                    comp.K(1,1) = comp.K(1,1)*abs(loc)^2/abs(val)^2;
                end
            end
            setCompensatorAndNotify(this,comp);
            if strcmp(data(1),getString(message('Control:design:compEditorCCZero'))) %Zero
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCZero')))
                        c = char(data(2));
                        ind = strfind(c,'±');
                        dzr = str2double(c(1:ind-1));
                        dzi = str2double(c(ind+1:end-1));
                        if zr == dzr && zi == dzi
                            this.DynamicsTable.Selection = ii;
                            updateEditDynamicsPanel(this);
                            break;
                        end
                    end
                end
            else %Pole
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCPole')))
                        c = char(data(2));
                        ind = strfind(c,'±');
                        dzr = str2double(c(1:ind-1));
                        dzi = str2double(c(ind+1:end-1));
                        if zr == dzr && zi == dzi
                            this.DynamicsTable.Selection = ii;
                            updateEditDynamicsPanel(this);
                            break;
                        end
                    end
                end
            end
        end

        function updateDynamicsTable(this)
            % Populate table from given compensator dynamics.
            Ts = abs(this.Compensator.Ts);
            this.DynamicsTable.Data = strings(0,4);
            this.DynamicsTablePZMap = {};
            Z = this.Compensator.Z{1,1};
            ZAdded = false(size(Z));
            for ii = 1:length(Z)
                if Z(ii) == real(Z(ii))
                    if Z(ii) == 0
                        type = getString(message('Control:design:compEditorDiff'));
                        damping = "1";
                    else
                        type = getString(message('Control:design:compEditorRealZero'));
                        damping = string(num2str(-sign(Z(ii))));
                    end
                    location = string(num2str(Z(ii)));
                    if Ts
                        sLocation = log(Z(ii))/Ts;
                        frequency = string(num2str(abs(sLocation)));
                    else
                        frequency = string(num2str(abs(Z(ii))));
                    end
                    this.DynamicsTable.Data(end+1,:) = [type,location,damping,frequency];
                    ZAdded(ii) = true;
                    this.DynamicsTablePZMap{end+1} = ii;
                elseif ~ZAdded(ii)
                    zr = real(Z(ii));
                    zi = imag(Z(ii));
                    type = getString(message('Control:design:compEditorCCZero'));
                    location = string([num2str(zr) '±' num2str(abs(zi)) +'i']);
                    if Ts
                        sLocation = log(Z(ii))/Ts;
                        zr = real(sLocation);
                        zi = imag(sLocation);
                    end
                    wn = sqrt(zr^2+zi^2);
                    damping = string(num2str(-zr/wn));
                    frequency = string(num2str(wn));
                    this.DynamicsTable.Data(end+1,:) = [type,location,damping,frequency];
                    idx = ii+find(Z(ii+1:end)==conj(Z(ii)));
                    ZAdded(ii) = true;
                    ZAdded(idx) = true;
                    this.DynamicsTablePZMap{end+1} = [ii idx];
                end
            end
            P = this.Compensator.P{1,1};
            PAdded = false(size(P));
            for ii = 1:length(P)
                if P(ii) == real(P(ii))
                    if P(ii) == 0
                        type = getString(message('Control:design:compEditorInt'));
                        damping = "1";
                    else
                        type = getString(message('Control:design:compEditorRealPole'));
                        damping = string(num2str(-sign(P(ii))));
                    end
                    location = string(num2str(P(ii)));
                    if Ts
                        sLocation = log(P(ii))/Ts;
                        frequency = string(num2str(abs(sLocation)));
                    else
                        frequency = string(num2str(abs(P(ii))));
                    end
                    this.DynamicsTable.Data(end+1,:) = [type,location,damping,frequency];
                    PAdded(ii) = true;
                    this.DynamicsTablePZMap{end+1} = ii;
                elseif ~PAdded(ii)
                    pr = real(P(ii));
                    pi = imag(P(ii));
                    type = getString(message('Control:design:compEditorCCPole'));
                    location = string([num2str(pr) '±' num2str(abs(pi)) +'i']);
                    if Ts
                        sLocation = log(P(ii))/Ts;
                        pr = real(sLocation);
                        pi = imag(sLocation);
                    end
                    wn = sqrt(pr^2+pi^2);
                    damping = string(num2str(-pr/wn));
                    frequency = string(num2str(wn));
                    this.DynamicsTable.Data(end+1,:) = [type,location,damping,frequency];
                    idx = ii+find(P(ii+1:end)==conj(P(ii)));
                    PAdded(ii) = true;
                    PAdded(idx) = true;
                    this.DynamicsTablePZMap{end+1} = [ii idx];
                end
            end
            if ~isempty(this.SelectedPZValue)
                for ii = 1:size(this.DynamicsTable.Data,1)
                    data = this.DynamicsTable.Data(ii,:);
                    if strcmp(data(1),getString(message('Control:design:compEditorCCPole'))) ||...
                            strcmp(data(1),getString(message('Control:design:compEditorCCZero')))
                        zeta = str2double(data(3));
                        w = str2double(data(4));
                        zr = -zeta*w;
                        zi = sqrt(w^2-zr^2);
                        if this.Compensator.Ts
                            loc = log(zr+zi*1j)/Ts;
                            zr = real(loc);
                            zi = imag(loc);
                        end
                        if abs(this.SelectedPZValue-(zr+zi*1i)) < sqrt(eps)
                            this.DynamicsTable.Selection = ii;
                            break;
                        end
                    else
                        loc = str2double(data(2));
                        if abs(this.SelectedPZValue-loc) < sqrt(eps)
                            this.DynamicsTable.Selection = ii;
                            break;
                        end
                    end
                end
            end
        end

        function updateEditDynamicsPanel(this)
            % Update visible editfields given table selection.
            if isempty(this.DynamicsTable.Selection)
                this.EditDynamicsLayout.RowHeight = {'fit',0,0,0,0,0};
                this.EditDynamicsLabel.Visible = true;
                this.PZLocationLabel.Visible = false;
                this.PZLocationEditField.Visible = false;
                this.ComplexConjugatePZFrequencyLabel.Visible = false;
                this.ComplexConjugatePZFrequencyEditField.Visible = false;
                this.ComplexConjugatePZDampingLabel.Visible = false;
                this.ComplexConjugatePZDampingEditField.Visible = false;
                this.ComplexConjugatePZRealLabel.Visible = false;
                this.ComplexConjugatePZRealEditField.Visible = false;
                this.ComplexConjugatePZImagLabel.Visible = false;
                this.ComplexConjugatePZImagEditField.Visible = false;
                this.SelectedPZValue = [];
            else
                data = this.DynamicsTable.Data(this.DynamicsTable.Selection,:);
                if strcmp(data(1),getString(message('Control:design:compEditorCCPole'))) ||...
                        strcmp(data(1),getString(message('Control:design:compEditorCCZero')))
                    this.EditDynamicsLayout.RowHeight = {0,0,'fit','fit','fit','fit'};
                    this.EditDynamicsLabel.Visible = false;
                    this.PZLocationLabel.Visible = false;
                    this.PZLocationEditField.Visible = false;
                    this.ComplexConjugatePZFrequencyLabel.Visible = true;
                    this.ComplexConjugatePZFrequencyEditField.Visible = true;
                    this.ComplexConjugatePZDampingLabel.Visible = true;
                    this.ComplexConjugatePZDampingEditField.Visible = true;
                    this.ComplexConjugatePZRealLabel.Visible = true;
                    this.ComplexConjugatePZRealEditField.Visible = true;
                    this.ComplexConjugatePZImagLabel.Visible = true;
                    this.ComplexConjugatePZImagEditField.Visible = true;
                    zeta = str2double(data(3));
                    w = str2double(data(4));
                    zr = -zeta*w;
                    zi = sqrt(w^2-zr^2);
                    if this.Compensator.Ts
                        loc = log(zr+zi*1j)/abs(this.Compensator.Ts);
                        zr = real(loc);
                        zi = imag(loc);
                    end
                    this.ComplexConjugatePZFrequencyEditField.Value = w;
                    this.ComplexConjugatePZDampingEditField.Value = zeta;
                    this.ComplexConjugatePZRealEditField.Value = zr;
                    this.ComplexConjugatePZImagEditField.Value = zi;
                    this.SelectedPZValue = zr+zi*1i;
                else
                    this.EditDynamicsLayout.RowHeight = {0,'fit',0,0,0,0};
                    this.EditDynamicsLabel.Visible = false;
                    this.PZLocationLabel.Visible = true;
                    this.PZLocationEditField.Visible = true;
                    this.ComplexConjugatePZFrequencyLabel.Visible = false;
                    this.ComplexConjugatePZFrequencyEditField.Visible = false;
                    this.ComplexConjugatePZDampingLabel.Visible = false;
                    this.ComplexConjugatePZDampingEditField.Visible = false;
                    this.ComplexConjugatePZRealLabel.Visible = false;
                    this.ComplexConjugatePZRealEditField.Visible = false;
                    this.ComplexConjugatePZImagLabel.Visible = false;
                    this.ComplexConjugatePZImagEditField.Visible = false;
                    loc = str2double(data(2));
                    this.PZLocationEditField.Value = loc;
                    this.SelectedPZValue = loc;
                end
            end
        end

        function updateFormatDisplay(this)
            % Update example ZPK display.
            switch this.DisplayFormat
                case "TimeConstant"
                    this.DisplayFormatLabel.Text = "$$DC\; \times \; \frac{\left(1+T_z\;s\right)}{\left(1+T_p\;s\right)}$$";
                case "NaturalFrequency"
                    this.DisplayFormatLabel.Text = "$$DC\; \times \; \frac{\left(1+\frac{s}{\omega_z}\right)}{\left(1+\frac{s}{\omega_p}\right)}$$";
                case "ZPK"
                    this.DisplayFormatLabel.Text = "$$K\; \times \; \frac{\left(s+z\right)}{\left(s+p\right)}$$";
            end
        end

        function updatePZDisplay(this)
            % Update ZPK display.
            [ZString, PString] = getPZDisplayString(this);
            if isempty(ZString) && isempty(PString)
                PZString = '';
            elseif isempty(ZString)
                fString = '\; \times \; \frac';
                PZString = sprintf('$$%s{%s}{%s}$$', fString, '1', PString);
            elseif isempty(PString)
                fString = '\; \times \;';
                PZString = sprintf('$$%s{%s}$$', fString, ZString);
            else
                fString = '\; \times \; \frac';
                PZString = sprintf('$$%s{%s}{%s}$$', fString, ZString, PString);
            end
            this.CompensatorPZLabel.Text = PZString;
        end

        function [ZString, PString] = getPZDisplayString(this)
            % Get ZP display from compensator.
            Z = this.Compensator.Z{1,1};
            P = this.Compensator.P{1,1};
            if this.Compensator.Ts
                var = 'z';
            else
                var = 's';
            end
            ZString = '';
            PString = '';
            ZAdded = false(size(Z));
            PAdded = false(size(P));
            numDiff = 0;
            numInt = 0;
            switch this.DisplayFormat
                case "TimeConstant"
                    % Real poles/zeros are written as (1+1/wn*p), complex-conjugate
                    % pole/zeros are written as (1+2*zeta/wn*s+1/wn^2*s^2).
                    for ii = 1:length(Z)
                        if Z(ii) == real(Z(ii))
                            if Z(ii) == 0
                                numDiff = numDiff+1;
                            else
                                if Z(ii) > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(abs(Z(ii)),1)
                                    ZString = [ZString sprintf('\\left(1%s%s\\right)',sn,var)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(1%s%g%s\\right)',sn,1/abs(Z(ii)),var)]; %#ok<AGROW>
                                end
                            end
                            ZAdded(ii) = true;
                        elseif ~ZAdded(ii)
                            re = real(Z(ii));
                            im = imag(Z(ii));
                            wn = sqrt(re^2+im^2);
                            zeta = re/wn;
                            if re == 0
                                if isapprox(wn,1)
                                    ZString = [ZString sprintf('\\left(1+%s^2\\right)',var)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(1+%g%s^2\\right)',1/wn^2,var)]; %#ok<AGROW>
                                end
                            else
                                if re > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(wn,1) && isapprox(2*abs(zeta)/wn,1)
                                    ZString = [ZString sprintf('\\left(1%s%s+%s^2\\right)',sn,var,var)]; %#ok<AGROW>
                                elseif isapprox(wn,1)
                                    ZString = [ZString sprintf('\\left(1%s%g%s+%s^2\\right)',sn,2*abs(zeta)/wn,var,var)]; %#ok<AGROW>
                                elseif isapprox(2*abs(zeta)/wn,1)
                                    ZString = [ZString sprintf('\\left(1%s%s+%g%s^2\\right)',sn,var,1/wn^2,var)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(1%s%g%s+%g%s^2\\right)',sn,2*abs(zeta)/wn,var,1/wn^2,var)]; %#ok<AGROW>
                                end
                            end
                            idx = ii+find(Z(ii+1:end)==conj(Z(ii)));
                            ZAdded(ii) = true;
                            ZAdded(idx) = true;
                        end
                    end
                    for ii = 1:length(P)
                        if P(ii) == real(P(ii))
                            if P(ii) == 0
                                numInt = numInt+1;
                            else
                                if P(ii) > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(abs(P(ii)),1)
                                    PString = [PString sprintf('\\left(1%s%s\\right)',sn,var)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(1%s%g%s\\right)',sn,1/abs(P(ii)),var)]; %#ok<AGROW>
                                end
                            end
                            PAdded(ii) = true;
                        elseif ~PAdded(ii)
                            re = real(P(ii));
                            im = imag(P(ii));
                            wn = sqrt(re^2+im^2);
                            zeta = re/wn;
                            if re == 0
                                if isapprox(wn,1)
                                    PString = [PString sprintf('\\left(1+%s^2\\right)',var)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(1+%g%s^2\\right)',1/wn^2,var)]; %#ok<AGROW>
                                end
                            else
                                if re > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(wn,1) && isapprox(2*abs(zeta)/wn,1)
                                    PString = [PString sprintf('\\left(1%s%s+%s^2\\right)',sn,var,var)]; %#ok<AGROW>
                                elseif isapprox(wn,1)
                                    PString = [PString sprintf('\\left(1%s%g%s+%s^2\\right)',sn,2*abs(zeta)/wn,var,var)]; %#ok<AGROW>
                                elseif isapprox(2*abs(zeta)/wn,1)
                                    PString = [PString sprintf('\\left(1%s%s+%g%s^2\\right)',sn,var,1/wn^2,var)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(1%s%g%s+%g%s^2\\right)',sn,2*abs(zeta)/wn,var,1/wn^2,var)]; %#ok<AGROW>
                                end
                            end
                            idx = ii+find(P(ii+1:end)==conj(P(ii)));
                            PAdded(ii) = true;
                            PAdded(idx) = true;
                        end
                    end
                case "NaturalFrequency"
                    % Real poles/zeros are written as (1+p/wn), complex-conjugate
                    % pole/zeros are written as (1+2*zeta*s/wn+s^2/wn^2).
                    for ii = 1:length(Z)
                        if Z(ii) == real(Z(ii))
                            if Z(ii) == 0
                                numDiff = numDiff+1;
                            else
                                if Z(ii) > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(abs(Z(ii)),1)
                                    ZString = [ZString sprintf('\\left(1%s%s\\right)',sn,var)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(1%s\\frac{%s}{%g}\\right)',sn,var,abs(Z(ii)))]; %#ok<AGROW>
                                end
                            end
                            ZAdded(ii) = true;
                        elseif ~ZAdded(ii)
                            re = real(Z(ii));
                            im = imag(Z(ii));
                            wn = sqrt(re^2+im^2);
                            zeta = re/wn;
                            if re == 0
                                if isapprox(wn,1)
                                    ZString = [ZString sprintf('\\left(1+%s^2\\right)',var)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(1+\\frac{%s^2}{%g}\\right)',var,wn^2)]; %#ok<AGROW>
                                end
                            else
                                if re > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(wn,1) && isapprox(2*abs(zeta)/wn,1)
                                    ZString = [ZString sprintf('\\left(1%s%s+%s^2\\right)',sn,var,var)]; %#ok<AGROW>
                                elseif isapprox(wn,1)
                                    ZString = [ZString sprintf('\\left(1%s\\frac{%s}{%g}+%s^2\\right)',sn,var,wn/(2*abs(zeta)),var)]; %#ok<AGROW>
                                elseif isapprox(2*abs(zeta)/wn,1)
                                    ZString = [ZString sprintf('\\left(1%s%s+\\frac{%s^2}{%g}\\right)',sn,var,var,wn^2)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(1%s\\frac{%s}{%g}+\\frac{%s^2}{%g}\\right)',sn,var,wn/(2*abs(zeta)),var,wn^2)]; %#ok<AGROW>
                                end
                            end
                            idx = ii+find(Z(ii+1:end)==conj(Z(ii)));
                            ZAdded(ii) = true;
                            ZAdded(idx) = true;
                        end
                    end
                    for ii = 1:length(P)
                        if P(ii) == real(P(ii))
                            if P(ii) == 0
                                numInt = numInt+1;
                            else
                                if P(ii) > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(abs(P(ii)),1)
                                    PString = [PString sprintf('\\left(1%s%s\\right)',sn,var)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(1%s\\frac{%s}{%g}\\right)',sn,var,abs(P(ii)))]; %#ok<AGROW>
                                end
                            end
                            PAdded(ii) = true;
                        elseif ~PAdded(ii)
                            re = real(P(ii));
                            im = imag(P(ii));
                            wn = sqrt(re^2+im^2);
                            zeta = re/wn;
                            if re == 0
                                if isapprox(wn,1)
                                    PString = [PString sprintf('\\left(1+%s^2\\right)',var)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(1+\\frac{%s^2}{%g}\\right)',var,wn^2)]; %#ok<AGROW>
                                end
                            else
                                if re > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(wn,1) && isapprox(2*abs(zeta)/wn,1)
                                    PString = [PString sprintf('\\left(1%s%s+%s^2\\right)',sn,var,var)]; %#ok<AGROW>
                                elseif isapprox(wn,1)
                                    PString = [PString sprintf('\\left(1%s\\frac{%s}{%g}+%s^2\\right)',sn,var,wn/(2*abs(zeta)),var)]; %#ok<AGROW>
                                elseif isapprox(2*abs(zeta)/wn,1)
                                    PString = [PString sprintf('\\left(1%s%s+\\frac{%s^2}{%g}\\right)',sn,var,var,wn^2)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(1%s\\frac{%s}{%g}+\\frac{%s^2}{%g}\\right)',sn,var,wn/(2*abs(zeta)),var,wn^2)]; %#ok<AGROW>
                                end
                            end
                            idx = ii+find(P(ii+1:end)==conj(P(ii)));
                            PAdded(ii) = true;
                            PAdded(idx) = true;
                        end
                    end
                case "ZPK"
                    % Real poles/zeros are written as (s+p), complex-conjugate
                    % pole/zeros are written as (s^2+2*zeta*wn*s+wn^2).
                    for ii = 1:length(Z)
                        if Z(ii) == real(Z(ii))
                            if Z(ii) == 0
                                numDiff = numDiff+1;
                            else
                                if Z(ii) > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                ZString = [ZString sprintf('\\left(%s%s%g\\right)',var,sn,abs(Z(ii)))]; %#ok<AGROW>
                            end
                            ZAdded(ii) = true;
                        elseif ~ZAdded(ii)
                            re = real(Z(ii));
                            im = imag(Z(ii));
                            wn = sqrt(re^2+im^2);
                            zeta = re/wn;
                            if re == 0
                                ZString = [ZString sprintf('\\left(%s^2+%g\\right)',var,wn^2)]; %#ok<AGROW>
                            else
                                if re > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(2*abs(zeta)*wn,1)
                                    ZString = [ZString sprintf('\\left(%s^2%s%s+%g\\right)',var,sn,var,wn^2)]; %#ok<AGROW>
                                else
                                    ZString = [ZString sprintf('\\left(%s^2%s%g%s+%g\\right)',var,sn,2*abs(zeta)*wn,var,wn^2)]; %#ok<AGROW>
                                end
                            end
                            idx = ii+find(Z(ii+1:end)==conj(Z(ii)));
                            ZAdded(ii) = true;
                            ZAdded(idx) = true;
                        end
                    end
                    for ii = 1:length(P)
                        if P(ii) == real(P(ii))
                            if P(ii) == 0
                                numInt = numInt+1;
                            else
                                if P(ii) > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                PString = [PString sprintf('\\left(%s%s%g\\right)',var,sn,abs(P(ii)))]; %#ok<AGROW>
                            end
                            PAdded(ii) = true;
                        elseif ~PAdded(ii)
                            re = real(P(ii));
                            im = imag(P(ii));
                            wn = sqrt(re^2+im^2);
                            zeta = re/wn;
                            if re == 0
                                PString = [PString sprintf('\\left(%s^2+%g\\right)',var,wn^2)]; %#ok<AGROW>
                            else
                                if re > 0
                                    sn = '-';
                                else
                                    sn = '+';
                                end
                                if isapprox(2*abs(zeta)*wn,1)
                                    PString = [PString sprintf('\\left(%s^2%s%s+%g\\right)',var,sn,var,wn^2)]; %#ok<AGROW>
                                else
                                    PString = [PString sprintf('\\left(%s^2%s%g%s+%g\\right)',var,sn,2*abs(zeta)*wn,var,wn^2)]; %#ok<AGROW>
                                end
                            end
                            idx = ii+find(P(ii+1:end)==conj(P(ii)));
                            PAdded(ii) = true;
                            PAdded(idx) = true;
                        end
                    end
            end
            % Integrators/differentiators are pulled to the front
            % and grouped together s^n.
            if numDiff > 1
                ZString = [sprintf('%s^%g',var,numDiff) ZString];
            elseif numDiff > 0
                ZString = [var ZString];
            end
            if numInt > 1
                PString = [sprintf('%s^%g',var,numInt) PString];
            elseif numInt > 0
                PString = [var PString];
            end
        end

        function updateContextMenu(this, ed)
            % Update table context menu and selection based on click location.
            interactionInformation = ed.InteractionInformation;
            if ed.ContextObject == this.DynamicsTable ...
                    && ~(interactionInformation.RowHeader || interactionInformation.ColumnHeader)
                row = interactionInformation.DisplayRow;
                col = interactionInformation.DisplayColumn;
                % React when a cell or the white space is clicked.
                if isempty([row col])
                    % Remove current row selections.
                    this.DynamicsTable.Selection = [];
                    children = this.DynamicsTableContextMenu.Children;
                    children(1).Enable = false;
                else
                    % Select the right-clicked row.
                    if isempty(this.DynamicsTable.Selection) || this.DynamicsTable.Selection ~= row
                        this.DynamicsTable.Selection = row;
                        updateEditDynamicsPanel(this);
                    end
                    % Enable submenus.
                    cm = this.DynamicsTableContextMenu;
                    children = cm.Children;
                    children(1).Enable = true;
                end
            else
                this.DynamicsTable.Selection = [];
                children = this.DynamicsTableContextMenu.Children;
                children(1).Enable = false;
            end
        end

        function setCompensatorAndNotify(this,comp)
            oldComp = this.Compensator_I;
            this.Compensator_I = zpk(comp);
            update(this);
            ed = ctrlguis.uicomponent.loopeditor.CompensatorChangedData(this.Compensator,oldComp);
            notify(this,'CompensatorChanged',ed);
        end
    end

    %% Static private methods
    methods (Static,Access=private)
        function validateCompensator(comp)
            try
                comp = zpk(comp);
            catch
                error(message('Control:design:loopEditorErrorCompZPK'));
            end
            if isempty(comp)
                error(message('Control:design:loopEditorErrorCompEmpty'));
            elseif ~issiso(comp)
                error(message('Control:design:loopEditorErrorCompMIMO'));
            elseif nmodels(comp) > 1
                error(message('Control:design:loopEditorErrorCompArray'));
            elseif ~isreal(comp)
                error(message('Control:design:loopEditorErrorCompComplex'));
            elseif hasdelay(comp)
                error(message('Control:design:loopEditorErrorCompDelay'));
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function qeUpdate(this)
            update(this);
        end

        function wdgt = qeGetWidgets(this)
            wdgt = struct('CompensatorPanel',this.CompensatorPanel,...
                'CompensatorPanelLayout',this.CompensatorPanelLayout,...
                'DisplayFormatPanel',this.DisplayFormatPanel,...
                'DisplayFormatLayout',this.DisplayFormatLayout,...
                'DisplayFormatDropDown',this.DisplayFormatDropDown,...
                'DisplayFormatLabel',this.DisplayFormatLabel,...
                'CompensatorLabel',this.CompensatorLabel,...
                'CompensatorGainEditField',this.CompensatorGainEditField,...
                'CompensatorPZLabel',this.CompensatorPZLabel,...
                'DynamicsPanel',this.DynamicsPanel,...
                'DynamicsLayout',this.DynamicsLayout,...
                'DynamicsTablePanel',this.DynamicsTablePanel,...
                'DynamicsTableLayout',this.DynamicsTableLayout,...
                'DynamicsTable',this.DynamicsTable,...
                'DynamicsTableLabel',this.DynamicsTableLabel,...
                'DynamicsTableContextMenu',this.DynamicsTableContextMenu,...
                'EditDynamicsPanel',this.EditDynamicsPanel,...
                'EditDynamicsLayout',this.EditDynamicsLayout,...
                'EditDynamicsLabel',this.EditDynamicsLabel,...
                'PZLocationLabel',this.PZLocationLabel,...
                'PZLocationEditField',this.PZLocationEditField,...
                'ComplexConjugatePZFrequencyLabel',this.ComplexConjugatePZFrequencyLabel,...
                'ComplexConjugatePZFrequencyEditField',this.ComplexConjugatePZFrequencyEditField,...
                'ComplexConjugatePZDampingLabel',this.ComplexConjugatePZDampingLabel,...
                'ComplexConjugatePZDampingEditField',this.ComplexConjugatePZDampingEditField,...
                'ComplexConjugatePZRealLabel',this.ComplexConjugatePZRealLabel,...
                'ComplexConjugatePZRealEditField',this.ComplexConjugatePZRealEditField,...
                'ComplexConjugatePZImagLabel',this.ComplexConjugatePZImagLabel,...
                'ComplexConjugatePZImagEditField',this.ComplexConjugatePZImagEditField,...
                'GridLayout',this.GridLayout);
        end
    end
end

