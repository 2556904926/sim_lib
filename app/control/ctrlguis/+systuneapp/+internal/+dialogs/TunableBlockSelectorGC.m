classdef (Hidden) TunableBlockSelectorGC < ctrluis.AbstractGC
    %% Graphical component for Tunable Block selection.
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    %% Properties
    properties(Access=private)
        Widgets = struct(...
            'blockTable',[], ...
            'sideButtonPanel',struct(...
            'syncButton',[], ...
            'addButton',[], ...
            'editButton',[], ...
            'highlightButton',[], ...
            'removeButton',[]), ...
            'bottomButtonPanel',[], ...
            'addDialog',[], ...
            'editDialogWidgets',[] ...
            );
        SimulinkFlag        
    end
    
    properties(Hidden)
        BlockHighlighted = false;
    end
    
    %% Constructor/Destructor
    methods
        function this = TunableBlockSelectorGC(tcpeer)
            %% Constructs TunableBlockSelectorGC graphical component
            % Call parent constructor.
            this = this@ctrluis.AbstractGC(tcpeer);
            
            % Set property values ------------
            this.SimulinkFlag = isSimulink(this.TCPeer.Data.ControlDesignData);
            this.Name = 'TunableBlockSelectorDialog';
            this.Title = getString(message('Control:systunegui:TunableBlockSelectorTitle'));            
            % Default value of DeleteOnClose should be false in
            % ctrluis.AbstractGC. We need to run a qual job with
            % DeleteOnClose = false to check test regression and then take
            % action accordingly.
            this.DeleteOnClose = false;
        end
    end
    
    %% Public methods
    methods
        function updateUI(this)
            %% Updates UI.
            
            if ~this.IsWidgetValid
                return
            end

            pushDataFomTCToUI(this)
            enableButtonIfRowSelected(this)            
        end
        
        function show(this,varargin)
            %% Overloaded SHOW method to open ADD BLOCKS dialog.
            
            show@ctrluis.AbstractGC(this,varargin{:})
            if isempty(this.Widgets.blockTable.Data)
                cbAddButton(this)
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function buildUI(this)
            %% Builds UI.
            
            setDialogDimension(this)
            createDialogLayout(this)
            createBlockTable(this,1)
            createSideButtonPanel(this,2)
            createBottomButtonPanel(this)
        end
           
        function connectUI(this)
            %% Connects to event listeners.
            
            % Add a callback function to the CloseEvent to close any
            % launched dialogs.
            registerUIListeners(this,addlistener(this,'CloseEvent', ...
                @(src,data)closeOpenDialogs(this)))
        end
        
        function cleanupUI(this)
            %% Releases resources.
            % CLEANUPUI is called as a part of deleting the dialog object.
            % Hence, destroy any resources that are not direct children of
            % this dialog.
            
            deleteAddDialog(this)
            deleteEditDialogs(this)
        end        
    end
    
    %% Private methods
    methods(Access=private)
        function pushDataFomTCToUI(this)
            %% Updates display using TC data.
            
            data = getModelTBData(this);
            this.Widgets.blockTable.Data = data;
        end

        function data = getModelTBData(this)
            %% GETMODELREQDATA Returns model data.
            
            rdata = this.TCPeer.Data.TunableBlocks;
            data = cell(size(rdata,1),2);
            if ~isempty(data)
                for ct=1:size(rdata,1)
                    data{ct,1} = rdata{ct,2};
                    data{ct,2} = rdata{ct,1}.BlockPath;
                end
            end
        end        
        
        function setDialogDimension(this)
            %% Sets dialog dimensions.
            
            fig = this.getWidget;
            fig.Position(3:4) = [400 250];
        end
        
        function createDialogLayout(this)
            %% Creates dialog layout.
            
            numRow = 8;
            numCol = 2;
            dialogLayout = uigridlayout(this.getWidget,[numRow numCol]);
            dialogLayout.RowHeight = ['1x',repmat({'fit'},[1 numRow-3]),'1x','fit'];
            dialogLayout.ColumnWidth = {'1x','fit'};
            dialogLayout.RowSpacing = 10;
            dialogLayout.ColumnSpacing = 10;
            dialogLayout.Padding = 10;
            this.Widgets.dialogLayout = dialogLayout;
        end
        
        function createBlockTable(this,row)
            %% Create block table.
            
            blockTable = uitable(this.Widgets.dialogLayout,'ColumnName',{...
                getString(message('Control:systunegui:TunableBlockSelectorActive')), ...
                getString(message('Control:systunegui:TunableBlockSelectorTunableBlocks'))}, ...
                'RowName',[], ...
                'SelectionType','row', ...
                'Multiselect','off', ...
                'RowStriping','off', ...
                'ColumnWidth',{'fit','auto'}, ...
                'ColumnEditable',[true false], ...
                'ColumnFormat',{'logical','char'}, ...
                'Interruptible','off' ...
                );
            blockTable.Layout.Row = [row length(this.Widgets.dialogLayout.RowHeight)-1];
            blockTable.Layout.Column = 1;
            blockTable.CellEditCallback = @(src,data)cbSelectionChangedInTable(this,data);
            blockTable.CellSelectionCallback = @(src,data)cbRowSelectedInTable(this);
            
            this.Widgets.blockTable = blockTable;
        end
        
        function createSideButtonPanel(this,row)
            %% Create side buttons.
            
            if this.SimulinkFlag
                this.Widgets.sideButtonPanel.syncButton = ...
                    createButton(this,'sync',row,@(src,data)cbSyncButton(this));
                
                row = row + 1;
                this.Widgets.sideButtonPanel.addButton = ...
                    createButton(this,'add',row,@(src,data)cbAddButton(this));
                
                row = row + 1;
                this.Widgets.sideButtonPanel.editButton = ...
                    createButton(this,'edit',row,@(src,data)cbEditButton(this));
                
                row = row + 1;
                this.Widgets.sideButtonPanel.highlightButton = ...
                    createButton(this,'hilite',row,@(src,data)cbHighLightButton(this));
                
                row = row + 1;
                this.Widgets.sideButtonPanel.removeButton = ...
                    createButton(this,'remove',row,@(src,data)cbRemoveButton(this));
            else
                this.Widgets.sideButtonPanel.editButton = ...
                    createButton(this,'edit',row+2,@(src,data)cbEditButton(this));
            end
            enableButtonIfRowSelected(this)
        end
        
        function button = createButton(this,type,row,fcn)
            %% Creates sync button
            
            [icon,toolTip] = getIconAndToolTip(type);
            button = uibutton(this.Widgets.dialogLayout,'Text','', ...
                'Icon',icon, ...
                'Tooltip',toolTip, ...
                'IconAlignment','center', ...
                'ButtonPushedFcn',fcn ...
                );
            button.Layout.Row = row;
            button.Layout.Column = 2;
        end
        
        function createBottomButtonPanel(this)
            %% Creates bottom button panel.
            
            bottomButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.Widgets.dialogLayout,["help" "close"]);
            this.Widgets.bottomButtonPanel = bottomButtonPanel;
            
            % Set button panel location in the dialog.
            buttonLayout = getWidget(bottomButtonPanel);
            buttonLayout.Layout.Row = length(this.Widgets.dialogLayout.RowHeight);
            buttonLayout.Layout.Column = [1 length(this.Widgets.dialogLayout.ColumnWidth)];
            
            % Attach callback functions.
            bottomButtonPanel.HelpButton.ButtonPushedFcn = @(src,data)cbHelpButton(this);
            bottomButtonPanel.CloseButton.ButtonPushedFcn = @(src,data)closeOpenDialogs(this);
        end
        
        function enableButtonIfRowSelected(this)
            %% Enables specific buttons on row selection.
            
            enable = ~isempty(this.Widgets.blockTable.Selection);
            this.Widgets.sideButtonPanel.syncButton.Enable = enable;
            this.Widgets.sideButtonPanel.editButton.Enable = enable;
            this.Widgets.sideButtonPanel.highlightButton.Enable = enable;
            this.Widgets.sideButtonPanel.removeButton.Enable = enable;
        end
        
        function cbSyncButton(this)
            %% Callback function to sync from the model.
            
            % Trap simulink model compilation errors.
            try
                tunableBlocks = this.TCPeer.Data.ControlDesignData.getTunableBlock;
                tunableBlock = tunableBlocks(this.Widgets.blockTable.Selection);
                this.TCPeer.Data.ControlDesignData.Architecture.setBlockParam(tunableBlock.BlockPath);
            catch me
                handleException(this,me,compilationAlertMsg(this))
            end
            
        end

        function msg = compilationAlertMsg(this)
            %% Returns compilation alert message.
            
            msg = getString(message('Control:systunegui:ModelCompilationError', ...
                this.TCPeer.Data.ControlDesignData.getArchitectureName));
        end
        
        function msg = hiliteAlertMsg(this)
            %% Returns highlight alert message.
            
            id = this.Widgets.blockTable.Selection;
            data = this.Widgets.blockTable.Data;
            msg = getString(message('Control:systunegui:BlockNotFoundNoHilite', ...
                data{id,2}));
        end
        
        function handleException(this,me,alertMsg)
            %% Handles model compilation exception.
            
            if isa(me,'MSLException')
                showExceptionInSimulinkDiagnosticViewer(this,me)
                showAlertDialog(this,alertMsg)
            else
                showAlertDialog(this,me.message)
            end
        end
        
        function showExceptionInSimulinkDiagnosticViewer(this,me)
            %% Shows exception in Simulink Diagnostic Viewer.
            
            % Always slTuner since ML side do not have block adding
            if isempty(this.TCPeer.Tool) % GroupCenter for unit test, no tool available
                %groupCenter = systuneapp.util.getDialogCenter(this.getDialog);
                fig = this.getWidget;
                groupCenter = [fig.Position(1:2) 0.5*fig.Position(3:4)];
            else % when tool is available
                groupCenter = slctrlguis.lintool.getToolGroupCenter(this.TCPeer.Tool);
            end
            slcontrollib.internal.utils.nagctlr(this.TCPeer.Data.ControlDesignData.getArchitectureName,...
                getString(message('Control:systunegui:toolName')),...
                getString(message('Control:systunegui:DiagnosticViewerErrorCategory')),...
                me,...
                groupCenter)
        end
        
        function showAlertDialog(this,alertMsg)
            %% Shows alert dialog.
            
            % Bring this dialog in front of other figures.
            fig = this.getWidget;
            figure(fig)
            
            % Show model compilation alert dialog.
            uialert(fig,alertMsg,this.Title)
        end
            
        function cbAddButton(this)
            %% Callback function for adding tunable blocks.
            
            % Trap simulink model compilation errors.
            try
                % Create the block selection dialog.
                firstTime = false;
                if isempty(this.Widgets.addDialog) || ~isvalid(this.Widgets.addDialog)
                    this.Widgets.addDialog = controllib.widget.internal.SelectBlockDialog(...
                        this.TCPeer.Data.ControlDesignData);
                    firstTime = true;
                end
                
                % Launch the dialog.
                if firstTime
                    % When opening for the first time, position it on east
                    % of the parent dialog.
                    show(this.Widgets.addDialog,this.getWidget,'East')
                else
                    % Otherwise, retain its position.
                    show(this.Widgets.addDialog)
                end
                pack(this.Widgets.addDialog)
            catch me
                handleException(this,me,compilationAlertMsg(this))
            end
        end

        function closeAddDialog(this)
            %% closes dialog for adding tunable blocks.
            
            if ~isempty(this.Widgets.addDialog) && isvalid(this.Widgets.addDialog)
                close(this.Widgets.addDialog)
            end
        end
        
        function deleteAddDialog(this)
            %% Deletes dialog for adding tunable blocks.
            
            if ~isempty(this.Widgets.addDialog) && isvalid(this.Widgets.addDialog)
                delete(this.Widgets.addDialog)
                this.Widgets.addDialog = [];
            end
        end
        
        function deleteEditDialogs(this)
            %% Deletes dialogs for editing blocks.
            
            % Return for invalid TunableBlockEditorsManager.
            if isempty(this.TCPeer.TunableBlockEditorsManager) || ...
                    ~isvalid(this.TCPeer.TunableBlockEditorsManager)
                return
            end
                
            % Delete each tunable block editor.
            editDialogs = this.TCPeer.TunableBlockEditorsManager.TunableBlockEditors;
            numEditDialogs = numel(editDialogs);
            for ct = 1:numEditDialogs
                delete(editDialogs{ct})
            end
            this.Widgets.editDialogWidgets = [];
        end
        
        function cbRemoveButton(this)
            %% Callback function for removing a selected block.
            
            % Trap simulink model compilation errors.
            try
                targetRow = this.Widgets.blockTable.Selection;
                removeSelectedBlock(this,targetRow)
                moveUpSelectionIfLastRowSelected(this,targetRow)
            catch me
                handleException(this,me,compilationAlertMsg(this))
            end
        end
        
        function removeSelectedBlock(this,targetRow)
            %% Removes the selected block from TC.
            % TC update automatically calls updateUI to update the display.
            
            tunableBlocks = this.TCPeer.Data.ControlDesignData.getTunableBlock;
            this.TCPeer.Data.ControlDesignData.removeTunableBlock(...
                tunableBlocks(targetRow));
        end
        
        function moveUpSelectionIfLastRowSelected(this,targetRow)
            %% Moves up row selection.
            % Row selection moves up if the last row is deleted. This is
            % not automatically done in a UITABLE.
                        
            numRows = size(this.Widgets.blockTable.Data,1);
            if targetRow > numRows
                nextRow = targetRow - 1;
                if nextRow == 0
                    this.Widgets.blockTable.Selection = [];
                else
                    this.Widgets.blockTable.Selection = nextRow;
                end
                enableButtonIfRowSelected(this)
            end
        end
        
        function cbHighLightButton(this)
            %% Callback function to highlight a selected block.

            % Trap exceptions for unexpected external change in the
            % selected block.
            try
                tunableBlock = this.TCPeer.Data.TunableBlocks{...
                    this.Widgets.blockTable.Selection,1};
                linearize.advisor.utils.go2block(tunableBlock.BlockPath)
                this.BlockHighlighted = true;
            catch me
                handleException(this,me,hiliteAlertMsg(this))
            end
        end
        
        function cbEditButton(this)
            %% Callback function to edit the specified block.
            
            fig = this.getWidget;
            currPointer = fig.Pointer;
            fig.Pointer = 'watch';
            restorePointer = onCleanup(@()resetPointer(fig,currPointer));
            
            tunableBlock = this.TCPeer.Data.TunableBlocks{this.Widgets.blockTable.Selection,1};
            this.TCPeer.TunableBlockEditorsManager.EditTunableBlock(tunableBlock,this.Widgets.sideButtonPanel.editButton);
            this.Widgets.editDialogWidgets = this.TCPeer.TunableBlockEditorsManager.getWidgets(tunableBlock);
            
            function resetPointer(f,pointer)
                f.Pointer = pointer;
            end
        end
        
        function cbRowSelectedInTable(this)
            %% A table row is selected with a mouse click.
            
            enableButtonIfRowSelected(this)
        end
        
        function cbSelectionChangedInTable(this,evtData)
            %% Block selection changed
            
            pushDataFromUIToTC(this)
            selectCurrentRow(this,evtData.Indices(1))
        end
        
        function pushDataFromUIToTC(this)
            %% Uses UI table to update TC data.
            
            data = this.Widgets.blockTable.Data;
            currData = this.TCPeer.Data.TunableBlocks;
            update = false;
            for ct = 1:size(currData,1)
                if currData{ct,2} ~= data{ct,1}
                    currData{ct,2} = data{ct,1};
                    update = true;
                end
            end
            
            if update
                setTunableBlocksData(this.TCPeer,currData);
            end            
        end
        
        function selectCurrentRow(this,row)
            %% Selects the row of the changed cell.
            % Changing a cell value does not automatically selects the row.
            % Enforcing row selection of the changed cell for back
            % compatibility.
            
            this.Widgets.blockTable.Selection = row;
            enableButtonIfRowSelected(this)            
        end
        
        function cbHelpButton(this) %#ok<MANU>
            %% Callback function to open help dialog.
            helpview('control','TunableBlockSelectorHelp','CSHelpWindow');
        end
        
        function closeOpenDialogs(this)
            %% Closes any open dialog.            
            closeAddDialog(this)
            % How to hide a java dialog? Deleting it temporarily.
            deleteEditDialogs(this)
            close(this)            
        end
    end
    
    %% Hidden methods
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            %% Returns widget and other launched dialog references.
            
            widgets = this.Widgets;
        end
        
        function qeSelectTable(this,row)
            %% Selects a row of the block table.
            
            this.Widgets.blockTable.Selection = row;
            enableButtonIfRowSelected(this)
        end
    end
    
end
%% Local function
function [icon,toolTip] = getIconAndToolTip(type)
%% Get icon location and tool tip values.

iconLocation = fullfile(matlabroot,'toolbox','shared','controllib', ...
    'general','resources');
            
switch(type)
    case 'sync'
        icon = fullfile(iconLocation,'Refresh_16.png');
        toolTip = getString(message('Control:systunegui:TunableBlockSelectorSyncFromModel'));
    case 'add'
        icon = fullfile(iconLocation,'Add_16.png');
        toolTip = getString(message('Control:systunegui:TunableBlockSelectorAddBlocks'));
    case 'edit'
        icon = fullfile(iconLocation,'EditVar_16.png');
        toolTip = getString(message('Control:systunegui:TunableBlockSelectorEdit'));
    case 'hilite'        
        icon = fullfile(matlabroot,'toolbox','slcontrol','slctrlutil', ...
                'resources','lintool','HighlightBlock_16.png');
        toolTip = getString(message('Control:systunegui:TunableBlockSelectorHighlight'));
    otherwise  %'remove'
        icon = fullfile(iconLocation,'Close_16.png');
        toolTip = getString(message('Control:systunegui:TunableBlockSelectorRemove'));
end

end