classdef PropertyEditorDialog < controllib.ui.internal.dialog.AbstractDialog
    %% PropertyEditorDialog - Creates a property editor dialog
    %
    %  PropertyEditorDialog creates a basic dialog for changing axis
    %  properties of an editor. It provides:
    %     - empty tabs for the specified tab labels and 
    %     - a button panel containing HELP and CLOSE buttons.
    %
    %  DLG = PROPERTYEDITORDIALOG(TABLABELS) creates a dialog, DLG with the
    %  specified TABLABELS. The tab labels are specified as a cell array of
    %  character vectors.
    %
    %  PropertyEditorDialog properties:
    %      TabLabels - Labels of the tabs
    % 
    %  The following two properties are defined for test purpose to provide
    %  label and limit tab contents using flat structure format.
    %      LabelTabWidgets - Label tab widgets
    %      LimitTabWidgets - Limit tab widgets
    %  You can directly access these properties from a TestCase or from the
    %  structure returned by qeGetWidgets method.
    %
    %  Other public properties are available from the super class.
    %
    %  PropertyEditorDialog methods:
    %      setTarget          - Set a new graphical editor as a target
    %      buildtab           - Build contents of the specified tab
    %      getLabelTabWidgets - Get layout for the label tab  
    %      getLimitTabWidgets - Get layout for the limit tab
    %
    %  The following hidden method provides access to the widget components
    %  of the dialog:
    %      qeGetWidgets - Returns structure of widget components
    %
    %  Other public methods are available from the super class.
    %
    %  See also 
    %      ctrlguis.csdesignerapp.plot.internal.GraphicalEditor.PropEditor
    %      ctrlguis.csdesignerapp.plot.internal.BodeEditorOL.edit
    %      ctrlguis.csdesignerapp.plot.internal.NicholsEditor.edit
    %      ctrlguis.csdesignerapp.plot.internal.RootLocusEditor.edit
    
    %  Copyright 2020-2023 The MathWorks, Inc.
    
    %% Properties
    properties(Access=private)
        Widgets = struct();
        
        Target
    end
    
    properties(SetAccess=private,GetAccess=public)
        TabLabels
    end
    
    properties(Access=private)
        Tabs
    end
    
    % Test purpose properties.
    properties(SetAccess=private,GetAccess=?matlab.unittest.TestCase)
        LabelTabWidgets
        LimitTabWidgets
    end
    
    %% Constructor
    methods
        function dlg = PropertyEditorDialog(tabLabels)
            dlg = dlg@controllib.ui.internal.dialog.AbstractDialog;
            
            % Set dialog properties.
            dlg.TabLabels = tabLabels;
            dlg.Name = 'PropertyEditorFrame';
            dlg.Title = getString(message('Controllib:gui:strPropertyEditor'));
            dlg.Tabs = struct('Name',tabLabels(:),'Tab',[],'Contents',[]);
            dlg.CloseMode = 'hide';
            
            % Build dialog
            getWidget(dlg);
            if dlg.IsWidgetValid
                buildUI(dlg)
            end
            
            % Add listener to the CloseEvent
            registerUIListeners(dlg,...
               addlistener(dlg,'CloseEvent',@(src,evt)cbCloseButton(dlg)))
            
        end
    end
    
    %% Public methods.
    methods
        function setTarget(dlg,newTarget)
            %SETTARGET  (Re)targets the Property Editor.
            
            if ~isequal(dlg.Target,newTarget)
                % Unselect old target's axes
                if ~isempty(dlg.Target) && ...
                        ((ishandle(dlg.Target) && ~dlg.Target.isBeingDestroyed) || ... %UDD
                        (isobject(dlg.Target) && isvalid(dlg.Target))) %MCOS
                    currentAxes = getaxes(dlg.Target);
                    if ~isactiveuimode(ancestor(currentAxes(1),'figure'),'Standard.EditPlot')
                        set(getaxes(dlg.Target),'Selected','off')
                    end
                end
                
                % Update property
                dlg.Target = newTarget;
                
                % Listener management
                if isempty(newTarget)
                    % Delete target-dependent listeners
                    unregisterUIListeners(dlg,'TargetDestroyed')
                else
                    % Listen for Target destruction
                    if ishandle(dlg.Target) %UDD
                        registerUIListeners(dlg,...
                            handle.listener(newTarget,'ObjectBeingDestroyed',@(src,evt)resetTargetAndClose(dlg)), ...
                            'TargetDestroyed')
                    else %MCOS
                        registerUIListeners(dlg,...
                            addlistener(newTarget,'ObjectBeingDestroyed',@(src,evt)resetTargetAndClose(dlg)), ...
                            'TargetDestroyed')
                    end
                    
                    % Delete tab widgets of the previous target.
                    unregisterDataListeners(dlg)
                    for tabId = 1:numel(dlg.Tabs)
                        if ~isempty(dlg.Tabs(tabId).Contents)
                            dlg.Tabs(tabId).Contents.Parent = [];
                            delete(dlg.Tabs(tabId).Contents)
                            dlg.Tabs(tabId).Contents = [];
                        end
                    end
                    % Test only
                    dlg.LabelTabWidgets = [];
                    dlg.LimitTabWidgets = [];
                    
                    % Populate tabs and sync data with new target.
                    newTarget.edit(dlg)
                    
                    % Pack
                    
                end
            end
            
            % Dialog visibility.
            if isempty(newTarget)
                close(dlg)
            else
                % Show which plot is selected
                newAxes = getaxes(newTarget);
                if ~isactiveuimode(ancestor(newAxes(1),'figure'),'Standard.EditPlot')
                    set(newAxes,'Selected','on')
                end
                show(dlg)
            end
        end
        
        function buildtab(dlg,index,newContents)
            %BUILDTAB  Builds Property Editor tabs.
            
            % Get the content of the specified tab.
            tab = dlg.Tabs(index).Tab;
            contents = dlg.Tabs(index).Contents;
            
            % Return if no change in the content.
            % =============================================================
            % NOTE: The following check might be redundant. Remove if it is
            % dead code.
            % =============================================================
            if isequal(contents,newContents)
                return
            end
            
            % Update tab contents.
            % =============================================================
            % NOTE: The following check might be redundant. Remove if it is
            % dead code.
            % =============================================================
            if ~isempty(contents)
                contents.Parent = [];
                delete(contents)
            end
            
            % Assign the specified tab as the parent of the new content.
            % =============================================================
            % NOTE: According to the workflow, new content is always valid.
            % We may remove the following empty check.
            % =============================================================
            if ~isempty(newContents)
                newContents.Parent = tab;
            end
            
            % Update tab info
            dlg.Tabs(index).Contents = newContents;
            
            % Add tab to the group.
            tab.Parent = dlg.Widgets.TabGroup;
        end
        
        function layout = getLabelTabWidgets(dlg,axs)
            % Build label tab widgets.
                        
            if isa(axs,'ctrluis.axespair')
                % Create 3 rows for axespair object.
                numRows = 4;
            else
                % Otherwise create 2 rows.
                numRows = 3;
            end
            
            % Create tab layout. 
            layout = uigridlayout('Parent',[],'Tag','labelTabLayout');
            layout.RowHeight = repmat({'1x'},[1 numRows]);
            layout.ColumnWidth = {'fit','1x'};
            layout.RowSpacing = 10;
            layout.ColumnSpacing = 5;
            layout.Padding = 20;
            widgets.layout = layout;
            
            % Title label
            titleLabel = uilabel(layout, ...
                'Tag','titleLabel', ...
                'Text',ctrlMsgUtils.message('Controllib:gui:strTitleLabel'), ...
                'HorizontalAlignment','right', ...
                'VerticalAlignment','top' ...
                );
            titleLabel.Layout.Row = 1;
            titleLabel.Layout.Column = 1;
            widgets.titleLabel = titleLabel;
            
            % X-axis label.
            xLabel = uilabel(layout, ...
                'Tag','xLabel', ...
                'Text',ctrlMsgUtils.message('Controllib:gui:strXLabelLabel'), ...
                'HorizontalAlignment','right', ...
                'VerticalAlignment','top' ...
                );
            xLabel.Layout.Row = 2;
            xLabel.Layout.Column = 1;
            widgets.xLabel = xLabel;
            
            % Y-axis label.
            yLabel = uilabel(layout, ...
                'Tag','yLabel', ...
                'Text',ctrlMsgUtils.message('Controllib:gui:strYLabelLabel'), ...
                'HorizontalAlignment','right', ...
                'VerticalAlignment','top' ...
                );
            yLabel.Layout.Column = 1;
            widgets.yLabel = yLabel;
            
            % Title edit
            titleTextArea = uitextarea(layout,...
                'Tag','titleTextArea', ...
                'Value',axs.Title);
            titleTextArea.Layout.Row = 1;
            titleTextArea.Layout.Column = 2;
            titleTextArea.ValueChangedFcn = @(src,evt)cbUpdateTitle(axs,src);
            widgets.titleTextArea = titleTextArea;
            
            % X-label edit
            xLabelTextArea = uitextarea(layout,...
                'Tag','xLabelTextArea', ...
                'Value',axs.XLabel);
            xLabelTextArea.Layout.Row = 2;
            xLabelTextArea.Layout.Column = 2;
            xLabelTextArea.ValueChangedFcn = @(src,evt)cbUpdateXLabel(axs,src);
            widgets.xLabelTextArea = xLabelTextArea;
            
            % Y-label edit
            if numRows == 3
                yLabel.Layout.Row = 3;
                
                yLabelTextArea = uitextarea(layout,...
                    'Tag','yLabelTextArea', ...
                    'Value',axs.YLabel);
                yLabelTextArea.Layout.Row = 3;
                yLabelTextArea.Layout.Column = 2;
                yLabelTextArea.ValueChangedFcn = @(src,evt)cbUpdateYLabel(axs,src);
                widgets.yLabelTextArea = yLabelTextArea;
            else
                yLabel.Layout.Row = [3 4];
                
                y1LabelTextArea = uitextarea(layout,...
                    'Tag','y1LabelTextArea', ...
                    'Value',axs.YLabel{1});
                y1LabelTextArea.Layout.Row = 3;
                y1LabelTextArea.Layout.Column = 2;
                y1LabelTextArea.ValueChangedFcn = @(src,evt)cbUpdateYLabel(axs,src,1);        
                widgets.y1LabelTextArea = y1LabelTextArea;
                
                y2LabelTextArea = uitextarea(layout,...
                    'Tag','y2LabelTextArea', ...
                    'Value',axs.YLabel{2});
                y2LabelTextArea.Layout.Row = 4;
                y2LabelTextArea.Layout.Column = 2;
                y2LabelTextArea.ValueChangedFcn = @(src,evt)cbUpdateYLabel(axs,src,2);        
                widgets.y2LabelTextArea = y2LabelTextArea;
            end
            dlg.LabelTabWidgets = widgets;
        end
        
        function layout = getLimitTabWidgets(dlg,axesView,panelTitles)
            % Build limit tab widgets.

            if isa(axesView,'controllib.chart.internal.view.axes.BodeAxesView')
                % Three panels for axespair object.
                numPanels = 3;
            else
                % Otherwise 2 panels.
                numPanels = 2;
            end
            
            % Create tab layout.
            layout = uigridlayout('Parent',[],'Tag','limitTabLayout');
            layout.RowHeight = repmat({'1x'},[1 numPanels]);
            layout.ColumnWidth = {'1x'};
            layout.RowSpacing = 10;
            layout.ColumnSpacing = 0;
            layout.Padding = 10;
            widgets.layout = layout;
            
            % Add limit panel for x-axis.
            xLimitWidgets = createLimitPanel(layout,1,1);
            xLimitWidgets.panel.Tag = 'xLimitPanel';
            limits = axesView.qeGetAxesGrid.XLimits{1};
            xLimitWidgets.panel.Title = panelTitles{1};
            xLimitWidgets.panel.UserData = limits;
            xLimitWidgets.autoScaleCheckBox.ValueChangedFcn = ...
                @(src,evt)cbAutoScaleCheckBox(axesView,src,'X',xLimitWidgets);
            xLimitWidgets.autoScaleLowerLimitEditField.Value = num2str(limits(1));
            xLimitWidgets.autoScaleUpperLimitEditField.Value = num2str(limits(2));
            xLimitWidgets.autoScaleLowerLimitEditField.ValueChangedFcn = ...
                @(src,evt)cbLimitEditField(axesView,src,'X',xLimitWidgets,true);
            xLimitWidgets.autoScaleUpperLimitEditField.ValueChangedFcn = ...
                @(src,evt)cbLimitEditField(axesView,src,'X',xLimitWidgets,false);
            L = addlistener(axesView,'LimitsChanged',@(es,ed) updateLimitPanel(axesView,'X',xLimitWidgets));
            registerDataListeners(dlg,L);
            % registerDataListeners(dlg,handle.listener(axs,'PostLimitChanged',...
            %     @(src,evt)updateLimitPanel(axs,'X',xLimitWidgets)))
            widgets.xLimitWidgets = xLimitWidgets;
  
            
            if numPanels == 2
                % Add limit panel for y-axis.
                yLimitWidgets = createLimitPanel(layout,2,1);
                yLimitWidgets.panel.Tag = 'yLimitPanel';
                limits = axesView.qeGetAxesGrid.YLimits{1};
                yLimitWidgets.panel.Title = panelTitles{2};
                yLimitWidgets.panel.UserData = limits;
                yLimitWidgets.autoScaleCheckBox.ValueChangedFcn = ...
                    @(src,evt)cbAutoScaleCheckBox(axesView,src,'Y',yLimitWidgets);
                yLimitWidgets.autoScaleLowerLimitEditField.Value = num2str(limits(1));
                yLimitWidgets.autoScaleUpperLimitEditField.Value = num2str(limits(2));
                yLimitWidgets.autoScaleLowerLimitEditField.ValueChangedFcn = ...
                    @(src,evt)cbLimitEditField(axesView,src,'Y',yLimitWidgets,true);
                yLimitWidgets.autoScaleUpperLimitEditField.ValueChangedFcn = ...
                    @(src,evt)cbLimitEditField(axesView,src,'Y',yLimitWidgets,false);
                L = addlistener(axesView,'LimitsChanged',@(es,ed) updateLimitPanel(axesView,'Y',yLimitWidgets));
                registerDataListeners(dlg,L);
                % registerDataListeners(dlg,handle.listener(axs,'PostLimitChanged',...
                %     @(src,evt)updateLimitPanel(axs,'Y',yLimitWidgets)))
                widgets.yLimitWidgets = yLimitWidgets;
            else
                % Add limit panel for y1-axis.
                ax = axesView.getAxes;
                y1LimitWidgets = createLimitPanel(layout,2,1);
                y1LimitWidgets.panel.Tag = 'y1LimitPanel';
                limits = ax(1).YLim;
                y1LimitWidgets.panel.Title = panelTitles{2};
                y1LimitWidgets.panel.UserData = limits;
                y1LimitWidgets.autoScaleCheckBox.ValueChangedFcn = ...
                    @(src,evt)cbAutoScaleCheckBox(axesView,src,'Y1',y1LimitWidgets);
                y1LimitWidgets.autoScaleLowerLimitEditField.Value = num2str(limits(1));
                y1LimitWidgets.autoScaleUpperLimitEditField.Value = num2str(limits(2));
                y1LimitWidgets.autoScaleLowerLimitEditField.ValueChangedFcn = ...
                    @(src,evt)cbLimitEditField(axesView,src,'Y1',y1LimitWidgets,true);
                y1LimitWidgets.autoScaleUpperLimitEditField.ValueChangedFcn = ...
                    @(src,evt)cbLimitEditField(axesView,src,'Y1',y1LimitWidgets,false);
                L = addlistener(axesView,'LimitsChanged',@(es,ed) updateLimitPanel(axesView,'Y1',y1LimitWidgets));
                registerDataListeners(dlg,L);
                % registerDataListeners(dlg,handle.listener(axs,'PostLimitChanged',...
                %     @(src,evt)updateLimitPanel(axs,'Y1',y1LimitWidgets)))
                widgets.y1LimitWidgets = y1LimitWidgets;
                
                % Add limit panel for y2-axis.
                y2LimitWidgets = createLimitPanel(layout,3,1);
                y2LimitWidgets.panel.Tag = 'y2LimitPanel';
                limits = ax(2).YLim;
                y2LimitWidgets.panel.Title = panelTitles{3};
                y2LimitWidgets.panel.UserData = limits;
                y2LimitWidgets.autoScaleCheckBox.ValueChangedFcn = ...
                    @(src,evt)cbAutoScaleCheckBox(axesView,src,'Y2',y2LimitWidgets);
                y2LimitWidgets.autoScaleLowerLimitEditField.Value = num2str(limits(1));
                y2LimitWidgets.autoScaleUpperLimitEditField.Value = num2str(limits(2));
                y2LimitWidgets.autoScaleLowerLimitEditField.ValueChangedFcn = ...
                    @(src,evt)cbLimitEditField(axesView,src,'Y2',y2LimitWidgets,true);
                y2LimitWidgets.autoScaleUpperLimitEditField.ValueChangedFcn = ...
                    @(src,evt)cbLimitEditField(axesView,src,'Y2',y2LimitWidgets,false);
                L = addlistener(axesView,'LimitsChanged',@(es,ed) updateLimitPanel(axesView,'Y2',y2LimitWidgets));
                registerDataListeners(dlg,L);
                widgets.y2LimitWidgets = y2LimitWidgets;
            end
            dlg.LimitTabWidgets = widgets;
        end
        
    end
    
    %% Protected methods for overloading.
    methods(Access=protected)
        function buildUI(dlg)
            %BUILD  Builds Property Editor.
            
            % Set dialog size.
            width = 380;
            height = 350;
            dlg.UIFigure.Position(3:4) = [width,height];
            
            %---Open an empty Frame with some status text
            figureLayout = uigridlayout(dlg.UIFigure,[2 1]);
            figureLayout.Tag = 'figureLayout';
            figureLayout.RowHeight = {'1x','fit'};
            figureLayout.ColumnWidth = {'1x'};
            figureLayout.RowSpacing = 0;
            figureLayout.ColumnSpacing = 0;
            figureLayout.Padding = 0;
            
            dlg.Widgets.FigureLayout = figureLayout;
            
            % Tab group
            tabGroup = uitabgroup(figureLayout,'Tag','tabGroup');
            tabGroup.Layout.Row = 1;
            tabGroup.Layout.Column = 1;
            
            dlg.Widgets.TabGroup = tabGroup;
            
            % Tabs
            numTabs = numel(dlg.TabLabels);
            tabs = repmat(uitab('Parent',[]),[1 numTabs]);
            for i = 1:numTabs
                dlg.Tabs(i).Name = dlg.TabLabels{i};
                tabs(i) = uitab('Parent',[], ...
                    'Title',dlg.TabLabels{i}, ...
                    'Tag',['tab' dlg.TabLabels{i}]);
                dlg.Tabs(i).Tab = tabs(i);
            end
            dlg.Widgets.Tabs = tabs;
            
            % ButtonPanel
            buttonPanel = uipanel(figureLayout,'Tag','buttonPanel');
            buttonPanel.Layout.Row = 2;
            buttonPanel.Layout.Column = 1;
            dlg.Widgets.ButtonPanel = buttonPanel;
            
            buttonPanelLayout = uigridlayout(buttonPanel,[1 3]);
            buttonPanelLayout.RowHeight = {'fit'};
            buttonPanelLayout.ColumnWidth = {'fit','1x','fit'};
            buttonPanelLayout.RowSpacing = 0;
            buttonPanelLayout.ColumnSpacing = 0;
            buttonPanelLayout.Padding = 5;
            
            dlg.Widgets.ButtonPanelLayout = buttonPanelLayout;
            
            % Help button
            helpButton = uibutton(buttonPanelLayout, ...
                'Text', ctrlMsgUtils.message('Controllib:general:strHelp'), ...
                'Tag','btnHelp');
            helpButton.Layout.Row = 1;
            helpButton.Layout.Column = 1;
            helpButton.ButtonPushedFcn = @(src,evt)cbHelpButton(dlg);
            dlg.Widgets.HelpButton = helpButton;
            
            % Close button
            closeButton = uibutton(buttonPanelLayout, ...
                'Text',ctrlMsgUtils.message('Controllib:general:strClose'), ...
                'Tag','btnClose');
            closeButton.Layout.Row = 1;
            closeButton.Layout.Column = 3;
            closeButton.ButtonPushedFcn = @(src,evt)cbCloseButton(dlg);
            dlg.Widgets.CloseButton = closeButton;
        end
        
        function cleanupUI(dlg)
            % Clean up parentless widgets.
            
            for i = 1:numel(dlg.Tabs)
                if isempty(dlg.Tabs(i).Contents)
                    delete(dlg.Tabs(i).Tab)
                end
            end
        end
    end
    
    %% Hidden QE methods for overloading.
    methods(Hidden)
        function widgets = qeGetWidgets(dlg)
            % Return widgets of the dialog. 
            
            widgets = dlg.Widgets;
            widgets.labelTabWidgets = dlg.LabelTabWidgets; 
            widgets.limitTabWidgets = dlg.LimitTabWidgets;
        end
    end
    
    %% Private methods
    methods(Access=private)
        function resetTargetAndClose(dlg)
            dlg.setTarget([])
            close(dlg)
        end
        
        function deselectTarget(dlg)
            if ~isempty(dlg.Target)
                currentAxes = getaxes(dlg.Target);
                if ~isactiveuimode(ancestor(currentAxes(1),'figure'),'Standard.EditPlot')
                    set(currentAxes,'Selected','off')
                end
            end
        end
        
        function cbCloseButton(dlg)
            % Close editor
            
            % Deselect if the current target axis is selected.
            deselectTarget(dlg)
            
            % Hide the dialog.
            close(dlg)
        end
        
        function cbHelpButton(dlg) %#ok<MANU>
            if isempty(ver('control')) || ~license('test','Control_Toolbox')
                if isempty(ver('ident')) || ~ license('test','Identification_Toolbox')
                    utSloptimGUIHelp('axes_properties');
                else
                    identguihelp('response_properties');
                end
            else
                ctrlguihelp('response_properties');
            end
        end
                
    end
