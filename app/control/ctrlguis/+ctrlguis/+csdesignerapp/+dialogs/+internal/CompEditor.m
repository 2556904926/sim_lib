classdef CompEditor < controllib.ui.internal.dialog.AbstractDialog & ...
                      matlab.mixin.SetGet
    % COMPENSATOR EDITOR is a dialog that let's users edit the structure
    % of their controller from DataBrowser, Tuning Dialogs and such

    % Copyright 2013 - 2022 The Mathworks, Inc.
    
    properties (SetAccess = private, GetAccess =? matlab.unittest.TestCase)
        
        Parent

        Compensator

        FrequencyUnits
        PrecisionFormat
        GainCache
        DesignerData
        Preferences
        PZTable
        CurrentPZType

        GainList
        CompList
        AllCompList
        SelectedCompensator
        Ts

        Widgets
        UIListeners

    end

    properties (Access = public)
        CompensatorIndex
    end

    properties (Constant = true)
        PRECISION = '%0.5g';
    end
    
    methods
        function this = CompEditor(Parent, DesignerData, Index)
            %  COMPEDITOR 
            %  Set all relevant properties when contrusting the first 
            %  instance
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.DesignerData = DesignerData;
            this.PrecisionFormat = this.PRECISION;
            this.Parent = Parent;
            this.Title = getString(message(['Control:' ...
                'compDesignTask:strCompensatorEditor']));
            this.Name = sprintf('CSD-Compensator-Editor-%s', ...
                matlab.lang.internal.uuid);
            this.CloseMode = 'destroy';


            % find tunable blocks in the model
            boolIsGainBlock = [];
            tunableBlocks = getTunableBlocks(this.DesignerData);
            if ~isempty(tunableBlocks)
                boolIsGainBlock = isGainBlock(tunableBlocks);
            end
            
            % assign gain lists and compensator lists
            this.GainList = tunableBlocks(boolIsGainBlock);
            this.CompList = tunableBlocks(~boolIsGainBlock);
            this.AllCompList = tunableBlocks; 

            % assign index, compensator
            if isempty(Index)
                Index = 1;
            end
                
            set(this, 'CompensatorIndex', Index);
            this.SelectedCompensator = get(this, 'SelectedCompensator');
            this.Ts = getTs(this.SelectedCompensator);


            % assign frequencyUnits
            this.FrequencyUnits = get(this, 'FrequencyUnits');
            
            
        end

        function Preferences = get.Preferences(this)
            Preferences = getPreferences(this.Parent);
        end

        function FrequencyUnits = get.FrequencyUnits(this)
             prefrences = getPreferences(this.Parent);
             FrequencyUnits = prefrences.FrequencyUnits;
        end

        function Compensator = get.SelectedCompensator(this)
            
            Compensator = this.AllCompList(this.CompensatorIndex);
        end

        function set.CompensatorIndex(this, index)
            this.CompensatorIndex = index;
        end

        function updateUI(this)
            
            % update the comp dropdown
            this.Widgets.CompListDropdown.Value = this.Widgets.CompListDropdown. ...
                    Items{this.CompensatorIndex};
            updateCompDisplay(this);
            
            if isSimulink(this.DesignerData)
                updateParamTab(this);
                updatePZTable(this);
                updateEditPanel(this);
                % this.Widgets.TabGroupPanel.SelectedTab = this.Widgets.ParamTab;
            else
                updatePZTable(this);
                updateEditPanel(this);
                % this.Widgets.TabGroupPanel.SelectedTab = this.Widgets.PZTab;
            end
        end

        function updateCompDisplay(this)
            
            % reset index and compensator
            % update to current selection

            this.SelectedCompensator = get(this, 'SelectedCompensator');
            this.Ts = getTs(this.SelectedCompensator);
            % assign frequencyUnits
            this.FrequencyUnits = get(this, 'FrequencyUnits');

            c = this.SelectedCompensator;
            [PZString, GainString, lenString] = ctrlguis.csdesignerapp. ...
                                utils.internal.utParseCompDisplay(c);
            this.Widgets.CompPZLabel.Text = PZString;
            this.Widgets.CompGainLabel.Value = str2num(GainString);
        end

        function updatePZTable(this)
            
            % get the poles, zeros and sampling time
            PZGroup = this.SelectedCompensator.PZGroup;
            [nRows, ~] = size(this.Widgets.PZTable);
            nPZGroup = length(PZGroup); 
            vNames = ["Type", "Location", "Damping", "Frequency"];
            
            % create an empty dataset
            data = table('Size', [0 4], 'VariableTypes', ...
                {'string', 'string', 'string', 'string'});
            data.Properties.VariableNames = vNames;

            if ~isempty(PZGroup)
                % update the table if there's a change
                if ~isequal(nRows, nPZGroup) || ~isequal(nPZGroup, 0)
                    for i = 1:nPZGroup
                        rowdata = cell2table(updatePZData(this, PZGroup(i)));
                        data(i, (1:4)) = rowdata;
                    end
                    this.Widgets.PZTable.ColumnName = {getString(message('Control:compDesignTask:strType')),...
                                          getString(message('Control:compDesignTask:strLocation')),...
                                          getString(message('Control:compDesignTask:strDamping')),...
                                          getString(message('Control:compDesignTask:strFrequency'))};
                    this.Widgets.PZTable.Data = data;
                end
            else
                this.Widgets.PZTable.Data = [];
            end
        end

        function updateParamTab(this)
            % get and filter parameters
            parameters = getParameters(this.SelectedCompensator);
            if ~isempty(parameters)
                parameters = parameters(strcmp('on', {parameters.Tunable}));
            end
            
            %% filter out double value parameters only
            for ct = 1:length(parameters)
                if ~strcmp('double',class(parameters(ct).Value))
                    parameters(ct) = [];
                end
            end
            
            nParameters = length(parameters);
            nParameterWidgets = length(this.Widgets.ParamEF);

            for i = 1:nParameterWidgets
                delete(this.Widgets.ParamEF{i});
            end
            this.Widgets.ParamEF = {};
            for i = 1:nParameters
                widgets = createParameterRow(this, ...
                    parameters(i), i);
                this.Widgets.ParamEF{end+1} = widgets;

            end

        end

        function Widgets = get.Widgets(this)
            Widgets = this.Widgets; 
        end

    end

    methods (Access = protected)
        
        function buildUI(this)
            % BUILDUI 
            % creates all relevant UIComponents when contructing the 
            % dialog. This is split into the following sections: 
            % 1. Compensator 
            % 2. Pole-Zero Tab - more sections involved
            % 3. Parameter Tab (not active in ML) 
            % 4. Button Panel

            % create main grid layout and split into 3 sections. 
            % 1. Compensator 
            % 2. Tab Sections 
            % 3. Button Panel

            this.UIFigure.Position(3:4) = [750 450]; 
            mainGridLayout = uigridlayout(this.UIFigure, [3 2]);
            mainGridLayout.RowHeight = {'fit', '1x', 'fit'};
            mainGridLayout.ColumnWidth = {'1x', 'fit'}; %1x
            mainGridLayout.Tag = 'CSD-Dialog-Compensator-Editor-GridLayout';
            mainGridLayout.Scrollable = 'on';

            this.Widgets.GridLayout = mainGridLayout;
            
            % create the UI components for Compensator Display
            createCompensatorDisplay(this);
            % create the UI components for Tab Group
            createTabGroup(this);
            createPoleZeroTab(this);
            if isSimulink(this.DesignerData)
                createParameterTab(this);
                this.Widgets.TabGroupPanel.SelectedTab = this.Widgets.PZTab;
            end


            % create button panel
            buttonPanel = createButtonPanel(this);
            this.Widgets.ButtonPanel = buttonPanel;
        end

        function connectUI(this)
            
            L1 = addlistener(this.DesignerData, ...
                                 'TunableBlocksListChanged', ...
                                 @(src, evt)updateUI(this));
            L2 = addlistener(this.DesignerData.Architecture, ...
                                'SystemChanged', ...
                                 @(src, evt)updateUI(this));
            L3 = addlistener(this.Preferences, 'FrequencyUnits', 'PostSet', ...
                @(src, evt)updateUI(this));
            
            L4 = addlistener(this.SelectedCompensator, 'ValueChanged', ...
                @(src, evt)updateUI(this));

