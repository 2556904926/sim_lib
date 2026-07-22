classdef AutomatedTuningDialog < controllib.ui.internal.dialog.AbstractDialog & ...
        matlab.mixin.SetGet
    % Automated Tuning Dialog of Control System Designer
    % Dialog class that manages the Data and the common elements of the UI
    % shared by PID, LQG, LoopSyn, IMC automated tuning method dialogs

    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties (Access = public)
        ControlDesignData    % Data to get response and tuned blocks from
        LoopsToTune = struct(...
            'Compensator',   [], ...
            'CompName',      {}, ...
            'Responses',     [], ...
            'ResponseNames', {}, ...
            'SpecData',      []);
        SelectedIdx     % Index into LoopToTune (selected response being tuned)
        EventManager    % Event manager to handle posting status, undo and redo
        
        Widgets            % Widgets used in the UI
        TuningSpecPanel    % Panel class that manages specifications of the tuning method
        ShowLoopList = true      % Flag to show/ hide list of loops (and to select loop being tuned)
        ResponseDialog     % Handle to create new response dialog
        
        SelectedLoopListeners   % Listeners to currently selected compensator, loop data
        ResponseDefinitionListeners
        
%         Title
%         Name
        Dialog
        ToolID

        DialogHeight = 550
        DialogWidth = 450

        PadeOrder
    end
    
    properties (Transient)
    end
    
    methods
        
        function this = AutomatedTuningDialog(ToolData, EventManager, ToolID)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            
            this.ControlDesignData = ToolData;

            if nargin >= 2
                this.EventManager = EventManager;
            end

            if nargin == 3
                this.ToolID = ToolID;
            end

            this.PadeOrder = ToolData.getPreferences.PadeOrder;
            
            % update list of tunable loops
            findLoopsToTune(this);
            
            % Set default loop to be tuned
            this.SelectedIdx = 1;
            
            % Add Data Listeners
%             createDataListeners(this);
                        
        end

        function delete(this)
            delete(this.ResponseDialog);

            % Delete loop listeners
            for ct = 1:numel(this.SelectedLoopListeners)
                delete(this.SelectedLoopListeners{ct});
                this.SelectedLoopListeners{ct} = [];
            end

            delete(this.ResponseDefinitionListeners);
        end
        
        % update the entire dialog to swap between different tuning
        % methods
        function updateUI(this)
%             Options = this.ToolData.getOptions;
            Widgets = this.Widgets;

            NewResponseName = '';
            NewResponseFlag = false;
            if nargin > 1
                NewResponseFlag = true;
                if strcmpi(ed.Type, 'Add')
                    NewResponseName = getName(ed.Data);
                end
            end
            % Update the UI when data changes
            % Disable the UI listeners
            disableDataListeners(this);
            disableUIListeners(this);
            % Find new loops to tune
            findLoopsToTune(this);
            
            % Update Selection Panel
            updateCompSelectionPanel(this);
            
            if NewResponseFlag && ismember(NewResponseName, this.Widgets.LoopsToTuneDropdown.Items)
                this.Widgets.LoopsToTuneDropdown.Value = NewResponseName;
            end
            
            % Enable the UI listeners
            enableUIListeners(this);
            enableDataListeners(this);
            
            % reparent response listeners
            % Add listener to response definition changed to update open
            % loop plant
            % Note: The open loop plant is never cached. The series
            % compensators can change due to definition changed, and
            % updateUI is needed due to this. However, if the definition
            % changed is only due to a change in the name we can optimize
            % the update.
            delete(this.ResponseDefinitionListeners );
            this.ResponseDefinitionListeners = [];
            Responses = getResponses(this.ControlDesignData);
            if~isempty(Responses)
                for ct=1:numel(Responses)
                    this.ResponseDefinitionListeners = [this.ResponseDefinitionListeners; ...
                        addlistener(Responses(ct),'DefinitionChanged',@(es,ed)updateUI(this))];
                end
            end
            
            % Pack dialog
            if this.IsVisible
                pack(this);
            end
            
        end
        
        % modular functions for update
        function updateSpecData(this)
            % Get spec data from tuning panel and update self
            if ~isempty(this.LoopsToTune)
%                 SpecData = getSpecData(this);
                %TO-DO
                SpecData = get(this.TuningSpecPanel, 'SpecData');
                this.LoopsToTune(this.SelectedIdx).SpecData = SpecData;

            end
        end
     
        function updateCompDisplay(this)
            % Update pole zero list and gain display for selected compensator
            
            % Display pole/ zero list
            if isempty(this.SelectedIdx) || isempty(getSelectedCompensator(this))
                % If there are no loops/ compensators to be tuned
                PZString = '';
                GainString = sprintf('%s', getString(message('Control:designerapp:NotTunableByMethod')));
                enableButtons(this, 'off');
            else
                [PZString, GainString, lenString] = localParseDisplay(this);
                % update loop list for compensator
                updateLoopListPanel(this);
                enableButtons(this, 'on');
            end
            
            
            % update widget values
            try
                this.Widgets.CompPZLabel.Text = PZString;
                this.Widgets.CompGainLabel.Text = GainString;