end
%% Local functions --------------------------------------------------------
function widgets = createLimitPanel(layout,row,col)
% Creat a limit panel.

panel = uipanel(layout,...
    'Tag','limitPanel',...
    'Title','limit','BorderType','none');
panel.Layout.Row = row;
panel.Layout.Column = col;
widgets.panel = panel;

panelLayout = uigridlayout(panel,[2 4]);
panelLayout.Tag = 'panelLayout';
panelLayout.RowHeight = {'fit','fit'};
panelLayout.ColumnWidth = {'fit','1x','fit','1x'};
panelLayout.RowSpacing = 10;
panelLayout.ColumnSpacing = 10;
panelLayout.Padding = 10;
widgets.panelLayout = panelLayout;

autoScaleLabel = uilabel(panelLayout, ...
    'Tag','autoScaleLabel',...
    'Text',ctrlMsgUtils.message('Controllib:gui:strAutoScaleLabel'), ...
    'HorizontalAlignment','right');
autoScaleLabel.Layout.Row = 1;
autoScaleLabel.Layout.Column = 1;
widgets.autoScaleLabel = autoScaleLabel;

autoScaleCheckBox = uicheckbox(panelLayout, ...
    'Tag','autoScaleCheckBox',...
    'Value',true,'Text','');
autoScaleCheckBox.Layout.Row = 1;
autoScaleCheckBox.Layout.Column = 2;
widgets.autoScaleCheckBox = autoScaleCheckBox;

