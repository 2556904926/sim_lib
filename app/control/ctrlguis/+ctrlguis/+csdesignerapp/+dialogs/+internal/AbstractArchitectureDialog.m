classdef AbstractArchitectureDialog < controllib.ui.internal.dialog.AbstractDialog
    % Abstract dialog class for architecture edit dialogs
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    %% Properties
    properties (Access = protected)
        % Data properties
        ConfigData
        
        % Local copy of the data that gets modified
        LocalConfigData
        
        % Widgets
        Widgets
        
        isInitialized
        
        EventManager        
        
        WaitBar

        % Store handle to Import Dialogsre
        ImportDlgHandles
    end
    
    properties(Access=private)
        

        IsDialogPacked = false
    end
    
    %% Constructor
    methods (Access = protected)
        function dlg = AbstractArchitectureDialog(configData)
            % Superclass constructor
            dlg = dlg@controllib.ui.internal.dialog.AbstractDialog;
            
            % Set data
            dlg.ConfigData = configData;
            
            % Create working copy
            dlg.LocalConfigData = copyArch(configData);
            
            % Dialog Title
            dlg.Title = getTitle(dlg);
            
            % Add listener for close event.
            registerUIListeners(dlg,addlistener(dlg,'CloseEvent', ...
                @(es,ed)cbCancelClicked(dlg)),'CancelUpdate');
            
            % Create data listeners
            createDataListeners(dlg);
            if ~isSimulink(configData)
                addBlockChangedListeners(dlg);
                dlg.Name = "CSDApp_SimulinkConfigurationDialog";
            else
                dlg.Name = "CSDApp_MATLABConfigurationDialog";
            end
            dlg.isInitialized = true;
            
        end
    end
    
    %% Public methods
    methods
        function setEventManager(this, EM)
            this.EventManager = EM;
        end

        function show(this,varargin)
            show@controllib.ui.internal.dialog.AbstractDialog(this,varargin{:});
            pack(this,'topleft');
        end
    end
    
    %% Protected methods
    methods(Access=protected)
        function buildUI(dlg)
            % Create dialog
            
            % Create tabbed panel for tabs
            tabbedPanel = uitabgroup('Parent',[],'Tag','TabbedPanel');
            dlg.Widgets.TabbedPanel = tabbedPanel;
            padding = 5;
            if isSimulink(dlg.ConfigData)
                layout = uigridlayout(dlg.UIFigure,[2 1],'Scrollable','off', ...
                    'Tag','Layout');
                layout.ColumnSpacing = 0;
                layout.RowSpacing = 0;
                layout.Padding = 0;
                layout.RowHeight = {'1x','fit'};
                layout.ColumnWidth = {'1x'};
                
                innerLayout = uigridlayout(layout,[1 1]);
                innerLayout.Padding = 0;
                innerLayout.RowHeight = {'1x'};
                innerLayout.ColumnWidth = {'1x'};
                innerLayout.Scrollable = 'off';
                
                dlg.Widgets.Layout = innerLayout;
                
                tabbedPanel.Parent = innerLayout;
                tabbedPanel.Layout.Row = 1;
                tabbedPanel.Layout.Column = 1;
                
                buttonLayout = uigridlayout(layout,[1 1]);
                buttonLayout.RowHeight = {'fit'};
                buttonLayout.Padding = [5 5 5 3];
                buttonLayout.RowSpacing = 0;
                buttonPanel = createButtonPanel(dlg,buttonLayout,1,1);
            else
                % Get purpose panel.
                purposePanel = getPurposePanel(dlg);
                dlg.Widgets.PurposePanel = purposePanel;
                
                layout = uigridlayout(dlg.UIFigure,[3 2],'Scrollable','off', ...
                    'Tag','Layout');
                layout.ColumnSpacing = padding;
                layout.RowSpacing = 0;
                layout.Padding = padding;
                layout.RowHeight = {'fit','1x','fit'};
                layout.ColumnWidth = {'fit','1x'};
                dlg.Widgets.Layout = layout;
                
                selectionPanel = createConfigurationSelectionPanel(dlg);
                dlg.Widgets.SelectionPanel = selectionPanel;
                selectionPanel.Parent = layout;
                selectionPanel.Layout.Row = [1 2];
                selectionPanel.Layout.Column = 1;
                
                purposePanel.Parent = layout;
                purposePanel.Layout.Row = 1;
                purposePanel.Layout.Column = 2;
                
                tabbedPanel.Parent = layout;
                tabbedPanel.Layout.Row = 2;
                tabbedPanel.Layout.Column = 2;
                
                buttonPanel = createButtonPanel(dlg,layout,3,[1 2]);                
            end
            dlg.Widgets.ButtonPanel = buttonPanel;
            
            % Add tab contents to the tabbed panel
            tabs = getTabPnls(dlg);
            dlg.Widgets.Tabs = tabs;
        end
        
        function removeBlockChangedListeners(dlg)
            % Remove data listeners attached to the blocks.
            if ~isSimulink(dlg.LocalConfigData)
                blocks = getBlocks(dlg.LocalConfigData);
                for ct = 1:numel(blocks)
                    unregisterDataListeners(dlg,getIdentifier(blocks{ct}))
                end
            end
        end
        
        function createDataListeners(dlg)            
            % Register the data listeners.
            
            registerDataListeners(dlg,[...
                addlistener(dlg.LocalConfigData,'SystemChanged',@(es,ed)updateWidgets(dlg)); ... % Update dialog contents when data changes
                addlistener(dlg.ConfigData, 'ObjectBeingDestroyed', @(es,ed)delete(dlg))], ...   % Delete dialog when data is no longer valid
                {'LocalConfigChanged','ConfigDeleted'} ...
                );
        end
        
        function cleanupUI(dlg)
            % Cleanup import handle.
            
            for i = 1:numel(dlg.ImportDlgHandles)
                delete(dlg.ImportDlgHandles(i))
            end
            dlg.ImportDlgHandles = [];
        end
        
        function cbValueChanged(dlg,ct,rethrowFlag)
            expr = dlg.Widgets.BlocksTab.Value(ct).Value;
            if any(strfind(expr, '<')) && any(strfind(expr, '>')) && any(strfind(expr, 'x'))
                % Do nothing if the expression is <nxm> classname
            else
                try
                    sys = evalin('base', expr);
                    if (isreal(sys) &&  isequal(size(sys),[1 1])) || (isa(sys,'lti') && isequal(iosize(sys),[1 1]))
                        disableDataListeners(dlg,dlg.Widgets.BlocksTab.Identifier(ct).Text);
                        dlg.LocalConfigData.setBlockValue(dlg.Widgets.BlocksTab.Identifier(ct).Text, sys);
                        enableDataListeners(dlg,dlg.Widgets.BlocksTab.Identifier(ct).Text);
                    else
                        error(getString(message('Control:designerapp:errImportDialogMsg2',dlg.Widgets.BlocksTab.Identifier(ct).Text)));
                    end
                catch ME
                    if nargin>2
                        rethrow(ME);
                    else
                        uialert(dlg.UIFigure,ME.message,dlg.Title);
                    end
                    updateBlocks(dlg);
                end
            end
        end
        
        function cbImportClicked(dlg, ct)
            % When the import dialog is open, we need to listen to tuned
            % block value changed events to update the architecture dialog.
            if isempty(dlg.ImportDlgHandles)
                b = false;
            else
                [b,idx] = ismember(dlg.Widgets.BlocksTab.Identifier(ct).Text,{dlg.ImportDlgHandles.BlockName});
                if b && ~isequal(dlg.ImportDlgHandles(idx).Data,dlg.LocalConfigData)
                    dlg.ImportDlgHandles(idx) = [];
                    b = false;
                end
            end
            if b
                show(dlg.ImportDlgHandles(idx),dlg.Widgets.BlocksTab.Import(ct));
            else
                importDlg = ctrlguis.csdesignerapp.dialogs.internal.ImportDialog(dlg.LocalConfigData, ...
                    dlg.Widgets.BlocksTab.Identifier(ct).Text);
                show(importDlg,dlg.Widgets.BlocksTab.Import(ct));
                dlg.ImportDlgHandles = [dlg.ImportDlgHandles; importDlg];
                if isSimulink(dlg.LocalConfigData)
                    % Update widgets for simulink architecture when Import
                    % is successful
                    addlistener(importDlg,'ImportCompleted',@(es,ed) updateWidgets(dlg));
                end
            end
            
        end
        
        function purposePanel = getPurposePanel(dlg)
            purposePanel = uipanel('Parent',[],'BorderType','none', ...
                'Tag','SelectionPanel');
        end
        
        function selectionPanel = createConfigurationSelectionPanel(dlg)
            selectionPanel = uipanel('Parent',[],'BorderType','none', ...
                'Tag','SelectionPanel');
        end
        
        function cbCancelClicked(dlg)
            % Cancel architecture update.
            disableUIListeners(dlg,'CancelUpdate')                
            if dlg.IsWidgetValid && isvalid(dlg.LocalConfigData)
                removeBlockChangedListeners(dlg)
                unregisterDataListeners(dlg,'LocalConfigChanged')
                delete(dlg.LocalConfigData)
                dlg.isInitialized = false;
                fig = getWidget(dlg);
                fig.Pointer = 'arrow';
                
                close(dlg)
            end
            % Close Import dialogs
            for k = 1:numel(dlg.ImportDlgHandles)
                close(dlg.ImportDlgHandles(k))
            end
            enableUIListeners(dlg,'CancelUpdate')
        end
    end
        
    %% Abstract protected methods.
    methods (Abstract = true, Access = protected)
        getTabPnls(dlg);
        getTitle(dlg);
        addBlockChangedListeners(dlg,ct);
        updateBlocks(dlg)
        cbHelpClicked(dlg);
        cbOkClicked(dlg)
        updateWidgets(dlg)
    end

    %% Private methods.
    methods(Access=private)        
        function buttonPanel = createButtonPanel(dlg,parentLayout,row,col)
            % Create a panel containing OK, CANCEL, and HELP buttons.
            
            % Create button panel and get the button layout.
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                parentLayout,["help" "ok" "cancel"]);
            
            layout = getWidget(buttonPanel);
            layout.Layout.Row = row;
            layout.Layout.Column = col;
            layout.Padding(end) = parentLayout.Padding(end);
            
            % Attach callback functions
            buttonPanel.HelpButton.ButtonPushedFcn = @(es,ed)cbHelpClicked(dlg);            
            buttonPanel.OKButton.ButtonPushedFcn = @(es,ed)cbOkClicked(dlg);            
            buttonPanel.CancelButton.ButtonPushedFcn = @(es,ed)cbCancelClicked(dlg);           
        end
    end
            
    %% Hidden QE methods
    methods (Access = public, Hidden = true)        
        function widgets = qeGetWidgets(dlg)
            widgets = dlg.Widgets;
        end
        
        function Data = qeGetLocalConfigData(this)
            Data = this.LocalConfigData;
        end
        
        function importDlg = qeGetImportDlg(dlg)
            importDlg = dlg.ImportDlgHandles;
        end
    end
    
    %% Static methods
    methods (Static = true)
        function strValue = SelectStringToDisplay(Component, StringCell)
            %SELECTSTRINGTODISPLAY Return display string
            %
            %    strValue = SelectStringToDisplay(Width, StringCell)
            %
            %    Choose whether the long or the short string has to be
            %    displayed according to the supplied component's width
            %
            %    The long/short strings are defined/constructed by
            %    ctrluis.DefaultValueDisplayFcn()
            %
            %    Inputs:
            %       component - component that displays the text
            %       StringCell - cell array of strings, 1st entry is long
            %                  string, 2nd entry is short string.
            %
            %    Outputs:
            %       strValue - String that is chosen according to component
            %                  width
            %
            if iscell(StringCell)
                fm = Component.Peer.getFontMetrics(Component.Peer.getFont);
                if max(Component.Peer.getSize.getWidth,Component.Peer.getPreferredSize.getWidth) > ...
                        fm.stringWidth(strcat(StringCell{1},'xxxx'))  %Pad with xxxx to account for combobox dropdown
                    strValue = StringCell{1};
                else
                    strValue = StringCell{2};
                end
            else
                strValue = StringCell;
            end
        end
        
        function strValue = ValueDisplayFcn(value, EditState)
            %DEFAULTVALUEDISPLAYFCN Return display string
            %
            %    strValue = DefaultValueDisplayFcn(value)
            %
            %    Create display strings for a value. Two strings are
            %    returned:
            %      Long string  - given by mat2str(value) if value is 2D
            %                     numeric or value if value is a string
            %      Short string - string with <NxM class> format except in
            %                     cases of a numeric or logical scalars,
            %                     when the short string is a redcued
            %                     precision value
            %
            %    In case of a scalar input, choose between 'Full precision'
            %    or 'Truncated precision'.
            %
            %    Inputs:
            %       value     - value to convert to a display string
            %       EditState - flag to select between full or short
            %                   precision for scalar values
            %
            %    Outputs:
            %       strValue - cell array of strings, 1st entry is long
            %                  string, 2nd entry is short string.
            %
            strValue = cell(2,1);
            dims = sprintf('%dx',size(value));
            strValue{2} = sprintf('<%s %s>',dims(1:end-1),class(value));
            if isscalar(value) && (isnumeric(value) || islogical(value)) && EditState
                strValue{1} = mat2str(value);      %Full precision
                strValue{2} = mat2str(value);      %Full precision
            elseif isscalar(value) && (isnumeric(value) || islogical(value)) && ~EditState
                strValue{1} = sprintf('%g',value); %Truncated precision
                strValue{2} = sprintf('%g',value); %Truncated precision
            elseif ismatrix(value) && (isnumeric(value) || islogical(value))
                strValue{1} = mat2str(value);
            elseif ischar(value)
                strValue{1} = value;
            else
                strValue{1} = strValue{2};
            end
        end
    end    
end