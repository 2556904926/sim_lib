classdef AddSignalFromModel < controllib.ui.internal.dialog.AbstractDialog
    %% Dialog for for adding signal from the model.
    %
    %  DLG = ADDSIGNALFROMMODEL(<INPUTS>) creates DLG using the specfied
    %  <INPUTS>.
    %
    %   Examples:
    %
    %       %% Construct and show dialog.
    %       dlg = ctrlguis.csdesignerapp.dialogs.internal.AddSignalFromModel(<inputs>);
    %       show(dlg)
    %
    %  See also ctrlguis.csdesignerapp.panels.internal.SignalListPanel
    %           ctrlguis.csdesignerapp.panels.internal.IOTransferGC
    %           ctrlguis.csdesignerapp.panels.internal.LoopTransferGC
    
    % Copyright 2015-2023 The MathWorks, Inc.
    
    %% Properties
    properties(Access = private)
        Data
        CandidateSignals = cell(0,1);
        Widgets = struct(...
            'dialogLayout',[],...
            'headerLabel',[],...            
            'signalPanel',[], ...
            'signalPanelLayout',[],...
            'signalNameLabel',{{}},...
            'highlightSignalButton',{{}},...
            'removeSignalButton',{{}},...
            'helpButton',[],...
            'addSignalsButton',[],...
            'cancelButton',[]...
            );
        
        % Simulink signal selector tool-component
        SignalSelectorTC
        
        % Add Signal call-back handle
        % Using this dialog, either a location, or a permanant opening
        % could be added. Use this property to specify the function handle
        % that does the signal addition
        AddSignalHandle
        
        % Add signal to signal list used for response definition - used if
        % the add signal dialog is launced from a response creation/
        % plotting dialog.
        SignalListPanel
        
        %Highlight property for QE method
        HighlightSignalStatus = false;
        
        ButtonIconWidth = 20;
        
        EditType = ctrlguis.csdesignerapp.panels.internal.SignalEditType.Initialization;
        SignalIndex
    end
    
    %% Constructor
    methods
        function this = AddSignalFromModel(data,addSignalHandle,signalListPanel)
            this = this@controllib.ui.internal.dialog.AbstractDialog;
            
            this.Title = getString(message('Control:designerapp:AddSignalFromModelTitle'));
            this.Name = 'dlgAddSignalFromModel';
            this.AddSignalHandle = addSignalHandle;
            
            this.Data = data;
            registerDataListeners(this,addlistener(data,...
                'ObjectBeingDestroyed',@(src,evt)delete(this)));
            
            opts = getSignalSelectorOptions(data);
            this.SignalSelectorTC = Simulink.sigselector.SigSelectorTC(opts);
            registerDataListeners(this,addlistener(this.SignalSelectorTC,...
                'ItemsChanged',@(src,evt)cbSignalSelectorItemChanged(this)));
            
            % Add listener if signalListPanel is provided
            if nargin > 2
                this.SignalListPanel = signalListPanel;
                registerDataListeners(this,addlistener(signalListPanel,...
                    'ObjectBeingDestroyed',@(src,evt)delete(this)));
            end
            
            registerUIListeners(this,addlistener(this,'CloseEvent', ...
                @(src,data)delete(this)))
        end
    end
    
    %% Public methods
    methods
        function updateUI(this)
            % Updates graphical component with data
            
            if this.IsWidgetValid
                disableUIListeners(this)
                updateSignalPanel(this)
                enableUIListeners(this)
            end
            
            if this.IsVisible
