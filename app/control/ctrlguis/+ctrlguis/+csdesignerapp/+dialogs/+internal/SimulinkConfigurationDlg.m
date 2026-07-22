classdef SimulinkConfigurationDlg < ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog
    %% Dialog to configure a Simulink architecture in Control System Designer
    %
    % ST0 = slTuner('scdspeedctrl');
    % arch = ctrlguis.csdesignerapp.data.architectures.internal.SimulinkArchitecture(ST0);
    % data = ctrlguis.csdesignerapp.data.internal.DesignerData(arch);
    % dlg = ctrlguis.csdesignerapp.dialogs.internal.SimulinkConfigurationDlg(arch);
    % show(dlg);
    
    % Copyright 2014-2022 The MathWorks, Inc.
    
    properties (Access = private)
        % Dialog handles
        AddTunableBlockDialog
        AddLocationsDialog
        AddOpeningsDialog
        OPPicker
        LinearizationOptionsPnl
        LinearizationOptionsTC
        ArchitectureListener
        DialogCloseListener
        
        %Highlight property for QE method
        HighlightBlockStatus = false
        HighlightSignalStatus = false
        
        % Grid
        LinTabGrid
    end
    
    methods
        %% Constructor
        function this = SimulinkConfigurationDlg(ConfigData)
            % Superclass constructor
            this = this@ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog(ConfigData);
            
            % Add relevant listeners
            this.ArchitectureListener = addlistener(ConfigData, 'SystemChanged', @(es,ed)cbCancelClicked(this));
            this.DialogCloseListener = addlistener(this,'CloseEvent',@(es,ed) closeAddTunableBlockDialog(this));
        end
    end
    
    methods (Access = protected)
        %% TITLE
        function Title = getTitle(this)
            Title = getString(message('Control:designerapp:strEditSimulinkArchitecture'));
        end
        
        %% CREATE TABS
        function Tabs = getTabPnls(this)
            % Create blocks tab
            Tabs(1) = createBlocksTab(this);
            % Create signals tab
            Tabs(2) = createSignalsTab(this);
            % Create linearization tab
            Tabs(3) = createLinearizationTab(this);
        end
        
        %% BLOCKS - PANELS
        function blocksTab = createBlocksTab(this)
            % Tab
            blocksTab = uitab(this.Widgets.TabbedPanel);
            blocksTab.Title = getString(message('Control:designerapp:strBlocksTabTitle'));
            % Grid
            blockListGrid = uigridlayout(blocksTab,[2,5],...
                'Scrollable','off');
            blockListGrid.RowHeight = {'fit','fit'};
            blockListGrid.ColumnWidth = {250,100,'fit','fit','fit'};
            this.Widgets.BlocksTab.ListPnl = blockListGrid;
            % Titles
            labelTitle = uilabel(blockListGrid,...
                'Text',getString(message('Control:designerapp:strBlockName')),...
                'FontWeight','bold');
            labelTitle.Layout.Row = 1;
            labelTitle.Layout.Column = 1;
            this.Widgets.LabelTitleLbl = labelTitle;
            valueTitle = uilabel(blockListGrid,...
                'Text',getString(message('Control:designerapp:strBlockValue')),...
                'FontWeight','bold');
            valueTitle.Layout.Row = 1;
            valueTitle.Layout.Column = 2;
            this.Widgets.BlocksTab.ValueTitleLbl = valueTitle;
            % Add Blocks Button
            addBlocksGrid = uigridlayout(blockListGrid,[1 1]);
            addBlocksGrid.Layout.Row = 2;
            addBlocksGrid.Layout.Column = 1;
            addBlocksGrid.RowHeight = {'fit'};
            addBlocksGrid.ColumnWidth = {'fit'};
            addBlocksGrid.Padding = 0;
            addBlocksButton = uibutton(addBlocksGrid,...
                'Text',getString(message('Control:designerapp:strAddBlocks')));
            this.Widgets.BlocksTab.AddFromModelBtnGrid = addBlocksGrid;
            this.Widgets.BlocksTab.AddFromModelBtn = addBlocksButton;
            LBlk = addlistener(addBlocksButton, 'ButtonPushed', @(es,ed)addBlocksFromModel(this));
            registerUIListeners(this, LBlk);
            
            this.Widgets.BlocksTab.Identifier = [];
            this.Widgets.BlocksTab.Value = [];
            this.Widgets.BlocksTab.Import = [];
            this.Widgets.BlocksTab.Remove = [];
            this.Widgets.BlocksTab.Highlight = [];
        end
        
        function addBlockListRow(this,block,ct)
            % For each block, create five things - Label for identifier,
            % Edit field for Value, Import button, Remove button, Highlight
            % button
            blockListGrid = this.Widgets.BlocksTab.ListPnl;
            % Identifier Label
            Labels = uilabel(blockListGrid);
            Labels.Layout.Row = ct + 1;
            Labels.Layout.Column = 1;
            Labels.HorizontalClipping = 'left';
            this.Widgets.BlocksTab.Identifier = [this.Widgets.BlocksTab.Identifier; Labels];
            % Value Text
            Value = uieditfield(blockListGrid);
            Value.Layout.Row = ct + 1;
            Value.Layout.Column = 2;
            Value.Tag = block.getIdentifier;
            this.Widgets.BlocksTab.Value = [this.Widgets.BlocksTab.Value; Value];
            % Import Button
            Import = uibutton(blockListGrid,'Text','');
            matlab.ui.control.internal.specifyIconID(Import, 'import_data', 16);
            Import.Layout.Row = ct + 1;
            Import.Layout.Column = 3;
            this.Widgets.BlocksTab.Import = [this.Widgets.BlocksTab.Import; Import];
            if ~isa(block,'ctrlguis.csdesignerapp.data.architectures.internal.TunedLTI')  || this.isConstrained(block)
                Value.Enable = false;
                Import.Enable = false;
            end
            % Hightlight Button
            Highlight = uibutton(blockListGrid,'Text','');
            matlab.ui.control.internal.specifyIconID(Highlight, 'highlightBlockAction', 16);
            Highlight.Layout.Row = ct + 1;
            Highlight.Layout.Column = 4;
            this.Widgets.BlocksTab.Highlight = [this.Widgets.BlocksTab.Highlight; Highlight];
            % Remove Button
            Remove = uibutton(blockListGrid,'Text','');
            matlab.ui.control.internal.specifyIconID(Remove, 'delete', 16);
            Remove.Layout.Row = ct + 1;
            Remove.Layout.Column = 5;
            this.Widgets.BlocksTab.Remove = [this.Widgets.BlocksTab.Remove; Remove];
            % Addlisteners
            ValueListener = addlistener(Value, 'ValueChanged', @(es,ed)cbValueChanged(this, ct));
            ImportListener = addlistener(Import, 'ButtonPushed', @(es,ed)cbImportClicked(this, ct));
            HighlightBlockListener = addlistener(Highlight, 'ButtonPushed', @(es,ed)cbHighlightBlockClicked(this, ct));
            RemoveBlockListener = addlistener(Remove, 'ButtonPushed', @(es,ed)cbRemoveBlockClicked(this, ct));
            registerUIListeners(this, ValueListener);
            registerUIListeners(this, ImportListener);
            registerUIListeners(this, HighlightBlockListener);
            registerUIListeners(this, RemoveBlockListener);
        end
        
        %% BLOCKS - CALLBACKS
        function addBlocksFromModel(this)
            % Launch the block selection GUI
            if isempty(this.AddTunableBlockDialog) || ~isvalid(this.AddTunableBlockDialog)
                try
                    this.AddTunableBlockDialog = controllib.widget.internal.SelectBlockDialog(this.LocalConfigData);
                catch Ex
                    % always slTuner since ML side do not have block adding
                    slcontrollib.internal.utils.nagctlr(getName(this.LocalConfigData),...
                        getString(message('Control:general:Tool_controlSystemDesigner_Label')),...
                        getString(message('Control:designerapp:strTunedBlock')),...
                        Ex);
                    return;
                end
            end
            try % Trap tunable block error due to simulink compilation errors
                show(this.AddTunableBlockDialog,this,'EAST');
            catch Ex
                % always slTuner since ML side do not have block adding
                slcontrollib.internal.utils.nagctlr(getName(this.LocalConfigData),...
                    getString(message('Control:general:Tool_controlSystemDesigner_Label')),...
                    getString(message('Control:designerapp:strTunedBlock')),...
                    Ex);
            end
        end
        
        function cbHighlightBlockClicked(this, ct)
            BlockPath = this.Widgets.BlocksTab.Identifier(ct).Text;
            try
                if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.ConfigData.getName))
                    open_system(this.ConfigData.getName);
                end
                hilite_system(BlockPath,'find');
                pause(1);
                hilite_system(BlockPath,'none');
                this.HighlightBlockStatus = true;
            catch ME
                uialert(getWidget(this),ME.message,this.Title);
                this.HighlightBlockStatus = false;
            end
        end
        
        function cbRemoveBlockClicked(this, ct)
            try
                removeBlock(this.LocalConfigData, this.Widgets.BlocksTab.Identifier(ct).Text);
            catch
                updateBlocks(this);
            end
        end
        
        function addBlockChangedListeners(this,idx)
            Blocks = getTunedBlocks(this.LocalConfigData);
            for ct = 1:numel(Blocks)
                LBlock(ct) = addlistener(Blocks(ct), 'ValueChanged', @(es,ed)updateWidgets(this)); %#ok<*AGROW>
            end
            this.BlockListeners{idx} = LBlock;
        end
        
        %% SIGNALS - PANEL
        function SignalsTab = createSignalsTab(this)
            % Tab
            SignalsTab = uitab(this.Widgets.TabbedPanel);
            SignalsTab.Title = getString(message('Control:designerapp:strSignalsTabTitle'));
            
            signalsTabGrid = uigridlayout(SignalsTab,[2 1],...
                'Scrollable','off');
            signalsTabGrid.RowHeight = {'fit','fit'};
            signalsTabGrid.ColumnWidth = {'1x'};
            
            % Location
            locationGrid = uigridlayout(signalsTabGrid,[2 4]);
            locationGrid.RowHeight = {'fit','fit'};
            locationGrid.ColumnWidth = {250,'fit','fit','fit'};
            this.Widgets.SignalsTab.Locations.ListPnl = locationGrid;
            
            locationTitle = uilabel(locationGrid,...
                'Text',getString(message('Control:designerapp:strLocations')),...
                'FontWeight','bold');
            locationTitle.Layout.Row = 1;
            locationTitle.Layout.Column = 1;
            
            addButtonGrid = uigridlayout(locationGrid,[1 1]);
            addButtonGrid.Layout.Row = 2;
            addButtonGrid.Layout.Column = 1;
            addButtonGrid.RowHeight = {'fit'};
            addButtonGrid.ColumnWidth = {'fit'};
            addButtonGrid.Padding = 0;
            addLocationButton = uibutton(addButtonGrid,...
                'Text',getString(message('Control:designerapp:strAddLocations')));
            this.Widgets.SignalsTab.Locations.AddFromModelBtn = addLocationButton;
            this.Widgets.SignalsTab.Locations.AddFromModelBtnGrid = addButtonGrid;
            
            % Listener
            LSig = addlistener(addLocationButton, 'ButtonPushed', ...
                @(es,ed)addLocationsFromModel(this));
            registerUIListeners(this, LSig);
            
            % Openings
            openingGrid = uigridlayout(signalsTabGrid,[2 4]);
            openingGrid.RowHeight = {'fit','fit'};
            openingGrid.ColumnWidth = {250,'fit','fit','fit'};
            openingGrid.Layout.Row = 2;
            openingGrid.Layout.Column = 1;
            this.Widgets.SignalsTab.Openings.ListPnl = openingGrid;
            
            openingTitle = uilabel(openingGrid,...
                'Text',getString(message('Control:designerapp:strOpenings')),...
                'FontWeight','bold');
            openingTitle.Layout.Row = 1;
            openingTitle.Layout.Column = 1;
            
            addButtonGrid = uigridlayout(openingGrid,[1 1]);
            addButtonGrid.Layout.Row = 2;
            addButtonGrid.Layout.Column = 1;
            addButtonGrid.RowHeight = {'fit'};
            addButtonGrid.ColumnWidth = {'fit'};
            addButtonGrid.Padding = 0;
            addOpeningButton = uibutton(addButtonGrid,...
                'Text',getString(message('Control:designerapp:strAddOpenings')));
            this.Widgets.SignalsTab.Openings.AddFromModelBtn = addOpeningButton;
            this.Widgets.SignalsTab.Openings.AddFromModelBtnGrid = addButtonGrid;
            
            % Listener
            LSig = addlistener(addOpeningButton, 'ButtonPushed',...
                @(es,ed)addOpeningsFromModel(this));
            registerUIListeners(this, LSig);
            
            this.Widgets.SignalsTab.Locations.Identifier = [];
            this.Widgets.SignalsTab.Locations.Remove = [];
            this.Widgets.SignalsTab.Locations.Highlight = [];
            
            this.Widgets.SignalsTab.Openings.Identifier = [];
            this.Widgets.SignalsTab.Openings.Remove = [];
            this.Widgets.SignalsTab.Openings.Highlight = [];
        end
        
        function createLocationsListPnl(this)
            % For each signal, create three things - Label for identifier,
            % Edit field for Value, Import button
            
            % Remove widgets that are no longer valid
            delete(this.Widgets.SignalsTab.Locations.Identifier);
            this.Widgets.SignalsTab.Locations.Identifier = [];
            delete(this.Widgets.SignalsTab.Locations.Remove);
            this.Widgets.SignalsTab.Locations.Remove = [];
            delete(this.Widgets.SignalsTab.Locations.Highlight);
            this.Widgets.SignalsTab.Locations.Highlight = [];
            
            % Get number of signals
            Signals = getAvailableSignals(this.LocalConfigData);
            NumSignals = numel(Signals);
            
            locationGrid = this.Widgets.SignalsTab.Locations.ListPnl;
            locationGrid.RowHeight = repmat({'fit'},1,NumSignals + 2);
            this.Widgets.SignalsTab.Locations.AddFromModelBtnGrid.Layout.Row = NumSignals + 2;
            
            % Create components and the required number of rows in the grid
            for ct = 1:NumSignals
                % Identifier Label
                Labels(ct) = uilabel(locationGrid,'HorizontalClipping','left');
                Labels(ct).Layout.Row = ct + 1;
                Labels(ct).Layout.Column = 1;
                this.Widgets.SignalsTab.Locations.Identifier = [this.Widgets.SignalsTab.Locations.Identifier; Labels(ct)];
                
                % Remove Button
                Remove(ct) =uibutton(locationGrid,'Text','');
                matlab.ui.control.internal.specifyIconID(Remove(ct), 'delete', 16);
                Remove(ct).Layout.Row = ct + 1;
                Remove(ct).Layout.Column = 4;
                this.Widgets.SignalsTab.Locations.Remove = [this.Widgets.SignalsTab.Locations.Remove; Remove(ct)];
                
                % Highlight Button
                Highlight(ct) = uibutton(locationGrid,'Text','');
                matlab.ui.control.internal.specifyIconID(Highlight(ct), 'highlightBlockAction', 16);
                Highlight(ct).Layout.Row = ct + 1;
                Highlight(ct).Layout.Column = 3;
                this.Widgets.SignalsTab.Locations.Highlight = [this.Widgets.SignalsTab.Locations.Highlight; Highlight(ct)];
                
                % Addlisteners
                HighlightSignalsListener(ct) = addlistener(Highlight(ct), 'ButtonPushed', @(es,ed)cbHighlightSignalClicked(this, ct, 'Locations'));
                RemoveSignalsListener(ct) = addlistener(Remove(ct), 'ButtonPushed', @(es,ed)cbRemoveSignalClicked(this, ct));
            end
            
            if NumSignals > 0
                registerUIListeners(this, HighlightSignalsListener);
                registerUIListeners(this, RemoveSignalsListener);
            end
        end
        
        function createOpeningsListPnl(this)
            % For each signal, create three things - Label for identifier,
            % Edit field for Value, Import button
            
            delete(this.Widgets.SignalsTab.Openings.Identifier);
            this.Widgets.SignalsTab.Openings.Identifier = [];
            delete(this.Widgets.SignalsTab.Openings.Remove);
            this.Widgets.SignalsTab.Openings.Remove = [];
            delete(this.Widgets.SignalsTab.Openings.Highlight);
            this.Widgets.SignalsTab.Openings.Highlight = [];
            
            % Get number of signals
            Signals = getOpenings(this.LocalConfigData);
            NumSignals = numel(Signals);
            
            openingGrid = this.Widgets.SignalsTab.Openings.ListPnl;
            openingGrid.RowHeight = repmat({'fit'},1,NumSignals + 2);
            this.Widgets.SignalsTab.Openings.AddFromModelBtnGrid.Layout.Row = NumSignals + 2;
            
            % Create components and the required number of rows in the grid
            for ct = 1:NumSignals
                % Identifier Label
                Labels(ct) = uilabel(openingGrid,'HorizontalClipping','left');
                Labels(ct).Layout.Row = ct + 1;
                Labels(ct).Layout.Column = 1;
                this.Widgets.SignalsTab.Openings.Identifier = [this.Widgets.SignalsTab.Openings.Identifier; Labels(ct)];
                
                % Remove Button
                Remove(ct) =uibutton(openingGrid,'Text','');
                matlab.ui.control.internal.specifyIconID(Remove(ct), 'delete', 16);
                Remove(ct).Layout.Row = ct + 1;
                Remove(ct).Layout.Column = 4;
                this.Widgets.SignalsTab.Openings.Remove = [this.Widgets.SignalsTab.Openings.Remove; Remove(ct)];
                
                % Highlight Button
                Highlight(ct) = uibutton(openingGrid,'Text','');
                matlab.ui.control.internal.specifyIconID(Highlight(ct), 'highlightBlockAction', 16);
                Highlight(ct).Layout.Row = ct + 1;
                Highlight(ct).Layout.Column = 3;
                this.Widgets.SignalsTab.Openings.Highlight = [this.Widgets.SignalsTab.Openings.Highlight; Highlight(ct)];
                
                % Addlisteners
                HighlightSignalsListener(ct) = addlistener(Highlight(ct), 'ButtonPushed', @(es,ed)cbHighlightSignalClicked(this, ct, 'Openings'));
                RemoveSignalsListener(ct) = addlistener(Remove(ct), 'ButtonPushed', @(es,ed)cbRemoveOpeningClicked(this, ct));
            end
            
            if NumSignals >0
                registerUIListeners(this, HighlightSignalsListener);
                registerUIListeners(this, RemoveSignalsListener);
            end
        end
        
        %% SIGNALS - CALLBACKS
        function addSignalsFromModel(this, AdderHandle)
            if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.ConfigData.getName))
                open_system(this.ConfigData.getName);
            end
            this.AddSignalsDialog = ctrlguis.csdesignerapp.dialogs.internal.AddSignalFromModel(this.LocalConfigData, AdderHandle);
            show(this.AddSignalsDialog,this.Widgets.SignalsTab.Locations.AddFromModelBtn,'North');
        end
        
        function addLocationsFromModel(this)
            if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.ConfigData.getName))
                open_system(this.ConfigData.getName);
            end
            if isempty(this.AddLocationsDialog) || ~isvalid(this.AddLocationsDialog)
                this.AddLocationsDialog = ...
                    ctrlguis.csdesignerapp.dialogs.internal.AddSignalFromModel(...
                        this.LocalConfigData,@addSignal);
                this.AddLocationsDialog.Title = ...
                    getString(message('Control:designerapp:AddSignalDialogTitleSelectLocations'));
                show(this.AddLocationsDialog,this,'EAST');
            else
                show(this.AddLocationsDialog);
            end
        end
        
        function addOpeningsFromModel(this)
            if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.ConfigData.getName))
                open_system(this.ConfigData.getName);
            end
            if isempty(this.AddOpeningsDialog) || ~isvalid(this.AddOpeningsDialog)
                this.AddOpeningsDialog = ...
                    ctrlguis.csdesignerapp.dialogs.internal.AddSignalFromModel(...
                        this.LocalConfigData,@addOpening);
                this.AddOpeningsDialog.Title = ...
                    getString(message('Control:designerapp:AddSignalDialogTitleSelectOpenings'));
                show(this.AddOpeningsDialog,this,'EAST');
            else
                show(this.AddOpeningsDialog);
            end
        end
        
        function cbRemoveSignalClicked(this, ct)
            removeSignal(this.LocalConfigData, this.Widgets.SignalsTab.Locations.Identifier(ct).Text);
        end
        
        function cbRemoveOpeningClicked(this, ct)
            removeOpening(this.LocalConfigData, this.Widgets.SignalsTab.Openings.Identifier(ct).Text);
        end
        
        function cbHighlightSignalClicked(this, ct, FieldName)
            if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.ConfigData.getName))
                open_system(this.ConfigData.getName);
            end
            % Get the block and port handle
            SignalName = this.Widgets.SignalsTab.(FieldName).Identifier(ct).Text;
            try
                Point = resolveSignalID(this.LocalConfigData, SignalName, FieldName);
                BlockPath = Point.Block;
                hilite_system(BlockPath,'find');
                pause(1);
                hilite_system(BlockPath,'none');
                this.HighlightSignalStatus = true;
            catch ME
                uialert(getWidget(this),ME.message,this.Title);
                this.HighlightSignalStatus = false;
            end
        end
        
        %% LINEARIZATION SETTINGS - PANELedit 
        function LinTab = createLinearizationTab(this)
            LinTab = uitab(this.Widgets.TabbedPanel);
            LinTab.Title = getString(message('Control:designerapp:strLinearizationOptions'));
            this.LinTabGrid = uigridlayout(LinTab,[3 1]);
            this.LinTabGrid.RowHeight = {'fit',1,'fit'};
            this.LinTabGrid.ColumnWidth = {'1x'};
            this.LinTabGrid.Scrollable = 'off';
            
            createOPPickerPnl(this);
            createLinearizationOptionsPnl(this);
        end
        
        function opGrid = createOPPickerPnl(this)
            linTabGrid = this.LinTabGrid;
            opGrid = uigridlayout(linTabGrid,[2 1]);
            opGrid.RowHeight = {'fit','fit'};
            opGrid.Layout.Row = 1;
            opGrid.Padding = 0;
            
            opLabel = uilabel(opGrid,'Text',...
                getString(message('Control:designerapp:strOperatingPoint')),...
                'FontWeight','bold');
            this.Widgets.LinTab.OpPicker.Label = opLabel;
            this.OPPicker = slctrlguis.lintool.widgets.OPPickerPanel(this.ConfigData,true,...
                'ParentContainer',opGrid,'Row',2,'Column',1);
            setOPPicker(this.ConfigData,this.OPPicker);
            
            OPPickerListener1 = addlistener(this.OPPicker,'SelectionChanged',@(es,ed) operatingPointChanged(this));
            OPPickerListener2 = addlistener(this.OPPicker,'OPVariableModified',@(es,ed) operatingPointChanged(this));
            this.Widgets.LinTab.OpPicker.OpPicker = this.OPPicker;
            
            registerUIListeners(this,OPPickerListener1, OPPickerListener2);
        end
        
        function pnl = createLinearizationOptionsPnl(this)
            linTabGrid = this.LinTabGrid;
            this.LinearizationOptionsTC = ...
                ctrlguis.csdesignerapp.panels.internal.LinearizationOptionsTC(this.LocalConfigData,this);
            this.LinearizationOptionsPnl = createView(this.LinearizationOptionsTC,...
                'Parent',linTabGrid,...
                'Row',3,'Column',1,'Dialog',this);
            pnl = getWidget(this.LinearizationOptionsPnl);
            this.Widgets.LinTab.LinOptions = this.LinearizationOptionsPnl;
        end
        
        %% LINEARIZATION SETTINGS - CALLBACKS
        function operatingPointChanged(this)
            OpSelection = this.OPPicker.getSelection;
            op = ctrlguis.csdesignerapp.dialogs.internal.SimulinkConfigurationDlg.getOperatingPointFromSelection(OpSelection);
            % REVISIT: postActionStatus
            % set operating point
            this.LocalConfigData.setOperatingPoints(op);
        end
        
        %% HELP CALLBACK
        function cbHelpClicked(this)
            ctrlguihelp('CSD_SimulinkArchitectureHelp','CSHelpWindow');
        end
        