%                 pack(this);
            catch ME
                uialert(this.UIFigure, ME, "internal UI Error");
            end
            
        end
        
        function updateLoopListPanel(this)
            % New list of loops
            CurrentLoop = this.Widgets.LoopsToTuneDropdown.Value;
            
            NewList = this.LoopsToTune(this.SelectedIdx).ResponseNames;
            
            % Update combo-box items
%             removeAllItems(this.Widgets.cmbLoopList);
            this.Widgets.LoopsToTuneDropdown.Items = {};
            if isempty(NewList)
                % Nothing to tune, disable buttons)
                % TO-DO:
                this.Widgets.LoopsToTuneDropdown.Enable = 'off';
                this.Widgets.LoopsToTuneDropdown.Placeholder = getString(...
                    message('Control:designerapp:strAddNewLoop'));
                this.Widgets.LoopsToTuneDropdown.FontAngle = 'italic';
                enableButtons(this, 'off');
            else
                % TO-DO:
                this.Widgets.LoopsToTuneDropdown.Enable = 'on';
                this.Widgets.LoopsToTuneDropdown.FontAngle = 'normal';
                enableButtons(this, 'on');
%                 this.Widgets.CompListDropdown.Items = NewList;
%                 for ct = 1:numel(NewList)
%                     addItem(this.Widgets.cmbLoopList, NewList{ct});
%                 end
                this.Widgets.LoopsToTuneDropdown.Items = NewList;
            end
            % Set selected loop to currently selected loop when possible
            if ~isempty(CurrentLoop) && any(ismember(CurrentLoop, NewList))
                this.Widgets.LoopsToTuneDropdown.Value = CurrentLoop;
            end            
        end
        
        function updateSpecPanel(this,RespIdx)
            % At this point, we have the compensator being tuned and the
            % response being tuned. Check if the compensator can be tuned
            % by the given method. Also check if there are any messages to
            % be posted to the dialog.
            
            % RespIDx - Response Index
            if isempty(RespIdx)
                bool = false;
                Message = getString(message...
                    ('Control:designerapp:AutomatedTuningUndefinedLoop'));
                set(this.TuningSpecPanel, 'Compensator', ...
                    getSelectedCompensator(this));
                set(this.TuningSpecPanel, 'Response', []);
            else
                Compensator = getSelectedCompensator(this);
                if RespIdx == 0
                    % Select first response by default
                    Response = this.LoopsToTune...
                        (this.SelectedIdx).Responses(1);
                else
                    Response = this.LoopsToTune...
                        (this.SelectedIdx).Responses(RespIdx);
                end
                [bool, Message] = isCompensatorTunable(this, ...
                    Compensator,Response);
                % Push compensator
                set(this.TuningSpecPanel, 'Compensator', Compensator);
                % and previously selected response
                % Reparent listener
                unregisterDataListeners(this, 'PlantValueChanged');
                set(this.TuningSpecPanel, 'Response', Response);
                L = addlistener(Response, 'PlantValueChanged', ...
                    @(es,ed)updateUI(this));
                registerDataListeners(this, L, 'PlantValueChanged');
            end
            
            if bool
                % Compensator is tunable, update the spec panel as
                % neccesary
                this.TuningSpecPanel.Panel.Visible = 'on';
                this.Widgets.MessagePanel.Visible = 'off';
                this.UIFigure.Position(4) = this.DialogHeight;

                if ~isempty(Message)
%                     this.Widgets.MessagePanel.Layout.Row = 2;
                    this.Widgets.MessagePanel.Visible = 'on';
%                     this.Widgets.Message.Value = Message;
                    this.Widgets.Message.Text = Message;
                else
%                     this.Widgets.MessagePanel.Layout.Row = 1;
                    this.Widgets.MessagePanel.Visible = 'off';
%                     this.Widgets.Message.Value = '';
                    this.Widgets.Message.Text = '';
                end
                
                if ~isempty(this.TuningSpecPanel)
                    
                    % Push spec data
                    % specData = getSpecData(this);
                    % if(~isempty(specData))
                        set(this.TuningSpecPanel, 'SpecData', getSpecData(this));
                        updateUI(this.TuningSpecPanel);
                    % end
                end

            else
                % Compensator is not tunable. Remove spec panel and replace
                % with notification panel with the appropriate message
                this.UIFigure.Position(4) = 350;
                if ~isempty(Message)
                    this.Widgets.Message.Text = Message;
                    this.TuningSpecPanel.Panel.Visible = 'off';
                    this.Widgets.MessagePanel.Visible = 'on';
%                     this.Widgets.Message.Value = Message;
                end
                
            end
            % Enable or disable tune button
            if bool
                this.Widgets.UpdateButton.Enable = 'on';
            else
                this.Widgets.UpdateButton.Enable = 'off';
            end