%             L4 = addlistener(this.CompensatorIndex, 'ValueChanged', ...
%                 @(src, evt)updateCompListDropdown(this));

            % add callback to dropdown
            this.Widgets.CompListDropdown.ValueChangedFcn = @(src, evt) ...
                    updateCompListDropdown(this, src, evt);

            % add callback to gain
            this.Widgets.CompGainLabel.ValueChangedFcn = @(src, evt) ...
                    updateGain(this, src, evt);

            % add callbacks to addContextMenu Children items
            addSubMenu = this.Widgets.AddPZMenu.Children;
            for i = 1:length(addSubMenu)
                addSubMenu(i).MenuSelectedFcn = @(src, evt)addPoleZero( ...
                                                    this, src, evt);
            end

            this.Widgets.DeletePZMenu.MenuSelectedFcn = @(src, evt)deletePoleZero( ...
                                                    this, src, evt);
            % add callback to table selection to update Editor Dynamics
            this.Widgets.PZTable.SelectionChangedFcn = @(src, evt) ...
                                    updateEditPanel(this);
            % Add callback to update selection when right-clicking to open context menu
            L5 = addlistener(this.Widgets.PZTable.ContextMenu,'ContextMenuOpening',...
                @(es,ed) cbContextMenuOpening(this,ed));

            % pz - editor
            % add callbacks to EditFields
            this.Widgets.EditField1.ValueChangedFcn = @(src, evt) ...
                updatePZEditFields(this, src, evt);
            this.Widgets.EditField2.ValueChangedFcn = @(src, evt) ...
                updatePZEditFields(this, src, evt);
            this.Widgets.EditField3.ValueChangedFcn = @(src, evt) ...
                updatePZEditFields(this, src, evt);
            this.Widgets.EditField4.ValueChangedFcn = @(src, evt) ...
                updatePZEditFields(this, src, evt);
            this.Widgets.EditField5.ValueChangedFcn = @(src, evt) ...
                updatePZEditFields(this, src, evt);

            % add callbacks to help & cancel buttons
            buttonPanel = this.Widgets.ButtonPanel;
            buttonPanel.HelpButton.ButtonPushedFcn = @(src, evt) ...
                                cbHelpButton(this);
            buttonPanel.CancelButton.ButtonPushedFcn = @(src, evt) ...
                                cbCancelButton(this);

            this.UIListeners{end+1} = L1;
            this.UIListeners{end+1} = L2;

            registerDataListeners(this, L1, 'TunableBlockChangedListener');
            registerDataListeners(this, L2, 'SystemChangedListener');
            registerDataListeners(this, L3, 'FrequencyUnitsListener');
            registerDataListeners(this, L4, 'CompensatorVCListener');
            registerUIListeners(this,L5,'TableContextMenuOpening');
        end

        function cleanupUI(this)
            
            % delete the top level layout container.
            delete(this.Widgets.GridLayout)
            this.Widgets.GridLayout = [];
        end

        function createCompensatorDisplay(this)
            compSelectionPanel = uipanel(this.Widgets.GridLayout, 'Title', ...
                                         getString(message( ...
                                         'Control:designerapp:strCompensator')));
            compSelectionPanel.Layout.Row = 1;
            compSelectionPanel.Layout.Column = [1 2];
            compSelectionPanel.FontWeight = 'bold';
            compSelectionPanel.BorderType = 'none';

            compSelectionLayout = uigridlayout(compSelectionPanel, [1 1]);
            compSelectionLayout.RowHeight = {'fit', 'fit'};
            compSelectionLayout.ColumnWidth = {'1x'};

            this.Widgets.CompensatorPanel = compSelectionPanel;
            this.Widgets.CompensatorLayout = compSelectionLayout;

            
            [~, wdgts] = ctrlguis.csdesignerapp.utils.internal.utCompensatorDisplay(this.AllCompList, ...
                                this.Widgets.CompensatorLayout, ...
                                this.SelectedCompensator);
            [isMember, memberIndex] = ismember(this.SelectedCompensator.Name, ...
                                               wdgts.CompListDropdown.Items);
            if isMember
                wdgts.CompListDropdown.Value = wdgts.CompListDropdown. ...
                    Items{memberIndex};
            else
                wdgts.CompListDropdown.Value = wdgts.CompListDropdown. ...
                    Items{1};
            end
            this.Widgets.CompListDropdown = wdgts.CompListDropdown;
            this.Widgets.CompPZLabel = wdgts.CompPZLabel;
            this.Widgets.CompGainLabel = wdgts.CompGainLabel;
        end

        function createTabGroup(this)

            
            tabPanel = uitabgroup(this.Widgets.GridLayout);
            tabPanel.Layout.Row = 2;
            tabPanel.Layout.Column = [1 2];

            this.Widgets.TabGroupPanel = tabPanel;
        end

        function createPoleZeroTab(this)
            pzTab = uitab(this.Widgets.TabGroupPanel);
            pzTab.Title = getString(message( ...
                          'Control:compDesignTask:strPoleZero'));
            
            pzTabGridLayout = uigridlayout(pzTab, [4 2]);
            pzTabGridLayout.RowHeight = {'1x', '1x', '1x', 'fit'};
            pzTabGridLayout.ColumnWidth = {'1x', '1x'};

            pzTabDynamicsPanel = uipanel(pzTabGridLayout);
            pzTabDynamicsPanel.Title = getString(message( ...
                          'Control:compDesignTask:strDynamics'));
            pzTabDynamicsPanel.FontWeight = 'bold';
            pzTabDynamicsPanel.BorderType = 'none';
            pzTabDynamicsPanel.Layout.Row = [1 3];
            pzTabDynamicsPanel.Layout.Column = 1;

            pzTabTableGridLayout = uigridlayout(pzTabDynamicsPanel, [1 1]);
            pzTabTableGridLayout.RowHeight = {'20x', '1x'};
            pzTabTableGridLayout.ColumnWidth = {'1x'};
            pzTabTableGridLayout.Scrollable = 'on';
            
            % create Dynamics Table
            pzDynamicsTable = uitable(pzTabTableGridLayout);
            pzDynamicsTable.Layout.Row = 1;
            pzDynamicsTable.Layout.Column = 1;
            pzDynamicsTable.Multiselect = 'off';
            pzDynamicsTable.SelectionType = 'row';
            pzDynamicsTable.Data = table([], [], [], [], 'VariableNames', ...
                ["Type", "Location", "Damping", "Frequency"]);
            pzDynamicsTable.ColumnName = {getString(message('Control:compDesignTask:strType')),...
                                          getString(message('Control:compDesignTask:strLocation')),...
                                          getString(message('Control:compDesignTask:strDamping')),...
                                          getString(message('Control:compDesignTask:strFrequency'))};
            pzDynamicsTable.ContextMenu = uicontextmenu('Parent', ...
                                            this.UIFigure);
            
            contextMenuItems1 = uimenu(pzDynamicsTable.ContextMenu, 'Text', ...
                            getString(message( ...
                      'Control:compDesignTask:strAddPoleZero')));
            contextMenuItems2 = uimenu(pzDynamicsTable.ContextMenu, 'Text', ...
                            getString(message( ...
                      'Control:compDesignTask:strDeletePoleZero')));

            % submenu for add pole zero 
            addRealPoleMenu = uimenu(contextMenuItems1, 'Text', ...
                getString(message(['' ...
                'Control:compDesignTask:strRealPole'])));
%             addRealPoleMenu.MenuSelectedFcn = @(src, evt)addPoleZero(this, ...
%                 src, evt);
            addComplexPoleMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strComplexPole'])));
            addIntegratorMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strIntegrator'])));

            addRealZeroMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strRealZero'])), ...
                'Separator', 'on');
            addComplexZeroMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strComplexZero'])));
            addDifferentiatorMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strDifferentiator'])));

            addLeadCompMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strLead'])), ...
                'Separator', 'on');
            addLagCompMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strLag'])));
            addNotchMenu = uimenu(contextMenuItems1, 'Text', getString(message(['' ...
                'Control:compDesignTask:strNotch'])));

            
            if isempty(pzDynamicsTable.Data)
                contextMenuItems2.Enable = 'off';
            end

            % create the initial data dict for the submenu that was successfully created
            createPZDataTable(this);

            % info label beneath the table
            pzLabelPanel = uipanel(pzTabGridLayout);
            pzLabelPanel.Layout.Row = 4;
            pzLabelPanel.Layout.Column = 1;
            pzLabelPanel.BorderType = 'none';
            pzLabelGridLayout = uigridlayout(pzLabelPanel, [1 1]);
            pzLabelGridLayout.RowHeight = {'1x'};
            pzLabelGridLayout.ColumnWidth = {'1x'};
            pzLabelGridLayout.Padding = [0 0 0 0];
            pzMessagePanel = uilabel(pzLabelGridLayout);
            pzMessagePanel.Layout.Row = 1;
            pzMessagePanel.Layout.Column = 1;
            pzMessagePanel.Text = getString(message( ...
                      ['Control:compDesignTask:' ...
                      'msgRightClickToAddDeletePZ']));
            
            % Edit Dynamics Panel
            pzEditorPanel = uipanel(pzTabGridLayout);
            pzEditorPanel.Layout.Row = [1 3];
            pzEditorPanel.Layout.Column = 2;
            pzEditorPanel.Title = getString(message( ...
                      'Control:compDesignTask:strEditSelectedDynamics'));
            pzEditorPanel.FontWeight = 'bold';
            pzEditorPanel.BorderType = 'none';
            
            pzEditorGridLayout = uigridlayout(pzEditorPanel, [5 2]);
            pzEditorGridLayout.RowHeight = {'fit', 'fit', 'fit', 'fit', 'fit'};
            pzEditorGridLayout.ColumnWidth = {'1x', '1x'};
            
            pzEditorInfoLabel = uilabel(pzEditorGridLayout);
            pzEditorInfoLabel.Layout.Row = [1 4];
            pzEditorInfoLabel.Layout.Column = [1 2];
            pzEditorInfoLabel.Text = getString(message( ...
                      ['Control:compDesignTask:' ...
                      'msgSelectSingleRowToEdit']));
            pzEditorInfoLabel.VerticalAlignment = 'top';
            pzEditorInfoLabel.Visible = 'off';
            pzEditorInfoLabel.WordWrap = 'on';
            

            % has only Location component
            label1 = uilabel(pzEditorGridLayout);
            
            label1.HorizontalAlignment = 'right';
            label1.Layout.Row = 1;
            label1.Layout.Column = 1;
            label1.Visible = 'off';

            EditField1 = uieditfield(pzEditorGridLayout, ...
                'numeric');
            EditField1.Layout.Row = 1;
            EditField1.Layout.Column = 2;
            EditField1.Visible = 'off';

            % has Nat. Freq, damping, Real, Imag part components
%             [Wn, Z] = damp(pzDynamicsTable.Selection{2}, this.Ts);
            label2 = uilabel(pzEditorGridLayout);
            
            label2.HorizontalAlignment = 'right';
            label2.Layout.Row = 2;
            label2.Layout.Column = 1;
            label2.Visible = 'off';

            EditField2 = uieditfield(pzEditorGridLayout, ...
                'numeric');
            EditField2.Layout.Row = 2;
            EditField2.Layout.Column = 2;
%             Wn*funitconv('rad/s', this.FrequencyUnits);
            EditField2.Visible = 'off';

            % Damping
            label3 = uilabel(pzEditorGridLayout);
            
            label3.HorizontalAlignment = 'right';
            label3.Layout.Row = 3;
            label3.Layout.Column = 1;
            label3.Visible = 'off';

            EditField3 = uieditfield(pzEditorGridLayout, ...
                'numeric');
            EditField3.Layout.Row = 3;
            EditField3.Layout.Column = 2;
            EditField3.Visible = 'off';

            % Real
            label4 = uilabel(pzEditorGridLayout);
            label4.Visible = 'off';
            
            label4.HorizontalAlignment = 'right';
            label4.Layout.Row = 4;
            label4.Layout.Column = 1;

            EditField4 = uieditfield(pzEditorGridLayout, ...
                'numeric');
            EditField4.Visible = 'off';
            EditField4.Layout.Row = 4;
            EditField4.Layout.Column = 2;
%             EditFieldReal.Value = [];%real(pzDynamicsTable.Selection{2});

            % Imag
            label5 = uilabel(pzEditorGridLayout);
            label5.Visible = 'off';
            
            label5.HorizontalAlignment = 'right';
            label5.Layout.Row = 5;
            label5.Layout.Column = 1;

            EditField5 = uieditfield(pzEditorGridLayout, ...
                'numeric');
            EditField5.Visible = 'off';
            EditField5.Layout.Row = 5;
            EditField5.Layout.Column = 2;
