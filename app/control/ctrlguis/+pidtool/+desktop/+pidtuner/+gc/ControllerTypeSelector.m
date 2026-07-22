classdef ControllerTypeSelector < handle
    %CONTROLLERTYPESELECTOR
    
    % Copyright 2015-2018 The MathWorks, Inc.
    
    properties
        ControllerTypeButton
    end
    
    properties(Dependent = true)
        SelectedIndex
        SelectedItem
    end
    
    properties (Access = private)
        ControllerList
        ControllerListItems
        SelectedIndex_
    end
    methods
        function this = ControllerTypeSelector(controllerlist)
            this.ControllerList = controllerlist;            
            this.ControllerTypeButton = matlab.ui.internal.toolstrip.DropDownButton();
            this.ControllerTypeButton.Tag = 'PIDTUNER_CONTROLLERTYPEBUTTON';
            this.ControllerTypeButton.Popup = buildPopupItemsList(this);
            
            addlistener(this.ControllerList, 'DesiredController', 'PostSet', @(~,~)cbDesiredControllerChanged(this));
            
            % Initialize button label from ControllerList
            cbDesiredControllerChanged(this);
        end
        
        %% Build Popup Item List
        function popup = buildPopupItemsList(this)
            
            import matlab.ui.internal.toolstrip.*
            % Create popup list
            popup = PopupList();
            
            % 1DOF Header
            header = PopupListHeader(ctrlMsgUtils.message('Control:pidtool:str12dofControllerTypes', '1'));
            popup.add(header);
            
            % Create List of 1DOF Options
            types1DOF = {'P','I','PI','PD','PID','PDF','PIDF'};
            this.ControllerListItems = types1DOF;
            Tags = strcat('1DOFListItem_',types1DOF);
            L1 = length(types1DOF);
            for ct = 1:L1
                item = ListItem(types1DOF{ct});
                item.Tag = Tags{ct};
                item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct);
                item.ShowDescription = false;
                popup.add(item);
            end
                        
            % 2DOF Header
            header = PopupListHeader(ctrlMsgUtils.message('Control:pidtool:str12dofControllerTypes', '2'));
            popup.add(header);
            
            % Create List of 2DOF Options
            types2DOF = {'PI2','PD2','PID2','PDF2','PIDF2'};
            this.ControllerListItems = [this.ControllerListItems types2DOF];
            Tags = strcat('2DOFListItem_',types2DOF);
            L2 = length(types2DOF);
            for ct = 1:length(types2DOF)
                item = ListItem(types2DOF{ct});
                item.Tag = Tags{ct};
                item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct+L1);
                item.ShowDescription = false;
                popup.add(item);
            end
            
            % 2DOF Variants Header
            header = PopupListHeader(pidtool.utPIDgetStrings('cst', 'str2DOFVariants'));
            popup.add(header);
            
            % Identify New Plant
            types2DOFVariants = {'I-PD   (b = 0, c = 0)',...
                'ID-P   (b = 0, c = 1)','PI-D   (b = 1, c = 0)',...
                'I-PDF (b = 0, c = 0)','IDF-P (b = 0, c = 1)',...
                'PI-DF (b = 1, c = 0)'};
            this.ControllerListItems = [this.ControllerListItems types2DOFVariants];
            Tags = strcat('2DOFVariantListItem_',regexprep(types2DOFVariants,'\s*\([b\sc,=01]*\)',''));
            for ct = 1:length(types2DOFVariants)
                item = ListItem(types2DOFVariants{ct});
                item.Tag = Tags{ct};
                item.ItemPushedFcn = @(~,~) itemSelectionCallback(this,ct+L1+L2);
                item.ShowDescription = false;
                popup.add(item);
            end

            
        end
        
        %% Button Label
        function updateButtonLabel(this)
            % update controller type
            typeStr = this.getTypefromID(this.SelectedIndex_);
            this.ControllerTypeButton.Text = localPadSpaces(typeStr);
        end
        
        %% Selected Index
        function val = get.SelectedIndex(this)
            val = this.SelectedIndex_;
        end
        
        function set.SelectedIndex(this,val)
            % Push selected controller type to the controller list
            ctype = this.getTypefromID(val);
            this.ControllerList.DesiredTypeStr = ctype;
            
            % Update selected index based on the updtaed controller list
            tunerDesiredType = this.ControllerList.DesiredTypeStr;
            this.SelectedIndex_ = this.getIDfromType(tunerDesiredType);
            this.updateButtonLabel();
        end
        %============================================================================(Selected Item)
        function val = get.SelectedItem(this)
            val = deblank(this.ControllerTypeButton.Text);
        end
        
        function set.SelectedItem(this,val)
            id = this.getIDfromType(val);
            if ~isempty(id)
                this.SelectedIndex = id;
            end
        end
        %==================================================================================(Utility)
        function id = getIDfromType(this,type)
            ctypes = this.ControllerListItems;
            if ~isempty(ctypes)
                ctypes = regexprep(ctypes,'\s*\([b\sc,=01]*\)','');
                id = find(strcmpi(ctypes,type));
            else
                id = 1;
            end
        end
        function type = getTypefromID(this,id)
            ctypes = this.ControllerListItems;
            if ~isempty(ctypes)
                type = ctypes{id};
                type = regexprep(type,'\s*\([b\sc,=01]*\)','');
            else
                type = 'P';
            end
        end
        
    end
end

function cbDesiredControllerChanged(this)
%CBDESIREDCONTROLLERCHANGED
tunerDesiredType = this.ControllerList.DesiredTypeStr;
this.SelectedIndex_ = this.getIDfromType(tunerDesiredType);
this.updateButtonLabel();
end

function itemSelectionCallback(this, idx)
% Types menu item selection
% Item selection callback only updates ControllerList. View (button label) is updated
% through the ControllerList change listener
this.SelectedIndex = idx;
end

function strOut = localPadSpaces(typestr)
% Pad a string to make the output string lenght to num
switch typestr
    case 'I'
        num = 16;
    case {'P','PI'}
        num = 15;
    case {'PD','PID','PI2'}
        num = 14;
    case {'PDF','PIDF','PD2','PID2','I-PD','ID-P','PI-D'}
        num = 13;
    case {'PDF2','PIDF2','I-PDF','IDF-P','PI-DF'}
        num = 12;
end
strOut = blanks(num);
n = length(typestr);
strOut(1:n) = typestr;
end