%             setEnabled(this.Widgets.BtnUpdate, bool);
        end
        
        function updateCompSelectionPanel(this)            
            % Get the current loop/compensator being tuned
            SelectedComp = this.Widgets.CompListDropdown.Value;
            
            % Get new list of compensators
            
            if isempty(this.LoopsToTune)
                % If no compensators/ loops can be tuned by current method
                % hide irrelevant widgets
                showCompensatorDisplayWidgets(this, 'off');
                setSelectedIdx(this, []);
                this.Widgets.NoCompensatorLabel.Text = ...
                    getString(message('Control:designerapp:NotTunableByMethod'));
            else
                NewList = {this.LoopsToTune.CompName};
                % Else, show relevant widgets
                showCompensatorDisplayWidgets(this, 'on');

                this.Widgets.NoCompensatorLabel.Text = '';
                
                % Refresh compensator list combo box with new list of
                % compensators to tune

                this.Widgets.CompListDropdown.Items = NewList;
%                 for ct = 1:numel(NewList)
%                     addItem(this.Widgets.cmbCompensatorList, NewList{ct});
%                 end
                
                % If the current compensator being tuned is in the new list
                % of loops, update SelectedIdx to match. Else, reset
                % selected loop to the first one in the list
                [bool, idx] = ismember(SelectedComp, NewList);
                if bool
                    setSelectedIdx(this, idx);
                    this.Widgets.CompListDropdown.Value = SelectedComp;
                else
                    setSelectedIdx(this, 1);
                    this.Widgets.CompListDropdown.Value = NewList{1};
                end
            end
%             try
%                 pack(this);
%             end
        end

        function showLoopList(this)
            this.ShowLoopList = ~this.ShowLoopList;
            updateLoopListPanel(this);
        end
                
        function updatePadeOrder(this,ed)
            this.PadeOrder = ed.AffectedObject.(ed.Source.Name);
            updateUI(this.TuningSpecPanel);
        end
        
        
        %% Public - Utilities
        function Model = utApproxDelay(this,Model)
            % Helper function for approximating delays
            if hasdelay(Model)
                if isequal(Model.Ts,0)
                    PO = this.PadeOrder;
                    Model = pade(Model,PO,PO,PO);
                else
                    if isa(Model,'ltipack.ltidata')
                        Model = elimDelay(Model);
                    else
                        Model = absorbDelay(Model);
                    end
                end
            end
        end
        
        function wt = getWidgets(this)
            wt = this.Widgets;
        end
        
        function showCompensatorDisplayWidgets(this, logical)
            logicalOnOff = matlab.lang.OnOffSwitchState(logical);
            try
                this.Widgets.CompensatorLayout.Visible = logicalOnOff;
                this.Widgets.NoCompensatorLayout.Visible = ~logicalOnOff;
            catch ME
                uialert(this.UIFigure, ME.msg, 'Icon', 'error');
            end
        end

        % TO-DO: not using pack until fitToContent gets resolved
        function pack(this)
           
        end
    end
    
    methods (Access = protected)
        
        %% Add Listeners %%
        function connectUI(this)
            
            % Data Listeners - DesignData's ResponseListChanged,
            L = addlistener(this.ControlDesignData, 'ResponsesListChanged', @(es,ed)updateUI(this));
            registerDataListeners(this,L);

            L = addlistener(this.ControlDesignData.Preferences, 'PadeOrder', 'PostSet', ...
                @(es,ed)updatePadeOrder(this,ed));
            registerDataListeners(this, L);

            % Tuning Spec Data Listeners
            addSpecDataListeners(this);
            
            % Dropdown Listeners
            addDropdownListeners(this);

            % listeners for Add, Help, Cancel and Update
            addButtonListeners(this)

            addlistener(this,'CloseEvent',@(es,ed) delete(this));
            
        end
        
        function reparentListeners(this)
            % Reparent listeners to currently selected compensator and loop
            % Add listeners to the following events:
            
            % Delete listeners to old block, old response
            for ct = 1:numel(this.SelectedLoopListeners)
                delete(this.SelectedLoopListeners{ct});
                this.SelectedLoopListeners{ct} = [];
            end
            
            % add listeners to new block, new response
            L{1} = addlistener(this.LoopsToTune(this.SelectedIdx).Compensator, 'ValueChanged', @(es,ed)updateCompDisplay(this));
            L{2} = addlistener(this.LoopsToTune(this.SelectedIdx).Compensator, 'PZGroup', 'PostSet', @(es,ed)updateCompDisplay(this));
            L{3} = addlistener(this.LoopsToTune(this.SelectedIdx).Compensator, 'GainChanged', @(es,ed)updateCompDisplay(this));

            this.SelectedLoopListeners = L;
        end
        
        function addSpecDataListeners(this)
            if ~isempty(this.TuningSpecPanel)
                sdL = addlistener(this.TuningSpecPanel, 'SpecDataChanged', @(es,ed)updateSpecData(this));
                registerDataListeners(this, sdL, 'UpdateSpecDataListener');
            end
        end
        
        function addDropdownListeners(this)
            % create listener for compensator dropdown
            compDropdownListener = addlistener(...
                this.Widgets.CompListDropdown, 'ValueChanged', ...
                @(es, ed)updateCompSelectionPanel(this));
            % create listener for loops to tune dropdown
            looplistDropdownListener = addlistener(...
                this.Widgets.LoopsToTuneDropdown, 'ValueChanged', ...
                @(es, ed)updateLoopListPanel(this));

            registerUIListeners(this, compDropdownListener, ...
                {'CompListDropdown'});
            registerUIListeners(this, looplistDropdownListener, ...
                {'LoopsToTuneDropdown'});
        end
        
        function addButtonListeners(this)
            
            % create button listeners - compensator panel
            addLoopListener = addlistener(this.Widgets.AddLoopButton, ...
                                'ButtonPushed', @(es,ed)cbAddLoop(this));
            
            % create button listeners - button panel 
            
            updateListener = addlistener(this.Widgets.UpdateButton, ...
                'ButtonPushed', @(es,ed)cbUpdateButton(this));
            helpListener = addlistener(this.Widgets.ButtonPanel.HelpButton, ...
                'ButtonPushed', @(es,ed)cbHelpButton(this));
            cancelListener = addlistener(this.Widgets.ButtonPanel.CloseButton, ...
                'ButtonPushed', @(es,ed)cbCloseButton(this));
            
            % register listeners
            registerUIListeners(this, addLoopListener, {'AddLoopButon'});
            registerUIListeners(this, updateListener, {'UpdateButton'});
            registerUIListeners(this, helpListener, {'HelpButton'});
            registerUIListeners(this, cancelListener, {'CancelButton'});
            
        end
        
        %% UI Methods %%
        function buildUI(this)
            
            %   Creates dialog using the following layout:
            %   ----------------------------------
            %   | Header                         |
            %   ----------------------------------
            %   | CompensatorSelectionPanel      |
            %   ----------------------------------
            %   | CompSpecificationsPanel        |
            %   ----------------------------------
            %   | ButtonPanel                    |
            %   ----------------------------------
            
            % Set dialog size
            this.UIFigure.Position(3:4) = [this.DialogWidth, this.DialogHeight];
            gridLayout = uigridlayout(this.UIFigure, [4, 1]);
            gridLayout.RowHeight = {'fit', '1x', 'fit', 'fit'};
            gridLayout.ColumnWidth = {'1x'};
            gridLayout.Tag = 'CSD_AutomatedTuningDialog_GridLayout';
            % add to Widgets
            
            this.Widgets.DialogLayout = gridLayout;
            
            % Compensator Selection Panel
            createCompSelectionPanel(this);
            
            % Message Panel
            createMessagePanel(this);

            % Compensator Specification Panel
            createCompSpecPanel(this)
            
            % Button Panel
            row = 4; col = 1;%[1 2];
            buttonPanel = createButtonPanel(this, gridLayout, row, col);
            

            % add to Widgets
            this.Widgets.ButtonPanel = buttonPanel;
            
            % add listeners - connect UI should do this