%             EditFieldImag.Value = [];%imag(pzDynamicsTable.Selection{2});

            if isempty(pzDynamicsTable.Selection)
                pzEditorInfoLabel.Visible = 'on';
            else
                updateEditPanel(this);
            end
            

            % add to widgets
            this.Widgets.PZTab = pzTab;
            this.Widgets.PZTable = pzDynamicsTable;
            this.Widgets.AddPZMenu = contextMenuItems1;
            this.Widgets.DeletePZMenu = contextMenuItems2;
            this.Widgets.AddRealPoleMenu = addRealPoleMenu;
            this.Widgets.AddRealZeroMenu = addRealZeroMenu;
            this.Widgets.AddComplexPoleMenu = addComplexPoleMenu;
            this.Widgets.AddComplexZeroMenu = addComplexZeroMenu;
            this.Widgets.AddDifferentorMenu = addDifferentiatorMenu;
            this.Widgets.AddIntegratorMenu = addIntegratorMenu;
            this.Widgets.AddLeadCompMenu = addLeadCompMenu;
            this.Widgets.AddLagCompMenu = addLagCompMenu;
            this.Widgets.AddNotchMenu = addNotchMenu;

            % add to Widgets - Edit Panel
            this.Widgets.EditGL = pzEditorGridLayout;
            this.Widgets.EditInfoLabel = pzEditorInfoLabel;
            this.Widgets.Label1 = label1;
            this.Widgets.EditField1 = EditField1;
            this.Widgets.Label2 = label2;
            this.Widgets.EditField2 = EditField2;
            this.Widgets.Label3 = label3;
            this.Widgets.EditField3 = EditField3;
            this.Widgets.Label4 = label4;
            this.Widgets.EditField4 = EditField4;
            this.Widgets.Label5 = label5;
            this.Widgets.EditField5 = EditField5;

        end

        function createParameterTab(this)
            paramTab = uitab(this.Widgets.TabGroupPanel);
            paramTab.Title = getString(message( ...
                          'Control:compDesignTask:strParameter'));
            if isSimulink(this.DesignerData)
                paramTab.HandleVisibility = 'on';
            else
                paramTab.HandleVisibility = 'off';
            end

            
            % get and filter parameters
            parameters = getParameters(this.SelectedCompensator);
            if ~isempty(parameters)
                parameters = parameters(strcmp('on', {parameters.Tunable}));
            end
            

            %% filter out double value parameters only
            for ct = 1:length(parameters)
                if ~strcmp('double',class(parameters(ct).Value))
                    parameters(ct) = [];
                end
            end
            nParameters = length(parameters);

            % increase rows depending on number of parameters
            nRows = nParameters+1;
            paramTabGridLayout = uigridlayout(paramTab, [nRows 5]);
            for i = 1:nRows
                paramTabGridLayout.RowHeight{i} = 'fit';
            end
            paramTabGridLayout.ColumnWidth = {'fit', 100, 40, '1x', 40};
            paramTabGridLayout.Scrollable = 'on';
            
            this.Widgets.ParamTab = paramTab;
            this.Widgets.ParamGL = paramTabGridLayout;

            paramLabel = uilabel(this.Widgets.ParamGL);
            paramLabel.Text = getString(message( ...
                          'Control:compDesignTask:strParameter'));
            paramLabel.Layout.Row = 1;
            paramLabel.Layout.Column = 1;
            paramLabel.HorizontalAlignment = 'center';
            paramLabel.FontWeight = 'bold';

            valueLabel = uilabel(this.Widgets.ParamGL);
            valueLabel.Text = getString(message( ...
                          'Control:compDesignTask:strValue'));
            valueLabel.Layout.Row = 1;
            valueLabel.Layout.Column = 2;
            valueLabel.HorizontalAlignment = 'center';
            valueLabel.FontWeight = 'bold';

            minLabel = uilabel(this.Widgets.ParamGL);
            minLabel.Text = 'Min';
            minLabel.Layout.Row = 1;
            minLabel.Layout.Column = 3;
            minLabel.HorizontalAlignment = 'center';
            minLabel.FontWeight = 'bold';

            maxLabel = uilabel(this.Widgets.ParamGL);
            maxLabel.Text = 'Max';
            maxLabel.Layout.Row = 1;
            maxLabel.Layout.Column = 5;
            maxLabel.HorizontalAlignment = 'center';
            maxLabel.FontWeight = 'bold';

            

            this.Widgets.ParamEF = {};
            
            if nParameters > 0
                for i = 1:nParameters
                    widgets = createParameterRow(this, ...
                        parameters(i), i);
                    this.Widgets.ParamEF{end+1} = widgets;
                    
                end
            end

            
        end

        function widgets = createParameterRow(this, parameter, index)
            
            value = parameter.Value;
            nameEditField = uilabel(this.Widgets.ParamGL);
            nameEditField.Layout.Row = index+1;
            nameEditField.Layout.Column = 1;
            nameEditField.Text = parameter.Name;
            nameEditField.HorizontalAlignment = 'center';
%             nameEditField.Editable = 'off';
            nameEditField.Tag = string(index);
           
            
            valueEditField = uieditfield(this.Widgets.ParamGL);
            valueEditField.Layout.Row = index+1;
            valueEditField.Layout.Column = 2;
            valueEditField.Tag = string(index);
            valueEditField.Value = mat2str(value);
            valueEditField.ValueChangedFcn = @(src, event)updateEditFieldSlider(this, ... 
                                            src, event);

            % when the value is scalar create other components
            if length(value) < 2
                if value > 0
                    maxValue = 10^(ceil(log10(value)));
                    if isinf(maxValue)
                        maxValue = realmax;
                    end
                    minValue = maxValue/10;
                elseif value < 0
                    minValue = -10^(ceil(log10(abs(value))));
                    if isinf(minValue)
                        minValue = -realmax;
                    end
                    maxValue = minValue/10;
                else
                    minValue = -1;
                    maxValue = 1;
                end

                sliderValue = min(maxValue,max(minValue,value));
    
                minEditField = uieditfield(this.Widgets.ParamGL, 'numeric');
                minEditField.Layout.Row = index+1;
                minEditField.Layout.Column = 3;
                minEditField.Tag = string(index);
                minEditField.Value = minValue;
                minEditField.ValueChangedFcn = @(src, event)updateEditFieldMin(this, ... 
                                                src);
    
                valueSlider = uislider(this.Widgets.ParamGL);
                valueSlider.Layout.Row = index+1;
                valueSlider.Layout.Column = 4;
                valueSlider.MajorTickLabels = {};
                valueSlider.MinorTicks = [];
                valueSlider.MajorTicks = [];
                valueSlider.Limits = [minValue, maxValue];
                valueSlider.Value = sliderValue;
                valueSlider.Tag = string(index);
                valueSlider.ValueChangedFcn = @(src, event)updateEditFieldSlider(this, ... 
                                                src, event);
                
    
                maxEditField = uieditfield(this.Widgets.ParamGL, 'numeric');
                maxEditField.Layout.Row = index+1;
                maxEditField.Layout.Column = 5;
                maxEditField.Value = maxValue;
                maxEditField.Tag = string(index);
                maxEditField.ValueChangedFcn = @(src, event)updateEditFieldMax(this, ... 
                                                src);

                if isinf(value)
                    minEditField.Enable = false;
                    valueSlider.Enable = false;
                    maxEditField.Enable = false;
                end                
            else
                minEditField = [];
                maxEditField = [];
                valueSlider = [];
            end
            
            
            
            widgets = [nameEditField; valueEditField; minEditField; 
                valueSlider; maxEditField];
        end

        function buttonPanel = createButtonPanel(this, row, col)
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.Widgets.GridLayout, ["help" "cancel"], 'Commit', 3);
        end
    end

    methods (Access = private)
        
        function updateCompListDropdown(this, src, evt)

            if ~isempty(src)
                selectedComp = evt.Value;
            else
                selectedComp = get(this, 'SelectedCompensator');
            end

            [bIsMember, uintIndex] = ismember(selectedComp, ...
                                               this.Widgets.CompListDropdown.Items);
            
            if bIsMember
                index = uintIndex;
            else
                index = 1;
            end
            

