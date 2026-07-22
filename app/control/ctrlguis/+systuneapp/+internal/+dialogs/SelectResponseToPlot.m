classdef SelectResponseToPlot < controllib.ui.internal.dialog.AbstractDialog
    %% SELECTRESPONSETOPLOT Selects and plots a response.

    %  Copyright 2013-2021 The MathWorks, Inc.

    %% Properties
    properties(Access=private)
        ControlDesignData
        PlotManager
        Widgets = struct(...
            'DialogLayout', [], ...
            'ResponseLabel', [], ...
            'ResponseDropDown', [], ...
            'IOTransferPanel',[], ...
            'LoopTransferPanel',[], ...
            'SensitivityTransferPanel',[], ...
            'EntireSystemTransferPanel',[], ...
            'TunedBlockResponsePanel',[], ...
            'ResponseDetailsText', [], ...
            'PlotButton', [], ...
            'CancelButton', [] ...
            );
        PlotType
        ResponseDialogTC
        ResponseDialogGC
        ResponseDetailsTextHeight = 200;
        DialogWidth = 410;
        DialogHeight = 375;
        RowSpacing = 10;
    end

    %% Constructor & destructor
    methods
        function this = SelectResponseToPlot(controlDesignData, plotManager, plotType)
            %% Constructs a SelectResponseToPlot object.

            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.ControlDesignData = controlDesignData;
            this.PlotManager = plotManager;
            this.PlotType = plotType;
            this.Title = systuneapp.PlotEnum.getNewPlotTitle(this.PlotType.Tag);
            this.Name = 'SelectResponseDialog';
            this.CloseMode = 'destroy';
        end

        function delete(this)
            %% Release handle objects.

            cleanupUI(this)
            clear this
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            %% Updates UI.

            disableUIListeners(this);
            cbSwapResponsePanel(this);
            enableUIListeners(this);
        end
    end

    %% Protected methods.
    methods(Access=protected)
        function buildUI(this)

            %   Creates dialog using the following layout:
            %   ------------------------
            %   | ResponseDropdown     |
            %   ------------------------
            %   | ResponsePanel        |
            %   ------------------------
            %   | ButtonPanel          |
            %   ------------------------

            % Set dialog size.
            this.UIFigure.Position(3:4) = [this.DialogWidth this.DialogHeight];
            responseItems = createResponseItems(this);
            createDialogLayout(this)
            createResponseDropdown(this,responseItems)
            createResponseDetailsText(this)
            createButtonPanel(this)
            cbSwapResponsePanel(this)
        end

        function connectUI(this)
            %% Adds listeners to the interactive widgets.
            weakThis = matlab.lang.WeakReference(this);
            registerUIListeners(this, addlistener(this, ...
                'CloseEvent', @(es, ed)delete(weakThis.Handle)))
            registerUIListeners(this, addlistener(this.Widgets.ResponseDropDown, ...
                'ValueChanged', @(es, ed)cbSwapResponsePanel(weakThis.Handle)),...
                'ResponseDropDownListener')
            registerUIListeners(this, addlistener(this.Widgets.PlotButton, ...
                'ButtonPushed', @(es, ed)cbPlot(weakThis.Handle)))
            registerUIListeners(this, addlistener(this.Widgets.CancelButton, ...
                'ButtonPushed', @(es, ed)cbCancel(weakThis.Handle)))

            registerDataListeners(this,addlistener(this.ControlDesignData, ...
                findprop(this.ControlDesignData,'Responses'),'PostSet',@(s,e)updateWidgets(weakThis.Handle)), ...
                'ResponseListChangeListener')
        end

        function cleanupUI(this)
            %% Cleans up UI components and related data.

            % Delete widgets.
            if this.IsWidgetValid
                % ResponseDialogGC widgets are also destroyed when deleting
                % the dialog widget.

                delete(this.getWidget)
            end

            % Response detail text might be valid if unparented.
            deleteIfValid(this.Widgets.ResponseDetailsText)

            % Delete data.
            deleteIfValid(this.ResponseDialogTC)
        end
    end

    %% Private methods.
    methods(Access=private)
        function updateWidgets(this)
            %% Updates widgets.

            disableUIListeners(this);
            if this.IsWidgetValid
                updatesResponseDropdown(this)
                cbSwapResponsePanel(this);
            end
            enableUIListeners(this);
        end

        function updatesResponseDropdown(this)
            %% Updates response drop down list.

            [responseItems,numResponsesFromDB] = createResponseItems(this);
            this.Widgets.ResponseDropDown.Items = responseItems;
            if numResponsesFromDB == 0
                this.Widgets.ResponseDropDown.Value = responseItems{1};
            else
                this.Widgets.ResponseDropDown.Value = responseItems{numResponsesFromDB};
            end
        end

        function [responseItems,numResponsesFromDB] = createResponseItems(this)
            %% Creates response item list.


            % We want the option to plot the entire system response and the
            % plot of a selected block if the plot is a pole-zero plot and if
            % there is atleast one analysis point in specified
            defaultResponses = {...
                getString(message('Control:systunegui:NewIOTransferResponse')), ...
                getString(message('Control:systunegui:NewLoopTransferResponse')),...
                getString(message('Control:systunegui:NewSensitivityTransferResponse'))...
                };
            responsesFromDB = getResponseName(this.ControlDesignData);
            numResponsesFromDB = numel(responsesFromDB);
            responsesFromDB = sort(responsesFromDB);
            responseItems = [responsesFromDB', defaultResponses];

            % We don't want loop-transfer response if the plot is not a
            % frequency domain plot.
            if ~(strcmp(this.PlotType.Tag , 'bode') || ...
                    strcmp(this.PlotType.Tag , 'sigma') || ...
                    strcmp(this.PlotType.Tag , 'nyquist') || ...
                    strcmp(this.PlotType.Tag , 'nichols'))

                responseItems(end-1) = [];
            end

            if (strcmp(this.PlotType.Tag , 'pzmap') || strcmp(this.PlotType.Tag , 'iopzmap')) ...
                    && ~isempty(this.ControlDesignData.getArchitecture.TunedBlocks)
                % Add Tuned Block Response for pzplots
                addTunedBlockResponse = getString(message('Control:systunegui:NewTunedBlockResponse'));
                responseItems = [responseItems, addTunedBlockResponse];
            end
            if (strcmp(this.PlotType.Tag , 'pzmap') || strcmp(this.PlotType.Tag , 'iopzmap')) ...
                    && ~isempty(this.ControlDesignData.getAvailableSignals)
                % We want the option to plot the entire system response and the
                % plot of a selected block if the plot is a pole-zero plot and if
                % there is atleast one analysis point in specified
                addEntireSysResponse = getString(message('Control:systunegui:NewEntireSystemResponse'));
                responseItems = [responseItems, addEntireSysResponse];
            end
        end

        function resetResponsePanel(this)
            %% Unparents details text and reset layout format.

            this.Widgets.ResponseDetailsText.Parent = [];
            this.Widgets.DialogLayout.RowHeight{2} = '1x';
        end

        function wt = createTransferResponsePanel(this,type)
            %% Creates a response panel.

            names = '';
            responses = getResponse(this.ControlDesignData);
            for ct = 1:length(responses)
                names = [names, getName(responses(ct))]; %#ok<AGROW>
            end
            n = 1;
            while contains(names,sprintf('%s%d',type,n))
                n = n+1;
            end
            name = sprintf('%s%d',type,n);
            this.ResponseDialogGC = createView(this.ResponseDialogTC);
            this.ResponseDialogGC.ShowButtons = false;
            this.ResponseDialogGC.Padding = 0;
            this.ResponseDialogGC.RowSpacing = 10;
            resetResponsePanel(this)
            wt = createWidgets(this.ResponseDialogGC, ...
                this.Widgets.DialogLayout,2,[1 2],name);
        end

        function wt = createIOTransferResponsePanel(this)
            %% Creates panel for input-output transfer response.
            import systuneapp.internal.panels.ResponseInputOutputTransferTC

            this.ResponseDialogTC = ResponseInputOutputTransferTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'IOTransfer');
        end

        function wt = createOpenLoopResponsePanel(this)
            %% Creates panel for open loop response.
            import systuneapp.internal.panels.ResponseLoopTransferTC

            this.ResponseDialogTC = ResponseLoopTransferTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'LoopTransfer');            
        end

        function wt = createSensitivityResponsePanel(this)
            %% Creates panel for sensitivity response.
            import systuneapp.internal.panels.ResponseSensitivityTransferTC

            this.ResponseDialogTC = ResponseSensitivityTransferTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'SensitivityTransfer');            
        end

        function wt = createEntireSystemResponsePanel(this)
            %% Creates panel for entire system response.
            import systuneapp.internal.panels.ResponseEntireSystemTC

            this.ResponseDialogTC = ResponseEntireSystemTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'IOTransfer');
        end

        function wt = createTunedBlockResponsePanel(this)
            %% Creates panel for tuned block response.
            import controllib.widget.internal.responseplot.ResponseTunedBlockTC

            this.ResponseDialogTC = ResponseTunedBlockTC(this.ControlDesignData);
            this.ResponseDialogGC = createView(this.ResponseDialogTC);
            this.ResponseDialogGC.ShowButtons = false;
            this.ResponseDialogGC.Padding = 0;
            resetResponsePanel(this)
            wt = createWidgets(this.ResponseDialogGC, ...
                this.Widgets.DialogLayout, 2, [1 2]);
        end

        function createDialogLayout(this)
            %% Creates dialog layout.

            dialogLayout = uigridlayout(this.UIFigure,[3 2]);
            dialogLayout.RowHeight = {'fit','1x','fit'};
            dialogLayout.ColumnWidth = {'fit','1x'};
            dialogLayout.RowSpacing = this.RowSpacing;
            dialogLayout.ColumnSpacing = 5;
            dialogLayout.Padding = 10;

            this.Widgets.DialogLayout = dialogLayout;
        end

        function createResponseDropdown(this, responseItems)
            %% Creates a dropdown list of different response types.

            responseLabel = uilabel('Parent', this.Widgets.DialogLayout, 'Text', ...
                getString(message('Control:systunegui:SelectResponseToPlot')));
            responseLabel.Layout.Row = 1;
            responseLabel.Layout.Column = 1;
            responseDropDown = uidropdown('Parent', this.Widgets.DialogLayout, ...
                'Items',responseItems);
            responseDropDown.Layout.Row = 1;
            responseDropDown.Layout.Column = 2;

            this.Widgets.ResponseLabel = responseLabel;
            this.Widgets.ResponseDropDown = responseDropDown;
        end

        function createResponseDetailsText(this)
            %% Creates a response details text.

            if isempty(this.Widgets.ResponseDetailsText)
                responseDetailsText = uitextarea('Parent',[]);
                responseDetailsText.Editable = 'off';
                responseDetailsText.Enable = 'off';

                this.Widgets.ResponseDetailsText = responseDetailsText;
            end

            if isempty(this.Widgets.ResponseDetailsText.Value)
                return
            end

            this.Widgets.ResponseDetailsText.Parent = this.Widgets.DialogLayout;
            this.Widgets.ResponseDetailsText.Layout.Row = 2;
            this.Widgets.ResponseDetailsText.Layout.Column = [1 2];
        end

        function createButtonPanel(this)
            %% Creates a bottom button panel.
            import controllib.widget.internal.buttonpanel.ButtonPanel

            parentLayout = this.Widgets.DialogLayout;
            buttonPanel = ButtonPanel(parentLayout,"Cancel","Commit",1);
            buttonContainer = getWidget(buttonPanel);
            buttonContainer.Layout.Row = numel(parentLayout.RowHeight);
            buttonContainer.Layout.Column = [1 2];
            buttonContainer.Padding = [0 0 0 this.RowSpacing];
            buttonContainer.Scrollable = 'on';

            plotBtnId = 2;
            buttonContainer.ColumnWidth{plotBtnId} = buttonPanel.ButtonWidth;
            plotButton = uibutton('Parent', buttonContainer, ...
                'Text', getString(message('Control:designerapp:PlotResponse')));
            plotButton.Layout.Row = 1;
            plotButton.Layout.Column = 2;

            this.Widgets.PlotButton = plotButton;
            this.Widgets.CancelButton = buttonPanel.CancelButton;
            this.Widgets.ButtonPanel = buttonPanel;
        end

        function cbSwapResponsePanel(this)
            %% Updates the response panel with the current selection.

            % Clean-up past ResponseDialogTC/GC
            deleteIfValid(this.ResponseDialogTC);
            deleteIfValid(this.ResponseDialogGC);

            % swap panel depending on dropdown selection
            switch this.Widgets.ResponseDropDown.Value
                case getString(message('Control:systunegui:NewIOTransferResponse'))
                    this.Widgets.IOTransferPanel = createIOTransferResponsePanel(this);
                case getString(message('Control:systunegui:NewLoopTransferResponse'))
                    this.Widgets.LoopTransferPanel = createOpenLoopResponsePanel(this);
                case getString(message('Control:systunegui:NewSensitivityTransferResponse'))                    
                    this.Widgets.SensitivityTransferPanel = createSensitivityResponsePanel(this);
                case getString(message('Control:systunegui:NewEntireSystemResponse'))
                    this.Widgets.EntireSystemTransferPanel = createEntireSystemResponsePanel(this);
                case getString(message('Control:systunegui:NewTunedBlockResponse'))
                    this.Widgets.TunedBlockResponsePanel = createTunedBlockResponsePanel(this);
                otherwise
                    responses = getResponse(this.ControlDesignData);
                    responseNames = getResponseName(this.ControlDesignData);

                    selectedResponseName = this.Widgets.ResponseDropDown.Value;
                    index = strfind(responseNames, selectedResponseName);
                    for ind = 1:numel(index)
                        if ~isempty(index{ind})
                            idx = ind;
                        end
                    end

                    selectedResponse = responses(idx).Response;
                    ResponseDetails = selectedResponse.getDisplayPreviewText;
                    this.Widgets.ResponseDetailsText.Value = ResponseDetails;
                    createResponseDetailsText(this)
            end
        end

        function cbPlot(this)
            %% Callback function for plot button.

            fig = this.UIFigure;
            currPointer = controllib.widget.internal.utils.setPointer(fig,'watch');
            restorePointer = onCleanup(@()controllib.widget.internal.utils.setPointer(fig,currPointer));
            disableUIListeners(this,'ResponseDropDownListener');

            try
                if strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:systunegui:NewIOTransferResponse'))) ...
                        || strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:systunegui:NewSensitivityTransferResponse')))...
                        || strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:systunegui:NewLoopTransferResponse')))...
                        || strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:systunegui:NewEntireSystemResponse')))
                    switch this.Widgets.ResponseDropDown.Value
                        case getString(message('Control:systunegui:NewIOTransferResponse'))
                            responseName = this.Widgets.IOTransferPanel.responseEditField.Value;
                        case getString(message('Control:systunegui:NewSensitivityTransferResponse'))
                            responseName = this.Widgets.SensitivityTransferPanel.responseEditField.Value;
                        case getString(message('Control:systunegui:NewLoopTransferResponse'))
                            responseName = this.Widgets.LoopTransferPanel.responseEditField.Value;
                        case getString(message('Control:systunegui:NewEntireSystemResponse'))
                            responseName = this.Widgets.EntireSystemTransferPanel.responseEditField.Value;
                    end
                    this.ResponseDialogTC.Name = responseName;
                    disableDataListeners(this,'ResponseListChangeListener')
                    setResponse(this.ResponseDialogTC);
                    responses = this.ControlDesignData.getResponse;
                    responseList = arrayfun(@(x)getName(x),responses, 'UniformOutput', false);
                    listIndex = arrayfun(@(x) strcmp(x,responseName),responseList);
                    responseToPlot = responses(listIndex);
                    this.PlotManager.createResponsePlot(responseToPlot,this.PlotType);
                elseif strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:systunegui:NewTunedBlockResponse')))
                    tunedBlockName = this.ResponseDialogGC.qeGetWidgets.tunableElementListBox.Value;
                    listIndex = arrayfun(@(x) contains(x,['/',tunedBlockName]),...
                        this.ControlDesignData.getArchitecture.TunedBlocks);
                    tunedBlocks = this.ControlDesignData.getTunableBlock;
                    if ~any(listIndex)
                        % Use TunableBlocks from ControlDesignData if
                        % listIndex is not found using the TunedBlocks in
                        % Architecture. This happens in the case where
                        % blocks are added after opening the app, and are
                        % then named as "modelname_blockname".
                        listIndex = arrayfun(@(x) contains(x,tunedBlockName),{tunedBlocks.Name});
                    end
                    this.PlotManager.createTunedBlockPlot(tunedBlocks(find(listIndex,1)), this.PlotType);
                else
                    responses = this.ControlDesignData.getResponse;
                    responseNames = arrayfun(@(x)getName(x),responses, 'UniformOutput', false);
                    listIndex = arrayfun(@(x) strcmp(x,this.Widgets.ResponseDropDown.Value),responseNames);
                    this.PlotManager.createResponsePlot(responses(find(listIndex,1)),this.PlotType)
                end
                delete(this)
            catch ME
                delete(restorePointer)
                uialert(fig,ME.message,this.Title,'Icon','error');
                enableDataListeners(this,'ResponseListChangeListener')
                enableUIListeners(this,'ResponseDropDownListener');
            end
        end
        
        function cbCancel(this)
            %% Callback function for cancel button.

            delete(this)
        end

    end

    %% Hidden methods.
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            %% Returns UI components.

            widgets = this.Widgets;
        end

        function tc = qeGetTC(this)
            tc = this.ResponseDialogTC;
        end

        function qeSwapResponsePanel(this)
            cbSwapResponsePanel(this);
        end
    end

end
%% Local functions --------------------------------------------------------
function deleteIfValid(h)
%% Delete handle if nonempty and valid.

if ~isempty(h) && isvalid(h)
    delete(h)
end
end