autoScaleLimitLabel = uilabel(panelLayout, ...
    'Tag','autoScaleLimitLabel',...
    'Text',ctrlMsgUtils.message('Controllib:gui:strLimitsLabel'), ...
    'HorizontalAlignment','right');
autoScaleLimitLabel.Layout.Row = 2;
autoScaleLimitLabel.Layout.Column = 1;
widgets.autoScaleLimitLabel = autoScaleLimitLabel;

autoScaleLowerLimitEditField = uieditfield(panelLayout, ...
    'Tag','autoScaleLowerLimitEditField',...
    'HorizontalAlignment','left');
autoScaleLowerLimitEditField.Layout.Row = 2;
autoScaleLowerLimitEditField.Layout.Column = 2;
widgets.autoScaleLowerLimitEditField = autoScaleLowerLimitEditField;

autoScaleLimitConLabel = uilabel(panelLayout, ...
    'Tag','autoScaleLimitConLabel',...
    'Text',getString(message('Controllib:gui:strTo')), ...
    'HorizontalAlignment','center');
autoScaleLimitConLabel.Layout.Row = 2;
autoScaleLimitConLabel.Layout.Column = 3;
widgets.autoScaleLimitConLabel = autoScaleLimitConLabel;

autoScaleUpperLimitEditField = uieditfield(panelLayout, ...
    'Tag','autoScaleUpperLimitEditField',...
    'HorizontalAlignment','left');
