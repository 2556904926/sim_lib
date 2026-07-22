classdef SelectResponseToEdit < ctrlguis.csdesignerapp.dialogs.internal.SelectResponseToPlot
    
    %% SelectReponseToEdit creates a uifigure based dialog, while
    % inheriting from SelectResponseToPlot dialog, overall inheriting from 
    % AbstractDialog and MixedIn Dialog 
    %
    % Main methods: buildUI(), cleanupUI() have similar components to 
    % SelectResponseToPlot. 
    %
    % This files pertains code to all "Graphical Tuning Methods" Dialog
    % under "Tuning Methods" in CSD App
    %
    % See also
    %     ctrlguis.csdesignerapp.dialogs.internal.SelectResponseToPlot
    %     controllib.ui.internal.dialog.AbstractDialog
    
    %  Copyright 2013 - 2021 The Mathworks, Inc
    
    properties(Access=private)
        ToolsManager
        ToolID
    end
    
    methods (Access = public)
        function this = SelectResponseToEdit(designerData, toolsManager, toolID)
            this = this@ctrlguis.csdesignerapp.dialogs.internal.SelectResponseToPlot(designerData, [], toolID);
            this.ToolsManager = toolsManager;
            this.ToolID = toolID;
            this.Title = getString(message('Control:designerapp:SelectResponseToEdit'));
            this.Name = "CSDApp_NewEditorDialog" + matlab.lang.internal.uuid;
            this.CloseMode = 'destroy';
        end        
    end
    
    methods (Access = protected)
        
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

            % Set default dialog dimension. 
            this.UIFigure.Position(3:4) = [this.DialogWidth this.DialogHeight];                
            
            % Get the names of all the loop transfer responses
            allResponses = getResponses(this.ControlDesignData);
            responseNames = {};
            if strcmpi(this.PlotType,'CLBode') && ~isempty(allResponses)
                addIOResponse = getString(message('Control:designerapp:NewIOTransferResponse'));
                loopList = ~isLoopTransfer(allResponses) & issiso(allResponses);
                responseNames = getResponsesNames(this.ControlDesignData);
                responseNames = responseNames(loopList);
                responseNames = [sort(responseNames)', addIOResponse];
            elseif ~isempty(allResponses)
                addLoopResponse = getString(message('Control:designerapp:NewLoopTransferResponse'));
                Response = allResponses(issiso(allResponses));
                loopList = isLoopTransfer(Response);
                responseNames = getResponsesNames(this.ControlDesignData);
                responseNames = responseNames(loopList);
                responseNames = [sort(responseNames)', addLoopResponse];
            elseif isempty(allResponses)
                 if strcmpi(this.PlotType,'CLBode')
                    addResponse = getString(message('Control:designerapp:NewIOTransferResponse'));
                 else
                    addResponse = getString(message('Control:designerapp:NewLoopTransferResponse'));
                 end
                 responseNames = [sort(responseNames)', addResponse];
            end

            % Create Widgets
            createDialogLayout(this)
            createResponseDropdown(this, responseNames)
            createResponseDetailsText(this)
            createArchitecturePanel(this)
            createButtonPanel(this)
            cbSwapResponsePanel(this)
        end
        
        %% CALLBACKS
        function cbHelpButton(this)
            if isSimulink(this.ControlDesignData.getArchitecture)
                ctrlguihelp('CSD_SL_SelectResponseToEditHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_SelectResponseToEditHelp','CSHelpWindow');
            end
        end
        
        function cbPlotButton(this)
            fig = this.UIFigure;
            currPointer = controllib.widget.internal.utils.setPointer(fig,'watch');
            restorePointer = onCleanup(@()controllib.widget.internal.utils.setPointer(fig,currPointer));            
            disableUIListeners(this,'ResponseDropDownListener');
            
            try
                if strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:designerapp:NewLoopTransferResponse'))) || ...
                        strcmp(this.Widgets.ResponseDropDown.Value, getString(message('Control:designerapp:NewIOTransferResponse')))
                    switch this.Widgets.ResponseDropDown.Value
                        case getString(message('Control:designerapp:NewLoopTransferResponse'))
                            responseName = this.Widgets.LoopTransferPanel.responseEditField.Value;
                        case getString(message('Control:designerapp:NewIOTransferResponse'))
                            responseName = this.Widgets.IOTransferPanel.responseEditField.Value;
                        otherwise
                            responseName = this.Widgets.ResponseDropDown.Value;
                    end
                    this.ResponseDialogTC.Name = responseName;
                    setResponse(this.ResponseDialogTC);
                    responses = getResponses(this.ControlDesignData);
                    allResponseNames =[];
                    for ct = 1:length(responses)
                        allResponseNames = [allResponseNames, {getName(responses(ct))}]; %#ok<AGROW> 
                    end
                    [b, idx] = ismember(responseName, allResponseNames);
                    % The last response added to the list should be plotted
                    if b
                        createGraphicalEditor(this, responses(idx));
                    end
                else
                    responses = getResponses(this.ControlDesignData);
                    responseNames = arrayfun(@(x)getName(x), responses, 'UniformOutput', false);
                    selectedResponseName = this.Widgets.ResponseDropDown.Value;
                    listIndex = arrayfun(@(x) strcmp(x, selectedResponseName), responseNames);
                    createGraphicalEditor(this, responses(find(listIndex,1)));
                end
                delete(this)
            catch ME
                delete(restorePointer)

                % Set params for error dialog
                icon = 'Error';
                % Check for error strings w.r.t Design
                isWrongSignal = strcmpi(ME.identifier, 'Control:lftmodel:getTransfer91') || ...
                    strcmpi(ME.identifier, 'Control:lftmodel:getTransfer92');
                if isWrongSignal
                    isLocation = ~isempty(this.ResponseDialogTC) && ...
                        isSimulink(this.ControlDesignData.getArchitecture) && ...
                        strcmpi(this.ResponseDialogTC.Type,'LoopTransfer') &&  ...
                        ~isempty(this.ResponseDialogTC.Location) && ...
                        ismember(this.ResponseDialogTC.Location,this.ControlDesignData.getArchitecture.getOpenings);
                    isOpening = ~isempty(this.ResponseDialogTC) && ...
                        ~isempty(this.ResponseDialogTC.Openings) && ...
                        isSimulink(this.ControlDesignData.getArchitecture) && ...
                        ismember(this.ResponseDialogTC.Openings, this.ControlDesignData.getArchitecture.getOpenings);
                    if (isLocation || any(isOpening))
                        msg = getString(message('Control:designerapp:OpeningDefinedAtLocation'));
                    else
                        msg = ME.message;
                    end
                else
                    msg = ME.message;
                end

                uialert(fig, msg, this.Title, 'Icon', icon);
                enableUIListeners(this,'ResponseDropDownListener');
            end            
        end
        
        function createGraphicalEditor(this, response)
            createGraphicalEditor(this.ToolsManager,this.ToolID,response)
        end

    end
end