%             % assign index, compensator
            set(this, 'CompensatorIndex', index);
            this.SelectedCompensator = get(this, 'SelectedCompensator');
            this.Ts = getTs(this.SelectedCompensator);

            updateUI(this);
        end

        function updateGain(this, src, evt)
            % update the gaiin to the compensator
            EventMgr = this.Parent.getEventManager;
            editString = getString(message(['Control:compDesignTask:' ...
                'strEditGain']));
            T = controllib.app.managers.eventmanager.internal. ...
                        FunctionTransaction(editString);

            try
                
                S = saveSession(this.SelectedCompensator);
                T.UndoFcn = {@loadSession this.SelectedCompensator S};

                index = this.CompensatorIndex;
                this.AllCompList(index).setFormattedGain(evt.Value);

                % update table view
                notifyValueChanged(this.SelectedCompensator);
                % Set redo function
                S = saveSession(this.SelectedCompensator);
                T.RedoFcn = {@loadSession this.SelectedCompensator S};

                EventMgr.record(T);
                % Notify status and history listeners
                EventMgr.postActionStatus('off', editString);
                EventMgr.add2Hist(editString);

            catch ME
                src.Value = evt.PreviousValue;
                title = getString(message( ...
                    'Control:compDesignTask:strCompensatorEditor'));
                uialert(this.UIFigure, ME.message, title);
                return
            end
            updateUI(this);
        end

        function addPoleZero(this, src, evt)
            % this method helps in adding poles and zeros to the compensator
            % and updates the event manager, plots.
            type = evt.Source.Text;
            

            % see datatable created in `createPZTable`
            pzAction = this.PZTable.Properties.RowNames;

            % intialize to be empty
            dPole = [];
            dZero = [];
            switch type
                case pzAction{1}
                    sType = this.PZTable.Type{1};
                    dPole = this.PZTable.Poles{1};
                case pzAction{2}
                    sType = this.PZTable.Type{2};
                    dPole = this.PZTable.Poles{2};
                case pzAction{3}
                    sType = this.PZTable.Type{3};
                    dPole = this.PZTable.Poles{3};
                case pzAction{4}
                    sType = this.PZTable.Type{4};
                    dZero = this.PZTable.Zeros{4};
                case pzAction{5}
                    sType = this.PZTable.Type{5};
                    dZero = this.PZTable.Zeros{5};
                case pzAction{6}
                    sType = this.PZTable.Type{6};
                    dZero = this.PZTable.Zeros{6};
                case pzAction{7}
                    sType = this.PZTable.Type{7};
                    dPole = this.PZTable.Poles{7};
                    dZero = this.PZTable.Zeros{7};
                case pzAction{8}
                    sType = this.PZTable.Type{8};
                    dPole = this.PZTable.Poles{8};
                    dZero = this.PZTable.Zeros{8};
                case pzAction{9}
                    sType = this.PZTable.Type{9};
                    dPole = this.PZTable.Poles{9};
                    dZero = this.PZTable.Zeros{9};
            end
            
            % If discrete (Ts~=0) convert to discrete values
            if this.Ts
                if ~isempty(dZero)
                    dZero = exp(dZero*this.Ts);
                end
                if ~isempty(dPole)
                    dPole = exp(dPole*this.Ts);
                end
            end

            % Add the PZGroup to the end of the PZGroup list associated with compensator (idxC)
            % successful action on the SISOTOOL side will be recorded
            EventMgr = this.Parent.getEventManager;
            T = controllib.app.managers.eventmanager.internal. ...
                        FunctionTransaction('Add Pole/Zero');

            try
                
                S = saveSession(this.SelectedCompensator);
                T.UndoFcn = {@loadSession this.SelectedCompensator S};

                addPZ(this.SelectedCompensator, sType, dZero, dPole);

                % update table view
                updateUI(this);
                % Set redo function
                S = saveSession(this.SelectedCompensator);
                T.RedoFcn = {@loadSession this.SelectedCompensator S};

                EventMgr.record(T);
                % Notify status and history listeners
                EventMgr.postActionStatus('off',sprintf('Added %s to %s', ...
                    sType, this.SelectedCompensator.Name));

            catch ME
                title = getString(message( ...
                    'Control:compDesignTask:strCompensatorEditor'));
                uialert(this.UIFigure, ME.message, title);
                return
            end

            % need to add to export?
        end

        function deletePoleZero(this, src, evt)
            % this method helps in deleting poles and zeros to the compensator
            % and updates the event manager, plots.
            type = evt.Source.Text;

            % find the index of the table selection
            idxSelected = this.Widgets.PZTable.Selection;

            % get pole-zero group of the current comp
            PZGroup = this.SelectedCompensator.PZGroup;            
            
            % Delete the PZGroup to the end of the PZGroup list 
            % associated with compensator (idxC)
            % successful action on the Container side will be recorded
            EventMgr = this.Parent.getEventManager;
            T = controllib.app.managers.eventmanager.internal. ...
                        FunctionTransaction('Delete');

            try
                
                S = saveSession(this.SelectedCompensator);
                T.UndoFcn = {@loadSession this.SelectedCompensator S};

                deletePZ(this.SelectedCompensator, PZGroup(idxSelected));

                % update table view
                updateUI(this);
                % Set redo function
                S = saveSession(this.SelectedCompensator);
                T.RedoFcn = {@loadSession this.SelectedCompensator S};

                EventMgr.record(T);
                % Notify status and history listeners
                EventMgr.postActionStatus('off',sprintf(['Deleted Pole/Zero' ...
                    ' from %s'], ...
                    type, this.SelectedCompensator.Name));

            catch ME
                title = getString(message( ...
                    'Control:compDesignTask:strCompensatorEditor'));
                uialert(this.UIFigure, ME.message, title);
                return
            end
        end
        
        function createPZDataTable(this)
            % this method creates a data dictionary that resembles
            % the following structure
            %
            %                       
            %                      Type           Poles           Zeros    
            %                   ___________    ____________    ____________
            % 
            % Real Pole         {'Real'   }    {[      -1]}    {[       0]}
            % Complex Pole      {'Complex'}    {2×1 double}    {[       0]}
            % Integrator        {'Real'   }    {[       0]}    {[       0]}
            % Real Zero         {'Real'   }    {[       0]}    {[      -1]}
            % Complex Zero      {'Complex'}    {[       0]}    {2×1 double}
            % Differentiator    {'Real'   }    {[       0]}    {[       0]}
            % Lead              {'LeadLag'}    {[     -10]}    {[      -1]}
            % Lag               {'LeadLag'}    {[      -1]}    {[     -10]}
            % Notch             {'Notch'  }    {2×1 double}    {2×1 double}


            Action = {
            getString(message('Control:compDesignTask:strRealPole'));
            getString(message('Control:compDesignTask:strComplexPole'));
            getString(message('Control:compDesignTask:strIntegrator'));
            getString(message('Control:compDesignTask:strRealZero'));
            getString(message('Control:compDesignTask:strComplexZero'));
            getString(message('Control:compDesignTask:strDifferentiator'));
            getString(message('Control:compDesignTask:strLead'));
            getString(message('Control:compDesignTask:strLag'));
            getString(message('Control:compDesignTask:strNotch'));
                };
                
            Type = {'Real'; 'Complex'; 'Real'; 'Real'; 'Complex'; 
                'Real'; 'LeadLag'; 'LeadLag'; 'Notch' };
            
            Poles = {-1; [-1+1i; -1-1i]; 0; 0; 0; 0; -10; -1; 
                [-1+0i; -1-0i]};
            Zeros = {0; 0; 0; -1; [-1+1i; -1-1i]; 0; -1; -10; 
                [-.1+.995i; -.1-.995i]};
            
            this.PZTable = table(Type, Poles, Zeros, 'RowNames', Action);
        end
    
        function rowdata = updatePZData(this, Group)
            
            FreqUnits = this.FrequencyUnits;
            if ~isempty(Group)
              switch Group.Type
                  case 'Real'
                    % Real pole/zero
                    if isempty(Group.Pole)
                        Location = Group.Zero;
                        if (~this.Ts && Location ~= 0) || ( this.Ts && Location ~= 1)
                            ID = getString(message( ...
                                'Control:compDesignTask:strRealZero'));
                        else
                            ID = getString(message( ...
                                'Control:compDesignTask:strDifferentiator'));
                        end
                    else
                        Location = Group.Pole;
                        if (~this.Ts && Location ~= 0) || ( this.Ts && Location ~= 1)
                            ID = getString(message( ...
                                'Control:compDesignTask:strRealPole'));
                        else
                            ID = getString(message( ...
                                'Control:compDesignTask:strIntegrator'));
                        end
                    end
                   
                    [Wn, Z] = damp(Location,this.Ts);
                    Z(Z==0) = 0; %Prevent sprintf form printing -0 for non-pc
    
                    rowdata = { ID, sprintf('%.3g', Location), sprintf('%.3g',Z) , ...
                        sprintf('%.3g',Wn*funitconv('rad/s',FreqUnits)) };
        
        
                    case 'Complex'
                        % Complex pole/zero
                        if isempty(Group.Pole)
                            ID = getString(message( ...
                                'Control:compDesignTask:strComplexZero'));
                            Location = Group.Zero(1);
                        else
                            ID = getString(message( ...
                                'Control:compDesignTask:strComplexPole'));
                            Location = Group.Pole(1);
                        end
                        [Wn, Z] = damp(Location, this.Ts);
                        Z(Z==0) = 0; %Prevent sprintf form printing -0 for non-pc
                        rowdata = { ID, sprintf('%.3g +/- %.3gi', ...
                            real(Location),abs(imag(Location))), ...
                            sprintf('%.3g',Z), ...
                            sprintf('%.3g',Wn*funitconv('rad/s',FreqUnits)) };
        
        
                    case 'LeadLag'
                        % Lead or lag network (s+tau1)/(s+tau2)
                        if (this.Ts == 0 && Group.Pole < Group.Zero) || ...
                            (this.Ts ~= 0 && abs(Group.Pole) < abs(Group.Zero))
                            ID = getString(message('Control:compDesignTask:strLead'));
                        else
                            ID = getString(message('Control:compDesignTask:strLag'));
                        end
        
                        Location = [Group.Zero, Group.Pole];
                        rowdata = { ID, sprintf('%.3g, %.3g', Location), ...
                            '1', sprintf('%.3g, %.3g', ...
                            abs(Location)*funitconv('rad/s',FreqUnits)) };
        
        
                    case 'Notch'
                        % Notch filter.
                        ID = getString(message('Control:compDesignTask:strNotch'));
                        LocationZ = Group.Zero(1);
                        [~, Zz] = damp(LocationZ, this.Ts);
                        Zz(Zz==0) = 0; %Prevent sprintf form printing -0 for non-pc
                        LocationP = Group.Pole(1);
                        [Wn, Zp] = damp(LocationP, this.Ts);
                        Zp(Zp==0) = 0; %Prevent sprintf form printing -0 for non-pc
        
                        rowdata = { ID, sprintf('%.3g +/- %.3gi, %.3g +/- %.3gi', ...
                            real(LocationZ), abs(imag(LocationZ)),...
                            real(LocationP), abs(imag(LocationP))), ...
                            sprintf('%.3g, %.3g',Zz, Zp), ...
                            sprintf('%.3g', Wn*funitconv('rad/s',FreqUnits)) };
              end
            else
                rowdata=[];
            end
        end

        function updateEditPanel(this)

            % fetch action types from data table
            pzAction = this.PZTable.Properties.RowNames;
            
            % find the index of the table selection
            idxSelected = this.Widgets.PZTable.Selection;

            % get pole-zero group of the current comp
            PZGroup = this.SelectedCompensator.PZGroup;

            % tuen off visibility on Edit Panel components
            turnOffEditWidgets(this);

            % if there's selection on the table, update the panel
            if ~isempty(idxSelected)

                % enable delete PZ submenu
                this.Widgets.DeletePZMenu.Enable = 'on';
                % find the type of the POle-Zero Group
                type = this.Widgets.PZTable.Data{idxSelected,1};  
    
                % update the location values using poles/zeros
                if isempty(PZGroup(idxSelected).Pole)
                    location = PZGroup(idxSelected).Zero;
                else
                    location = PZGroup(idxSelected).Pole;
                end

                switch type
                    case {pzAction{1}, pzAction{3}, pzAction{4}, pzAction{6}}
                        % only 1 set of label, EditField for 
                        % Real Pole, Real Zero, Integrator, Differentiator
                        
                        labelText = getString(message( ...
                                'Control:compDesignTask:strLocation')); 
                        this.Widgets.Label1.Text = labelText;
                        this.Widgets.Label1.Visible = 'on';
                        this.Widgets.EditField1.Visible = 'on';
                        this.Widgets.EditField1.Value = location;
                        this.Widgets.EditField1.Tag = labelText;

                    case {pzAction{2}, pzAction{5}}
                        % 4 set of label, EditField for 
                        % Complex Pole, Complex Zero
                        labelText1 = getString(message( ...
                            'Control:compDesignTask:strNaturalFrequency'));
                        labelText2 = getString(message( ...
                            'Control:compDesignTask:strDamping'));
                        labelText3 = getString(message( ...
                            'Control:compDesignTask:strRealPart'));
                        labelText4 = getString(message( ...
                            'Control:compDesignTask:strImaginaryPart'));

                        [Wn, Z] = damp(location(1), this.Ts);
                        this.Widgets.Label1.Text = labelText1; 
                        this.Widgets.Label1.Visible = 'on';
                        this.Widgets.EditField1.Visible = 'on';
                        this.Widgets.EditField1.Value = (Wn* ...
                                funitconv('rad/s', this.FrequencyUnits));
                        this.Widgets.EditField1.Tag = labelText1;
                        
                        this.Widgets.Label2.Text = labelText2; 
                        this.Widgets.Label2.Visible = 'on';
                        this.Widgets.EditField2.Visible = 'on';
                        this.Widgets.EditField2.Value = Z;
                        this.Widgets.EditField2.Tag = labelText2;
                        
                        this.Widgets.Label3.Text = labelText3; 
                        this.Widgets.Label3.Visible = 'on';
                        this.Widgets.EditField3.Visible = 'on';
                        this.Widgets.EditField3.Value = real(location(1));
                        this.Widgets.EditField3.Tag = labelText3;
    
                        this.Widgets.Label4.Text = labelText4; 
                        this.Widgets.Label4.Visible = 'on';
                        this.Widgets.EditField4.Visible = 'on';
                        this.Widgets.EditField4.Value = imag(location(1));
                        this.Widgets.EditField4.Tag = labelText4;
    
                    case {pzAction{7}, pzAction{8}}
    
                        % 4 set of label, EditField for Lead, Lag
                        ZLocation = PZGroup(idxSelected).Zero;
                        PLocation = PZGroup(idxSelected).Pole;
    
                        if (this.Ts ~=0)
                            % discrete case
                            ZLocation = log(ZLocation)/this.Ts;
                            PLocation = log(PLocation)/this.Ts;
                        end
    
                        labelText1 = getString(message( ...
                            'Control:compDesignTask:strRealZero'));
                        labelText2 = getString(message( ...
                            'Control:compDesignTask:strRealPole'));
                        labelText3 = getString(message( ...
                            'Control:compDesignTask:lblMaxDeltaPhase'));
                        labelText4 = getString(message( ...
                            'Control:compDesignTask:lblAtFrequency'));

                        % Calculate the maximum phase addition from lead/lag and freq
                        % at which it occurs
                        alpha = ZLocation/PLocation;
                        phasemax = asin((1-alpha)/(1+alpha))/pi*180;
                        wmax = -ZLocation/sqrt(alpha);
    
                        % UI update
                        this.Widgets.Label1.Text = labelText1; 
                        this.Widgets.Label1.Visible = 'on';
                        this.Widgets.EditField1.Visible = 'on';
                        this.Widgets.EditField1.Value = ZLocation;
                        this.Widgets.EditField1.Tag = labelText1;
                        
                        this.Widgets.Label2.Text = labelText2; 
                        this.Widgets.Label2.Visible = 'on';
                        this.Widgets.EditField2.Visible = 'on';
                        this.Widgets.EditField2.Value = PLocation;
                        this.Widgets.EditField2.Tag = labelText2;
                        
                        this.Widgets.Label3.Text = labelText3; 
                        this.Widgets.Label3.Visible = 'on';
                        this.Widgets.EditField3.Visible = 'on';
                        this.Widgets.EditField3.Value = phasemax;
                        this.Widgets.EditField3.Tag = labelText3;
    
                        this.Widgets.Label4.Text = labelText4; 
                        this.Widgets.Label4.Visible = 'on';
                        this.Widgets.EditField4.Visible = 'on';
                        this.Widgets.EditField4.Value = wmax*funitconv('rad/s', ...
                                    this.FrequencyUnits);
                        this.Widgets.EditField4.Tag = labelText4;
                        
                    case pzAction{9}
                        % 5 set of label, EditField for Notch
                        labelText1 = getString(message( ...
                            'Control:compDesignTask:strNaturalFrequency'));
                        labelText2 = getString(message( ...
                            'Control:compDesignTask:strDampingZero'));
                        labelText3 = getString(message( ...
                            'Control:compDesignTask:strDampingPole'));
                        labelText4 = getString(message( ...
                            'Control:compDesignTask:strNotchDepthdB'));
                        labelText5 = getString(message( ...
                            'Control:compDesignTask:strNotchWidthLog'));

                        Zz = PZGroup(idxSelected).ZetaZero;
                        Zp = PZGroup(idxSelected).ZetaPole;
                        Wn = PZGroup(idxSelected).Wn;
                        ndepth = PZGroup(idxSelected).Depth;
                        nwidth = PZGroup(idxSelected).Width;
    
                        % UI update
                        this.Widgets.Label1.Text = labelText1; 
                        this.Widgets.Label1.Visible = 'on';
                        this.Widgets.EditField1.Visible = 'on';
                        this.Widgets.EditField1.Value = (Wn* ...
                                funitconv('rad/s', this.FrequencyUnits));
                        this.Widgets.EditField1.Tag = labelText1;
                        
                        this.Widgets.Label2.Text = labelText2; 
                        this.Widgets.Label2.Visible = 'on';
                        this.Widgets.EditField2.Visible = 'on';
                        this.Widgets.EditField2.Value = Zz;
                        this.Widgets.EditField2.Tag = labelText2;
                        
                        this.Widgets.Label3.Text = labelText3; 
                        this.Widgets.Label3.Visible = 'on';
                        this.Widgets.EditField3.Visible = 'on';
                        this.Widgets.EditField3.Value = Zp;
                        this.Widgets.EditField3.Tag = labelText3;
    
                        this.Widgets.Label4.Text =labelText4; 
                        this.Widgets.Label4.Visible = 'on';
                        this.Widgets.EditField4.Visible = 'on';
                        this.Widgets.EditField4.Value = 20*log10(ndepth);
                        this.Widgets.EditField4.Tag = labelText4;
    
                        this.Widgets.Label5.Text = labelText5; 
                        this.Widgets.Label5.Visible = 'on';
                        this.Widgets.EditField5.Visible = 'on';
                        this.Widgets.EditField5.Value = nwidth;
                        this.Widgets.EditField5.Tag = labelText5;
                    otherwise
                        this.Widgets.EditInfoLabel.Visible = 'on';
                        
                end
            else
                this.Widgets.EditInfoLabel.Visible = 'on';
                % enable delete PZ submenu
                this.Widgets.DeletePZMenu.Enable = 'off';
            end
        end

        function updatePZEditFields(this, src, event)
            % fetch action types from data table
            pzAction = this.PZTable.Properties.RowNames;
            
            % find the index of the table selection
            idxSelected = this.Widgets.PZTable.Selection;
            
            % get pole-zero group of the current comp - current selection
            PZGroup = this.SelectedCompensator.PZGroup;
            
            % get values from the event
            value = event.Value;
            previousValue = event.PreviousValue;
            tag = src.Tag;
            
            % update desc and status
            [desc, status] = updatePZStatusBar(this, idxSelected, pzAction, PZGroup, ...
                    value, previousValue, tag);
            
            EventMgr = this.Parent.getEventManager;
            T = controllib.app.managers.eventmanager.internal. ...
                    FunctionTransaction(desc);
            
            try
                % Set undo function
                S = saveSession(this.SelectedCompensator);
                T.UndoFcn = {@loadSession this.SelectedCompensator S};
            
                % update PZ Group and UI to reflect changes
                updateSelectedPZGroupValues(this, idxSelected, pzAction, PZGroup, ...
                    value, previousValue, tag);
                notifyValueChanged(this.SelectedCompensator);
            %                 updateUI(this);
            
                % Set redo function
                S = saveSession(this.SelectedCompensator);
                T.RedoFcn = {@loadSession this.SelectedCompensator S};
                
                EventMgr.record(T);
                % Notify status and history listeners
                EventMgr.postActionStatus('off', status);
            
            catch ME
                title = getString(message( ...
                    'Control:compDesignTask:strCompensatorEditor'));
                uialert(this.UIFigure, ME.message, title);
                return
            end
        end

        function updatePZEditFields2(this, src, event)
            % fetch action types from data table
            pzAction = this.PZTable.Properties.RowNames;
            
            % find the index of the table selection
            idxSelected = this.Widgets.PZTable.Selection;

            % get pole-zero group of the current comp - current selection
            PZGroup = this.SelectedCompensator.PZGroup;

            % get values from the event
            value = event.Value;
            previousValue = event.PreviousValue;
            tag = src.Tag;

            messageLL = "pole and zero are stable minimum phase";
            if ~isempty(idxSelected)
                % find the type of the Pole-Zero Group
                type = this.Widgets.PZTable.Data{idxSelected,1};  
                switch type
                    case {pzAction{1}, pzAction{3}, pzAction{4}, pzAction{6}}
                        % this.Widgets.EditField1.Tag = ....
                        % Real Pole, Real Zero, Integrator, Differentiator
                        % Real pole/zero
                        
                        if isempty(PZGroup(idxSelected).Pole)
                            % real zero or integrator
                            PZGroup(idxSelected).Zero = value;
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditZero'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedZero'));
                        else
                            % real pole or integrator
                            PZGroup(idxSelected).Pole = value;
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditPole'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedPole'));
                        end

                    case {pzAction{2}, pzAction{5}}
                        % 4 set of label, EditField for 
                        % Complex Pole, Complex Zero
                        labelText1 = getString(message( ...
                            'Control:compDesignTask:strNaturalFrequency'));
                        labelText2 = getString(message( ...
                            'Control:compDesignTask:strDamping'));
                        labelText3 = getString(message( ...
                            'Control:compDesignTask:strRealPart'));
                        labelText4 = getString(message( ...
                            'Control:compDesignTask:strImaginaryPart'));
                        switch tag
                            case labelText1
                                % change in Natural frequency EditField
                                Wn = value * funitconv(this.FrequencyUnits, ...
                                    'rad/s');
                                Z = this.Widgets.EditField2.Value;
                                

                                location = -Z*Wn + Wn*sqrt(Z^2-1);
                                pzLocation = [location; conj(location)];

                                if this.Ts ~= 0
                                    pzLocation = exp(pzLocation*this.Ts);
                                end

                            case labelText2
                                % change in Damping EditField
                                Wn = this.Widgets.EditField2.Value;
                                Z = value;
                                

                                if abs(Z) > 1
                                    Z = sign(Z);
                                end

                                location = -Z*Wn + Wn*sqrt(Z^2-1);
                                pzLocation = [location; conj(location)];

                                if this.Ts ~= 0
                                    pzLocation = exp(pzLocation*this.Ts);
                                end

                            case labelText3
                                % change in real part of pole
                                realLocation = value;
                                imagLocation = this.Widgets.EditField4.Value;

                                pzLocation = [realLocation + 1i * imagLocation;
                                              realLocation - 1i * imagLocation];
                            case labelText4
                                % change in imag part of pole
                                realLocation = this.Widgets.EditField3.Value;
                                imagLocation = value;

                                pzLocation = [realLocation + 1i * imagLocation;
                                              realLocation - 1i * imagLocation];
                        end

                        % update desc and msg for status bar
                        if isempty(PZGroup(idxSelected).Pole)
                            % complex zero 
                            PZGroup(idxSelected).Zero = pzLocation;
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditComplexZero'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedComplexZero'));
                        else
                            % complex pole
                            PZGroup(idxSelected).Pole = pzLocation;
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditComplexPole'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedComplexPole'));
                        end
                        
                        % update EditField ui to reflect changes 
                        [Wn, Z] = damp(pzLocation(1), this.Ts);
                                
                        this.Widgets.EditField1.Value = Wn;
                        this.Widgets.EditField2.Value = Z;
                        this.Widgets.EditField3.Value = real(pzLocation(1));
                        this.Widgets.EditField4.Value = imag(pzLocation(1));

                    case {pzAction{7}, pzAction{8}}
    
                        % EditField for Lead, Lag
                        labelText1 = getString(message( ...
                            'Control:compDesignTask:strRealZero'));
                        labelText2 = getString(message( ...
                            'Control:compDesignTask:strRealPole'));
                        labelText3 = getString(message( ...
                            'Control:compDesignTask:lblMaxDeltaPhase'));
                        labelText4 = getString(message( ...
                            'Control:compDesignTask:lblAtFrequency'));

                        switch tag
                            case labelText1
                                ZL = value;
                                PL = this.Widgets.EditField2.Value;
                                resetZeroValue = previousValue;
                                phaseMRad = this.Widgets.EditField3.Value;
                                Wm = this.Widgets.EditField4.Value;

                                % Continuous condition that 
                                % pole and zero are stable minimum phase
                                condition1 = (this.Ts == 0)  && ...
                                    (ZL <= 0 ) && (PL <= 0);
                                % Discrete condition that 
                                % pole and zero are stable minimum phase
                                condition2 = (this.Ts ~= 0) && ...
                                    (abs(ZL) <= 1)  && ...
                                    (abs(PL) <= 1);
                                if condition1 || condition2
                                    zeroLocation = ZL;
                                    poleLocation = PL;
                                else
                                    zeroLocation = resetZeroValue;
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageLL, title);
                                end
                            case labelText2 
                                PL = value;
                                ZL = this.Widgets.EditField1.Value;
                                resetPoleValue = previousValue;
                                phaseMRad = this.Widgets.EditField3.Value;
                                Wm = this.Widgets.EditField4.Value;

                                % Continuous condition that 
                                % pole and zero are stable minimum phase
                                condition1 = (this.Ts == 0)  && ...
                                    (ZL <= 0 ) && (PL <= 0);
                                % Discrete condition that 
                                % pole and zero are stable minimum phase
                                condition2 = (this.Ts ~= 0) && ...
                                    (abs(ZL) <= 1)  && ...
                                    (abs(PL) <= 1);
                                if condition1 || condition2
                                    zeroLocation = ZL;
                                    poleLocation = PL;
                                else
                                    zeroLocation = resetPoleValue;
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageLL, title);
                                end
                            case labelText3
                                % phase change
                                phaseMRad = value*pi/180;
                                % max phasevalue phasemdeg < 90 for computation
                                maxPhaseValue = asin(1-eps); 
                                if (abs(phaseMRad) > maxPhaseValue)
                                    phaseMRad = sign(phaseMRad)*maxPhaseValue;
                                end
                                
                                Wm = this.Widgets.EditField4.Value;
                                % make sure Wm is in rad/s
                                Wm = Wm*funitconv(this.FrequencyUnits, ...
                                    'rad/s');

                                if (abs(phaseMRad) > maxPhaseValue)
                                    zeroLocation = NaN;
                                    poleLocation = NaN;
                                else
                                    % Zero = alpha * Pole
                                    alpha = (1-sin(phaseMRad))/ ...
                                            (1+sin(phaseMRad));
                                    
                                    zeroLocation = -Wm*sqrt(alpha);
                                    poleLocation = zeroLocation/alpha;
                                    
                                    if (this.Ts ~= 0)
                                        zeroLocation = exp(zeroLocation* ...
                                            this.Ts);
                                        poleLocation = exp(poleLocation* ...
                                            this.Ts);
                                    end
                                end

                            case labelText4
                                Wm = value*funitconv(this.FrequencyUnits, ...
                                    'rad/s');
                                phaseMRad = this.Widgets.EditField3.Value*pi/180;
                                % max phasevalue phasemdeg < 90 for computation
                                maxPhaseValue = asin(1-eps); 
                                if (abs(phaseMRad) > maxPhaseValue)
                                    phaseMRad = sign(phaseMRad)*maxPhaseValue;
                                end

                                if (abs(phaseMRad) > maxPhaseValue)
                                    zeroLocation = NaN;
                                    poleLocation = NaN;
                                else
                                    % Zero = alpha * Pole
                                    alpha = (1-sin(phaseMRad))/ ...
                                            (1+sin(phaseMRad));
                                    
                                    zeroLocation = -Wm*sqrt(alpha);
                                    poleLocation = zeroLocation/alpha;
                                    
                                    if (this.Ts ~= 0)
                                        zeroLocation = exp(zeroLocation* ...
                                            this.Ts);
                                        poleLocation = exp(poleLocation* ...
                                            this.Ts);
                                    end
                                end
                        end
                        
                        % update PZGroup
                        PZGroup(idxSelected).Zero = zeroLocation;
                        PZGroup(idxSelected).Pole = poleLocation;
                        
                        % UI update
                        this.Widgets.EditField1.Value = PZGroup(idxSelected).Zero;
                        this.Widgets.EditField2.Value = PZGroup(idxSelected).Pole;
                        this.Widgets.EditField3.Value = phaseMRad;
                        this.Widgets.EditField4.Value = Wm;
                        
                        % update desc and msg for status bar
                        if zeroLocation > poleLocation
                            % Lead & Lag 
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditLead'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedLead'));
                        else
                            % Lead & Lag
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditLag'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedLag'));
                        end
                        
                    case pzAction{9}
                        % 5 set of label, EditField for Notch
                        labelText1 = getString(message( ...
                            'Control:compDesignTask:strNaturalFrequency'));
                        labelText2 = getString(message( ...
                            'Control:compDesignTask:strDampingZero'));
                        labelText3 = getString(message( ...
                            'Control:compDesignTask:strDampingPole'));
                        labelText4 = getString(message( ...
                            'Control:compDesignTask:strNotchDepthdB'));
                        labelText5 = getString(message( ...
                            'Control:compDesignTask:strNotchWidthLog'));
                        switch tag
                            case labelText1
                                if value >= 10*eps/log(10)
                                    Wn = value*funitconv(this.FrequencyUnits, ...
                                         'rad/s');
                                    ZetaP = this.Widgets.EditField3.Value;
                                    ZetaZ = this.Widgets.EditField2.Value;
                                    [desc, status] = ...
                                            evaluateNotch(this, Wn, ZetaZ, ZetaP);
                                else
                                    this.Widgets.EditField1.Value = previousValue;
                                    messageWn = 'Value is < 10*eps/log(10)';
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageWn, title);
                                end

                            case labelText2
                                ZetaP = this.Widgets.EditField3.Value;
                                ZetaZ = value;
                                Wn = this.Widgets.EditField1.Value;
                                Wn = Wn*funitconv(this.FrequencyUnits, ...
                                    'rad/s');
                                if ZetaP > ZetaZ
                                   [desc, status] = ...
                                            evaluateNotch(this, Wn, ZetaZ, ZetaP);
                                else
                                    this.Widgets.EditField2.Value = previousValue;
                                    messageWn = 'Zero should be greater than Pole';
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageWn, title);
                                end
                            case labelText3
                                ZetaP = value;
                                ZetaZ = this.Widgets.EditField2.Value;
                                Wn = this.Widgets.EditField1.Value;
                                Wn = Wn*funitconv(this.FrequencyUnits, ...
                                    'rad/s');
                                if ZetaP > ZetaZ
                                   [desc, status] = ...
                                            evaluateNotch(this, Wn, ZetaZ, ZetaP);
                                else
                                    this.Widgets.EditField3.Value = previousValue;
                                    messageWn = 'Zero should be greater than Pole';
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageWn, title);
                                end
                            case labelText4
                                depth = value;
                                width = this.Widgets.EditField5.Value;
                                Wn = this.Widgets.EditField1.Value;
                                Wn = Wn*funitconv(this.FrequencyUnits, ...
                                    'rad/s');
                                if isreal(depth) && (depth <= 0)
                                    depth = 10^(depth/20);
                                    
                                    [desc, status] = evaluateNotch2(this, ...
                                                        depth, width, Wn);
                                else
                                    this.Widgets.EditField4.Value = previousValue;
                                    messageWn = 'Enter a valid number';
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageWn, title);
                                end
                            case labelText5
                                width = value;
                                depth = this.Widgets.EditField4.Value;
                                Wn = this.Widgets.EditField1.Value;
                                Wn = Wn*funitconv(this.FrequencyUnits, ...
                                    'rad/s');
                                if (width > 0) || isnan(width)
                                    depth = 10^(depth/20);
                                    
                                    [desc, status] = evaluateNotch2(this, ...
                                                        depth, width, Wn);
                                else
                                    this.Widgets.EditField5.Value = previousValue;
                                    messageWn = 'Enter a valid number';
                                    title = getString(message( ...
                                        'Control:compDesignTask:strCompensatorEditor'));
                                    uialert(this.UIFigure, messageWn, title);
                                end
                        end
                    otherwise
                        this.Widgets.EditInfoLabel.Visible = 'on';
                        
                end

                % update UI and event manager
                updatePZGroupValues(this, status, desc)
            else
                return
            end
        end

        function turnOffEditWidgets(this)
            [row, col] = size(this.Widgets.EditGL.Children);

            for i = 1:row
                this.Widgets.EditGL.Children(i).Visible = 'off';
            end
        end
        
        % parameter tab updates
        function updateEditFieldSlider(this, src, event)
            index = str2double(src.Tag);
            selectedWidgets = this.Widgets.ParamEF{index};
            type = src.Type;
            % ensure previous value is valid
            if isscalar(event.PreviousValue)
                resetValue = event.PreviousValue;
            else
                resetValue = eval(event.PreviousValue);
            end
            
            

            if length(selectedWidgets) > 2 
                switch type
                    case 'uislider' 
                        % update EditField
                        value = src.Value;
                        selectedWidgets(2).Value = mat2str(value);