%             addUIListeners(this);
        end
        
        function cleanupUI(this)
            % Delete any non-children of the dialog.
            if this.IsWidgetValid
                % Deleting UIFigure will delete everything.
                % Otherwise delete the top level layout container.
                delete(this.Widgets.DialogLayout)
                this.Widgets.DialogLayout = [];
            end
%             % Otherwise delete the top level layout container.
%             delete(this.Widgets.DialogLayout)
            this.Widgets.DialogLayout = [];
        end
        
        function createCompSelectionPanel(this)
            % create selection panel
            compSelectionPanel = uipanel(this.Widgets.DialogLayout, 'Title', ...
                                         getString(message('Control:designerapp:strCompensator')));
            compSelectionPanel.Layout.Row = 1;
            compSelectionPanel.FontWeight = 'bold';
            compSelectionPanel.BorderType = 'none';
            
            panelLayout = uigridlayout(compSelectionPanel, [1 1]);
            % create a gridlayout for parenting other uicomponents
%             compSelectionLayout.RowHeight = {'fit', '1x', 'fit', 'fit', 'fit'};
%             compSelectionLayout.ColumnWidth = {'fit', 'fit', 'fit', '1x', '1x'};
            compSelectionLayout = uigridlayout(panelLayout, [5 5]);
            compSelectionLayout.RowHeight = {60, 'fit', 'fit', 'fit', 'fit'};
            compSelectionLayout.ColumnWidth = {60, 60, 'fit', 'fit', 'fit'};
            compSelectionLayout.Layout.Row = 1;
            compSelectionLayout.Layout.Column = 1;
            compSelectionLayout.Scrollable = 'on';

            noCompLayout = uigridlayout(panelLayout,[1 1],Visible='off');
            noCompLayout.Layout.Row = 1;
            noCompLayout.Layout.Column = 1;
            noCompLayout.Scrollable = 'on';
            noCompLabel = uilabel(noCompLayout,Text='',WordWrap='on');

