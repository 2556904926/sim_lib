classdef DesignSection < handle
    %DESIGNSECTION
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties
        TPComponent
        AddPlotPopup
        TunerTC
        DomainComboBox
        AddPlotButton
    end
    events
        AddNewPlot
    end
    methods
        function this = DesignSection(tunertc)
            %DESIGNSECTION
            
            this.TPComponent = matlab.ui.internal.toolstrip.Section(pidtool.utPIDgetStrings('cst','strDesign'));
            this.TPComponent.Tag = 'Design';
            this.TPComponent.CollapsePriority = 3;
            this.TunerTC = tunertc;
            this.layout();
            this.initialize();
            this.updateView();
        end
        function layout(this)
            %LAYOUT
            import matlab.ui.internal.toolstrip.*
            column1 = this.TPComponent.addColumn('width',120); % NOTE: temporary workaround due to issue with dynamic column sizing
            
            % Add Domain Label and Drop Down
            domainLabel = Label(pidtool.utPIDgetStrings('cst','strDomain'));
            Values = {pidtool.utPIDgetStrings('cst','strFrequencyDomain');...
                pidtool.utPIDgetStrings('cst','strTimeDomain')};
            this.DomainComboBox = DropDown(Values);
            this.DomainComboBox.Description = getString(message('Control:pidtool:ttipDomainDropdown'));
            
            % Add Add Plot Drop Down
            this.AddPlotButton = DropDownButton(pidtool.utPIDgetStrings('cst','strAddPlot'),Icon('new_plot'));
            this.AddPlotButton.Tag = 'PIDTUNER_ADDPLOTBUTTON';
            this.AddPlotButton.Popup = buildPopupItemsList(this);
            this.AddPlotButton.Description = getString(message('Control:pidtool:ttipAddPlotDropdown'));
            
            % Add Controls to Section
            column1.add(domainLabel);
            column1.add(this.DomainComboBox);
            column1.add(this.AddPlotButton);
        end
        
        %% Build Popup Item List
        function popup = buildPopupItemsList(this)
            
            import matlab.ui.internal.toolstrip.*
            % Create popup list
            popup = PopupList();
            
            % Step Header
            header = PopupListHeader(pidtool.utPIDgetStrings('cst', 'plotpanel_typecombo1'));
            popup.add(header);
            
            % Create List of Step Plot Options
            popup = createListItems(this,popup,1);
              
            % Bode Header
            header = PopupListHeader(pidtool.utPIDgetStrings('cst', 'plotpanel_typecombo2'));
            popup.add(header);
            
            % Create List of Bode Options
            popup = createListItems(this,popup,7);

        end
        
        function popup = createListItems(this,popup,startIdx)
            % Create List Items (common for step and bode)
            import matlab.ui.internal.toolstrip.*
            
            % Plant
            ct = startIdx;
            itemName = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo6');
            item = ListItem(itemName);
            item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
            item.ShowDescription = false;
            popup.add(item);
            ct = ct + 1;
            
            % Open-Loop
            itemName = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo5');
            item = ListItem(itemName);
            item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
            item.ShowDescription = false;
            popup.add(item);
            ct = ct + 1;
            
            % Reference Tracking
            itemName = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo1');
            item = ListItem(itemName);
            item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
            item.ShowDescription = false;
            popup.add(item);
            ct = ct + 1;
            
            % Controller Effort
            itemName = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo2');
            item = ListItem(itemName);
            item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
            item.ShowDescription = false;
            popup.add(item);
            ct = ct + 1;
            
            % Input Disturbance Rejection
            itemName = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo3');
            item = ListItem(itemName);
            item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
            item.ShowDescription = false;
            popup.add(item);
            ct = ct + 1;
            
            % Output Disturbance Rejection
            itemName = pidtool.utPIDgetStrings('cst', 'plotpanel_systemcombo4');
            item = ListItem(itemName);
            item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
            item.ShowDescription = false;
            popup.add(item);

        end
        
        %% Initialization and Update Methods
        function initialize(this)
            %INITIALIZE
            addlistener(this.TunerTC.InputVariables, 'DesignDomain', 'PostSet', @(~,~)this.updateView());
            addlistener(this.DomainComboBox, 'ValueChanged', @(src,~)designDomainComboboxCallback(this, src));
        end
        function updateView(this)
            %UPDATE
            
            if strcmp(this.TunerTC.InputVariables.DesignDomain,'frequency')
                desiredid = 1;
            else
                desiredid = 2;
            end
            if desiredid ~= this.DomainComboBox.SelectedIndex
                this.DomainComboBox.SelectedIndex = desiredid;
            end
        end
    end
end
function designDomainComboboxCallback(this, src)
%DESIGNDOMAINCOMBOBOXCALLBACK
if src.SelectedIndex == 1
    this.TunerTC.InputVariables.DesignDomain = 'frequency';
else
    this.TunerTC.InputVariables.DesignDomain = 'time';
end
end

function itemSelectionCallback(this, id)
% Plots menu item selection
switch logical(true)
    case id==1 || id==7
        resptype = 'p';
    case id==2 || id==8
        resptype = 'olsys';
    case id==3 || id==9
        resptype = 'r2y';
    case id==4 || id==10
        resptype = 'r2u';
    case id==5 || id==11
        resptype = 'id2y';
    case id==6 || id==12
        resptype = 'od2y';
end
if id <=6
    plottype = 'step';
else
    plottype = 'bode';
end
notify(this, 'AddNewPlot', pidtool.desktop.pidtuner.tc.AddPlotEventData(plottype,resptype));
fastDesign(this.TunerTC);
end

