classdef Configuration1Dlg < ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog
    % Dialog to edit the architecture (Configuration 1)
    
    % Copyright 2014-2020 The MathWorks, Inc.
    
    %% Properties    
    properties (Access = public)
        NewArchitecture = false;
    end
    
    properties (Access = private)
        % Sign Identifiers
        SignData
        Config1Data
        Config2Data
        Config3Data
        Config4Data
        Config5Data
        Config6Data
    end
    
    %% Events
    events
        NewArchitectureCreated
    end
    
    %% Constructor
    methods        
        function dlg = Configuration1Dlg(ConfigData)
            % Super class constructor
            dlg = dlg@ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog(ConfigData);
            switch  getConfiguration(dlg.ConfigData)
                case 1
                    dlg.Config1Data = dlg.LocalConfigData;
                case 2
                    dlg.Config2Data = dlg.LocalConfigData;
                case 3
                    dlg.Config3Data = dlg.LocalConfigData;
                case 4
                    dlg.Config4Data = dlg.LocalConfigData;
                case 5
                    dlg.Config5Data = dlg.LocalConfigData;
                case 6
                    dlg.Config6Data = dlg.LocalConfigData;
            end
            
            % Hardcoded loop sign identifier
            dlg.SignData.Identifier = {'S1'};
        end        
    end
    
    %% Public methods.
    methods (Access = public)        
        function updateUI(dlg)
            disableUIListeners(dlg);
            if ~dlg.isInitialized
                dlg.LocalConfigData = copyArch(dlg.ConfigData);
                addBlockChangedListeners(dlg)
                registerDataListeners(dlg,...
                    addlistener(dlg.LocalConfigData,'SystemChanged',@(es,ed)updateWidgets(dlg)), ...
                    'LocalConfigChanged' ...
                    );
                dlg.isInitialized = true;
            end
            
            updateWidgets(dlg);
            enableUIListeners(dlg)
        end
    end
    
    %% Protected methods    
    methods (Access = protected)
        function Title = getTitle(this)
            Title = getString(message('Control:designerapp:strEditMatlabArchitecture', ...
                this.LocalConfigData.getConfiguration));
        end
        
        function selectionPanel = createConfigurationSelectionPanel(dlg)
            % Create configuration selection widget.
            
            % Create selection panel.
            selectionPanel = uipanel('Parent',[],'BorderType','none', ...
                'Tag','SelectionPanel');

            % Create panel layout. First row is for the panel title, next 6
            % rows are used for the selection buttons and the last row is
            % used to fillup the gap when increasing height of the dialog.
            numConfig = 6;
            columnWidth = 149;
            buttonRowHeight = 57;
            selectionPanelLayout = uigridlayout(selectionPanel,[8 1], ...
                'Scrollable','on','Tag','SelectionPanelLayout');
            selectionPanelLayout.ColumnSpacing = 0;
            selectionPanelLayout.RowSpacing = 0;
            selectionPanelLayout.RowHeight = [{'fit'} ...
                repmat({buttonRowHeight},[1 numConfig]) {'1x'}];
            selectionPanelLayout.ColumnWidth = {columnWidth};
            selectionPanelLayout.Padding = 0;
            dlg.Widgets.SelectionPanelLayout = selectionPanelLayout;
                                   
            % Create a separate label to specify the title of the panel. We
            % could use the panel title, however, the separate label helps
            % auto-width adjustment of the panel to the title width.
            selectionPanelLabel = uilabel(selectionPanelLayout,...
                'Text',getString(message('Control:compDesignTask:strSelectArchitectureLabel')), ...
                'Tag','SelectionPanelLabel');
            selectionPanelLabel.Layout.Row = 1;
            selectionPanelLabel.Layout.Column = 1;
            dlg.Widgets.SelectionPanelLabel = selectionPanelLabel;
            
            % Toggle button group.
            buttonGroup = uibuttongroup(selectionPanelLayout,'Tag','ButtonGroup');
            buttonGroup.Layout.Row = [2 7];
            buttonGroup.Layout.Column = 1;
            buttonGroup.SelectionChangedFcn = @(es,ed)changeArchitecture(dlg,ed);
            buttonGroup.Units = 'pixels';
            dlg.Widgets.ButtonGroup = buttonGroup;
            
            selectionPanelConfigButtons = repmat(uitogglebutton('Parent',[]),[numConfig 1]);
            for ct = 1:numConfig
                icon = ctrlguis.csdesignerapp.Icon.(sprintf('CONFIGURATION_%d_THUMB',ct));
                selectionPanelConfigButtons(ct) = uitogglebutton(buttonGroup,...
                    'Text','','Icon',icon.Description, ...
                    'Tag',['SelectionPanelConfigButtons' num2str(ct)]);
                selectionPanelConfigButtons(ct).Position(1) = 1;
                selectionPanelConfigButtons(ct).Position(3) = columnWidth;
                selectionPanelConfigButtons(ct).Position(4) = buttonRowHeight;
                selectionPanelConfigButtons(ct).UserData = ct;
                if ct>1
                    selectionPanelConfigButtons(ct).Position(2) = ...
                        selectionPanelConfigButtons(ct-1).Position(2)-buttonRowHeight;
                else
                    selectionPanelConfigButtons(ct).Position(2) = 5*buttonRowHeight;
                end
            end
            currentConfig = dlg.LocalConfigData.getConfiguration;
            selectionPanelConfigButtons(currentConfig).Value = 1;
            
            dlg.Widgets.SelectionPanelConfigButtons = selectionPanelConfigButtons;
        end
        
        function tabs = getTabPnls(dlg)
            % Create blocks tab
            tabs(1) = createBlocksTab(dlg);
            tabs(2) = createLoopSignsTab(dlg);
        end
        
        function purposePanel = getPurposePanel(dlg)
            % Construct and return purpose panel handle.
            
            % Create panel
            purposePanel = uipanel('Parent',[],'Tag','PurposePanel');
            purposePanel.BorderType = 'none';
            
            % Create panel layout
            purposePanelLayout = uigridlayout(purposePanel,[1 1], ...
                'Scrollable','on','Tag','PurposePanelLayout');
            purposePanelLayout.ColumnSpacing = 0;
            purposePanelLayout.RowSpacing = 0;
            purposePanelLayout.Padding = 5;
            purposePanelLayout.RowHeight = {160};
            purposePanelLayout.ColumnWidth = {485};
            
            % Add icon
            icon = getArchitectureIcon(dlg.LocalConfigData);
            purposePanelImage = uiimage(purposePanelLayout, ...
                'ImageSource',icon.Description,'ScaleMethod','stretch', ...
                'Tag','PurposePanelImage');
            purposePanelImage.Layout.Row = 1;
            purposePanelImage.Layout.Column = 1;
            
            % Update widget.
            dlg.Widgets.PurposePanelLayout = purposePanelLayout;            
            dlg.Widgets.PurposePanelImage = purposePanelImage;            
        end
        
        function cbLoopSignsChanged(this,ct)
            ID = this.Widgets.LoopSignsTab.Identifier(ct).Text;
            Value = this.Widgets.LoopSignsTab.Sign(ct).Value;
            
            setLoopSignWithID(this.LocalConfigData, ID, Value);
        end
        
        function addBlockChangedListeners(dlg)
            blocks = getBlocks(dlg.LocalConfigData);
            for ct = 1:numel(blocks)
                registerDataListeners(dlg,addlistener(blocks{ct},'ValueChanged', ...
                    @(es,ed)updateWidgets(dlg)),getIdentifier(blocks{ct}))
            end
        end
        
        function cbHelpClicked(dlg) %#ok<MANU>
            % Open help window
            
            ctrlguihelp('CSD_MatlabArchitectureHelp','CSHelpWindow');
        end
        
        function cbOkClicked(dlg)
            
            % Set busy cursor
            progressDlg = uiprogressdlg(getWidget(dlg),...
                Message=getString(message('Control:designerapp:updateArchitecture')),...
                Title=getString(message('Control:designerapp:EditArchitectureTitle')),...
                Indeterminate=true);
            % dlg.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(true,dlg.getWidget,dlg.WaitBar);
            
            % Status
            if ~isempty(dlg.EventManager)
                postActionStatus(dlg.EventManager, 'on', getString(message('Control:designerapp:updateArchitecture')));
            end
            % BLOCKS
            % Evaluate value text-boxes for any value changes
            try
                for ct = 1:numel(dlg.Widgets.BlocksTab.Name)
                    cbValueChanged(dlg,ct)
                    cbNameChanged(dlg,ct)
                end
                validateFixedBlocks(dlg.LocalConfigData);
                validateSampleTime(dlg.LocalConfigData);
                % Compute the closed loop to verify everything is valid
                getCL(dlg.LocalConfigData);
                if dlg.ConfigData.getConfiguration ~= dlg.LocalConfigData.getConfiguration
                    % Set designerdata architecture
                    unregisterDataListeners(dlg,'ConfigDeleted')
                    dlg.ConfigData = copyArch(dlg.LocalConfigData);
                    registerDataListeners(dlg,...
                        addlistener(dlg.ConfigData, 'ObjectBeingDestroyed', @(es,ed)delete(dlg)), ...
                        'ConfigDeleted' ...
                        );
                    
                    ed = controllib.app.internal.GenericEventData(dlg.ConfigData);
                    notify(dlg,'NewArchitectureCreated',ed);
                else
                    % Blocks
                    % Get blocks from local and actual configuration
                    localBlks = getBlocks(dlg.LocalConfigData);
                    blks = getBlocks(dlg.ConfigData);
                    
                    % Pass values and names to actual configuration
                    for ct = 1:numel(blks)
                        valueToSet = getValue(localBlks{ct});
                        if ~isequal(getValue(blks{ct}),valueToSet)
                            % Only set the value if it changed - otherwise,
                            % pzgroups get scrapped for no reason
                            setValue(blks{ct}, getValue(localBlks{ct}),'NoEvent');
                        end
                        blks{ct}.Name = localBlks{ct}.Name;
                    end
                    
                    % Loop signs
                    % Get loopsigns from local configuration
                    loopSign = getLoopSignWithID(dlg.LocalConfigData);
                    % Pass loopsigns to actual configuration
                    for ct = 1:size(loopSign,1)
                        setLoopSignWithID(dlg.ConfigData, loopSign{ct,1}, loopSign{ct,2});
                    end
                end
                removeBlockChangedListeners(dlg)
                unregisterDataListeners(dlg,'LocalConfigChanged')
                delete(dlg.LocalConfigData)                
                dlg.isInitialized = false;
                dlg.ConfigData.updateArchitecture();
                % Close
                % Status
                if ~isempty(dlg.EventManager)
                    clearActionStatus(dlg.EventManager);
                end
                % Reset cursor to regular mode.
                delete(progressDlg);
                % dlg.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,dlg.getWidget,dlg.WaitBar);

                % Close Import dialogs
                for k = 1:numel(dlg.ImportDlgHandles)
                    close(dlg.ImportDlgHandles(k))
                end

                close(dlg);
            catch ME
                updateBlocks(dlg);
                uialert(dlg.UIFigure,ME.message,dlg.Title);
                % Status
                if ~isempty(dlg.EventManager)
                    clearActionStatus(dlg.EventManager);
                end
                % Reset cursor to regular mode.
                delete(progressDlg);
                % dlg.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,dlg.getWidget,dlg.WaitBar);
            end
        end        
        
        function updateBlocks(dlg)

            blocks = getBlocks(dlg.LocalConfigData);
            numBlocks = numel(blocks);
            preNumBlocks = length(dlg.Widgets.BlocksTab.Layout.RowHeight) - 1;
            
            if preNumBlocks ~= numBlocks
                dlg.Widgets.BlocksTab.Layout.RowHeight = [{'fit'} repmat({'fit'},[1 numBlocks])];
            end

            if numBlocks < preNumBlocks
                idx = numBlocks+1:preNumBlocks;
                delete(dlg.Widgets.BlocksTab.Identifier(idx))
                delete(dlg.Widgets.BlocksTab.Name(idx))
                delete(dlg.Widgets.BlocksTab.Value(idx))
                delete(dlg.Widgets.BlocksTab.Import(idx))
                
                dlg.Widgets.BlocksTab.Identifier(idx) = [];
                dlg.Widgets.BlocksTab.Name(idx) = [];
                dlg.Widgets.BlocksTab.Value(idx) = [];
                dlg.Widgets.BlocksTab.Import(idx) = [];
            end
            

            if numBlocks > preNumBlocks
                for i = preNumBlocks+1:numBlocks
                    row = i + 1;   
                    
                    dlg.Widgets.BlocksTab.Identifier = [dlg.Widgets.BlocksTab.Identifier ...
                        uilabel(dlg.Widgets.BlocksTab.Layout,'Tag',['BlocksTabIdentifier' num2str(i)])];
                    dlg.Widgets.BlocksTab.Identifier(i).Layout.Row = row;
                    dlg.Widgets.BlocksTab.Identifier(i).Layout.Column = 1;

                    dlg.Widgets.BlocksTab.Name = [dlg.Widgets.BlocksTab.Name ...
                        uieditfield(dlg.Widgets.BlocksTab.Layout,'Tag',['BlocksTabName' num2str(i)])];
                    dlg.Widgets.BlocksTab.Name(i).Layout.Row = row;
                    dlg.Widgets.BlocksTab.Name(i).Layout.Column = 2;
                    dlg.Widgets.BlocksTab.Name(i).ValueChangedFcn = @(es,ed)cbNameChanged(dlg,i);
                    
                    dlg.Widgets.BlocksTab.Value = [dlg.Widgets.BlocksTab.Value ...
                        uieditfield(dlg.Widgets.BlocksTab.Layout,'Tag',['BlocksTabValue' num2str(i)])];
                    dlg.Widgets.BlocksTab.Value(i).Layout.Row = row;
                    dlg.Widgets.BlocksTab.Value(i).Layout.Column = 3;
                    dlg.Widgets.BlocksTab.Value(i).ValueChangedFcn = @(es,ed)cbValueChanged(dlg,i);
                    
                    btn = uibutton(dlg.Widgets.BlocksTab.Layout,'Text','', ...
                        'IconAlignment','center','Tag',['BlocksTabImport' num2str(i)]);
                    matlab.ui.control.internal.specifyIconID(btn, 'import_data', 16);
                    dlg.Widgets.BlocksTab.Import = [dlg.Widgets.BlocksTab.Import ...
                        btn];
                    dlg.Widgets.BlocksTab.Import(i).Layout.Row = row;
                    dlg.Widgets.BlocksTab.Import(i).Layout.Column = 4;
                    dlg.Widgets.BlocksTab.Import(i).ButtonPushedFcn = @(es,ed)cbImportClicked(dlg,i);                    
                end
            end            
            
            for ct = 1:numel(blocks)
                dlg.Widgets.BlocksTab.Identifier(ct).Text = getIdentifier(blocks{ct});
                dlg.Widgets.BlocksTab.Name(ct).Value = blocks{ct}.Name;
                
                stringCell = ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog.ValueDisplayFcn(blocks{ct}.getValue, true);
                dlg.Widgets.BlocksTab.Value(ct).Value = stringCell{2};
            end
        end
        
        function updateWidgets(dlg)
            
            disableUIListeners(dlg);
            
            % Title
            dlg.Title = getTitle(dlg);
            
            % Update selection panel. 
            currentConfig = dlg.LocalConfigData.getConfiguration;
            dlg.Widgets.SelectionPanelConfigButtons(currentConfig).Value = 1;
            
            % Update purpose panel image if configuration changed.
            icon = getArchitectureIcon(dlg.LocalConfigData);
            if ~strcmp(dlg.Widgets.PurposePanelImage.ImageSource,icon.Description)
                dlg.Widgets.PurposePanelImage.ImageSource = icon.Description;
            end
                        
            % Blocks
            updateBlocks(dlg)
            
            % Loop signs
            updateLoopSigns(dlg)
            
            % Uncomment the following code when pack() is available.
            %if dlg.IsWidgetValid
            %    pack(dlg);
            %end
            
            enableUIListeners(dlg);
        end        
    end
    
    %% Private methods
    methods(Access=private)
        function changeArchitecture(dlg,ed)
            dlg.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(true,dlg.getWidget,dlg.WaitBar);
            
            ct = ed.NewValue.UserData;
            if dlg.LocalConfigData.getConfiguration ~= ct
                dlg.Widgets.SelectionPanelConfigButtons(dlg.LocalConfigData.getConfiguration).Value = 0;
                oldData = dlg.LocalConfigData;
                removeBlockChangedListeners(dlg)
                unregisterDataListeners(dlg,'LocalConfigChanged')
                                
                switch  ct
                    case 1
                        if isempty(dlg.Config1Data) || ~isvalid(dlg.Config1Data)
                            dlg.Config1Data = ctrlguis.csdesignerapp.data.architectures.internal.Config1Architecture(ss(1),ss(1),ss(1),ss(1));
                        end
                        dlg.LocalConfigData = dlg.Config1Data;
                    case 2
                        if isempty(dlg.Config2Data) || ~isvalid(dlg.Config2Data)
                            dlg.Config2Data = ctrlguis.csdesignerapp.data.architectures.internal.Config2Architecture(ss(1),ss(1),ss(1),ss(1));
                        end
                        dlg.LocalConfigData = dlg.Config2Data;
                    case 3
                        if isempty(dlg.Config3Data) || ~isvalid(dlg.Config3Data)
                            dlg.Config3Data = ctrlguis.csdesignerapp.data.architectures.internal.Config3Architecture(ss(1),ss(1),ss(1),ss(1));
                        end
                        dlg.LocalConfigData = dlg.Config3Data;
                    case 4
                        if isempty(dlg.Config4Data) || ~isvalid(dlg.Config4Data)
                            dlg.Config4Data = ctrlguis.csdesignerapp.data.architectures.internal.Config4Architecture(ss(1),ss(1),ss(1),ss(1));
                        end
                        dlg.LocalConfigData = dlg.Config4Data;
                    case 5
                        if isempty(dlg.Config5Data) || ~isvalid(dlg.Config5Data)
                            dlg.Config5Data = ctrlguis.csdesignerapp.data.architectures.internal.Config5Architecture(ss(1),ss(1),ss(1),ss(1),ss(1));
                        end
                        dlg.LocalConfigData = dlg.Config5Data;
                    case 6
                        if isempty(dlg.Config6Data) || ~isvalid(dlg.Config6Data)
                            dlg.Config6Data = ctrlguis.csdesignerapp.data.architectures.internal.Config6Architecture(ss(1),ss(1),ss(1),ss(1),ss(1),ss(1),ss(1));
                        end
                        dlg.LocalConfigData = dlg.Config6Data;
                end
                                
                % Try to map values to the new configuraiton
                oldBlocks = oldData.getBlocks;
                oldID = cellfun(@(x)getIdentifier(x),oldData.getBlocks,'UniformOutput',false);
                newID = cellfun(@(x)getIdentifier(x),dlg.LocalConfigData.getBlocks,'UniformOutput',false);
                
                [commonBlocks,iOld] = intersect(oldID,newID);
                
                for ct = 1:numel(commonBlocks)
                    setBlockValue(dlg.LocalConfigData, commonBlocks{ct}, getValue(oldBlocks{iOld(ct)}));
                end
                
                dlg.Title = getTitle(dlg);
                dlg.NewArchitecture = true;
                createDataListeners(dlg);
                registerDataListeners(dlg,...
                    addlistener(dlg.LocalConfigData,'SystemChanged',@(es,ed)updateWidgets(dlg)), ...
                    'LocalConfigChanged' ...
                    );                
                addBlockChangedListeners(dlg)
                updateUI(dlg);
                
                dlg.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,dlg.getWidget,dlg.WaitBar);
            end
        end
                        
        function blocksTab = createBlocksTab(dlg)
            % Add listener to TableChanged

            import ctrlguis.csdesignerapp.dialogs.internal.AbstractArchitectureDialog
            
            % Create tab.
            blocksTab = uitab(dlg.Widgets.TabbedPanel,...
                'Title',getString(message('Control:designerapp:strBlocksTabTitle')), ...
                'Tag','BlocksTab');
            dlg.Widgets.BlocksTab.Tab = blocksTab;
            
            % Create tab layout.
            blocks = getBlocks(dlg.LocalConfigData);
            numBlocks = numel(blocks);
            blocksTabLayout = uigridlayout(blocksTab,[numBlocks+1 5],'Scrollable','on', ...
                'Tag','BlocksTabLayout');
            blocksTabLayout.ColumnSpacing = 5;
            blocksTabLayout.RowSpacing = 5;
            blocksTabLayout.RowHeight = [{'fit'} repmat({'fit'},[1 numBlocks])];
            blocksTabLayout.ColumnWidth = {'fit',180,180,25,10};
            blocksTabLayout.Padding = 5;
            dlg.Widgets.BlocksTab.Layout = blocksTabLayout;
            
            % Titles
            labelTitle = uilabel(blocksTabLayout, ...
                'Text',getString(message('Control:designerapp:strBlockIdentifier')), ...
                'Tag','BlocksTabLabelTitle');
            labelTitle.Layout.Row = 1;
            labelTitle.Layout.Column = 1;            
            dlg.Widgets.BlocksTab.LabelTitle = labelTitle;
            
            nameTitle = uilabel(blocksTabLayout, ...
                'Text',getString(message('Control:designerapp:strBlockName')), ...
                'Tag','BlocksTabNameTitle');
            nameTitle.Layout.Row = 1;
            nameTitle.Layout.Column = 2;            
            dlg.Widgets.BlocksTab.NameTitle = nameTitle;
            
            valueTitle = uilabel(blocksTabLayout, ...
                'Text',getString(message('Control:designerapp:strBlockValue')), ...
                'Tag','BlocksTabValueTitle');
            valueTitle.Layout.Row = 1;
            valueTitle.Layout.Column = 3;            
            dlg.Widgets.BlocksTab.ValueTitle = valueTitle;
                        
            % For each block, create the following components:
            %     - Label for identifier,
            %     - Edit field for Name, 
            %     - Edit field for Value, and 
            %     - Import button.            
            blockIdentifier = repmat(uilabel('Parent',[]),[1 numBlocks]);
            blockName = repmat(uieditfield('Parent',[]),[1 numBlocks]);
            blockValue = repmat(uieditfield('Parent',[]),[1 numBlocks]);
            importButton = repmat(uibutton('Parent',[]),[1 numBlocks]);
            for ct = 1:numBlocks                
                row = ct + 1;
                
                blockId = blocks{ct}.getIdentifier();                
                blockIdentifier(ct) = uilabel(blocksTabLayout,'Text',blockId, ...
                    'Tag',['BlocksTabIdentifier' num2str(ct)]);
                blockIdentifier(ct).Layout.Row = row;
                blockIdentifier(ct).Layout.Column = 1;
                dlg.Widgets.BlocksTab.Identifier(ct) = blockIdentifier(ct);
                
                blockName(ct) = uieditfield(blocksTabLayout,'Value',blockId, ...
                    'Tag',['BlocksTabName' num2str(ct)]);
                blockName(ct).Layout.Row = row;
                blockName(ct).Layout.Column = 2;
                blockName(ct).ValueChangedFcn = @(es,ed)cbNameChanged(dlg,ct);
                dlg.Widgets.BlocksTab.Name(ct) = blockName(ct);
                
                value = AbstractArchitectureDialog.ValueDisplayFcn(blocks{ct}.getValue,true);                
                blockValue(ct) = uieditfield(blocksTabLayout,'Value',value{2}, ...
                    'Tag',['BlocksTabValue' num2str(ct)]);
                blockValue(ct).Layout.Row = row;
                blockValue(ct).Layout.Column = 3;
                blockValue(ct).ValueChangedFcn = @(es,ed)cbValueChanged(dlg,ct);
                dlg.Widgets.BlocksTab.Value(ct) = blockValue(ct);
                
                importButton(ct) = uibutton(blocksTabLayout,'Text','', ...
                    'IconAlignment','center', ...
                    'Tag',['BlocksTabImport' num2str(ct)]);
                matlab.ui.control.internal.specifyIconID(importButton(ct),'import_data',16);

                importButton(ct).Layout.Row = row;
                importButton(ct).Layout.Column = 4;
                importButton(ct).ButtonPushedFcn = @(es,ed)cbImportClicked(dlg,ct);
                dlg.Widgets.BlocksTab.Import(ct) = importButton(ct);                
            end
        end
        
        function loopSignsTab = createLoopSignsTab(dlg)
            % Construct loop sign widget.
            
            % Create tab.
            loopSignsTab = uitab(dlg.Widgets.TabbedPanel, ...
                'Title',getString(message('Control:designerapp:strLoopSignsTabTitle')), ...
                'Tag','LoopSignsTab');
            dlg.Widgets.LoopSignsTab.Tab = loopSignsTab;
            
            % Create tab layout.
            signals = getLoopSignWithID(dlg.LocalConfigData);
            numSignals = size(signals,1);
            loopSignsTabLayout = uigridlayout(loopSignsTab,[numSignals+1 2],'Scrollable','on', ...
                'Tag','LoopSignsTabLayout');
            loopSignsTabLayout.ColumnSpacing = 5;
            loopSignsTabLayout.RowSpacing = 5;
            loopSignsTabLayout.RowHeight = [{'fit'} repmat({'fit'},[1 numSignals])];
            loopSignsTabLayout.ColumnWidth = {'fit','fit'};
            loopSignsTabLayout.Padding = 5;
            dlg.Widgets.LoopSignsTab.Layout = loopSignsTabLayout;
            
            
            % Titles
            labelTitle = uilabel(loopSignsTabLayout, ...
                'Text',getString(message('Control:designerapp:strBlockIdentifier')), ...
                'Tag','LoopSignsTabLabelTitle');
            labelTitle.Layout.Row = 1;
            labelTitle.Layout.Column = 1;
            dlg.Widgets.LoopSignsTab.LabelTitle = labelTitle;
            
            nameTitle = uilabel(loopSignsTabLayout,...
                'Text',getString(message('Control:designerapp:strLoopSignName')), ...
                'Tag','LoopSignsTabNameTitle');
            nameTitle.Layout.Row = 1;
            nameTitle.Layout.Column = 2;
            dlg.Widgets.LoopSignsTab.NameTitle = nameTitle;
            
            % For each loop sign, create the following two components:
            %     - Label for identifier and
            %     - combo-box for Name
            
            % Remove widgets that are no longer valid
            if numSignals == 0
                delete(dlg.Widgets.LoopSignsTab.Identifier)
                dlg.Widgets.LoopSignsTab.Identifier = [];
                delete(dlg.Widgets.LoopSignsTab.Sign)
                dlg.Widgets.LoopSignsTab.Sign  = [];
                
                return
            end
            
            % Create components and the required number of rows in the grid
            label = repmat(uilabel('Parent',[]),[1 numSignals]);
            name = repmat(uidropdown('Parent',[]),[1 numSignals]);
            for ct = 1:numSignals
                
                row = ct + 1;
                % Identifier Label
                label(ct) = uilabel(loopSignsTabLayout,'Text',signals{ct,1},...
                    'Tag',['LoopSignsTabIdentifier' num2str(ct)]);
                label(ct).Layout.Row = row;
                label(ct).Layout.Column = 1;
                dlg.Widgets.LoopSignsTab.Identifier(ct) = label(ct);
                
                % Name Text
                name(ct) = uidropdown(loopSignsTabLayout,'Items',{'+','-'},'Value',signals{ct,2}, ...
                    'Tag',['WidgetsLoopSignsTabSign' num2str(ct)]);
                name(ct).Layout.Row = row;
                name(ct).Layout.Column = 2;
                name(ct).ValueChangedFcn = @(es,ed) cbLoopSignsChanged(dlg,ct);
                dlg.Widgets.LoopSignsTab.Sign(ct) = name(ct);
            end
        end
                
        function cbNameChanged(dlg,ct)
            % Callback function to update block name.
            
            id = dlg.Widgets.BlocksTab.Identifier(ct).Text;
            name = dlg.Widgets.BlocksTab.Name(ct).Value;
            dlg.LocalConfigData.setBlockName(id,name);
        end
        
        function updateLoopSigns(dlg)
            % Updates loop signs when configuration is changed.
            
            % Get loop info.
            loops = getLoopSignWithID(dlg.LocalConfigData);
            numLoops = size(loops,1);
            preNumLoops = length(dlg.Widgets.LoopSignsTab.Layout.RowHeight)-1;

            % Update layout if the current number of loops is changed.
            if preNumLoops ~= numLoops
                dlg.Widgets.LoopSignsTab.Layout.RowHeight = [{'fit'} repmat({'fit'},[1 numLoops])];
            end
            
            % Remove widget components if the current loop number is less
            % than the previous loop number.
            if numLoops < preNumLoops
                idx = numLoops+1:preNumLoops;
                delete(dlg.Widgets.LoopSignsTab.Identifier(idx))
                delete(dlg.Widgets.LoopSignsTab.Sign(idx))
                
                dlg.Widgets.LoopSignsTab.Identifier(idx) = [];
                dlg.Widgets.LoopSignsTab.Sign(idx) = [];
            end
            
            % Add widget components if the current loop number is greater 
            % than the previous loop number.
            if numLoops > preNumLoops
                for i = preNumLoops+1:numLoops
                    row = i + 1;                    
                    dlg.Widgets.LoopSignsTab.Identifier = [dlg.Widgets.LoopSignsTab.Identifier ...
                        uilabel(dlg.Widgets.LoopSignsTab.Layout, ...
                        'Tag',['LoopSignsTabIdentifier' num2str(i)])];
                    dlg.Widgets.LoopSignsTab.Identifier(i).Layout.Row = row;
                    dlg.Widgets.LoopSignsTab.Identifier(i).Layout.Column = 1;

                    dlg.Widgets.LoopSignsTab.Sign = [dlg.Widgets.LoopSignsTab.Sign ...
                        uidropdown(dlg.Widgets.LoopSignsTab.Layout,'Items',{'+','-'},...
                        'Tag',['LoopSignsTabSign' num2str(i)])];
                    dlg.Widgets.LoopSignsTab.Sign(i).Layout.Row = row;
                    dlg.Widgets.LoopSignsTab.Sign(i).Layout.Column = 2;
                    dlg.Widgets.LoopSignsTab.Sign(i).ValueChangedFcn = @(es,ed) cbLoopSignsChanged(dlg,i);
                end
            end
            
            % Update loop names and signs.
            for i = 1:numLoops
                dlg.Widgets.LoopSignsTab.Identifier(i).Text = loops{i,1};
                dlg.Widgets.LoopSignsTab.Sign(i).Value = loops{i,2};
            end
        end        
    end    
end