%             compHtmlLayout = uigridlayout(panelLayout, [1 1]);
%             compHtmlLayout.Layout.Row = 1;
%             compHtmlLayout.Layout.Column = 2;
%             compHtmlLayout.RowHeight = {'fit'};
%             compHtmlLayout.ColumnWidth = {'fit'};

            %add widgets
            this.Widgets.CompensatorPanel = compSelectionPanel;
            this.Widgets.CompensatorLayout = compSelectionLayout;
            this.Widgets.NoCompensatorLayout = noCompLayout;
            this.Widgets.NoCompensatorLabel = noCompLabel;

%             this.Widgets.CompHTMLLayout = compHtmlLayout;
            
            % create dropdown for comp selection
            createCompensatorDisplay(this);
            
            % create dropdown for loop selection
            % if ~isempty(this.LoopsToTune)
                createLoopsToTuneComponents(this);
            % end            
        end
        
        function createCompensatorDisplay(this)
            
            dropdownItems = {this.LoopsToTune.CompName};
            %adding additional row with 1x to accomodate layout issues
            gridLayoutDD = uigridlayout(this.Widgets.CompensatorLayout);
            gridLayoutDD.Padding = 0;
            gridLayoutDD.RowSpacing = 0;
            gridLayoutDD.RowHeight = {'1x','fit', '1x'};
            gridLayoutDD.ColumnWidth = {'1x'};
            gridLayoutDD.Layout.Row = 1;
            gridLayoutDD.Layout.Column = [1 2];

            compListDropdown = uidropdown(gridLayoutDD);
            compListDropdown.Layout.Row = 2;
            compListDropdown.Layout.Column = 1;
            compListDropdown.Items = dropdownItems;
            % compListDropdown.VerticalAlignment = 'center';
            
            compEqualToLabel = uilabel(this.Widgets.CompensatorLayout);
            compEqualToLabel.Layout.Row = 1;
            compEqualToLabel.Layout.Column = 3;
            compEqualToLabel.Text = '=';
            
            % get text for gain and pole-zero labels
            if isempty(this.SelectedIdx) || isempty(getSelectedCompensator(this))
                % If there are no loops/ compensators to be tuned
                PZString = '';
                GainString = sprintf('%s', getString(message('Control:designerapp:NotTunableByMethod')));
                this.Widgets.NoCompensatorLabel.Text = ...
                    getString(message('Control:designerapp:NotTunableByMethod'));
                enableButtons(this, 'off');
            else
                [PZString, GainString, lenString] = localParseDisplay(this);
                enableButtons(this, 'on');
                % update loop list for compensator
%                 updateLoopListPanel(this);
            end
            
            compGainLabel = uilabel(this.Widgets.CompensatorLayout);
            compGainLabel.Layout.Row = 1;
            compGainLabel.Layout.Column = 4;
            compGainLabel.Text = GainString;
            compGainLabel.Interpreter = 'html';
%             compGainLabel.WordWrap = 'on';
            
            compPZLabel = uilabel(this.Widgets.CompensatorLayout);
            compPZLabel.Layout.Row = 1;
            compPZLabel.Layout.Column = 5;
            compPZLabel.Interpreter = 'html'; %'html';
            compPZLabel.VerticalAlignment = 'center';
            compPZLabel.Text = PZString;
                
%             compPZLabel.HTMLSource = PZString;
%             compPZLabel.Position = [100 2 12.5*lenString 40];
            

            % add to Widgets
            this.Widgets.CompListDropdown = compListDropdown;
            this.Widgets.CompPZLabel = compPZLabel;
            this.Widgets.CompGainLabel = compGainLabel;
        end
        
        function createLoopsToTuneComponents(this)
            
            selectLabel = uilabel(this.Widgets.CompensatorLayout);
            selectLabel.Layout.Row = 2;
            selectLabel.Layout.Column = [1 2];
            selectLabel.Text = getString(message('Control:designerapp:strSelectLoopToTune'));
            
            if isempty(this.LoopsToTune)
                responseNames = {};
            else
                responseNames = this.LoopsToTune.ResponseNames;
            end
            loopsToTuneDropdown = uidropdown(this.Widgets.CompensatorLayout);
            loopsToTuneDropdown.Layout.Row = 3;
            loopsToTuneDropdown.Layout.Column = [1 2];
            loopsToTuneDropdown.ItemsData = {};
            loopsToTuneDropdown.Items = {};
            
            if ~isempty(responseNames)
                loopsToTuneDropdown.Items = responseNames;
            end
            
            addToolTip = getString(message('Control:designerapp:strAddNewLoop'));
            addLoopButton = uibutton(this.Widgets.CompensatorLayout, ...
                                    'Text', '', ...
                                    'Tooltip',addToolTip, ...
                                    'IconAlignment','center'); %ButtonFcnLayout
            matlab.ui.control.internal.specifyIconID(addLoopButton,'add',16);
            addLoopButton.Layout.Row = 3;
            addLoopButton.Layout.Column = 3;
            
            % add widgets
            this.Widgets.LoopsToTuneDropdown = loopsToTuneDropdown;
            this.Widgets.AddLoopButton = addLoopButton;
            
        end
        
        function createCompSpecPanel(this)
            
            compSpecPanel = uipanel(this.Widgets.DialogLayout, 'Title', ...
                                         getString(message( ...
                                         'Control:designerapp:strSpecifications')));
            compSpecPanel.Layout.Row = 2;
            compSpecPanel.FontWeight = 'bold';
            compSpecPanel.BorderType = 'none';
            this.Widgets.SpecPanel = compSpecPanel;
            
            % create messagePanel for notifications
