classdef TuningMethodTypePickerNew < handle
    % Picker for Tuning Methods
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties (Access = public)
        % Widgets
        DropDown
        PopUp
        ToolsManager
    end
    methods
        function this = TuningMethodTypePickerNew(ToolsManager,Label,Icon)
            % create drop down
            if nargin<1
                error(message('Controllib:general:UnexpectedError', 'The Tools Manager must be passed in during creation'));
            elseif nargin<2
                this.DropDown = matlab.ui.internal.toolstrip.DropDownButton;
            elseif nargin<3
                this.DropDown = matlab.ui.internal.toolstrip.DropDownButton(Label);
            else
                this.DropDown = matlab.ui.internal.toolstrip.DropDownButton(Label,Icon);
            end
            
            % listener for down action
            this.DropDown.DynamicPopupFcn = @(es,ed)populatePopup(this);
            
            % Set the tools manager
            this.ToolsManager = ToolsManager;
        end
        
        function dd = getDropDownButton(this)
            % Return the drop down button
            dd = this.DropDown;
        end
    end
    methods(Access = protected)
        function popup = populatePopup(this)
            % create popup list
            popup = matlab.ui.internal.toolstrip.PopupList();
            
            % Get list of tools from tools manager
            ToolsList = getToolsList(this.ToolsManager);
            Type = {ToolsList.Category};        
            
            % Graphical methods header
            header = matlab.ui.internal.toolstrip.PopupListHeader(getString(message('Control:designerapp:strGraphicalTuning')));
            header.Tag = 'GraphicalTuning';
            popup.add(header);

            % Add graphical methods
            Idx = ismember(Type, 'Graphical');
            Idx = find(Idx == 1);
            GraphicalItems = ToolsList(Idx);
            
            for ct=1:length(GraphicalItems)
                if isa(GraphicalItems(ct).Icon, 'matlab.ui.internal.toolstrip.Icon')
                    Icon = GraphicalItems(ct).Icon;
                else
                    Icon = matlab.ui.internal.toolstrip.Icon(GraphicalItems(ct).Icon);
                end
                
                Label = GraphicalItems(ct).Name;
                Item = matlab.ui.internal.toolstrip.ListItem(Label,Icon);
                Item.Description = GraphicalItems(ct).Description;
                Item.Tag = GraphicalItems(ct).ID;
                addlistener(Item, 'ItemPushed',  @(es,ed) localOpenTool(this,es));
                
                popup.add(Item);
            end
            
            % Automated methods header
            header = matlab.ui.internal.toolstrip.PopupListHeader(getString(message('Control:designerapp:strAutomatedTuning')));
            header.Tag = 'AutomatedTuning';
            popup.add(header);
            
            % Add automated methods
            Idx = ismember(Type, 'Automated');
            Idx = find(Idx == 1);
            AutomatedItems = ToolsList(Idx);
            
            for ct=1:length(AutomatedItems)
                if isa(AutomatedItems(ct).Icon, 'matlab.ui.internal.toolstrip.Icon')
                    Icon = AutomatedItems(ct).Icon;
                else
                    Icon = matlab.ui.internal.toolstrip.Icon(AutomatedItems(ct).Icon);
                end
                
                Label = AutomatedItems(ct).Name;
                Item = matlab.ui.internal.toolstrip.ListItem(Label,Icon);
                Item.Description = AutomatedItems(ct).Description;
                Item.Tag = AutomatedItems(ct).ID;
                addlistener(Item, 'ItemPushed',  @(es,ed) localOpenTool(this,es));
                popup.add(Item);
            end
        end
        
        function localOpenTool(this, es)
            % Open the selected tool
            openTool(this.ToolsManager, es.Tag, this.DropDown);
        end
    end
end