autoScaleUpperLimitEditField.Layout.Row = 2;
autoScaleUpperLimitEditField.Layout.Column = 4;
widgets.autoScaleUpperLimitEditField = autoScaleUpperLimitEditField;
end

function cbUpdateTitle(axs,src)
% Callback function to update axis-title. 

axs.Title = src.Value;
end

function cbUpdateXLabel(axs,src)
% Callback function to update x-axis label. 

val = sprintf('%s\n',src.Value{:});
axs.XLabel = val(1:end-1);
end

function cbUpdateYLabel(axs,src,id)
% Callback function to update y-axis label. 

for k = 1:length(src.Value)
    if k <= length(axs.YLabel)
        axs.YLabel(k) = src.Value{k};
    end
end
end

function cbAutoScaleCheckBox(axs,src,xy,widgets)
% Callback function to update auto-scale selection.

if src.Value
    newLimMode = "auto";
else
    newLimMode = "manual";
end

switch xy
    case 'X'
        axs.XLimitsMode = newLimMode;
        limits = axs.XLimits;
    case 'Y'
        axs.YLimitsMode = newLimMode;
        limits = axs.YLimits;
    case 'Y1'
        axs.YLimitsMode{1} = newLimMode;
        limits = axs.YLimits{1};
    case 'Y2'
        axs.YLimitsMode{2} = newLimMode;
        limits = axs.YLimits{2};