%             messagePanel(this);
            % create Tuning Spec Panel
            SpecData = getSpecData(this);
            getSpecPanel(this, this.Widgets.SpecPanel, SpecData);
        end
        
        function notificationPanel(this)
        end
        
        function createMessagePanel(this)
            % add message when loops to tune or compensator is invalid
            % Parent panel is SpecPanel
            % ensure upon call this.TuningSpecPanel.Panel.Visible is 'off'
            messagePanel = uigridlayout(this.Widgets.DialogLayout, [1 2]);
            messagePanel.Layout.Row = 3;
            messagePanel.Visible = 'on';
            messagePanel.RowHeight = {'fit'};
            messagePanel.ColumnWidth = {'fit', '1x'};
            
            messageIcon = uiimage(messagePanel);
            matlab.ui.control.internal.specifyIconID(messageIcon, 'warning', 16);
            messageIcon.Layout.Column = 1;
            messageIcon.ScaleMethod = 'scaledown';
            
%             messageLabel = uitextarea(messagePanel);
            messageLabel = uilabel(messagePanel);
            % to fit in the grid, set the column layout to 1,2
            
            messageLabel.Layout.Column = [2 3]; 
            messageLabel.Text = '';
            messageLabel.Interpreter = 'html';
            messageLabel.WordWrap = 'on';
            messageLabel.HorizontalAlignment = 'left';
%             messageLabel.Editable = 'off';

            this.Widgets.MessagePanel = messagePanel; 
            this.Widgets.Message = messageLabel;
        end
        
        function buttonPanel = createButtonPanel(this, parentLayout, row, col)
            % Create a panel containing HELP, UPDATE, CANCEL buttons.
            
            % Create button panel and get the button layout.
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                parentLayout,["help" "close"], 'Commit', 3);
            
            widget = getWidget(buttonPanel);
            widget.Layout.Row = row;
            widget.Layout.Column = col;
            widget.Padding(end) = parentLayout.Padding(end);
%             widget.CancelButton.Layout.Column = 3;
            
            updateButton = uibutton(widget, 'Text',...
                getString(message('Control:designerapp:strUpdateCompensator')));
            updateButton.Layout.Row = 1;
            updateButton.Layout.Column = 4;
            widget.ColumnWidth{updateButton.Layout.Column} = 150;
            this.Widgets.UpdateButton = updateButton;
