classdef SelectResponseToPlot < controllib.ui.internal.dialog.AbstractDialog
    % Class for selection and plot of a response in Control System Tuner
    % App.
    
    % Copyright 2013 - 2021 The MathWorks, Inc.
    
    properties (GetAccess = public, SetAccess = protected)
        ControlDesignData
        PlotManager
        Widgets = struct(...
            'DialogLayout', [], ...
            'ResponseLabel', [], ...
            'ResponseDropDown', [], ...
            'IOTransferPanel',[], ...
            'LoopTransferPanel',[], ...
            'SensitivityTransferPanel',[], ...
            'TunedBlockResponsePanel',[], ...
            'ResponseDetailsText', [], ...
            'ResponseArchitectureLayout', [], ...
            'ResponseArchitectureLabel', [], ...
            'ResponseArchitectureIcon', [], ...
            'PlotButton', [], ...
            'CancelButton', [], ...
            'HelpButton', [] ...
            );
        PlotType
        ResponseDialogTC
        ResponseDialogGC
        ResponseDetailsTextHeight = 200;
        IconHeight = 200;
        IconWidth = 515;
        DialogWidth = 535;
        DialogHeight = 625;
        RowSpacing = 10;
        LabelHeight = 20;
    end
   
    methods (Access = public)
        
        % Constructor
        function this = SelectResponseToPlot(controlDesignData, plotManager, plotType)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            this.ControlDesignData = controlDesignData;
            this.PlotManager = plotManager;
            this.PlotType = plotType;
            if isa(plotType,'ctrlguis.csdesignerapp.plot.internal.PlotEnum')
                this.Title = ctrlguis.csdesignerapp.plot.internal.PlotEnum.getNewPlotTitle(plotType.Tag);
            end
            this.Name = "CSDApp_NewPlotDialog" + matlab.lang.internal.uuid;
            this.CloseMode = 'destroy';
        end
        
        % Other Public methods
        function updateUI(this)
            disableUIListeners(this);
            cbSwapResponsePanel(this);
            enableUIListeners(this);
        end
    end

    methods(Access=protected)
        function buildUI(this)
            
            %   Creates dialog using the following layout:
            %   ------------------------
            %   | ResponseDropdown     |
            %   ------------------------
            %   | ResponsePanel        |
            %   ------------------------
            %   | ArchitecturePanel    |
            %   ------------------------
            %   | ButtonPanel          |
            %   ------------------------
            
            % Populate responses from DataBrowser (DB) and the Default
            % Panels
            responsesFromDB = getResponsesNames(this.ControlDesignData);
            responsesFromDB = sort(responsesFromDB);
            
            
            % We want the option to plot a selected block if the plot is a
            % pole-zero plot and if there is atleast one analysis point in
            % specified.
            defaultResponses = {getString(message('Control:designerapp:NewIOTransferResponse')), ...
                    getString(message('Control:designerapp:NewLoopTransferResponse')),...
                    getString(message('Control:designerapp:NewSensitivityTransferResponse'))};
            responseItems = [responsesFromDB', defaultResponses];
            
            % We don't want loop-transfer response if the plot is not a
            % frequency domain plot
            if ~(strcmp(this.PlotType.Tag , 'bode') || ...
                    strcmp(this.PlotType.Tag , 'sigma') || ...
                    strcmp(this.PlotType.Tag , 'nyquist') || ...
                    strcmp(this.PlotType.Tag , 'nichols'))

                responseItems(end-1) = [];
            end
            
            if (strcmp(this.PlotType.Tag , 'pzmap') || strcmp(this.PlotType.Tag , 'iopzmap')) ... 
                    && ~isempty(this.ControlDesignData.getArchitecture.getTunedBlocks)
                % Add Tuned Block Response for pzplots
                addTunedBlockResponse = getString(message('Control:designerapp:NewTunedBlockResponse'));
                responseItems = [responseItems, addTunedBlockResponse];
            end
            
            createDialogLayout(this)
            createResponseDropdown(this, responseItems)
            createResponseDetailsText(this)
            createArchitecturePanel(this)
            createButtonPanel(this)
            cbSwapResponsePanel(this)
        end

        function connectUI(this)
            %% Adds listeners.

            registerUIListeners(this, addlistener(this, ...
                'CloseEvent', @(es, ed)delete(this)))
            registerUIListeners(this, addlistener(this.Widgets.ResponseDropDown, ...
                'ValueChanged', @(es, ed)cbSwapResponsePanel(this)),...
                'ResponseDropDownListener');
            registerUIListeners(this, addlistener(this.Widgets.HelpButton, ...
                'ButtonPushed', @(es, ed)cbHelpButton(this)));
            registerUIListeners(this, addlistener(this.Widgets.PlotButton, ...
                'ButtonPushed', @(es, ed)cbPlotButton(this)));
            registerUIListeners(this, addlistener(this.Widgets.CancelButton, ...
                'ButtonPushed', @(es, ed)cbCancelButton(this)));
        end

        function cleanupUI(this)
            % Delete widgets.
            if this.IsWidgetValid
                % ResponseDialogGC widgets are also destroyed when deleting
                % the dialog widget.

                delete(this.getWidget)
            end

            % Response detail text might be valid if unparented.
            deleteIfValid(this.Widgets.ResponseDetailsText)

            % Response architecture layout might be valid if unparented.
            deleteIfValid(this.Widgets.ResponseArchitectureLayout)
            
            % Delete data.
            deleteIfValid(this.ResponseDialogTC)
        end
                        
        function createDialogLayout(this)
            %% Creates a dialog layout.
            dialogLayout = uigridlayout(this.UIFigure,[4 2]);
            dialogLayout.RowHeight = {'fit','1x','fit','fit'};
            dialogLayout.ColumnWidth = {'fit','1x'};
            dialogLayout.RowSpacing = this.RowSpacing;
            dialogLayout.ColumnSpacing = 5;
            dialogLayout.Padding = 10;
            dialogLayout.Scrollable = true;

            this.Widgets.DialogLayout = dialogLayout;            
        end
        
        function createResponseDropdown(this,responseItems)
            %% Creates a response drop down list.

            % Set the header label
            responseLabel = uilabel('Parent', this.Widgets.DialogLayout, 'Text', ...
                getString(message('Control:designerapp:SelectResponseToPlot')));
            responseLabel.Layout.Row = 1;
            responseLabel.Layout.Column = 1;
            % Create the dropwdown
            responseDropDown = uidropdown('Parent', this.Widgets.DialogLayout, ...
                'Items',responseItems);
            responseDropDown.Layout.Row = 1;
            responseDropDown.Layout.Column = 2;

            this.Widgets.ResponseLabel = responseLabel;
            this.Widgets.ResponseDropDown = responseDropDown;
        end
        
        function createResponseDetailsText(this)
            %% Creates a response detail text.

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
        
        function createArchitecturePanel(this)
            %% Creates an architecture panel.

            icon = getArchitectureIcon(getArchitecture(this.ControlDesignData));
            if ~isempty(icon) && ~isSimulink(getArchitecture(this.ControlDesignData))
                if isempty(this.Widgets.ResponseArchitectureLayout)
                    archPanelLayout = uigridlayout('Parent',[]);
                    archPanelLayout.RowHeight = {'fit', this.IconHeight};
                    archPanelLayout.ColumnWidth = {'1x',this.IconWidth,'1x'};
                    archPanelLayout.RowSpacing = this.RowSpacing;
                    archPanelLayout.ColumnSpacing = 0;
                    archPanelLayout.Padding = 0;
                    % archPanelLayout.Scrollable = 'on';

                    this.Widgets.ResponseArchitectureLayout = archPanelLayout;
                end
                this.Widgets.ResponseArchitectureLayout.Parent = this.Widgets.DialogLayout;
                this.Widgets.ResponseArchitectureLayout.Layout.Row = 3;
                this.Widgets.ResponseArchitectureLayout.Layout.Column = [1 2];

                if isempty(this.Widgets.ResponseArchitectureLabel)
                    responseArchitectureLabel = uilabel('Parent', archPanelLayout, 'Text', ...
                        getString(message('Control:designerapp:ArchitectureResponse')));
                    responseArchitectureLabel.Layout.Row = 1;
                    responseArchitectureLabel.Layout.Column = [1 3];

                    this.Widgets.ResponseArchitectureLabel = responseArchitectureLabel;
                end

                if isempty(this.Widgets.ResponseArchitectureIcon)
                    responseArchitectureIcon = uiimage('Parent', archPanelLayout, ...
                        'ImageSource', icon.Description, ...
                        'ScaleMethod','stretch');
                    responseArchitectureIcon.Layout.Row = 2;
                    responseArchitectureIcon.Layout.Column = 2;

                    this.Widgets.ResponseArchitectureIcon = responseArchitectureIcon;
                end
                this.Widgets.ResponseArchitectureIcon.ImageSource = icon.Description;
            end
        end
        
        function createButtonPanel(this)
            %% Creates a bottom button panel.
            import controllib.widget.internal.buttonpanel.ButtonPanel

            buttonPanel = ButtonPanel(this.Widgets.DialogLayout, ...
                ["Help","Cancel"],"Commit",1);
            buttonContainer = getWidget(buttonPanel);
            buttonContainer.Layout.Row = numel(this.Widgets.DialogLayout.RowHeight);
            buttonContainer.Layout.Column = [1 2];
            buttonContainer.Padding = [0 0 0 this.RowSpacing];
            buttonContainer.ColumnWidth{3} = buttonPanel.ButtonWidth;
            % buttonContainer.Scrollable = 'on';
            plotButton = uibutton('Parent', buttonContainer, ...
                'Text', getString(message('Control:designerapp:PlotResponse')));
            plotButton.Layout.Row = 1;
            plotButton.Layout.Column = 3;
                        
            cancelButton = buttonPanel.CancelButton;
            helpButton = buttonPanel.HelpButton;
            
            this.Widgets.PlotButton = plotButton;
            this.Widgets.CancelButton = cancelButton;
            this.Widgets.HelpButton = helpButton;
            this.Widgets.ButtonPanel = buttonPanel;
        end
         
        function cbHelpButton(this)
            %% Callback function for help button.

            if isa(this.ResponseDialogTC, 'ctrlguis.csdesignerapp.panels.internal.ResponseTunedBlockTC')
                ctrlguihelp('CSD_TunedBlockResponseHelp','CSHelpWindow');
            else
                if isSimulink(this.ControlDesignData.getArchitecture)
                    ctrlguihelp('CSD_SL_SelectResponseToPlotHelp','CSHelpWindow');
                else
                    ctrlguihelp('CSD_ML_SelectResponseToPlotHelp','CSHelpWindow');
                end
            end
        end
        
        function cbPlotButton(this)
            %% Callback function for plot button.

            fig = this.UIFigure;
            currPointer = controllib.widget.internal.utils.setPointer(fig,'watch');
            restorePointer = onCleanup(@()controllib.widget.internal.utils.setPointer(fig,currPointer));            
            disableUIListeners(this,'ResponseDropDownListener');
            
            try
                if strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:designerapp:NewIOTransferResponse'))) ...
                        || strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:designerapp:NewSensitivityTransferResponse')))...
                        || strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:designerapp:NewLoopTransferResponse')))
                    switch this.Widgets.ResponseDropDown.Value
                        case getString(message('Control:designerapp:NewIOTransferResponse'))
                            responseName = this.Widgets.IOTransferPanel.responseEditField.Value;
                        case getString(message('Control:designerapp:NewSensitivityTransferResponse'))
                            responseName = this.Widgets.SensitivityTransferPanel.responseEditField.Value; 
                        case getString(message('Control:designerapp:NewLoopTransferResponse'))
                            responseName = this.Widgets.LoopTransferPanel.responseEditField.Value;
                    end
                    this.ResponseDialogTC.Name = responseName;
                    setResponse(this.ResponseDialogTC);
                    responses = this.ControlDesignData.getResponses;
                    responseToPlot = responses(strcmp(getName(responses),responseName));
                    this.PlotManager.createResponsePlot(responseToPlot,this.PlotType);
                elseif strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:designerapp:NewTunedBlockResponse')))
                    tunedBlockName = this.ResponseDialogGC.qeGetWidgets.tunableElementListBox.Value;
                    listIndex = arrayfun(@(x) strcmp(x,tunedBlockName),{this.ControlDesignData.getArchitecture.getTunedBlocks.Name});
                    tunedBlocks = this.ControlDesignData.getArchitecture.getTunedBlocks;
                    this.PlotManager.createTunedBlockPlot(tunedBlocks(find(listIndex,1)), this.PlotType);
                else
                    responses = getResponses(this.ControlDesignData);
                    responseNames = arrayfun(@(x)getName(x),responses, 'UniformOutput', false);
                    listIndex = arrayfun(@(x) strcmp(x,this.Widgets.ResponseDropDown.Value),responseNames);
                    this.PlotManager.createResponsePlot(responses(find(listIndex,1)),this.PlotType);
                end
                delete(this)
            catch ME
                delete(restorePointer)

                % Error dialog
                icon = 'Error';
                if strcmpi(ME.identifier, 'Control:lftmodel:getTransfer92') ...
                        && (strcmpi(this.ResponseDialogTC.Type,'LoopTransfer') && ...
                        ismember(this.ResponseDialogTC.Location,this.ControlDesignData.getArchitecture.getOpenings))
                    msg = getString(message('Control:designerapp:OpeningDefinedAtLocation'));
                elseif strcmpi(ME.identifier,'Control:lftmodel:getTransfer91')
                    % Show error dialog if Location (open-loop and
                    % sensitivity response) or Opening is defined the same
                    % as a permanent opening
                    switch this.ResponseDialogTC.Type
                        case 'IOTransfer'
                            msg = getString(message('Control:designerapp:OpeningDefinedAtLoopOpeningLocation'));
                        case {'LoopTransfer','SensitivityTransfer'}
                            permanentOpenings = this.ControlDesignData.getArchitecture.getOpenings;
                            if ismember(this.ResponseDialogTC.Location,permanentOpenings)
                                msg = getString(message('Control:designerapp:OpeningDefinedAtLocation'));
                            elseif ismember(this.ResponseDialogTC.Openings,permanentOpenings)
                                msg = getString(message('Control:designerapp:OpeningDefinedAtLoopOpeningLocation'));
                            else
                                msg = ME.message;
                            end
                    end
                else
                    msg = ME.message;                    
                end

                uialert(fig, msg, this.Title, 'Icon', icon);
                enableUIListeners(this,'ResponseDropDownListener');
            end
        end
        
        function cbSwapResponsePanel(this)
            %% Updates the response panel with the current selection.

            % Clean-up past ResponseDialogTC/GC
            deleteIfValid(this.ResponseDialogTC);
            deleteIfValid(this.ResponseDialogGC);

            % swap panel depending on dropdown selection
            switch this.Widgets.ResponseDropDown.Value
                case getString(message('Control:designerapp:NewIOTransferResponse'))
                    this.Widgets.IOTransferPanel = createIOTransferResponsePanel(this);
                case getString(message('Control:designerapp:NewLoopTransferResponse'))
                    this.Widgets.LoopTransferPanel = createOpenLoopResponsePanel(this);
                case getString(message('Control:designerapp:NewSensitivityTransferResponse'))
                    this.Widgets.SensitivityTransferPanel = createSensitivityResponsePanel(this);
                case getString(message('Control:designerapp:NewTunedBlockResponse'))
                    this.Widgets.TunedBlockResponsePanel = createTunedBlockResponsePanel(this);
                otherwise
                    responses = getResponses(this.ControlDesignData);
                    responseNames = getResponsesNames(this.ControlDesignData);

                    selectedResponseName = this.Widgets.ResponseDropDown.Value;
                    index = strfind(responseNames, selectedResponseName);
                    for ind = 1:numel(index)
                        if ~isempty(index{ind})
                            idx = ind;
                        end
                    end

                    selectedResponse = getDefinition(responses(idx));
                    responseDetails = selectedResponse.getDisplayPreviewText;
                    this.Widgets.ResponseDetailsText.Value = responseDetails;
                    createResponseDetailsText(this)
                    createArchitecturePanel(this)
            end
            setDialogSize(this)
        end        
    end

    methods(Access=private)
        function setResponsePanelHeight(this,value)
            %% Sets response panel height.

            this.Widgets.DialogLayout.RowHeight{2} = value;
            pack(this)
        end        
        
        function resetResponsePanel(this)
            %% Unparents details text and reset layout format.

            this.Widgets.ResponseDetailsText.Parent = [];
            this.Widgets.DialogLayout.RowHeight{2} = '1x';
            if ~isempty(this.Widgets.ResponseArchitectureLayout) && ...
                    isvalid(this.Widgets.ResponseArchitectureLayout)
                this.Widgets.ResponseArchitectureLayout.Parent = [];
            end
            this.Widgets.DialogLayout.RowHeight{3} = 'fit';
        end
       
        function wt = createTransferResponsePanel(this,type)
            %% Creates a response panel.

            names = '';
            responses = getResponses(this.ControlDesignData);
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
            import ctrlguis.csdesignerapp.panels.internal.ResponseInputOutputTransferTC

            this.ResponseDialogTC = ResponseInputOutputTransferTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'IOTransfer');
        end

        function wt = createOpenLoopResponsePanel(this)
            %% Creates panel for open loop response.
            import ctrlguis.csdesignerapp.panels.internal.ResponseLoopTransferTC

            this.ResponseDialogTC = ResponseLoopTransferTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'LoopTransfer');            
        end

        function wt = createSensitivityResponsePanel(this)
            %% Creates panel for sensitivity response.
            import ctrlguis.csdesignerapp.panels.internal.ResponseSensitivityTransferTC

            this.ResponseDialogTC = ResponseSensitivityTransferTC(this.ControlDesignData);
            wt = createTransferResponsePanel(this,'SensitivityTransfer');            
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
                
        function cbCancelButton(this)
            %% Callback function for cancel button.

            cleanupUI(this);
            notify(this,'CloseEvent');
        end

        function setDialogSize(this)
            %% Adjusts dialog height.

            icon = getArchitectureIcon(getArchitecture(this.ControlDesignData));
            if isempty(icon) || isSimulink(getArchitecture(this.ControlDesignData))
                this.UIFigure.Position(3) = this.DialogWidth - this.IconWidth/4;
                this.UIFigure.Position(4) = this.DialogHeight - this.IconHeight ...
                    - 3*this.RowSpacing - this.LabelHeight; % Approx. arch. panel height
            else
                this.UIFigure.Position(3) = this.DialogWidth;
                this.UIFigure.Position(4) = this.DialogHeight;
            end

        end
    end

    %% Hidden methods.
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            %% Returns UI components.

            widgets = this.Widgets;
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