%                 pack(this)
            end
        end
        
    end
    
    %% Protected methods
    methods(Access=protected)
        function buildUI(this)
            % Creates dialog using the following layout:
            %   ------------------------
            %   | Header               |
            %   ------------------------
            %   | SignalListPanel      |
            %   ------------------------
            %   | ButtonPanel          |
            %   ------------------------
            
            % Set dialog size.
            this.UIFigure.Position(3:4) = [410 162];
            
            % Create dialog layout
            dialogLayout = uigridlayout(this.UIFigure,[3 4]);
            dialogLayout.Scrollable = true;
            dialogLayout.RowHeight = {'fit','1x','fit'};
            dialogLayout.RowSpacing = 5;
            dialogLayout.ColumnWidth = {'fit','1x','fit','fit'};
            dialogLayout.ColumnSpacing = 5;
            dialogLayout.Padding = 5;
            
            this.Widgets.dialogLayout = dialogLayout;
            
            % Add header
            row = 1;
            headerLabel = uilabel(dialogLayout,'Text',getString(message(...
                'Control:designerapp:AddSignalFromModelLabel',getName(this.Data))),...
                'Tag',createName('headerLabel'));
            headerLabel.Layout.Row = row;
            headerLabel.Layout.Column = [1 4];
            
            this.Widgets.headerLabel = headerLabel;
            
            % Add signal list panel
            row = row + 1;
            createSignalListPanel(this,row,[1 4])
            
            
            % Add buttons ----
            row = row + 1;
            % Help button
            helpButton = uibutton(dialogLayout,...
                'Text',getString(message('Control:designerapp:strHelp')),...
                'Tag',createName('helpButton'));
            helpButton.ButtonPushedFcn = @(src,evt)cbHelpButton(this);
            helpButton.Layout.Row = row;
            helpButton.Layout.Column = 1;
            this.Widgets.helpButton = helpButton;
            
            % Add-signals button
            addSignalsButton = uibutton(dialogLayout,...
                'Text',getString(message('Control:designerapp:AddSignalFromModelButtonLabel')),...
                'Tag',createName('addSignalsButton'), ...
                'Interruptible',false ...
                );
            addSignalsButton.ButtonPushedFcn = @(src,evt)cbAddSignalsButton(this);
            addSignalsButton.Layout.Row = row;
            addSignalsButton.Layout.Column = 3;
            this.Widgets.addSignalsButton = addSignalsButton;
            
            % Cancel button
            cancelButton = uibutton(dialogLayout,...
                'Text',getString(message('Control:designerapp:strCancel')),...
                'Tag',createName('cancelButton'));
            cancelButton.ButtonPushedFcn = @(src,evt)cbCancelButton(this);
            cancelButton.Layout.Row = row;
            cancelButton.Layout.Column = 4;
            this.Widgets.cancelButton = cancelButton;
            
        end
    end
    
    %% Private methods
    methods(Access=private)
        function createSignalListPanel(this,row,col)
            % Creates signal-list panel using the following layout:
            %   [SignalName HighlightSignalButton RemoveSignalButton]

            if this.EditType ~= ctrlguis.csdesignerapp.panels.internal.SignalEditType.Initialization
                return
            end            
            
            signals = this.CandidateSignals;
            numberOfSignals = numel(signals);
            numRows = max(numberOfSignals,1);
            numCols = 3;
            preSignalNumber = length(this.Widgets.signalNameLabel);
            
            % Create SignalPanel
            panel = uipanel(this.Widgets.dialogLayout);
            panel.Layout.Row = row;
            panel.Layout.Column = col;
            panel.BackgroundColor = 'white';
            
            this.Widgets.signalPanel = panel;
            
            % Create panel layout.
            layout = uigridlayout(panel,[numRows numCols]);
            layout.Scrollable = 'on';
            layout.Padding = 5;
            layout.ColumnSpacing = 5;
            layout.RowSpacing = 5;
            layout.RowHeight = repmat({'fit'},[1 numRows]);
            layout.ColumnWidth = [{'1x'} repmat({this.ButtonIconWidth},[1 numCols-1])];
            
            this.Widgets.signalPanelLayout = layout;
            
            % Initialize the widgets.
            initializeRow(this,signals,preSignalNumber+1:numberOfSignals)
            
            this.EditType = ctrlguis.csdesignerapp.panels.internal.SignalEditType.None;            
        end
        
        
        function initializeRow(this,signals,signalIndices)
            
            if isempty(signalIndices)
                return
            end
                        
            layout = this.Widgets.signalPanelLayout;
            signalNameLabel = this.Widgets.signalNameLabel;
            highlightSignalButton = this.Widgets.highlightSignalButton;
            removeSignalButton = this.Widgets.removeSignalButton;
            
            for ct = signalIndices
                % Signal Name
                signalNameLabel{ct} = uilabel(layout, ...
                    'Text',getSignalDisplayData(signals{ct}), ...
                    'Tag',createName(sprintf('SignalNameLabel_%d',ct))...
                    );
                signalNameLabel{ct}.Layout.Row = ct;
                signalNameLabel{ct}.Layout.Column = 1;
                
                % Highlight Signal Button
                highlightSignalButton{ct} = uibutton(layout, ...
                    'Text','',...
                    'IconAlignment','center', ...
                    'Tag',createName(sprintf('HighlightSignalButton_%d',ct)));
                matlab.ui.control.internal.specifyIconID(highlightSignalButton{ct}, 'highlightBlockAction', 16);
                highlightSignalButton{ct}.Layout.Row = ct;
                highlightSignalButton{ct}.Layout.Column = 2;
                highlightSignalButton{ct}.ButtonPushedFcn = ...
                    @(es,ed)cbHighlightSignalButton(this,ct);
                
                % Remove Signal Button
                removeSignalButton{ct} = uibutton(layout, ...
                    'Text','',...
                    'IconAlignment','center', ...
                    'Tag',createName(sprintf('RemoveSignalButton_%d',ct)));
                matlab.ui.control.internal.specifyIconID(removeSignalButton{ct}, 'delete', 16);
                removeSignalButton{ct}.Layout.Row = ct;
                removeSignalButton{ct}.Layout.Column = 3;
                removeSignalButton{ct}.ButtonPushedFcn = ...
                    @(src,evt)cbRemoveSignalButton(this,ct);
            end
            
            this.Widgets.signalNameLabel = signalNameLabel;
            this.Widgets.highlightSignalButton = highlightSignalButton;
            this.Widgets.removeSignalButton = removeSignalButton;
        end
        
        function checkWidgetConsistency(this,signals,signalIndices)
            
            if isempty(signalIndices)
                return
            end
            
            signalNameLabel = this.Widgets.signalNameLabel;
            highlightSignalButton = this.Widgets.highlightSignalButton;
            removeSignalButton = this.Widgets.removeSignalButton;
            
            for ct = signalIndices
                signalName = getSignalDisplayData(signals{ct});
                % Signal Name
                signalNameLabel{ct}.Text = signalName;
                signalNameLabel{ct}.Tag = createName(sprintf('SignalNameLabel_%d',ct));
                signalNameLabel{ct}.Layout.Row = ct;
                
                % Highlight Signal Button
                highlightSignalButton{ct}.Tag = createName(sprintf('HighlightSignalButton_%d',ct));
                highlightSignalButton{ct}.Layout.Row = ct;
                highlightSignalButton{ct}.ButtonPushedFcn = ...
                    @(es,ed)cbHighlightSignalButton(this,ct);
                
                % Remove Signal Button
                removeSignalButton{ct}.Tag = createName(sprintf('RemoveSignalButton_%d',ct));
                removeSignalButton{ct}.Layout.Row = ct;
                removeSignalButton{ct}.ButtonPushedFcn = ...
                    @(src,evt)cbRemoveSignalButton(this,ct);
            end
            
        end
        
        function updateSignalPanel(this)
            % Update signal list panel.
            
            if this.EditType == ctrlguis.csdesignerapp.panels.internal.SignalEditType.None
                return
            end
            
            signals = this.CandidateSignals;
            numberOfSignals = numel(signals);
            preSignalNumber = length(this.Widgets.signalNameLabel);
            layout = this.Widgets.signalPanelLayout;
            
            assert(abs(numberOfSignals-preSignalNumber)<=1,'You must add or remove only one signal.')
                        
            if this.EditType == ctrlguis.csdesignerapp.panels.internal.SignalEditType.Remove
                delete(this.Widgets.signalNameLabel{this.SignalIndex})
                this.Widgets.signalNameLabel(this.SignalIndex) = [];
                
                delete(this.Widgets.highlightSignalButton{this.SignalIndex})
                this.Widgets.highlightSignalButton(this.SignalIndex) = [];
                
                delete(this.Widgets.removeSignalButton{this.SignalIndex})
                this.Widgets.removeSignalButton(this.SignalIndex) = [];
                
                layout.RowHeight(this.SignalIndex) = [];
                
                checkWidgetConsistency(this,signals,this.SignalIndex:numberOfSignals)
            elseif this.EditType == ctrlguis.csdesignerapp.panels.internal.SignalEditType.Add
                layout.RowHeight = [layout.RowHeight {'fit'}];
                initializeRow(this,signals,preSignalNumber+1:numberOfSignals)
            end
            
            this.EditType = ctrlguis.csdesignerapp.panels.internal.SignalEditType.None;
        end
        
        function removeSignal(this,signalToDelete)
            import ctrlguis.csdesignerapp.utils.internal.newOrCommonItemsInList
            
            allSignals = this.CandidateSignals;
            [~,commonSignal,commonSignalIndex] = newOrCommonItemsInList(...
                signalToDelete,allSignals);
            
            if ~isempty(commonSignal)
                allSignals(commonSignalIndex,:) = [];
                this.CandidateSignals = allSignals;
                updateUI(this)
            end
        end
        
        function cbSignalSelectorItemChanged(this)
            % Add the selected model signal to candidate signals
            
            this.EditType = ctrlguis.csdesignerapp.panels.internal.SignalEditType.Add;            
            
            candidateSignals = this.CandidateSignals;
            allItems = getItems(this.SignalSelectorTC);
            if isempty(allItems)
                %Quick return, nothing to add
                return
            end
            %SigSelectorTC is setup as interactive with wholebusonly so
            %should only ever have one item
            [nSig,idx] = createSignal([candidateSignals{:}],allItems{1});
            if idx < 1
                %New signal
                candidateSignals = vertcat(candidateSignals,{nSig});
                this.CandidateSignals = candidateSignals;
                updateUI(this)
            end
        end
        
        function cbRemoveSignalButton(this,ct)
            % get signal name of the row that remove button is clicked
            
            this.EditType = ctrlguis.csdesignerapp.panels.internal.SignalEditType.Remove;
            this.SignalIndex = ct;
            
            signal = this.CandidateSignals(ct);
            disableUIListeners(this);
            % remove from tc data
            removeSignal(this,signal);
            enableUIListeners(this);
        end
        
        function cbHighlightSignalButton(this,ct)
            try
                if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.Data.getName))
                    open_system(this.Data.getName);
                end
                blockPath = convertToCell(this.CandidateSignals{ct}.BlockPath);
                hilite_system(blockPath,'find');
                pause(1);
                hilite_system(blockPath,'none');
                this.HighlightSignalStatus = true;
            catch ME
                this.HighlightSignalStatus = false;
                throw(ME);
            end
        end
        
        function cbHelpButton(this) %#ok<MANU>
            ctrlguihelp('CSD_AddSignalFromModelHelp','CSHelpWindow');
        end
        
        function cbCancelButton(this)
            delete(this);
        end
        
        function cbAddSignalsButton(this)
            
            fig = this.UIFigure;
            currPointer = ctrlguis.csdesignerapp.panels.internal.setPointer(fig,'watch');
            restorePointer = onCleanup(@()ctrlguis.csdesignerapp.panels.internal.setPointer(fig,currPointer));
            
            signals = this.CandidateSignals;
            disableUIListeners(this)
            if ~isempty(signals)
                if ~any(strcmp(find_system('type','block_diagram','Shown','on'),this.Data.getName))
                    open_system(this.Data.getName);
                end
                blockPaths = cellfun(@(x) convertToCell(x.BlockPath),signals);
                portIndexes = cellfun(@(x) x.PortIndex,signals);
                for ct=1:length(signals)
                    pointsToAdd(ct) = linio(blockPaths{ct},portIndexes(ct),'input'); %#ok<AGROW>
                end
                feval(this.AddSignalHandle, this.Data, pointsToAdd);
                if ~isempty(this.SignalListPanel)
                    [Names,Points] = this.Data.getPoints;
                    if strcmp(this.SignalListPanel.SignalListType,'Openings') || ~this.SignalListPanel.Data.Editable
                        for ct=1:length(signals)
                            slTunerPointName = Names(arrayfun(@(x) isequal(x.Block,blockPaths{ct}) & isequal(x.PortNumber,portIndexes(ct)),Points));
                            addSignal(this.SignalListPanel,slTunerPointName);
                        end
                    else
                        slTunerPointName = Names(arrayfun(@(x) isequal(x.Block,blockPaths{1}) & isequal(x.PortNumber,portIndexes(1)),Points));
                        [~,expandedList] = getAvailableSignals(this.SignalListPanel);
                        [subSignalList,isSingleSignal]=ctrlguis.csdesignerapp.utils.internal.expandSignalList(slTunerPointName{:},expandedList);
                        if isSingleSignal
                            subSignalList = {subSignalList};
                        end
                        addSignal(this.SignalListPanel,subSignalList(1));
                    end
                end
                %delete(restorePointer)
                delete(this)
            else
                delete(restorePointer)
                msg = getString(message(...
                    'Control:designerapp:AddSignalFromModelDialogError'));
                okLabel = getString(message('Control:designerapp:strOK'));                
                uiconfirm(this.getWidget,msg,this.Title,'Options',{okLabel}, ...
                    'Icon','error')
                enableUIListeners(this)
            end
        end
    end
    
    %% Hiden QE methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
        end
        
        function status = qeGetHighlightSignalStatus(this)
            status = this.HighlightSignalStatus;
        end
        
        function qeSetHighlightSignalStatus(this,status)
            if islogical(status)
                this.HighlightSignalStatus = status;
            end
        end
    end