%             iconLocation = fullfile(matlabroot,'toolbox','shared','controllib', ...
%                                     'general','resources');
%                                 
%             undoIcon = fullfile(iconLocation, 'Undo_16.png');
%             resetButton = uibutton(widget, 'Text', 'Reset Parameters');
%             resetButton.Layout.Row = 1;
%             resetButton.Layout.Column = 3;
%             resetButton.Icon = undoIcon;
%             % Attach callback functions
%             buttonPanel.HelpButton.ButtonPushedFcn = @(es,ed)cbHelpClicked(this);            
%             buttonPanel.OKButton.ButtonPushedFcn = @(es,ed)cbOkClicked(this);            
%             buttonPanel.CancelButton.ButtonPushedFcn = @(es,ed)cbCancelClicked(this);           
        
        end
        
        
        %% Data related methods
        % Find loops to tune from responses
        function findLoopsToTune(this)
            % Disable data listeners (as there is a possiblity of response
            % being added)
            disableDataListeners(this);
            % Disable UI Listeners - they are being modified
            disableUIListeners(this);
            % Reset loops to tune
            this.LoopsToTune = struct(...
                'Compensator',   [], ...
                'CompName',      {}, ...
                'Responses',     [], ...
                'ResponseNames', {}, ...
                'SpecData',      []);
            L = [];
            
            % All respones that are SISO and are Open-Loop Transfers
            Responses = getResponses(this.ControlDesignData);
            if isempty(Responses)
                LoopList = [];
            else
                LoopList = Responses(issiso(Responses) & ...
                    isLoopTransfer(Responses));
            end
            % Get compensators in series with each loop already defined
            for ct1 = 1:length(LoopList)
                SeriesComps{ct1,:} = getTunedFactors(LoopList(ct1)); %#ok<AGROW>
                for ct2 = 1:numel(SeriesComps{ct1,:})
                    % For each compensator in series, store compensator
                    % name and corresponding response
                    L(end+1).Compensator = SeriesComps{ct1}(ct2).Name;
                    L(end).Response = LoopList(ct1);
                end
            end
            
            % Get list of tuned blocks
            Blocks = getTunedBlocks(getArchitecture(this.ControlDesignData));
            
            % For each compensator,
            for ct = 1:numel(Blocks)
                Name = Blocks(ct).Name;
                % Does it belong in a feedback loop?
                b = hasFeedbackLoop(getArchitecture(this.ControlDesignData), Blocks(ct).getIdentifier);
                
                % If yes, is there a response that has it in series?
                if b
                    this.LoopsToTune(end+1).Compensator = Blocks(ct);
                    this.LoopsToTune(end).CompName = Blocks(ct).Name;
                    % REVISIT: Might be faster to compare handles rather
                    % than a string compare of names.
                    if ~isempty(L)
                        idx = ismember({L.Compensator},Name);
                    else
                        idx = 0;
                    end
                    if any(idx)
                        % If response already exists
                        this.LoopsToTune(end).Responses = [L(idx).Response]';
                        
                        % Place-holder for specdata
                        this.LoopsToTune(end).SpecData = [];
                        
                        % Response name and open loop plant
                        for ct2 = 1:numel(this.LoopsToTune(end).Responses )
                            this.LoopsToTune(end).ResponseNames{ct2,1} = getName(this.LoopsToTune(end).Responses(ct2));
                        end
                    end
                end
            end
            enableDataListeners(this);
            enableUIListeners(this);
            
        end
        
        %% get / set methods
        function SpecData = getSpecData(this)
            if isempty(this.SelectedIdx) || isempty(this.LoopsToTune)
                SpecData = [];
            else
                SpecData = this.LoopsToTune(this.SelectedIdx).SpecData;
            end
        end
        
        function Compensator = getSelectedCompensator(this)
            if isempty(this.LoopsToTune)
                Compensator = [];
            else
                Compensator = this.LoopsToTune(this.SelectedIdx).Compensator;
            end
        end
        
        function Plant = getSelectedOpenLoopPlant(this)
            Idx = ismember(this.LoopsToTune(this.SelectedIdx).ResponseNames, this.Widgets.LoopsToTuneDropdown.Value);
            Response = this.LoopsToTune(this.SelectedIdx).Responses(Idx);
            Compensator = this.LoopsToTune(this.SelectedIdx).Compensator;
            Plant = getOpenLoopPlant(Response,Compensator);
        end
        
        function setSelectedIdx(this, Idx)
             % Change the selected loop
            % Disable the UI listeners
            disableUIListeners(this);
            %             drawnow;
            
            if isempty(Idx) || Idx<1 || Idx>(numel(this.LoopsToTune)+1)
                % Protect against invalid index
                Idx = [];
            end
            
            this.SelectedIdx = Idx;
            
            updateCompDisplay(this);
            
            CurrentLoop = this.Widgets.LoopsToTuneDropdown.Value;
            
            if isempty(this.SelectedIdx)
                RespIdx = [];
                showCompensatorDisplayWidgets(this, 'off');
            elseif isempty(this.LoopsToTune(this.SelectedIdx).ResponseNames)
                RespIdx = [];
                % Reset listeners to new selected index response and
                % compensator - think about pushing this to updateUI
                showCompensatorDisplayWidgets(this, 'on');
                reparentListeners(this);
            else
                [~,RespIdx] = ismember(CurrentLoop, this.LoopsToTune(this.SelectedIdx).ResponseNames);
                showCompensatorDisplayWidgets(this, 'on');
                % Reset listeners to new selected index response and
                % compensator - think about pushing this to updateUI
                reparentListeners(this);
            end
            %TO-DO:
            updateSpecPanel(this,RespIdx);
            updateSpecData(this);
            % Enable the UI listeners
            enableUIListeners(this);
            updateUI(this.TuningSpecPanel);
        end
       
        
        %% Utility methods %%
        function [PZString, GainString, lenString] = localParseDisplay(this)

            % Get the selected compensator
            Compensator = getSelectedCompensator(this);

            % Get list of poles and zeros
            [ZString, PString] = getDisplayString(Compensator);
            lenString = max(length(ZString), length(PString));
            if isempty(ZString) && isempty(PString)
                % Three line breaks
                PZString = '';
                GainString = sprintf('%0.5g', getFormattedGain(Compensator));
            else
                PZString = sprintf('<center>%s</center><hr><center>%s</center>', ZString, PString);
%                 PZString = sprintf('<html><center>%s</center><hr><center>%s</center></html>', ZString, PString);
                GainString = sprintf('%0.5g x ', getFormattedGain(Compensator));