%                         value = eval(value);
                    case 'uieditfield' 
                    % update slider value
                        slider = selectedWidgets(4);
                        minField = selectedWidgets(3);
                        maxField = selectedWidgets(5);

                        try 
                            value = eval(src.Value);
                        catch ME
                            src.Value = resetValue;
                            title = getString(message( ...
                                'Control:compDesignTask:strCompensatorEditor'));
                            uialert(this.UIFigure, ME.message, title);
                            return
                        end

                        if ~isreal(value)
                            src.Value = mat2str(resetValue);
                            return;
                        elseif (value >= slider.Limits(2)) || (value <= slider.Limits(1))
                            if value > 0
                                maxValue = 10^(ceil(log10(value)));
                                minValue = maxValue/10;
                            elseif value < 0
                                minValue = -10^(ceil(log10(abs(value))));
                                maxValue = minValue/10;
                            else
                                minValue = -1;
                                maxValue = 1;
                            end
                            slider.Limits = [minValue, maxValue];
                            minField.Value = minValue;
                            maxField.Value = maxValue;
                            slider.Value = value;
                        else
                            slider.Value = value;
                        end
                end
            else
                selectedWidgets(2).Value = src.Value;
                value = eval(src.Value);
            end
            
            
            updateCompensatorParams(this, index, value);
        end

        function updateEditFieldMin(this, src)

            index = str2double(src.Tag);
            selectedWidgets = this.Widgets.ParamEF{index};
            slider = selectedWidgets(4);
            efMin = selectedWidgets(3);
            efValue = selectedWidgets(2);
            resetValue = slider.Limits(1);
            value = src.Value;

            
            if value > eval(efValue.Value)
                efMin.Value = resetValue;
            else
                efMin.Value = value;
                slider.Limits(1) = value;
            end
        end

        function updateEditFieldMax(this, src)

            index = str2double(src.Tag);
            selectedWidgets = this.Widgets.ParamEF{index};
            slider = selectedWidgets(4);
            efMax = selectedWidgets(5);
            efValue = selectedWidgets(2);
            
            value = src.Value;

            resetValue = slider.Limits(2);
            if value < eval(efValue.Value)
                efMax.Value = resetValue;
            else
                efMax.Value = value;
                slider.Limits(2) = value;
            end
            
        end

        function updateCompensatorParams(this, index, value)
            try
                EventMgr = this.Parent.getEventManager;
                T = controllib.app.managers.eventmanager.internal. ...
                    FunctionTransaction(getString(message( ...
                    'Control:compDesignTask:strEditParameterValue')));
                
                % Set undo function
                S = saveSession(this.SelectedCompensator);
                T.UndoFcn = {@loadSession this.SelectedCompensator S};
            
                setParameterValue(this.SelectedCompensator, index, ...
                                    value);
                % update UI to reflect changes
                updateUI(this);
                notifyValueChanged(this.SelectedCompensator);

                % Set redo function
                S = saveSession(this.SelectedCompensator);
                T.RedoFcn = {@loadSession this.SelectedCompensator S};
                
                EventMgr.record(T);
                % Notify status and history listeners
                Status = getString(message(['Control:compDesignTask:' ...
                    'msgModifiedCompensatorParameter']));
                EventMgr.postActionStatus('off',Status);
            catch ME
                title = getString(message( ...
                    'Control:compDesignTask:strCompensatorEditor'));
                uialert(this.UIFigure, ME.message, title);
                return
            end
        end
        
        function updatePZGroupValues(this, status, desc)

            EventMgr = this.Parent.getEventManager;
            T = controllib.app.managers.eventmanager.internal. ...
                    FunctionTransaction(desc);
            try
                % Set undo function
                S = saveSession(this.SelectedCompensator);
                T.UndoFcn = {@loadSession this.SelectedCompensator S};
            
                % update UI to reflect changes
                
                notifyValueChanged(this.SelectedCompensator);
