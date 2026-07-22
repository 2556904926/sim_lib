classdef (Hidden) GenssConfigGC < ctrluis.AbstractGC
    % Graphical component for genss configuration.    
    
    % Copyright 2013-2021 The MathWorks, Inc.    

    %% Properties
    properties(Access=private)
        Widgets = struct(...
            'dialogLayout',[], ...
            'editFieldLabel',[], ...
            'editField',[], ...
            'textArea',[], ...
            'buttonPanel',[] ...
            );
        EditFieldLabelHeight = 20; % Estimated
        EditFieldHeight = 20; % Estimated
        TextAreaHeight = 280;
        ButtonHeight = 20; % Estimated
        DialogWidth = 380;
        Spacing = 5;
    end
    
    %% Constructor
    methods
        function this = GenssConfigGC(tcpeer)
            this = this@ctrluis.AbstractGC(tcpeer);
            this.Name = 'GenssConfigDlg';
            this.Title = getString(message('Control:systunegui:MLGenFeedbackDialogTitle'));
            this.Padding = 5;
        end
    end
    
    %% Public methods
    methods
        function updateUI(this)
            %% UPDATEUI Updates system description.
            
            if ~this.IsWidgetValid
                return
            end
                
            tempVal = this.TCPeer.System;
            VarName = 'tempVal';
            if ~isempty(tempVal) || isa(tempVal, 'genss')
                % tempVal can be non-empty or an empty-genss
                
                genssDesc = evalc(VarName);
                
                % Remove unwanted strings and empty lines from the description
                genssDesc = strrep(genssDesc, sprintf('\n%s =\n\n', VarName),'');
                genssDesc = strrep(genssDesc, sprintf('\n%s\n\n', ...
                    getString(message('Control:lftmodel:genss13',VarName,VarName))),'');
                
                % Add block description
                nb = nblocks(tempVal);
                
                if nb == 0
                    blockDesc = []; %#ok<NASGU>
                    this.Widgets.textArea.Value = sprintf('%s', genssDesc);
                else
                    blockDesc = evalc('showBlockValue(tempVal)');
                    descLabel = getString(message('Control:systunegui:MLGenBlockDescription'));
                    this.Widgets.textArea.Value = sprintf('%s \n \n %s: \n \n %s',...
                        genssDesc,descLabel,blockDesc);
                end
                if isempty(this.Widgets.editField.Value)
                    dims = sprintf('%dx',iosize(tempVal));
                    this.Widgets.editField.Value = sprintf('<%s %s>', ...
                        dims(1:end-1),class(tempVal));
                end
            end
        end
    end
    
    %% Protected methods
    methods(Access = protected)
        function buildUI(this)
            %% BUILDUI Builds UI components.
            
            setDialogSize(this)
            
            setDialogLayout(this)
            
            row = 1;
            col = 1;
            addEditFieldLabel(this,row,col)
            
            row = row + 1;
            addEditField(this,row,col)
            
            row = row + 1;
            addTextArea(this,row,col)
            
            row = row + 1;
            addButtons(this,row,col)            
        end
    end
    
    %% Private methods
    methods(Access=private)
        function setDialogSize(this)
            %% SETDIALOGSIZE Sets dialog size.
            
            height = this.EditFieldLabelHeight + this.EditFieldHeight + ...
                this.TextAreaHeight + this.ButtonHeight + 5*this.Padding;
            this.UIFigure.Position(3:4) = [this.DialogWidth height];
        end
            
        function setDialogLayout(this)
            %% SETDIALOGLAYOUT Sets dialog layout.
            
            dialogLayout = uigridlayout(this.UIFigure,[5 1], ...
                'Scrollable',true);
            
            dialogLayout.RowHeight = {'fit','fit','1x','fit'};
            dialogLayout.ColumnWidth = {'1x'};
            dialogLayout.Padding = this.Padding;
            dialogLayout.ColumnSpacing = this.Spacing;
            dialogLayout.RowSpacing = this.Spacing;
            dialogLayout.Tag = 'dialogLayout';
            
            this.Widgets.dialogLayout = dialogLayout;
        end
            
        function addEditFieldLabel(this,row,col)
            %% ADDEDITFIELDLABEL Adds edit field label.
            
            editFieldLabel = uilabel(this.Widgets.dialogLayout, ...
                'Text',getString(message('Control:systunegui:MLGenFeedbackEdit')));
            editFieldLabel.Layout.Row = row;
            editFieldLabel.Layout.Column = col;
            editFieldLabel.Tag = 'editFieldLabel';

            this.Widgets.editFieldLabel = editFieldLabel;
        end
            
        function addEditField(this,row,col)
            %% ADDEDITFIELD Adds edit field for system input.
            
            editField = uieditfield(this.Widgets.dialogLayout);
            editField.Layout.Row = row;
            editField.Layout.Column = col;
            editField.Tag = 'editField';
            editField.UserData = struct('IsValidSystem',true);
            editField.ValueChangedFcn = @(src,data) cbEditField(this);

            this.Widgets.editField = editField;
        end
            
        function addTextArea(this,row,col)
            %% ADDTEXTAREA Adds text area for system description.
            
            textArea = uitextarea(this.Widgets.dialogLayout,'Editable',false);
            textArea.Layout.Row = row;
            textArea.Layout.Column = col;
            textArea.Tag = 'textArea';

            this.Widgets.textArea = textArea;
        end
            
        function addButtons(this,row,col)
            %% ADDBUTTONS Adds HELP, OK, and CANCEL buttons.
            
            % Create button panel and get the button layout.
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                this.Widgets.dialogLayout,["help" "ok" "cancel"]);
            this.Widgets.buttonPanel = buttonPanel;
            
            buttonLayout = getWidget(buttonPanel);
            buttonLayout.Layout.Row = row;
            buttonLayout.Layout.Column = col;
            
            % Attach callback functions
            buttonPanel.HelpButton.ButtonPushedFcn = @(src,data) cbHelpButton(this);            
            buttonPanel.OKButton.ButtonPushedFcn = @(src,data) cbOKButton(this);            
            buttonPanel.CancelButton.ButtonPushedFcn = @(src,data) cbCancelButton(this);            
        end

        function cbEditField(this)
            %% CBEDITFIELD Callback function for edit field.
            % It processes the user specified system input.

            try
                Expression = this.Widgets.editField.Value;
                if isempty(Expression)
                    setData(this.TCPeer, genss);
                else
                    customData = evalin('base', Expression);
                    if ~isa(customData,'genss')
                        customData = genss(customData);
                        Expression = ['genss(', Expression, ')'];
                    end
                    if nmodels(customData) == 1
                        customData.UserData = Expression;
                        setData(this.TCPeer,customData);
                    else
                        error(getString(message('Controllib:gui:lblSLTunableBlock_InvalidGenss')));
                    end
                end
                this.Widgets.editField.UserData.IsValidSystem = true;
            catch ME
                uiconfirm(getWidget(this),ME.message,this.Title, ...
                    'Icon','error','Options', {'Ok'});
                this.Widgets.editField.UserData.IsValidSystem = false;
            end
        end

        function cbOKButton(this)
            %% CBOKBUTTON Callback function to update system data.
            % It updates the config data using the user specified value.
            
            try
                if ~this.Widgets.editField.UserData.IsValidSystem
                    error(getString(message('Controllib:gui:lblSLTunableBlock_InvalidGenss')))
                end
                this.TCPeer.setSystem;
                if ~isempty(this.TCPeer.OKCallback)
                    feval(this.TCPeer.OKCallback,this.TCPeer.ConfigGenss);
                end
                delete(this)
            catch ME
                uiconfirm(getWidget(this),ME.message,this.Title, ...
                    'Icon','error','Options', {'Ok'})
            end
        end

        function cbHelpButton(this) %#ok<MANU>
            %% CBHELPBUTTON Opens help window.
            helpview('control','MATLABConfigGenSSDialog','CSHelpWindow');
        end
        
        function cbCancelButton(this)
            %% CBCANCELBUTTON Deletes the dialog object.
            
            delete(this)
        end
    end
    
    %% Hidden methods
    methods(Hidden)
        function wdgts = qeGetWidgets(this)
            %% QEGETWIDGETS Returns widgets.
            
            wdgts = this.Widgets;
        end
    end
end