end

% Reset limit values (if changed).
if src.Value && ~isequal(widgets.panel.UserData,limits)
    widgets.autoScaleLowerLimitEditField.Value = num2str(limits(1));
    widgets.autoScaleUpperLimitEditField.Value = num2str(limits(2));
    widgets.panel.UserData = limits;
end

end

function val = evalLim(str)
% Evaluate the string value. Return only valid real scalar value; otherwise
% throw error.

if isempty(str)
    error(message('Controllib:gui:errPropertyEditor_invalidLimitValue'))
end

val = evalin('base',str,'[]');
if isempty(val) || ~isreal(val) || any(~isfinite(val)) || ~isscalar(val)
    error(message('Controllib:gui:errPropertyEditor_invalidLimitValue'))
end

end

function cbLimitEditField(axs,src,xy,widgets,isLowerLimit)
% Callback function to update axis limit.

currentLims = widgets.panel.UserData;

try
    % Get new limit values.
    if isLowerLimit
        lowerLimit = evalLim(src.Value);
        upperLimit = currentLims(2);
    else
        lowerLimit = currentLims(1);
        upperLimit = evalLim(src.Value);
    end
    
    % Throw error for invalid limit values.
    if isempty(lowerLimit) || isempty(upperLimit) || lowerLimit>=upperLimit            
        error(message('Controllib:gui:errPropertyEditor_invalidLimitValue'))
    end
            
    % Return if no change in the limit values.
    newLimit = [lowerLimit upperLimit];
    if isequal(currentLims,newLimit)
        return
    end
    
    % Update the limit values.
    switch xy
        case 'X'
            axs.XLimits = newLimit;
        case 'Y'
            axs.YLimits = newLimit;
        case 'Y1'
            axs.YLimits{1} = newLimit;
        case 'Y2'
            axs.YLimits{2} = newLimit;
    end
    
    % Save the new limit values in case we need to restore it.
    widgets.panel.UserData = newLimit;
    
    % Uncheck auto-scale (if it's checked)
    if widgets.autoScaleCheckBox.Value
        widgets.autoScaleCheckBox.Value = 0;
    end
    
    % Update the limit value to ensure a variable value is shown in the
    % edit field.
    if isLowerLimit
        widgets.autoScaleLowerLimitEditField.Value = num2str(newLimit(1));
    else
        widgets.autoScaleUpperLimitEditField.Value = num2str(newLimit(2));
    end    
catch ME
    % Show error dialog.
    uialert(ancestor(qeGetChart(axs),'figure'),ME.message,...
        getString(message('Controllib:gui:strPropertyEditorError')));
    % Restore the valid limit value.
    if isLowerLimit
        widgets.autoScaleLowerLimitEditField.Value = num2str(currentLims(1));
    else
        widgets.autoScaleUpperLimitEditField.Value = num2str(currentLims(2));
    end
end
end

function updateLimitPanel(axs,xy,widgets)
% Update GUI when limits change

% Update auto-scale mode.
limMode = axs.(sprintf('%sLimitsMode',xy(1)));
switch xy
    case 'X'
        limits = axs.qeGetAxesGrid.XLimits{1};
        widgets.autoScaleCheckBox.Value = strcmp(limMode,'auto');
    case 'Y'
        limits = axs.qeGetAxesGrid.YLimits{1};
        widgets.autoScaleCheckBox.Value = strcmp(limMode,'auto');
    case 'Y1'
        limits = axs.qeGetAxesGrid.YLimits{1};
        widgets.autoScaleCheckBox.Value = strcmp(limMode{1},'auto');
    otherwise %'Y2'
        limits = axs.qeGetAxesGrid.YLimits{2};
        widgets.autoScaleCheckBox.Value = strcmp(limMode{2},'auto');
end

% Update limit values.
widgets.autoScaleLowerLimitEditField.Value = num2str(limits(1));
widgets.autoScaleUpperLimitEditField.Value = num2str(limits(2));

% Save the new limit values in case we need to restore it.
widgets.panel.UserData = limits;
end