%                 updateUI(this);
                % Set redo function
                S = saveSession(this.SelectedCompensator);
                T.RedoFcn = {@loadSession this.SelectedCompensator S};
                
                EventMgr.record(T);
                % Notify status and history listeners
                Status = status;
                EventMgr.postActionStatus('off',Status);
            catch ME
                title = getString(message( ...
                    'Control:compDesignTask:strCompensatorEditor'));
                uialert(this.UIFigure, ME.message, title);
                return
            end
        end

        function [desc, status] = updatePZStatusBar(this, idxSelected, ...
                             pzAction, PZGroup, value, previousValue, tag)
             if ~isempty(idxSelected)
                % find the type of the Pole-Zero Group
                type = this.Widgets.PZTable.Data{idxSelected,1};
                switch type
                    case {pzAction{1}, pzAction{3}, pzAction{4}, pzAction{6}}
                        % this.Widgets.EditField1.Tag = ....
                        % Real Pole, Real Zero, Integrator, Differentiator
                        % Real pole/zero
                        
                        if isempty(PZGroup(idxSelected).Pole)
                            
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditZero'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedZero'));
                        else
                            % real pole or integrator
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditPole'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedPole'));
                        end
                
                    case {pzAction{2}, pzAction{5}}
                        % 4 set of label, EditField for 
                        % Complex Pole, Complex Zero
                        
                        % update desc and msg for status bar
                        if isempty(PZGroup(idxSelected).Pole)
                            % complex zero 
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditComplexZero'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedComplexZero'));
                        else
                            % complex pole
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditComplexPole'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedComplexPole'));
                        end
                
                    case {pzAction{7}, pzAction{8}}
                
                        % EditField for Lead, Lag
                        [zeroLocation, poleLocation, ~, ~] = updateLeadLagEditFields(this, ...
                                                            value, tag, previousValue);
                        
                        % update desc and msg for status bar
                        if zeroLocation > poleLocation
                            % Lead & Lag 
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditLead'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedLead'));
                        else
                            % Lead & Lag
                            desc = getString(message( ...
                                'Control:compDesignTask:strEditLag'));
                            status = getString(message( ...
                                'Control:compDesignTask:msgEditedLag'));
                        end
                        
                    case pzAction{9}
                        % 5 set of label, EditField for Notch
                        % update PZGroup values
                        % updates UI components as well
                        
                        desc = getString(message( ...
                            'Control:compDesignTask:strEditNotch'));
                        status = getString(message( ...
                            'Control:compDesignTask:msgEditedNotch'));
                        
                end
             end
        end
        
        function updateSelectedPZGroupValues(this, idxSelected, pzAction, PZGroup, ...
                value, previousValue, tag)
            if ~isempty(idxSelected)
                % find the type of the Pole-Zero Group
                type = this.Widgets.PZTable.Data{idxSelected,1};  
                switch type
                    case {pzAction{1}, pzAction{3}, pzAction{4}, pzAction{6}}
                        % this.Widgets.EditField1.Tag = ....
                        % Real Pole, Real Zero, Integrator, Differentiator
                        % Real pole/zero
                        
                        if isempty(PZGroup(idxSelected).Pole)
                            % real zero or integrator
                            PZGroup(idxSelected).Zero = value;
                        else
                            % real pole or integrator
                            PZGroup(idxSelected).Pole = value;
                        end
            
                    case {pzAction{2}, pzAction{5}}
                        % 4 set of label, EditField for 
                        % Complex Pole, Complex Zero
                        
                        pzLocation = updateComplexEditFields(this, tag, value);
                        
                        % update desc and msg for status bar
                        if isempty(PZGroup(idxSelected).Pole)
                            % complex zero 
                            PZGroup(idxSelected).Zero = pzLocation;
                        else
                            % complex pole
                            PZGroup(idxSelected).Pole = pzLocation;
                        end
            
                        % update EditField ui to reflect changes 
                        [Wn, Z] = damp(pzLocation(1), this.Ts);
                                
                        this.Widgets.EditField1.Value = Wn;
                        this.Widgets.EditField2.Value = Z;
                        this.Widgets.EditField3.Value = real(pzLocation(1));
                        this.Widgets.EditField4.Value = imag(pzLocation(1));
            
                    case {pzAction{7}, pzAction{8}}
            
                        % EditField for Lead, Lag
                        [zeroLocation, poleLocation, phaseMRad, Wm] = updateLeadLagEditFields(this, ...
                                                            value, tag, previousValue);
            
                        % after saveSession
                        % update PZGroup
                        PZGroup(idxSelected).Zero = zeroLocation;
                        PZGroup(idxSelected).Pole = poleLocation;
                        
                        % UI update
                        this.Widgets.EditField1.Value = PZGroup(idxSelected).Zero;
                        this.Widgets.EditField2.Value = PZGroup(idxSelected).Pole;
                        this.Widgets.EditField3.Value = phaseMRad;
                        this.Widgets.EditField4.Value = Wm;
                        
                    case pzAction{9}
                        % 5 set of label, EditField for Notch
                        % update PZGroup values
                        % updates UI components as well
                        [zeroLocation, poleLocation] = updateNotchEditfields(this, tag, ...
                                            value, previousValue);
            
                        PZGroup(idxSelected).Zero = zeroLocation;
                        PZGroup(idxSelected).Pole = poleLocation;
                    otherwise
                        this.Widgets.EditInfoLabel.Visible = 'on';
                        
                end
        %     
        %         % update UI and event manager
        %         updatePZGroupValues(this, status, desc)
            else
                return
            end
        
        end
        
        function pzLocation = updateComplexEditFields(this, tag, value, PZGroup)
        
            labelText1 = getString(message( ...
                        'Control:compDesignTask:strNaturalFrequency'));
            labelText2 = getString(message( ...
                'Control:compDesignTask:strDamping'));
            labelText3 = getString(message( ...
                'Control:compDesignTask:strRealPart'));
            labelText4 = getString(message( ...
                'Control:compDesignTask:strImaginaryPart'));
            switch tag
                case labelText1
                    % change in Natural frequency EditField
                    Wn = value * funitconv(this.FrequencyUnits, ...
                        'rad/s');
                    Z = this.Widgets.EditField2.Value;
                    
        
                    location = -Z*Wn + Wn*sqrt(Z^2-1);
                    pzLocation = [location; conj(location)];
        
                    if this.Ts ~= 0
                        pzLocation = exp(pzLocation*this.Ts);
                    end
        
                case labelText2
                    % change in Damping EditField
                    Wn = this.Widgets.EditField1.Value;
                    Z = value;
                    
        
                    if abs(Z) > 1
                        Z = sign(Z);
                    end
        
                    location = -Z*Wn + Wn*sqrt(Z^2-1);
                    pzLocation = [location; conj(location)];
        
                    if this.Ts ~= 0
                        pzLocation = exp(pzLocation*this.Ts);
                    end
        
                case labelText3
                    % change in real part of pole
                    realLocation = value;
                    imagLocation = this.Widgets.EditField4.Value;
        
                    pzLocation = [realLocation + 1i * imagLocation;
                                  realLocation - 1i * imagLocation];
                case labelText4
                    % change in imag part of pole
                    realLocation = this.Widgets.EditField3.Value;
                    imagLocation = value;
        
                    pzLocation = [realLocation + 1i * imagLocation;
                                  realLocation - 1i * imagLocation];
            end
            
        end
        
        function [zeroLocation, poleLocation, phaseMRad, Wm] = updateLeadLagEditFields(this, ...
                value, tag, previousValue)
            messageLL = "pole and zero are stable minimum phase";
            labelText1 = getString(message( ...
                'Control:compDesignTask:strRealZero'));
            labelText2 = getString(message( ...
                'Control:compDesignTask:strRealPole'));
            labelText3 = getString(message( ...
                'Control:compDesignTask:lblMaxDeltaPhase'));
            labelText4 = getString(message( ...
                'Control:compDesignTask:lblAtFrequency'));
        
            switch tag
                case labelText1
                    ZL = value;
                    PL = this.Widgets.EditField2.Value;
                    resetZeroValue = previousValue;
                    phaseMRad = this.Widgets.EditField3.Value;
                    Wm = this.Widgets.EditField4.Value;
        
                    % Continuous condition that 
                    % pole and zero are stable minimum phase
                    condition1 = (this.Ts == 0)  && ...
                        (ZL <= 0 ) && (PL <= 0);
                    % Discrete condition that 
                    % pole and zero are stable minimum phase
                    condition2 = (this.Ts ~= 0) && ...
                        (abs(ZL) <= 1)  && ...
                        (abs(PL) <= 1);
                    if condition1 || condition2
                        zeroLocation = ZL;
                        poleLocation = PL;
                    else
                        zeroLocation = resetZeroValue;
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageLL, title);
                    end
                case labelText2 
                    PL = value;
                    ZL = this.Widgets.EditField1.Value;
                    resetPoleValue = previousValue;
                    phaseMRad = this.Widgets.EditField3.Value;
                    Wm = this.Widgets.EditField4.Value;
        
                    % Continuous condition that 
                    % pole and zero are stable minimum phase
                    condition1 = (this.Ts == 0)  && ...
                        (ZL <= 0 ) && (PL <= 0);
                    % Discrete condition that 
                    % pole and zero are stable minimum phase
                    condition2 = (this.Ts ~= 0) && ...
                        (abs(ZL) <= 1)  && ...
                        (abs(PL) <= 1);
                    if condition1 || condition2
                        zeroLocation = ZL;
                        poleLocation = PL;
                    else
                        poleLocation = resetPoleValue;
                        
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageLL, title);
                    end
                case labelText3
                    % phase change
                    phaseMRad = value*pi/180;
                    % max phasevalue phasemdeg < 90 for computation
                    maxPhaseValue = asin(1-eps); 
                    if (abs(phaseMRad) > maxPhaseValue)
                        phaseMRad = sign(phaseMRad)*maxPhaseValue;
                    end
                    
                    Wm = this.Widgets.EditField4.Value;
                    % make sure Wm is in rad/s
                    Wm = Wm*funitconv(this.FrequencyUnits, ...
                        'rad/s');
        
                    if (abs(phaseMRad) > maxPhaseValue)
                        zeroLocation = NaN;
                        poleLocation = NaN;
                    else
                        % Zero = alpha * Pole
                        alpha = (1-sin(phaseMRad))/ ...
                                (1+sin(phaseMRad));
                        
                        zeroLocation = -Wm*sqrt(alpha);
                        poleLocation = zeroLocation/alpha;
                        
                        if (this.Ts ~= 0)
                            zeroLocation = exp(zeroLocation* ...
                                this.Ts);
                            poleLocation = exp(poleLocation* ...
                                this.Ts);
                        end
                    end
        
                case labelText4
                    Wm = value*funitconv(this.FrequencyUnits, ...
                        'rad/s');
                    phaseMRad = this.Widgets.EditField3.Value*pi/180;
                    % max phasevalue phasemdeg < 90 for computation
                    maxPhaseValue = asin(1-eps); 
                    if (abs(phaseMRad) > maxPhaseValue)
                        phaseMRad = sign(phaseMRad)*maxPhaseValue;
                    end
        
                    if (abs(phaseMRad) > maxPhaseValue)
                        zeroLocation = NaN;
                        poleLocation = NaN;
                    else
                        % Zero = alpha * Pole
                        alpha = (1-sin(phaseMRad))/ ...
                                (1+sin(phaseMRad));
                        
                        zeroLocation = -Wm*sqrt(alpha);
                        poleLocation = zeroLocation/alpha;
                        
                        if (this.Ts ~= 0)
                            zeroLocation = exp(zeroLocation* ...
                                this.Ts);
                            poleLocation = exp(poleLocation* ...
                                this.Ts);
                        end
                    end
            end
        end
        
        function [zeroLocation, poleLocation] = updateNotchEditfields(this, tag, ...
                value, previousValue)
            labelText1 = getString(message( ...
                'Control:compDesignTask:strNaturalFrequency'));
            labelText2 = getString(message( ...
                'Control:compDesignTask:strDampingZero'));
            labelText3 = getString(message( ...
                'Control:compDesignTask:strDampingPole'));
            labelText4 = getString(message( ...
                'Control:compDesignTask:strNotchDepthdB'));
            labelText5 = getString(message( ...
                'Control:compDesignTask:strNotchWidthLog'));
            switch tag
                case labelText1
                    if value >= 10*eps/log(10)
                        Wn = value*funitconv(this.FrequencyUnits, ...
                             'rad/s');
                        ZetaP = this.Widgets.EditField3.Value;
                        ZetaZ = this.Widgets.EditField2.Value;
                        [zeroLocation, poleLocation] = ...
                                evaluateNotch(this, Wn, ZetaZ, ZetaP);
                    else
                        this.Widgets.EditField1.Value = previousValue;
                        messageWn = 'Value is < 10*eps/log(10)';
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageWn, title);
                    end
        
                case labelText2
                    ZetaP = this.Widgets.EditField3.Value;
                    ZetaZ = value;
                    Wn = this.Widgets.EditField1.Value;
                    Wn = Wn*funitconv(this.FrequencyUnits, ...
                        'rad/s');
                    if ZetaP > ZetaZ
                       [zeroLocation, poleLocation] = ...
                                evaluateNotch(this, Wn, ZetaZ, ZetaP);
                    else
                        this.Widgets.EditField2.Value = previousValue;
                        messageWn = 'Zero should be greater than Pole';
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageWn, title);
                    end
                case labelText3
                    ZetaP = value;
                    ZetaZ = this.Widgets.EditField2.Value;
                    Wn = this.Widgets.EditField1.Value;
                    Wn = Wn*funitconv(this.FrequencyUnits, ...
                        'rad/s');
                    if ZetaP > ZetaZ
                       [zeroLocation, poleLocation] = ...
                                evaluateNotch(this, Wn, ZetaZ, ZetaP);
                    else
                        this.Widgets.EditField3.Value = previousValue;
                        messageWn = 'Zero should be greater than Pole';
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageWn, title);
                    end
                case labelText4
                    depth = value;
                    width = this.Widgets.EditField5.Value;
                    Wn = this.Widgets.EditField1.Value;
                    Wn = Wn*funitconv(this.FrequencyUnits, ...
                        'rad/s');
                    if isreal(depth) && (depth <= 0)
                        depth = 10^(depth/20);
                        
                        [zeroLocation, poleLocation] = evaluateNotch2(this, ...
                                            depth, width, Wn);
                    else
                        this.Widgets.EditField4.Value = previousValue;
                        messageWn = 'Enter a valid number';
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageWn, title);
                    end
                case labelText5
                    width = value;
                    depth = this.Widgets.EditField4.Value;
                    Wn = this.Widgets.EditField1.Value;
                    Wn = Wn*funitconv(this.FrequencyUnits, ...
                        'rad/s');
                    if (width > 0) || isnan(width)
                        depth = 10^(depth/20);
                        
                        [zeroLocation, poleLocation] = evaluateNotch2(this, ...
                                            depth, width, Wn);
                    else
                        this.Widgets.EditField5.Value = previousValue;
                        messageWn = 'Enter a valid number';
                        title = getString(message( ...
                            'Control:compDesignTask:strCompensatorEditor'));
                        uialert(this.UIFigure, messageWn, title);
                    end
            end
        end

        function [zeroLocation, poleLocation] = evaluateNotch(this, Wn, ZetaZ, ZetaP)
            zeroLocation = -ZetaZ*Wn + Wn*sqrt(ZetaZ^2-1);
            poleLocation = -ZetaP*Wn + Wn*sqrt(ZetaP^2-1);
            
            zeroLocation = [zeroLocation; conj(zeroLocation)];
            poleLocation = [poleLocation; conj(poleLocation)];
            
            if (this.Ts ~= 0)
                zeroLocation = exp(zeroLocation*this.Ts);
                poleLocation = exp(poleLocation*this.Ts);
            end