%         function cleanupUI(this)
%             closeAddTunableBlockDialog(this);
%         end
        
        %% UPDATE 
        function updateWidgets(this)
            disableUIListeners(this);
            updateBlocks(this);
            updateSignals(this);
            update(this.LinearizationOptionsPnl);
            enableUIListeners(this);
        end
        
        function updateBlocks(this)
            disableUIListeners(this);
            BlockData = getTunedBlocks(this.LocalConfigData);
            
            % Remove widgets that are no longer valid
            delete(this.Widgets.BlocksTab.Identifier);
            this.Widgets.BlocksTab.Identifier = [];
            delete(this.Widgets.BlocksTab.Value);
            this.Widgets.BlocksTab.Value = [];
            delete(this.Widgets.BlocksTab.Import);
            this.Widgets.BlocksTab.Import = [];
            delete(this.Widgets.BlocksTab.Remove);
            this.Widgets.BlocksTab.Remove = [];
            delete(this.Widgets.BlocksTab.Highlight);
            this.Widgets.BlocksTab.Highlight = [];
            
            % Add Blocks
            blockListGrid = this.Widgets.BlocksTab.ListPnl;
            nBlocks = length(BlockData);
            blockListGrid.RowHeight = repmat({'fit'},1,nBlocks+2);
            
            this.Widgets.BlocksTab.AddFromModelBtnGrid.Layout.Row = nBlocks + 2;
            for ct = 1:nBlocks
                addBlockListRow(this,BlockData(ct),ct);
            end
            for ct = 1:numel(BlockData)
                this.Widgets.BlocksTab.Identifier(ct).Text = getBlockPath(this.LocalConfigData, BlockData(ct).Name);
                StringCell = ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog.ValueDisplayFcn(BlockData(ct).getValue, true);
                this.Widgets.BlocksTab.Value(ct).Value = StringCell{1};
            end
            
            enableUIListeners(this);
        end
        
        function cbOkClicked(this)
            isUpdateSuccessful = updateArchitecture(this);
            if isUpdateSuccessful
                cbCancelClicked(this);
            end                
        end
    end
    
    %% Public methods
    methods (Access = public)
        function updateUI(this)
            if ~this.isInitialized
                w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
                this.LocalConfigData = copyArch(this.ConfigData);
                setArchitecture(this.LinearizationOptionsTC,this.LocalConfigData);
                if ~isempty(this.AddTunableBlockDialog) && isvalid(this.AddTunableBlockDialog)
                    updateData(this.AddTunableBlockDialog,this.LocalConfigData);
                end
                warning(w);
                unregisterDataListeners(this);
                createDataListeners(this);
            end
            updateWidgets(this);
            this.isInitialized = true;
        end
    end
    
    methods (Access = public)
        function updateSignals(this)
            % Locations
            SignalData = getAvailableSignals(this.LocalConfigData);
            createLocationsListPnl(this);
            for ct = 1:numel(SignalData)
                this.Widgets.SignalsTab.Locations.Identifier(ct).Text = SignalData{ct};
            end
            
            % Openings
            SignalData = getOpenings(this.LocalConfigData);
            createOpeningsListPnl(this);
            
            for ct = 1:numel(SignalData)
                this.Widgets.SignalsTab.Openings.Identifier(ct).Text = SignalData{ct};
            end
        end
        
        function isUpdateSuccessful = updateArchitecture(this)
            % Cursor
            ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(true,getWidget(this));
            drawnow;
            
            % Status
            if ~isempty(this.EventManager)
                postActionStatus(this.EventManager, 'on', getString(message('Control:designerapp:updateArchitecture')));
            end
            
            delete(this.ArchitectureListener);
            
            w = warning('off','MATLAB:callback:error');
            isUpdateSuccessful = false;
            try
                % BLOCKS
                % Cache uncorrupted linearization options for setting it
                % back in case of any errors
                CurrentOptions = this.ConfigData.getLinearizationOptions;
                
                
                % Evaluate value text-boxes for any value changes
                for ct = 1:numel(this.Widgets.BlocksTab.Identifier)
                    cbValueChanged(this, ct, 'rethrow');
                end
                
                
                % Linearization options
                setLinearizationOptions(this.ConfigData,this.LocalConfigData.getLinearizationOptions);
                
                % Operating Points
                % Cache operating points to set them back in case of any
                % errors
                this.ConfigData.setOPPicker(this.OPPicker);
                op = this.LocalConfigData.getOperatingPoints;
                setOperatingPoints(this.ConfigData,op);
                
                OriginalTunedBlocks = this.ConfigData.getTunedBlocks;
                NewTunedBlocks =  this.LocalConfigData.getTunedBlocks;
                
                % Get old and new block names
                OriginalBlockNames = arrayfun(@(x)x.Name,OriginalTunedBlocks , 'UniformOutput', false);
                NewBlockNames = arrayfun(@(x)x.Name,NewTunedBlocks, 'UniformOutput', false);
                
                % Setdiff to find out which blocks need to be removed
                BlocksToBeRemoved = setdiff(OriginalBlockNames, NewBlockNames);
                
                % Remove blocks
                for ct = numel(BlocksToBeRemoved):-1:1
                    removeBlock(this.ConfigData, getBlockPath(this.ConfigData, BlocksToBeRemoved{ct}));
                end
                
                % add all the blocks and set block value
                NewBlockPath = getBlockPath(this.LocalConfigData);
                addTunableBlock(this.ConfigData, NewBlockPath);
                for ct = 1:numel(NewBlockNames)
                    % Value needs to be gotten from tunedblock's Data_, otherwise
                    % parameters are not computed correctly
                    if isTunable(this.LocalConfigData.getTunedBlocks(NewBlockNames{ct}))
                        NewValue = this.LocalConfigData.getTunedBlocks(NewBlockNames{ct}).getValue;
                        CurrentBlock = this.ConfigData.getTunedBlocks(NewBlockNames{ct});
                        OldValue = CurrentBlock.getValue;
                        if ~isequal(OldValue, NewValue)
                            % Only set the value if it changed - otherwise,
                            % pzgroups get scrapped for no reason
                            setValue(CurrentBlock, NewValue);
                        end
                    end
                end
                
                % Locations to be added and removed
                OriginalLocations = getAvailableSignals(this.ConfigData);
                NewLocations = getAvailableSignals(this.LocalConfigData);
                LocationsToBeAdded = ctrlguis.csdesignerapp.utils.internal.newOrCommonItemsInList(NewLocations,OriginalLocations);
                LocationsToBeRemoved = ctrlguis.csdesignerapp.utils.internal.newOrCommonItemsInList(OriginalLocations, NewLocations);
                
                for ct=1:length(LocationsToBeAdded)
                    % Find the signal delimiter
                    SignalName = LocationsToBeAdded{ct};
                    ind = strfind(SignalName,'[');
                    if isempty(ind)
                        ind = numel(SignalName)+1;
                    end
                    SignalName = SignalName(1:ind(1)-1);
                    addSignal(this.ConfigData, SignalName);
                end
                
                for ct = 1:length(LocationsToBeRemoved)
                    removeSignal(this.ConfigData, LocationsToBeRemoved);
                end
                
                
                % Openings to be added and removed
                OriginalOpenings = getOpenings(this.ConfigData);
                NewOpenings = getOpenings(this.LocalConfigData);
                OpeningsToBeAdded = ctrlguis.csdesignerapp.utils.internal.newOrCommonItemsInList(NewOpenings,OriginalOpenings);
                OpeningsToBeRemoved = ctrlguis.csdesignerapp.utils.internal.newOrCommonItemsInList(OriginalOpenings, NewOpenings);
                
                for ct = 1:numel(OpeningsToBeAdded)
                    SignalName = OpeningsToBeAdded{ct};
                    ind = strfind(SignalName,'[');
                    if isempty(ind)
                        ind = numel(SignalName)+1;
                    end
                    SignalName = SignalName(1:ind(1)-1);
                    addOpening(this.ConfigData, SignalName);
                end
                
                removeOpening(this.ConfigData, OpeningsToBeRemoved);
                
                % Validate everything once
                this.ConfigData.getCL;
                this.ConfigData.notify('SystemChanged');
                
                % Status
                if ~isempty(this.EventManager)
                    clearActionStatus(this.EventManager);
                end
                
                % Cursor
                ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,getWidget(this));
                
                %                 cancelUpdate(this);
                warning(w);
                isUpdateSuccessful = true;
            catch ME
                this.LocalConfigData.setLinearizationOptions(CurrentOptions);
                delete(this.LinearizationOptionsPnl);
                createLinearizationOptionsPnl(this);
                update(this.LinearizationOptionsPnl);
                uialert(this.UIFigure,ME.message,...
                    getString(message('Control:designerapp:strToolTitleShort')));
                % Status
                if ~isempty(this.EventManager)
                    clearActionStatus(this.EventManager);
                end
                
                % Cursor
                this.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,getWidget(this),this.WaitBar);
                this.ArchitectureListener = addlistener(this.ConfigData,'SystemChanged',@(es,ed) cbCancelClicked(this));
                enableUIListeners(this);
                warning(w);
            end
            
        end
        
        function closeAddTunableBlockDialog(this)
            if ~isempty(this.AddTunableBlockDialog) && isvalid(this.AddTunableBlockDialog)
                close(this.AddTunableBlockDialog);
            end
        end
        
        function close(this)
            closeAddTunableBlockDialog(this);
            closeAllDialogs(this.OPPicker);
            close@controllib.ui.internal.dialog.AbstractDialog(this);
        end
        
        function delete(this)
            localCheckAndDelete(this.AddTunableBlockDialog);
            localCheckAndDelete(this.AddLocationsDialog);
            localCheckAndDelete(this.AddOpeningsDialog);
            localCheckAndDelete(this.LinearizationOptionsTC);
            localCheckAndDelete(this.OPPicker);
        end
    end
    
    methods (Hidden = true)
        function BlkDlg = qeGetBlockDialog(this)
            BlkDlg = this.AddTunableBlockDialog;
        end

        function dlg = qeGetAddLocationsDialog(this)
            dlg = this.AddLocationsDialog;
        end
        
        function dlg = qeGetAddOpeningsDialog(this)
            dlg = this.AddOpeningsDialog;
        end
        
        function status = qeGetHighlightBlockStatus(this)
            status = this.HighlightBlockStatus;
        end
        
        function status = qeGetHighlightSignalStatus(this)
            status = this.HighlightSignalStatus;
        end
        
        function qeSetHighlightBlockStatus(this,status)
            if islogical(status)
                this.HighlightBlockStatus = status;
            end
        end
        
        function qeSetHighlightSignalStatus(this,status)
            if islogical(status)
                this.HighlightSignalStatus = status;
            end
        end
    end
    
    %% Static methdods
    methods (Static)
        function op = getOperatingPointFromSelection(OpSelection)
            
            switch OpSelection.Type
                case 'Snapshot'
                    op = slctrlguis.lintool.evalSnapshotVector(OpSelection.Data);
                case 'Model'
                    op = [];
                case 'Existing'
                    Workspace = OpSelection.Data.Workspace;
                    VariableName = OpSelection.Data.VariableName;
                    op = evalin(Workspace,VariableName);
                case 'Multiple'
                    op = [];
                    VarFrom = OpSelection.Data.From;
                    Workspace = OpSelection.Data.Workspace;
                    VariableName = OpSelection.Data.VariableName;
                    for ct=1:length(VariableName)
                        OpData = evalin(Workspace{VarFrom(ct)},VariableName{ct}); % general op data
                        op = vertcat(op,opcond.createOPFromSpecOrReport(OpData)); % get the operating point
                    end
            end
            
        end
        
        function boo = isConstrained(Blocks)
            boo = false(size(Blocks));
            for ct=1:numel(Blocks)
                % Checks if compensator has constraints
                Constraints = Blocks(ct).getConstraints;
                FixedDynamics = Blocks(ct).FixedDynamics;
                if ~isempty(Constraints) && (isfinite(Constraints.MaxZeros) || isfinite(Constraints.MaxPoles) || ...
                        ~(isempty(FixedDynamics) || isstatic(FixedDynamics)))
                    boo(ct) = true;
                end
            end
        end
    end
end

function localCheckAndDelete(widget)
if ~isempty(widget) && isvalid(widget)
    delete(widget);
end
end
