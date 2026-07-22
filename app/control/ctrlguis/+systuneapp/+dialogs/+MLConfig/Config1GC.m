classdef (Hidden) Config1GC < ctrluis.AbstractGC
    % Graphical Component for Configuration 1.        

    % Copyright 2013-2021 The MathWorks, Inc.
    
    %% Properties
    properties(Access=private)
        Widgets = struct(...
            'dialogLayout',[], ...
            'configIcon',[], ...
            'radioBtnGrpParentLayout',[], ...
            'radioBtnGrpC',[], ...
            'lblC',[], ...
            'txtC',[], ...
            'layoutC',[], ...
            'radioBtnGrpF',[], ...
            'lblF',[], ...
            'txtF',[], ...
            'layoutF',[], ...
            'radioBtnGrpG',[], ...
            'lblG',[], ...
            'txtG',[], ...
            'layoutG',[], ...
            'radioBtnGrpH',[], ...
            'lblH',[], ...
            'txtH',[], ...
            'layoutH',[], ...
            'newValueC',[], ...
            'newValueF',[], ...
            'newValueG',[], ...
            'newValueH',[], ...
            'currentC',[], ...
            'currentF',[], ...
            'currentG',[], ...
            'currentH',[], ...
            'buttonPanel',[], ...
            'tunableBlockColumnHeader',[], ...
            'fixedBlockColumnHeader',[] ...
            );
        
        DialogWidth = 550;
        Spacing = 10;
        IconHeight = 130;
        RadioButtonHeight = 50;
        RadioButtonX = 10;
        RadioButtonY = 1;
        RadioButtonWidth = 125;
        CurrentValueHeightOffset = 85; % Tuned value
        NewValueHeightOffset = 30; % Tuned value
        BottomPanelHeight = 20; % Estimated
        ColumnHeaderHeight = 20; % Estimated
        ColumnHeaderAlignment = 'left';
        ColumnHeaderFontWeight = 'bold';
        ColorRatio = 0.9;
    end
    
    %% Constructor
    methods
        function this = Config1GC(TCPeer)
            this = this@ctrluis.AbstractGC(TCPeer);
            this.Title = getString(message('Control:systunegui:MLStdFeedbackDialogTitle'));
            this.Name = 'Config1Dlg';
            this.Padding = 10;
        end
    end
    
    %% Public methods
    methods
        function show(this,varargin)
            %% SHOW Overloaded method to pack the dialog.
            
            show@ctrluis.AbstractGC(this,varargin{:})            
            pack(this,'topleft')            
        end
    end
    
    %% Protected methods    
    methods(Access= protected)
        function buildUI(this) %#ok<*MANU>
            %% Method "buildUI": 
            %
            %   "buildUI(this)"
            %
            %   Overload this method to build and assemble your dialog
            %   contents and add them to this.UIFigure.
            %   
            %   By default, it creates a 1-by-1 grid layout object.
            
            % Set dialog size.
            height = ...
                this.Padding + ...
                this.IconHeight + ...
                this.Padding + ...
                this.ColumnHeaderHeight + ...
                this.Padding + ...
                this.RadioButtonHeight + ...
                this.Padding + ...
                this.RadioButtonHeight + ...
                this.Padding + ...
                this.BottomPanelHeight + ...
                this.Padding;
            
            this.UIFigure.Position(3:4) = [this.DialogWidth height];
            
            createDialogLayout(this)
            
            createConfigIcon(this)
            
            createColumnHeaders(this)
            
            createRadioButtonGroups(this)
            
            createBottomButtonPanel(this)                       
        end        
    end
    
    %% Private methods
    methods(Access=private)
        function createDialogLayout(this)
            %% CREATEDIALOGLAYOUT Creates dialog layout.
            
            % -----------------------
            % Padding = 10
            % -----------------------\
            % IconHeight = 130        | => Row 1
            % -----------------------/
            % Padding = 10
            % -----------------------\
            % ColumnHeaderHeight = 20 | => Row 2 (Estimated height)
            % -----------------------/
            % Padding = 10
            % -----------------------\
            % RadioButtonHeight = 50  |
            % ----------------------- |
            % Padding = 10            | => Row 3 (Button groups)
            % ----------------------- |
            % RadioButtonHeight = 50  |
            % -----------------------/
            % Padding = 10
            % -----------------------\
            % BottomPanelHeight = 20  | => Row 4 (Estimated height)
            % -----------------------/
            % Padding = 10
            % -----------------------
            %
            % Row 5 is a buffer.
            %
            % Total height = 330
            
            
            dialogLayout = uigridlayout(this.UIFigure,[5 2], ...
                'Scrollable',true);
            dialogLayout.RowHeight = {this.IconHeight,'fit', ...
                2*this.RadioButtonHeight+this.Padding,'fit','1x'};
            dialogLayout.ColumnWidth = {'1x','1x'};
            dialogLayout.Padding = this.Padding;
            dialogLayout.ColumnSpacing = this.Spacing;
            dialogLayout.RowSpacing = this.Spacing;
            dialogLayout.Tag = 'dialogLayout';
            
            this.Widgets.dialogLayout = dialogLayout;
        end

        function createConfigIcon(this)
            %% CREATECONFIGICON Creates configuration icon architecture.

            layout = uigridlayout(this.Widgets.dialogLayout,[1 2], ...
                'Scrollable',false);
            layout.Layout.Row = 1;
            layout.Layout.Column = [1 2];            
            layout.Padding = 0;
            layout.ColumnWidth = {this.DialogWidth-2*this.Padding,'1x'};
            layout.ColumnSpacing = 0;
            layout.RowHeight = {this.IconHeight};
            layout.RowSpacing = 0;
            
            configIcon = uiimage(layout,'ScaleMethod','scaledown','Tag','configIcon');            
            configIcon.ImageSource = getIconPath('Config1.png');
            
            configIcon.Layout.Row = 1;
            configIcon.Layout.Column = 1;
            
            this.Widgets.configIcon = configIcon;
        end
           
        function createColumnHeaders(this)
            %% CREATECOLUMNHEADERS Creates column headers.
            
            createTunableBlockColumnHeader(this)
            createFixedBlockColumnHeader(this)            
        end

        function createTunableBlockColumnHeader(this)
            %% CREATETUNABLEBLOCKCOLUMNHEADER Creates tunable blocks header.
            
            tunableBlockColumnHeader = uilabel(this.Widgets.dialogLayout, ...
                'Text',getString(message('Control:systunegui:TunableBlocks')), ...
                'Tag','tunableBlockColumnHeader', ...
                'HorizontalAlignment',this.ColumnHeaderAlignment, ...
                'FontWeight',this.ColumnHeaderFontWeight ...
                );
            tunableBlockColumnHeader.Layout.Row = 2;
            tunableBlockColumnHeader.Layout.Column = 1;
            tunableBlockColumnHeader.BackgroundColor = this.ColorRatio*this.UIFigure.Color;
            
            this.Widgets.tunableBlockColumnHeader = tunableBlockColumnHeader;
        end

        function createFixedBlockColumnHeader(this)
            %% CREATEFIXEDBLOCKCOLUMNHEADER Creates fixed blocks header.
            
            fixedBlockColumnHeader = uilabel(this.Widgets.dialogLayout, ..., ...
                'Text',getString(message('Control:systunegui:FixedBlocks')), ...
                'Tag','fixedBlockColumnHeader', ...
                'HorizontalAlignment',this.ColumnHeaderAlignment, ...
                'FontWeight',this.ColumnHeaderFontWeight ...
                );
            fixedBlockColumnHeader.Layout.Row = 2;
            fixedBlockColumnHeader.Layout.Column = 2;
            fixedBlockColumnHeader.BackgroundColor = this.ColorRatio*this.UIFigure.Color;
            
            this.Widgets.fixedBlockColumnHeader = fixedBlockColumnHeader;
        end        
        
        function createRadioButtonGroups(this)
            %% CREATERADIOBUTTONGROUPS Creates rdadio button groups for the blocks.
            
            % Create 2x2 parent layout.
            createRadioBtnGrpParentLayout(this)
            
            % C
            block = getString(message('Control:systunegui:MLCompensatorC'));
            createBlockButtonGroup(this,this.Widgets.radioBtnGrpParentLayout,1,1,block)
            
            % F
            block = getString(message('Control:systunegui:MLCompensatorF'));
            createBlockButtonGroup(this,this.Widgets.radioBtnGrpParentLayout,2,1,block)
            
            % G
            block = getString(message('Control:systunegui:MLCompensatorG'));
            createBlockButtonGroup(this,this.Widgets.radioBtnGrpParentLayout,1,2,block)
            
            % H
            block = getString(message('Control:systunegui:MLCompensatorH'));
            createBlockButtonGroup(this,this.Widgets.radioBtnGrpParentLayout,2,2,block)
            
        end

        function createRadioBtnGrpParentLayout(this)
            %% CREATERADIOBTNGRPPARENTLAYOUT Creates parent layout            
            % Creates parent layout for radio button groups.
            
            radioBtnGrpParentLayout = uigridlayout(this.Widgets.dialogLayout,[2 2], ...
                'Scrollable',false);
            radioBtnGrpParentLayout.Padding = 0;
            radioBtnGrpParentLayout.RowHeight = {this.RadioButtonHeight,this.RadioButtonHeight};
            radioBtnGrpParentLayout.RowSpacing = 10;
            radioBtnGrpParentLayout.ColumnWidth = {'1x','1x'};
            radioBtnGrpParentLayout.ColumnSpacing = 10;
            radioBtnGrpParentLayout.Layout.Row = 3;
            radioBtnGrpParentLayout.Layout.Column = [1 2];
            radioBtnGrpParentLayout.Tag = 'radioBtnGrpParentLayout';
            this.Widgets.radioBtnGrpParentLayout = radioBtnGrpParentLayout;
        end
            
        function createBlockButtonGroup(this,parentLayout,row,col,block)
            %% CREATEBLOCKBUTTONGROUP Creates button group for a block
            
            % Create 2x3 block radio button group layout.
            layout = createRadioBtnGrpBlkLayout(this,parentLayout,row,col,block);
            
            % Create block label
            createBlockLabel(this,layout,block)
            
            % Create edit field for new value.
            txt = createEditField(this,layout,block);
                        
            % Radio button group for a block.
            createRadioBtnGrp(this,layout,block,txt)          
        end
        
        function layout = createRadioBtnGrpBlkLayout(this,parentLayout,row,col,block)
            %% CREATERADIOBTNGRPBLKLAYOUT Creates block value option layout
            % Creates layout for the radio button group for each block.
            
            tag = ['layout' block];
            layout = uigridlayout(parentLayout,[2 3], ...
                'Scrollable',false);
            layout.Padding = 0;
            layout.RowHeight = {'1x','1x'};
            layout.RowSpacing = 0;
            layout.ColumnWidth = {'fit',130,'1x'};
            layout.ColumnSpacing = 0;
            layout.Layout.Row = row;
            layout.Layout.Column = col;
            layout.Tag = tag;
            this.Widgets.(tag) = layout;
        end

        function createBlockLabel(this,layout,block)
            %% CREATEBLOCKLABEL Creates block label
            % Creates label for each block.
            
            tag = ['lbl' block];
            label = uilabel(layout,'Text',[block ':'],'Tag',tag);
            label.VerticalAlignment = 'top';
            label.Layout.Row = [1 2];
            label.Layout.Column = 1;
            this.Widgets.(tag) = label;
        end

        function txt = createEditField(this,layout,block)
            %% CREATEEDITFIELD Creates edit field.
            % Creates edit field to specify new value of a block.
            
            tag = ['txt' block];
            txt = uieditfield(layout,'Tag',tag,'Enable',false);
            txt.Layout.Row = 2;
            txt.Layout.Column = 3;
            this.Widgets.(tag) = txt;
        end

        function createRadioBtnGrp(this,layout,block,txt)
            %% CREATERADIOBTNGRP Creates a radio button group.
            % Creates a radio button group for each block to use either the
            % current block value or to specify a new value.
            
            % Layout
            tag = ['radioBtnGrp' block];
            radioButtonGroup = uibuttongroup(layout);
            radioButtonGroup.Layout.Row = [1 2];
            radioButtonGroup.Layout.Column = 2;
            radioButtonGroup.BorderType = 'none';
            radioButtonGroup.Tag = tag;
            this.Widgets.(tag) = radioButtonGroup;
            
            % Current value
            tag = ['current' block];
            currentValue = uiradiobutton(radioButtonGroup, ...
                'Text',getString(message('Control:systunegui:MLConfigCurrentValue')), ...
                'Value',true, ...
                'Position',[this.RadioButtonX this.RadioButtonY ...
                this.RadioButtonWidth this.CurrentValueHeightOffset], ...
                'Tag',tag ...
                );
            this.Widgets.(tag) = currentValue;
            
            % New value
            tag = ['newValue' block];
            newValue = uiradiobutton(radioButtonGroup, ...
                'Text',getString(message('Control:systunegui:MLConfigNewValue')), ...
                'Position',[this.RadioButtonX this.RadioButtonY ...
                this.RadioButtonWidth this.NewValueHeightOffset], ...
                'Tag',['newValue' block] ...
                );
            this.Widgets.(tag) = newValue;
            
            
            % Add function handle to enable/disable edit field when
            % newValue is selected/deselected.
            radioButtonGroup.SelectionChangedFcn = ...
                @(src,evt)cbNewValueRadioButton(this,newValue,txt);
        end
        
        function createBottomButtonPanel(this)
            %% CREATEBOTTOMBUTTONPANEL Create bottom button panel.
            
            % Create button panel and get the button layout.
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.Widgets.dialogLayout,["help" "ok" "cancel"]);
            this.Widgets.buttonPanel = buttonPanel;
            
            layout = getWidget(buttonPanel);
            layout.Layout.Row = 4;
            layout.Layout.Column = [1 2];
            
            % Attach callback functions
            buttonPanel.HelpButton.ButtonPushedFcn = @(src,data) cbHelpButton(this);            
            buttonPanel.OKButton.ButtonPushedFcn = @(src,data) cbOKButton(this);            
            buttonPanel.CancelButton.ButtonPushedFcn = @(src,data) cbCancelButton(this);            
        end

        function cbHelpButton(this)
            %% CBHELPBUTTON Opens help window.
            helpview('control','MATLABConfig1Dialog','CSHelpWindow');
        end
        
        function cbOKButton(this)
            %% CBOKBUTTON Pushes user specified block values to the architecture
            
            % Update data.
            data = getData(this.TCPeer);
            userData = struct;
            
            block = {'C','F','G','H'};
            for i = 1:length(block)                
                try
                    if this.Widgets.(['newValue' block{i}]).Value
                        newValue = this.Widgets.(['txt' block{i}]).Value;
                        data.(block{i}) = evalin('base',newValue);
                        switch block{i}
                            case {'C','F'}
                                userData.(block{i}) = sprintf('%s = %s;', ...
                                    (block{i}),newValue);
                            case {'G','H'}
                                userData.(block{i}) = newValue;
                        end
                    end
                catch
                   errorDialog(this,block{i})
                   return;
                end
            end

            % Update architecture
            try
                this.TCPeer.setSystem(data, userData);
                if ~isempty(this.TCPeer.OKCallback)
                    feval(this.TCPeer.OKCallback,this.TCPeer.Config1);
                end
                delete(this)
            catch ME
                if strcmp(ME.identifier, 'MATLAB:unassignedOutputs')
                    id = 'Control:systunegui:MLConfigCompensatorEmpty';
                    uiconfirm(getWidget(this),getString(message(id)),this.Title, ...
                        'Icon','error','Options', {'Ok'})
                else
                    uiconfirm(getWidget(this),ME.message,this.Title,'Icon','error', ...
                        'Options', {'Ok'})
                end
            end
        end

        function errorDialog(this,block)
            %% ERRORDIALOG Shows error dialog for invalid block value.
            
            id = 'Control:systunegui:MLConfigCompensatorError';
            uiconfirm(getWidget(this),getString(message(id,block)), ...
                this.Title,'Icon','error','Options', {'Ok'})            
        end
        
        function cbCancelButton(this)
            %% CBCANCELBUTTON Deletes the dialog object.
            
            delete(this)
        end
        
        function cbNewValueRadioButton(this,newValue,txtBox) %#ok<INUSL>
            %% CBNEWVALUERADIOBUTTON Enables/disables new value edit field
            
            txtBox.Enable = newValue.Value;
        end
    end
    
    %% Hidden methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            %% QEGETWIDGETS Returns widget structure
            
            widgets = this.Widgets;
        end
    end
end
%% Local functions --------------------------------------------------------
function iconPath = getIconPath(icon)
%% GETICONPATH Returns icon path.

iconPath = fullfile(matlabroot,'toolbox','control','ctrlguis','+systuneapp', ...
    'resources','mlconfig_icons',icon);
end