%             % find the index of the table selection
%             idxSelected = this.Widgets.PZTable.Selection;
% 
%             % get pole-zero group of the current comp - current selection
%             PZGroup = this.SelectedCompensator.PZGroup;
% 
%             % update PZGroup values
%             PZGroup(idxSelected).Zero = zeroLocation;
%             PZGroup(idxSelected).Pole = poleLocation;
%             desc = getString(message( ...
%                 'Control:compDesignTask:strEditNotch'));
%             status = getString(message( ...
%                 'Control:compDesignTask:msgEditedNotch'));
        end

        function [zeroLocation, poleLocation] = evaluateNotch2(this, depth, width, Wn)
            % Calculate maxwidth
            %      s^2 + (2*Zeta1^2)*s + wn^2
            % G(s)--------------
            %      s^2 + (2*Zeta2^2)*s + wn^2
            %
            % Depth = Zeta1/Zeta2
            
            p=.25; % percent depth for width calculation
            if depth == 1
                maxWidth = NaN; % depth = 1 -> pole/zero cancellation
            else
                alpha = depth^p;
                betaD = sqrt((alpha^2-depth^2)/(1-alpha^2));
                maxWidth = log10(1 + 2*betaD^2 + 2*betaD*sqrt(1+betaD^2));
            end
           
            
            if (width > maxWidth) || (depth == 1) || ...
                (width == 0) || isnan(width)
                zPole = 1; % equivalent to set width = maxwidth
            else
                y = 10^width;
                alpha = depth^0.25;
                beta2 = (y-1)^2/4/y;
                zPole = sqrt(beta2*(1-alpha)*(1+alpha)/((alpha-depth)* ...
                    (alpha+depth)));
            end
            
            zZero = zPole * depth;
            
            zeroLocation = -zZero*Wn + Wn*sqrt(zZero^2-1);
            poleLocation = -zPole*Wn + Wn*sqrt(zPole^2-1);
            
            zeroLocation = [zeroLocation; conj(zeroLocation)];
            poleLocation = [poleLocation; conj(poleLocation)];
            
            if (this.Ts ~= 0)
                zeroLocation = exp(zeroLocation*this.Ts);
                poleLocation = exp(poleLocation*this.Ts);
            end
        end

        function cbHelpButton(this)
            if isSimulink(this.DesignerData)
                ctrlguihelp('CSD_SL_CompensatorEditorHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_CompensatorEditorHelp','CSHelpWindow');
            end
        end

        function cbCancelButton(this)
            delete(this);
        end

        function cbContextMenuOpening(this,ed)
            % Modify selected row of table based on click-location and update the edit panel
            row = ed.InteractionInformation.DisplayRow;
            col = ed.InteractionInformation.DisplayColumn;
            if ~isempty([row col])
                this.Widgets.PZTable.Selection = row;
            else
                this.Widgets.PZTable.Selection = [];
            end
            updateEditPanel(this);
        end
    end

    methods (Hidden)
        function w = qeGetWidgets(this)
            w = this.Widgets;
        end
        function qeUpdateEditPanel(this)
            updateEditPanel(this);
        end
    end
end

