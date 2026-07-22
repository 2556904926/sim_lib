classdef SignalListPanel < controllib.ui.internal.dialog.AbstractContainer
    %% SignalListPanel - Creates a panel to maintain a list of signals
    %
    %  PNAEL = SIGNALLISTPANEL(DATA,LISTTYPE,PROPERTYNAME,LISTNAME,DLG)
    %  creates a signal list panel using the specified inputs.
    %
    %  SignalListPanel properties:
    %      Data           - Architecture
    %      SignalListType - Input, Output, Location or Opening
    %      PropertyName   - Input, Output, Location or Opening
    %      SignalListName - Signal list name
    %
    %  SignalListPanel methods:
    %       getWidget - Returns a gridlayout containing the widgets.
    %
    %   Examples:
    %
    %       %% Create design data and tool component.
    %       mdl = 'scdspeedctrl';
    %       open_system(mdl);
    %       architecture = slTuner(mdl,{'Reference Filter','PID Controller'});
    %       data = systuneapp.data.ControlDesignData(architecture,[]);
    %
    %       tc = systuneapp.internal.dialogs.LoopShapeTuningGoalTC(data);
    %
    %       %% Construct and show a signal list panel.
    %       openingListPanel = controllib.widget.internal.signallist.SignalListPanel(...
    %           tc,'Openings','Openings',tc.OpeningSignalLabel);
    %       qeShow(openingListPanel)
    %
    %       %% Embed the signal list panel in a different dialog.
    %       locationListPanel = controllib.widget.internal.signallist.SignalListPanel(...
    %           tc,'Location','Location',tc.LocationSignalLabel);
    %       widgets = getWidget(locationListPanel);
    %       fig = uifigure;
    %       layout = uigridlayout(fig,[1 1]);
    %       widgets.Parent = layout;
    %       
    %
    %  See also
    %  controllib.widget.internal.signallist.AddSignalFromModelDialog

    %  Copyright 2021 The MathWorks, Inc

    %% Properties
    properties(GetAccess=public,SetAccess=private)
        Data                % Architecture
        SignalListType      % Input, Output, Location or Opening
        SignalListName
        PropertyName        % Input, Output, Location or Opening
    end

    properties(Hidden)
        Parent
    end

    properties(Hidden,GetAccess=public,SetAccess=private)
        Widgets = struct(...
            'signalListPanelLayout',[], ...
            'contextMenu',[], ...
            'panelHeaderLabel',[], ...
            'addSignalButton',[], ...
            'addSignalFromModelDialog',[],...
            'signalList',[], ...
            'moveUpSignalButton',[], ...
            'moveDownSignalButton',[], ...
            'highlightSignalButton',[], ...
            'removeSignalButton',[], ...
            'selectListItemFcn',@clickListItem ...
            );
    end

    properties(Access=private)
        HighlightSignalStatus = false;

        RemoveIcon
        UpIcon
        DownIcon
        HighlightIcon
        AddSignalFromModelDialog

        EditType = controllib.widget.internal.signallist.SignalEditType.Initialization;
        SignalIndex

        RowHeight = 20; % pixel
    end

    %% Constructor/delete
    methods(Access = public)
        function this = SignalListPanel(data,SignalListType,PropertyName,SignalListName)
            this = this@controllib.ui.internal.dialog.AbstractContainer;
            this.Data = data;
            this.SignalListType = SignalListType;
            this.PropertyName = PropertyName;
            this.SignalListName = SignalListName;
            this.Name = 'SignalPanel';

            % Icons
            iconLocation = fullfile(matlabroot,'toolbox','shared','controllib', ...
                'general','resources','toolstrip_icons');
            this.RemoveIcon = 'delete';
            this.UpIcon = 'arrowNavigationNorth';
            this.DownIcon = 'arrowNavigationSouth';
            this.HighlightIcon = 'highlightBlockAction';           

            % Add listener to delete the panel when data is destroyed.
            weakThis = matlab.lang.WeakReference(this);
            registerDataListeners(this, ...
                addlistener(data,'ObjectBeingDestroyed', ...
                @(src,data)delete(weakThis.Handle)));
            registerDataListeners(this, ...
                addlistener(data,PropertyName,'PostSet', ...
                @(src,data)createFlatContextMenu(weakThis.Handle)));
            registerDataListeners(this, ...
                addlistener(data,PropertyName,'PostSet', ...
                @(src,data)updateUI(weakThis.Handle)));
        end

        function delete(this)
            % Delete unparented handle objects.

            delete(this.AddSignalFromModelDialog)
        end
    end

    %% Public methods
    methods(Access = public)
        function [container,widgets] = getWidget(this,layout,row,col)
            %% Overloaded getWidget method to attach a gridlayout parent.
            % It returns two outputs:
            %     - the container and 
            %     - individual widget handles in a structure.

            arguments
                this (1,1) controllib.widget.internal.signallist.SignalListPanel {mustBeValid}
                layout matlab.ui.container.GridLayout {mustBeValidIfNonempty} = matlab.ui.container.GridLayout.empty
                row double {mustBeValidInteger} = []
                col double {mustBeValidInteger} = []
            end

            this.Parent = layout;
            container = getWidget@controllib.ui.internal.dialog.AbstractContainer(this);
            widgets = this.Widgets;
            if isempty(layout) || isempty(row) || isempty(col)
                return
            end
            container.Layout.Row = row;
            container.Layout.Column = col;
        end
        
        function updateUI(this)
            % Updates graphical component with data
            if ~isempty(this.Widgets.signalListPanelLayout)
                updateSignalListPanel(this)
            end
        end

        function mUpdate(this) %#ok<MANU>
        end
        
        function createFlatContextMenu(this)
            % Creates a flat context menu using all available signals.
            fig = ancestor(this.Widgets.signalListPanelLayout,'figure');
            if isempty(fig)
                return
            end
            cmenu = uicontextmenu(fig);
            [allSignals,expandedAllSignals] = this.getAvailableSignals;
            signals = allSignals;
            nSignals = length(signals);
            if nSignals > 0
                for ct = 1:nSignals
                    % Determine whether there are subsignals.
                    [subSignalList,isSingleSignal] = ...
                        controllib.widget.internal.utils.expandSignalList(...
                        signals{ct},expandedAllSignals);

                    % Remove sub signals.
                    subSignals = subSignalList;%setdiff(subSignalList,this.getSignals);
                    subSignalNames = strrep(subSignals,signals{ct},''); % remove the top level signal name
                    nSubSignals = length(subSignals);

                    if ~isSingleSignal
                        if nSubSignals>0
                            % Multiple signal case: create a submenu for multiple signals of top level signal signal
                            subMenu = uimenu(cmenu,'Text',signals{ct}, ...
                                'Tag',createName(this,sprintf('AddSubSignalMenu_%s',signals{ct})));

                            if strcmp(this.SignalListType,'Openings') || this.Data.Editable % Openings/Response to plot - allow mimo
                                menuItem1 = uimenu(subMenu,...
                                    'Text',getString(message('Control:compDesignTask:SignalListMenuTopSignalLabel')), ...
                                    'Tag',createName(this,sprintf('AddSubSignalName_%s_All',signals{ct})));
                                menuItem1.MenuSelectedFcn = @(src,evt)addSignal(...
                                    this,signals(ct),signals(ct),subSignalList);

                                menuItem2 = uimenu(subMenu,...
                                    'Text',getString(message('Control:compDesignTask:SignalListMenuSubSignalLabel')), ...
                                    'Tag',createName(this,sprintf('AddSubSignalName_%s_AllSubSignals',signals{ct})));
                                menuItem2.MenuSelectedFcn = @(src,evt)addSignal(...
                                    this,subSignals,signals(ct),subSignalList);
                            end

                            for ctSub=1:nSubSignals
                                menuItem = uimenu(subMenu,'Text',subSignalNames{ctSub}, ...
                                    'Tag',createName(this,sprintf('AddSubSignalName_%s_%d',signals{ct},ctSub)));
                                menuItem.MenuSelectedFcn = @(src,evt)addSignal(...
                                    this,subSignals(ctSub),signals(ct),subSignalList);
                            end
                        end
                    else
                        if nSubSignals>0
                            % Scalar signal
                            menuItem = uimenu(cmenu,'Text',signals{ct}, ...
                                'Tag',createName(this,sprintf('AddSignalName_%d',ct)));
                            menuItem.MenuSelectedFcn = @(src,evt)addSignal(this,signals(ct));
                        end
                    end
                end
            end

            if isSimulink(this.Data.CDD)
                menuItem = uimenu(cmenu, ...
                    'Text',getString(message('Control:compDesignTask:strSelectSignalFromModel')), ...
                    'Tag',createName(this,'AddSignalFromModel'));
                menuItem.MenuSelectedFcn = @(src,evt)cbAddSignalFromModel(this);
            end

            this.Widgets.contextMenu = cmenu;
        end
        
    end

    %% Protected methods
    methods(Access = protected)
        function container = createContainer(this)
            % Creates and returns a panel containing the graphical
            % components.
            %
            %   It creates the widgets using the following panel layout:
            %
            %       -------------------------------------------------------------------------------------------------------------
            %       | panelHeaderLabel                                                                                          |
            %       -------------------------------------------------------------------------------------------------------------
            %       | addSignalButton|-| moveUpSignalButton | moveDownSignalButton | highlightSignalButton | removeSignalButton |
            %       -------------------------------------------------------------------------------------------------------------
            %       | signalNameListBox                                                                                         |
            %       -------------------------------------------------------------------------------------------------------------

            % Create panel header label.
            if isempty(this.SignalListName)
                panelHeaderLabel = '';
                % Three rows: button panel, signal panel, buffer
            else
                label = regexprep(this.SignalListName,'\n','<br>');
                panelHeaderLabel = uilabel('Parent',[]);
                panelHeaderLabel.Text = label;
                panelHeaderLabel.Tag = createName(this,'panelHeaderLabel');
                % Three rows: header, button panel, signal panel, buffer
            end
            this.Widgets.panelHeaderLabel = panelHeaderLabel;

            % Create panel layout.
            signalListPanelLayout = uigridlayout('Parent',this.Parent, ...
                "Tag",createName(this,'signalListPanelLayout') ...
                );
            signalListPanelLayout.ColumnWidth = {'1x'};
            if isempty(panelHeaderLabel)
                signalListPanelLayout.RowHeight = {'fit',this.RowHeight};
                signalListPanelLayout.RowSpacing = 0;
            else
                signalListPanelLayout.RowHeight = {'fit','fit',this.RowHeight};
                signalListPanelLayout.RowSpacing = 5;
            end
            signalListPanelLayout.ColumnSpacing = 0;
            signalListPanelLayout.Padding = 0;
            this.Widgets.signalListPanelLayout = signalListPanelLayout;

            % Add SignalTypeLabel (if not empty).
            rowIndex = 1;
            if ~isempty(panelHeaderLabel)
                panelHeaderLabel.Parent = signalListPanelLayout;
                panelHeaderLabel.Layout.Row = rowIndex;
                panelHeaderLabel.Layout.Column = 1;
                rowIndex = rowIndex + 1;
            end

            % Create button panel layout.
            createTopButtonLayout(this,rowIndex,1)
            rowIndex = rowIndex + 1;

            % Add signal list.
            createSignalPanel(this,rowIndex,1)

            % Create flat context menu.
            createFlatContextMenu(this)

            % Update output argument.
            container = signalListPanelLayout;
        end
    end

    %% Private methods
    methods(Access=private)
        function createSignalPanel(this,row,col)
            % Creates a signal panel.
            import controllib.widget.internal.signallist.SignalEditType

            if this.EditType ~= SignalEditType.Initialization
                return
            end

            % Get current signal list.
            signals = this.getSignals;
            numSignals = numel(signals);

            % Update signal list row height.
            listHeight = this.RowHeight*(numSignals+1);
            this.Widgets.signalListPanelLayout.RowHeight{end} = listHeight;

            listItems = cell(1,numSignals);
            for sigId = 1:numSignals
                listItems{sigId} = signals{sigId};
            end
            signalList = uilistbox(this.Widgets.signalListPanelLayout, ...
                "Items",listItems, ...
                "ItemsData",1:numSignals, ...
                "Value",{}, ...
                'Tag',createName(this,'signalList'), ...
                "ValueChangedFcn",@(src,data)cbSignalList(this,src) ...
                );
            signalList.Layout.Row = row;
            signalList.Layout.Column = col;
            this.Widgets.signalList = signalList;

            this.EditType = controllib.widget.internal.signallist.SignalEditType.None;
        end

        function cbSignalList(this,src)
            % Callback function for signal selection.

            this.SignalIndex = src.Value;
            changeButtonStatusWithSelectedSignalIndex(this)
        end

        function changeButtonStatusWithSelectedSignalIndex(this)
            % Changes button status with the selected signal index.

            index = this.SignalIndex;
            if isempty(index)
                setButtonStatus(this,false(1,4))
                return
            end

            numItems = numel(this.Widgets.signalList.Items);
            if index==1 && numItems>1
                setButtonStatus(this,[false true true true])
            elseif index==numItems && numItems>1
                setButtonStatus(this,[true false true true])
            elseif numItems == 1
                setButtonStatus(this,[false false true true])
            else
                setButtonStatus(this,[true true true true])
            end
        end

        function setButtonStatus(this,status)
            % Sets button status.

            this.Widgets.moveUpSignalButton.Enable = status(1);
            this.Widgets.moveDownSignalButton.Enable = status(2);
            this.Widgets.removeSignalButton.Enable = status(3);
            if ~isempty(this.Widgets.highlightSignalButton)
                this.Widgets.highlightSignalButton.Enable = status(4);
            end
        end

        function createTopButtonLayout(this,row,col)
            % Create top button layout

            % Top button layout
            % ------------------------------------------------------------
            %  -------------                 --   ----   ------   ------
            % |Add Signal V |               |UP| |DOWN| |HILITE| |DELETE|
            %  -------------                 --   ----   ------   ------
            % ------------------------------------------------------------
            buttonLayout = uigridlayout(this.Widgets.signalListPanelLayout,[1 6]);
            buttonLayout.RowHeight = {'fit'};
            buttonLayout.ColumnWidth = {'fit','1x','fit','fit','fit','fit'};
            buttonLayout.Padding = 0;
            buttonLayout.Layout.Row = row;
            buttonLayout.Layout.Column = col;

            % Add signal button
            col = 1;
            signals = this.getSignals;
            numberOfSignals = numel(signals);
            if numberOfSignals==0 || strcmp(this.SignalListType,'Openings') || ...
                    ~this.Data.Editable
                btnLabel = [getString(message(...
                    'Control:compDesignTask:AddSignalContextMenuButtonLabel')) ...
                    ' ' char(9660)];
                addSignalButton = uibutton(buttonLayout, ...
                    "Text",btnLabel, ...
                    'HorizontalAlignment','left', ...
                    'Tag',createName(this,'AddSignalButton'), ...
                    'Interruptible',false, ...
                    'ButtonPushedFcn',@(src,evt)cbAddSignalButton(this,src) ...
                    );
                addSignalButton.Layout.Row = 1;
                addSignalButton.Layout.Column = col;
                this.Widgets.addSignalButton = addSignalButton;
            end
            col = col + 2;

            % Move up button
            moveUpSignalButton = uibutton(buttonLayout,"Text",'', ...
                'IconAlignment','center', ...
                "Enable","off", ...
                'Tag',createName(this,'MoveUpSignalButton'), ...
                "ButtonPushedFcn",@(src,data)cbMoveSignalButton(this,-1) ...
                );
            matlab.ui.control.internal.specifyIconID(moveUpSignalButton,this.UpIcon,16);
            moveUpSignalButton.Layout.Row = 1;
            moveUpSignalButton.Layout.Column = col;
            this.Widgets.moveUpSignalButton = moveUpSignalButton;
            col = col + 1;

            % Move down button
            moveDownSignalButton = uibutton(buttonLayout,"Text",'', ...
                'IconAlignment','center', ...
                "Enable","off", ...
                'Tag',createName(this,'MoveDownSignalButton'), ...
                'ButtonPushedFcn',@(src,data)cbMoveSignalButton(this,1) ...
                );
            matlab.ui.control.internal.specifyIconID(moveDownSignalButton,this.DownIcon,16);
            moveDownSignalButton.Layout.Row = 1;
            moveDownSignalButton.Layout.Column = col;
            this.Widgets.moveDownSignalButton = moveDownSignalButton;
            col = col + 1;

            % Highlight button
            if isSimulink(this.Data.CDD)
                highlightSignalButton = uibutton(buttonLayout,"Text",'', ...
                    'IconAlignment','center', ...
                    "Enable","off", ...
                    'Tag',createName(this,'HighlightSignalButton'), ...
                    "ButtonPushedFcn",@(src,data)cbHighlightSignalButton(this) ...
                    );
                matlab.ui.control.internal.specifyIconID(highlightSignalButton,this.HighlightIcon,16);
                highlightSignalButton.Layout.Row = 1;
                highlightSignalButton.Layout.Column = col;
                this.Widgets.highlightSignalButton = highlightSignalButton;
                col = col + 1;
            end

            % Delete button
            removeSignalButton = uibutton(buttonLayout,"Text",'', ...
                'IconAlignment','center', ...
                "Enable","off", ...
                'Tag',createName(this,'RemoveSignalButton'), ...
                'ButtonPushedFcn',@(src,data)cbRemoveSignalButton(this) ...
                );
            matlab.ui.control.internal.specifyIconID(removeSignalButton,this.RemoveIcon,16);
            removeSignalButton.Layout.Row = 1;
            removeSignalButton.Layout.Column = col;
            this.Widgets.removeSignalButton = removeSignalButton;
        end

        function name = createName(this,value)
            % Create Name for testing by preappending signal list type.
            
            name = sprintf('%s_%s',this.PropertyName,value);
        end

        function Signal = getSignals(this)
            % Returns signals.
            
            if ~isempty(this.Data.(this.PropertyName))
                Signal= this.Data.(this.PropertyName)(:,1);
            else
                Signal = cell(0,1);
            end
        end

        function setSignals(this,SignalToSet)
            % Sets signals.
            
            this.Data.(this.PropertyName) = SignalToSet;
        end

        function tc = getAddSignalFromModelTC(this)
            % Returns TC of add signal from model.
            
            tc = this.AddSignalFromModelTC;
        end

        function updateSignalListPanel(this)
            % Update signal panel using the new signal list content.

            signalListPanelLayout = this.Widgets.signalListPanelLayout;
            if isempty(signalListPanelLayout) || ~isvalid(signalListPanelLayout)
                return
            end

            signals = this.getSignals;
            numSignals = numel(signals);
            signalListPanelLayout.RowHeight{end} = this.RowHeight*(numSignals+1);
            items = cell(1,numSignals);
            itemsData = 1:numSignals;

            for sigId = 1:numSignals
                items{sigId} = signals{sigId};
            end

            this.Widgets.signalList.Items = items;
            this.Widgets.signalList.ItemsData = itemsData;
            if isempty(this.SignalIndex)
                this.Widgets.signalList.Value = {};
            else
                this.Widgets.signalList.Value = this.SignalIndex;
            end

            changeButtonStatusWithSelectedSignalIndex(this)

            this.EditType = controllib.widget.internal.signallist.SignalEditType.None;
        end

        function moveSignal(this,signalToMove,offset)
            % SignalToMove is the signal we want to move
            % offset is the movement: +1 down one, -1 up one
            allSignals = this.getSignals;
            [~,~,commonSignalIndex] = ...
                controllib.widget.internal.utils.newOrCommonItemsInList(...
                signalToMove,allSignals);

            % Don't move signal on top to up and on bottom to down.
            if ((commonSignalIndex+offset)>0) && ...
                    ((commonSignalIndex+offset)<=length(allSignals))
                allSignals([commonSignalIndex+offset commonSignalIndex]) = ...
                    allSignals([commonSignalIndex commonSignalIndex+offset]);
                this.setSignals(allSignals);
                updateUI(this);
            end
        end

        function removeSignal(this,signalToDelete)
            allSignals = this.getSignals;
            [~,commonSignal,commonSignalIndex] = ...
                controllib.widget.internal.utils.newOrCommonItemsInList(...
                signalToDelete,allSignals);

            if ~isempty(commonSignal)
                allSignals(commonSignalIndex,:) = [];
                this.setSignals(allSignals);
                updateUI(this);
            end
        end

        function updateContextMenu(this)
            % Disable a menu item if the corresponding signal is already
            % added in the list.

            % Get the signals added to the list.
            [allSignals,expandedAllSignals] = this.getAvailableSignals;
            [visibleSignals,ids] = setdiff(allSignals,this.getSignals); %#ok<ASGLU>
            numAllSignals = numel(allSignals);
            isVisibleSignal = false(1,numAllSignals);
            if ~isempty(ids)
                isVisibleSignal(ids) = true;
            end

            % Update menu visibility according to the added signals.
            cmenu = this.Widgets.contextMenu;
            children = cmenu.Children;
            numChildren = numel(children);
            if isSimulink(this.Data.CDD)
                children(1).Visible = true;
            end
            for i = 1:numAllSignals
                children(numChildren-i+1).Visible = isVisibleSignal(i);
                if isVisibleSignal(i)
                    % Update submenu visibility according to the added
                    % signals. Determine whether there are subsignals.
                    [allSubSignalList,isSingleSignal] = ...
                        controllib.widget.internal.utils.expandSignalList(...
                        allSignals{i},expandedAllSignals);

                    if isSingleSignal
                        continue
                    end

                    % Find visible sub signals.
                    [visibleSubSignals,ids] = setdiff(allSubSignalList,this.getSignals); %#ok<ASGLU>
                    numAllSubSignals = numel(allSubSignalList);
                    isVisibleSubSignal = false(1,numAllSubSignals);
                    if ~isempty(ids)
                        % We can remove this empty-check since
                        % isVisibleSignal(i) is true, which indicates there
                        % must be at least one sub signal.
                        isVisibleSubSignal(ids) = true;
                    end
                    grandChildren = children(numChildren-i+1).Children;
                    numGrandChildren = numel(grandChildren);
                    for j = 1:numAllSubSignals
                        grandChildren(numAllSubSignals-j+1).Visible = isVisibleSubSignal(j);
                    end
                    for j = numAllSubSignals+1:numGrandChildren
                        if strcmp(this.SignalListType,'Openings') || this.Data.Editable
                            grandChildren(j).Visible = true;
                        else
                            grandChildren(j).Visible = false;
                        end
                    end
                end
            end

        end

        function cbMoveSignalButton(this,offset)
            % Callback function to move a signal up/down in the list.

            if offset < 0
                this.EditType = controllib.widget.internal.signallist.SignalEditType.MoveUp;
            elseif offset > 0
                this.EditType = controllib.widget.internal.signallist.SignalEditType.MoveDown;
            end
            ct = this.SignalIndex;
            this.SignalIndex = this.SignalIndex + offset;

            signal = this.getSignals;
            signal = signal(ct);
            
            % Remove from tc data.
            this.moveSignal(signal,offset);
        end

        function cbRemoveSignalButton(this)
            % Get signal name of the row that remove button is clicked.

            this.EditType = controllib.widget.internal.signallist.SignalEditType.Remove;

            % Get current selected signal.
            ct = this.SignalIndex;
            signal = this.getSignals;
            signal = signal(ct);

            % Updated index of the selected signal.
            numItems = numel(this.Widgets.signalList.Items);
            tmpSignalIndex = this.SignalIndex - 1;
            tmpNumItems = numItems - 1;
            if tmpSignalIndex < 1
                % First item is deleted
                if tmpNumItems == 0
                    % The list is empty
                    this.SignalIndex = [];
                else
                    % The list is not empty
                    this.SignalIndex = 1;
                end
            else
                % Non-first item deleted.
                if tmpNumItems > tmpSignalIndex
                    % Non-last item deleted.
                    this.SignalIndex = tmpSignalIndex + 1;
                else%if tmpNumItems == tmpSignalIndex
                    % The lst item deleted.
                    this.SignalIndex = tmpSignalIndex;
                end
            end

            % Remove the signal from tc data.
            removeSignal(this,signal)
        end

        function cbHighlightSignalButton(this)
            % Callback function for highlighting a signal in the model.

            ct = this.SignalIndex;

            try
                model = this.Data.CDD.getArchitectureName();
                if ~any(strcmp(find_system('type','block_diagram','Shown','on'),model))
                    open_system(model);
                end
                point = this.Data.CDD.resolveSignalID(this.getSignals{ct});
                blockPath = point.Block;                
                linearize.advisor.utils.go2block(blockPath)                
                
                this.HighlightSignalStatus = true;
            catch ME
                this.HighlightSignalStatus = false;
                throw(ME);
            end
        end

        function cbAddSignalButton(this,src)
            % Creates a contextmenu with available signals to add in the
            % signal list panel.

            this.EditType = controllib.widget.internal.signallist.SignalEditType.Add;

            % Update the signal-list context menu.
            if isempty(this.Widgets.contextMenu)
                createFlatContextMenu(this)
            else
                updateContextMenu(this)
            end

            % Draw now to ensure that the contextmenu is shown.
            drawnow

            % Get context menu position. Context menu is not shown if
            % position is (1,1). So, max logic is temporarily used here
            % until the isssue is addressed.
            pos = max(getpixelposition(src,true),2);
            
            % Show the context menu.
            open(this.Widgets.contextMenu,pos(1),pos(2))
        end

        function cbAddSignalFromModel(this)
            % Create and show add signal dialog

            this.EditType = controllib.widget.internal.signallist.SignalEditType.Add;

            visibleDlg = @(x)~isempty(x) && isvalid(x)&& x.IsVisible;
            if visibleDlg(this.AddSignalFromModelDialog)
                figure(this.AddSignalFromModelDialog.getWidget)
                return
            end

            if isempty(this.AddSignalFromModelDialog)            
                dlg = controllib.widget.internal.signallist.AddSignalFromModelDialog(...
                    this.Data.CDD.getArchitectureName());
                
                registerUIListeners(dlg,addlistener(dlg,'CloseEvent', ...
                    @(src,data)cbCancelButton(this)))
                
                dlg.HelpFcn = @(src,data)cbHelpButton(this);
                dlg.CancelFcn = @(src,data)cbCancelButton(this);
                dlg.AddSignalFcn = @(src,data)cbAddSignalsDialogButton(this);
                this.AddSignalFromModelDialog = dlg;
                this.Widgets.addSignalFromModelDialog = dlg;
            end
            
            show(this.AddSignalFromModelDialog,this.Widgets.addSignalButton)
        end

        function cbHelpButton(this) %#ok<MANU>
            % Callback function for the help button of add signal from
            % model dialog.
            
            ctrlguihelp('CSD_AddSignalFromModelHelp','CSHelpWindow');
        end
        
        function cbCancelButton(this)
            % Callback function for the cancel button of add signal from
            % model dialog.
            
            reset(this.AddSignalFromModelDialog)
            close(this.AddSignalFromModelDialog)
        end
        
        function cbAddSignalsDialogButton(this)
            % Callback function for the add signal button of add signal
            % from model dialog.

            fig = this.AddSignalFromModelDialog.getWidget;
            currPointer = controllib.widget.internal.utils.setPointer(fig,'watch');
            restorePointer = onCleanup(@()controllib.widget.internal.utils.setPointer(fig,currPointer));

            [blockPaths,portIndexes] = getBlockPathsAndPortNums(this.AddSignalFromModelDialog);
            numSignals =numel(blockPaths);
            if numSignals > 0
                if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.Data.CDD.getArchitectureName()))
                    open_system(this.Data.CDD.getArchitectureName());
                end
                for ct=1:numSignals
                    pointsToAdd(ct) = linio(blockPaths{ct},portIndexes(ct),'input'); %#ok<AGROW>
                end
                feval(this.Data.CDD.getAddSignalFcnName,this.Data.CDD.getArchitecture,pointsToAdd);
                [Names,Points] = this.Data.CDD.getArchitecture.getPoints;
                if strcmp(this.SignalListType,'Openings') || ~this.Data.Editable
                    for ct=1:numSignals
                        slTunerPointName = Names(arrayfun(@(x) isequal(x.Block,blockPaths{ct}) & isequal(x.PortNumber,portIndexes(ct)),Points));
                        addSignal(this,slTunerPointName);
                    end
                else
                    slTunerPointName = Names(arrayfun(@(x) isequal(x.Block,blockPaths{1}) & isequal(x.PortNumber,portIndexes(1)),Points));
                    [~,expandedList] = getAvailableSignals(this);
                    [subSignalList,isSingleSignal]=controllib.widget.internal.utils.expandSignalList(slTunerPointName{:},expandedList);
                    if isSingleSignal
                        subSignalList = {subSignalList};
                    end
                    addSignal(this,subSignalList(1));
                end
                cbCancelButton(this)
            else
                delete(restorePointer)
                msg = getString(message(...
                    'Control:compDesignTask:AddSignalFromModelDialogError'));
                okLabel = getString(message("Controllib:gui:strOK"));
                uiconfirm(fig,msg,this.AddSignalFromModelDialog.Title,'Options',{okLabel}, ...
                    'Icon','error')
            end
        end
        
        function [List,ExpandedList] = getAvailableSignals(this)
            switch lower(this.SignalListType)
                case {'input'}
                    [List,ExpandedList] = this.Data.CDD.getAvailableSignals('Inputs');
                case 'output'
                    [List,ExpandedList] = this.Data.CDD.getAvailableSignals('Outputs');
                case {'location','openings','disturbanceinput'}
                    [List,ExpandedList] = this.Data.CDD.getAvailableSignals('Locations');
                case {'all'}
                    [List,ExpandedList] = this.Data.CDD.getAvailableSignals('All');
            end
        end

    end

    %% Hidden methods
    methods(Hidden)
        function addSignal(this,signalToAdd,topSignal,subSignalList)
            if nargin==2 % single signal call
                topSignal = signalToAdd;
                subSignalList = cell(0,1);
            end

            allSignals = this.getSignals;
            % The following utility function should be in a general shared
            % package.
            newSignal = ...
                controllib.widget.internal.utils.newOrCommonItemsInList(...
                signalToAdd,allSignals);

            if ~isempty(newSignal)
                % If there are added ones, update list
                allSignals = vertcat(allSignals,newSignal);
                if isempty(subSignalList) % extract all subsignals
                    [~,ExpandedAllAvailabeSignals] = this.getAvailableSignals;
                    % The following utility function should be in a general
                    % shared package.
                    [subSignalList,isSingleSignal]= ...
                        controllib.widget.internal.utils.expandSignalList(...
                        signalToAdd{1},ExpandedAllAvailabeSignals);
                else
                    isSingleSignal = false;
                end

                if ~isSingleSignal % for multiple signal
                    if strcmp(signalToAdd,topSignal) % you want to add top signal, remove all sub signals
                        allSignals = setdiff(allSignals,subSignalList,'stable');
                    else % you want to add either all subsignals or o sub signal, then remove the top signal (if any)
                        allSignals = setdiff(allSignals,topSignal,'stable'); % remove top signal
                    end
                end
                setSignals(this,allSignals)
                % We don't need this updateUI call since any change in the
                % this.PropertyName signal will invoke updateUI.
            end

        end
        
        function status = qeGetHighlightSignalStatus(this)
            % Returns highlight status of a signal.
            
            status = this.HighlightSignalStatus;
        end

        function qeSetHighlightSignalStatus(this,status)
            % Sets value of HighlightSignalStatus flag.
            
            if islogical(status)
                this.HighlightSignalStatus = status;
            end
        end

        function widgets = qeGetWidgets(this)
            % Returns widgets.
            
            widgets = this.Widgets; 
            widgets.slp = this;
        end

        function selectSignal(this,index)
            clickListItem(this.Widgets.signalList,index)
        end
    end

end
%% Local functions
function clickListItem(src,index)
src.Value = index;
eventData = []; % Not used.
src.ValueChangedFcn(src,eventData)
end

function mustBeValid(value)
if isempty(value) || ~isvalid(value)
    error(message( 'MATLAB:class:InvalidHandle'))
end
end

function mustBeValidIfNonempty(value)
if isempty(value)
    return
end

if ~isscalar(value) || ~isvalid(value)
    error('Must be a valid scalar grid layout object.')
end
end

function mustBeValidInteger(value)
if isempty(value)
    return
end
mustBeScalarOrEmpty(value)
mustBeNumeric(value)
mustBePositive(value)
mustBeInteger(value)
end