end
%% Local functions --------------------------------------------------------
function opts = getSignalSelectorOptions(data)
% Configure Signal Selector tool component.

mdl = getName(data);
opts = Simulink.sigselector.Options;
opts.InteractiveSelection = true;
opts.BusSupport = 'wholeonly';
opts.FilterVisible = false;
opts.Model = mdl;
opts.MdlrefSupport = 'normalonly';

% Clear all signal selections
arrayfun(@(x) set_param(x,'Selected','off'),gsl(mdl));
end

function [nSig,idx] = createSignal(Signals,item)
nSig = Simulink.SimulationData.Signal;
nSig.Name      = item.Source.SignalName;
nSig.BlockPath = item.Source.Block;
nSig.PortIndex = item.Source.PortNumber;
nSig.PortType  = item.Source.PortType;
idx = 0;
ct = 1;
while idx==0 && ct <= numel(Signals)
    if isequal(Signals(ct).Name,nSig.Name) && ...
            isequal(Signals(ct).BlockPath,nSig.BlockPath) && ...
            isequal(Signals(ct).PortIndex,nSig.PortIndex) && ...
            isequal(Signals(ct).PortType,nSig.PortType)
        idx = ct;
    else
        ct = ct + 1;
    end
end
end

function strData = getSignalDisplayData(Signals,nonames)
%GETSIGNALDISPLAYDATA
%
%  str = getSignalDisplayData(Signals,[nonames])
%
%  Inputs:
%    Signals - vector of Simulink.SimulationData.Signal objects
%    nonames - flag indicating whether to include signal names
%              in description or only use path, if omitted the
%              default false value is used
%
% Outputs
%    str - cell array of strings for each element in Signals
%

if nargin < 2
    nonames = false;
end

nS = numel(Signals);
strData = '';
for ct=1:nS
    blkPath = convertToCell(Signals(ct).BlockPath);
    str = sprintf('%s:%d', ...
        blkPath{1},Signals(ct).PortIndex);
    if isempty(Signals(ct).Name) || nonames
        str = sprintf('%s',str);
    else
        str = sprintf('%s (%s)',str,Signals(ct).Name);
    end
    strData = str;
end
end

function name = createName(value)
% Create Name for testing by preappending signal list type
name = sprintf('%s_%s','AddSignal',value);
end