%                 PZString = sprintf('$$ %s {%s}{%s} $$', '\frac', ZString, PString);
%                 GainString = sprintf('$$ %0.5g x $$', getFormattedGain(Compensator));
            end
            
            
        end

        function enableButtons(this, opState)
            % opState is either 'on' or 'off'
            this.Widgets.UpdateButton.Enable = opState;
        end
        
        %% UI callback methods
        function cbAddLoop(this)
            % Create add new loop dialog, if not created already
            % Open add new loop dialog
            
            % Create new response with location set to output of block
            % being tuned.
            Blk = getSelectedCompensator(this);
            
            % Get existing points
            Architecture = getArchitecture(this.ControlDesignData);
            if isSimulink(Architecture)
                % New Loop at output of compensator
                NewLocation = getPath(Blk);
                addSignal(Architecture,NewLocation);
            else
                % REVISIT
                NewLocation = getLocationForBlock(Architecture, Blk.Name);
            end
            % Create the response
            L = ctrlguis.csdesignerapp.data.responses.internal.LoopTransfer(NewLocation);
            R = ctrlguis.csdesignerapp.data.responses.internal.Response(L,Architecture);
            ResponseDialogTC = ctrlguis.csdesignerapp.panels.internal.ResponseLoopTransferTC(this.ControlDesignData,R);
            ResponseDialogTC.Editable = true;
            Responses = getResponses(this.ControlDesignData);
            Names = [];
            for ct = 1:length(Responses)
                Names = [Names, getName(Responses(ct))];
            end
            n = 1;
            while ~isempty(strfind(Names, sprintf('LoopTransfer%d',n)))
                n = n+1;
            end
            ResponseDialogTC.Name = sprintf('LoopTransfer%d',n);
            % Pre-defined response, but still has to be added to CDD when
            % ok is hit
            ResponseDialogTC.Create = true;
            this.ResponseDialog = createView(ResponseDialogTC);
            show(this.ResponseDialog, this.Widgets.AddLoopButton, true);
            update(ResponseDialogTC);
        end
        
        function cbCloseButton(this)
            delete(this);
        end
        
        % updates the compensator values - computes compensator
        function cbUpdateButton(this)
            % Disable listeners
            for ct=1:numel(this.SelectedLoopListeners)
                this.SelectedLoopListeners{ct}.Enabled = false;
            end
            % Disable warnings
            sw = warning('off'); [lw,lwid] = lastwarn; lastwarn(''); %#ok<*WNOFF>
            % Cursor
%             this.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(true,this.Dialog,this.WaitBar);
            % Wait bar
            if ~isempty(this.EventManager)
                % Post status
                this.EventManager.postActionStatus('on', getString(message('Control:designerapp:updateCompensator')));
            end
            
            % Create a transaction
            Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction(this.getTransactionTitle);
            
            % Locally tune using widget values
            OL = getSelectedOpenLoopPlant(this);
            
            if isa(OL,'ltipack.frddata')
                OpenLoopPlant = frd(OL);
            else
                OpenLoopPlant = ss(OL);
            end
            
            % Tune
            CurrentCompensator = getSelectedCompensator(this);
            
            % Set undo function
            S = saveSession(CurrentCompensator);
            Transaction.UndoFcn = {@loadSession CurrentCompensator S};
            
            try
                currentPointer = this.UIFigure.Pointer;
                this.UIFigure.Pointer = 'watch';
                NewCompensator = tuneCompensator(this, OpenLoopPlant, ...
                    getSpecData(this));
                
                
                if ~isempty(NewCompensator)
                    % Set the selected compensator
                    setValue(CurrentCompensator, NewCompensator);
                end
                this.UIFigure.Pointer = currentPointer;
            catch ME
%                 ctrlguis.csdesignerapp.utils.internal.utDisplayMessage('error',ltipack.utStripErrorHeader(ME.message));
                this.UIFigure.Pointer = currentPointer;
                uialert(this.UIFigure, ...
                    ltipack.utStripErrorHeader(ME.message), this.Title, ...
                            'Icon', 'error');
                % Cursor and Status
                if ~isempty(this.EventManager)
                    clearActionStatus(this.EventManager);
                end
%                 this.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,this.Dialog,this.WaitBar);
                
                % Reset warnings
                warning(sw); lastwarn(lw,lwid);
                return;
            end
            
            % Set redo function
            S = saveSession(CurrentCompensator);
            Transaction.RedoFcn = {@loadSession CurrentCompensator S};
            
            if ~isempty(this.EventManager)
                % Record transaction
                this.EventManager.record(Transaction);
                % Post status
                this.EventManager.postActionStatus('off', ...
                    this.getTransactionTitle);
            end
            
            % Cursor
%             this.WaitBar = ctrlguis.csdesignerapp.utils.internal.setWaitingInsideDialog(false,this.Dialog,this.WaitBar);           
            % Reset warnings
            warning(sw); lastwarn(lw,lwid);
            % update compensator display
            updateCompSelectionPanel(this);
            % Enable listeners
            for ct=1:numel(this.SelectedLoopListeners)
                this.SelectedLoopListeners{ct}.Enabled = true;
            end
        end
    end
    
    %% Abstract methods
    methods (Abstract = true, Access = protected)
        getSpecPanel(this);
        tuneCompensator(this);
        isCompensatorTunable(this);
        cbHelpButton(this);
    end

    methods (Hidden = true)
        function C = qeTuneCompensator(this, OpenLoopPlant, SpecData)
            try
                C = tuneCompensator(this, OpenLoopPlant, SpecData);
            catch ME
                error(message(ME));
            end
        end
    end

    methods (Abstract = true, Static = true, Access = protected)
        getTransactionTitle;
    end
end