classdef StyleDialog < controllib.ui.internal.dialog.AbstractDialog
    % Class for the dialog to customize line styling for a Linear System Analyzer
    % session

    % Copyright 2024 The MathWorks, Inc.

    properties (Access=protected)
        App
        StyleManager = controllib.chart.internal.options.ResponseStyleManager
        ColorOrder

        DistinguishPanel
        ResponsesLabel
        ResponsesDropDown
        InputsLabel
        InputsDropDown
        OutputsLabel
        OutputsDropDown

        OrderPanel
        ColorOrderLabel
        MarkerOrderLabel
        LineStyleOrderLabel
        ColorUpBtn
        ColorDownBtn
        ColorList
        ColorAxes
        MarkerUpBtn
        MarkerDownBtn
        MarkerList
        LineStyleUpBtn
        LineStyleDownBtn
        LineStyleList

        ButtonPanel
        OKButton
        HelpButton
        CancelButton
        ApplyButton
    end

    properties (Access=protected, Constant)
        MarkerStyleDictionary = dictionary({'none','x','o','+','*','s','d','p'},...
            {getString(message('Control:viewer:strnone')),...
            getString(message('Control:viewer:strcross')),...
            getString(message('Control:viewer:strcircle')),...
            getString(message('Control:viewer:strplussign')),...
            getString(message('Control:viewer:strasterisk')),...
            getString(message('Control:viewer:strsquare')),...
            getString(message('Control:viewer:strdiamond')),...
            getString(message('Control:viewer:strpentagram'))})
        LineStyleDictionary = dictionary({'-','--','-.',':'},...
            {getString(message('Control:viewer:strsolid')),...
            getString(message('Control:viewer:strdashed')),...
            getString(message('Control:viewer:strdashdot')),...
            getString(message('Control:viewer:strdotted'))})
    end

    methods
        function this = StyleDialog(app)
            this = this@controllib.ui.internal.dialog.AbstractDialog();
            this.Name = 'LinearSystemAnalyzerStyleDialog';
            this.Title = getString(message('Control:viewer:strLineStyles'));
            this.App = app;
            this.StyleManager.ColorOrder = app.StyleManager.ColorOrder;
            this.StyleManager.MarkerOrder = app.StyleManager.MarkerOrder;
            this.StyleManager.LineStyleOrder = app.StyleManager.LineStyleOrder;
            this.StyleManager.SortByColor = app.StyleManager.SortByColor;
            this.StyleManager.SortByMarker = app.StyleManager.SortByMarker;
            this.StyleManager.SortByLineStyle = app.StyleManager.SortByLineStyle;
            this.ColorOrder = app.ColorOrder;
            this.CloseMode = 'destroy';
        end
    end
    methods (Access=protected)
        function buildUI(this)
            this.UIFigure.Position(3:4) = [405 410];
            figureGrid = uigridlayout(this.UIFigure,[4 1]);
            figureGrid.RowHeight = {'fit','1x','fit',0};

            this.DistinguishPanel = uipanel(figureGrid);
            this.DistinguishPanel.Layout.Row = 1;
            this.DistinguishPanel.Title = getString(message('Control:viewer:lblDistinguishBy'));
            distinguishGrid = uigridlayout(this.DistinguishPanel,[3 3]);
            distinguishGrid.RowHeight = {'fit','fit','fit'};
            distinguishGrid.ColumnWidth = {'fit','fit','1x'};
            distinguishItems = {getString(message('Control:viewer:strColor')),...
                getString(message('Control:viewer:strMarker')),...
                getString(message('Control:viewer:strLinestyle')),...
                getString(message('Control:viewer:strNoDistinction'))};
            this.ResponsesLabel = uilabel(distinguishGrid);
            this.ResponsesLabel.Layout.Row = 1;
            this.ResponsesLabel.Layout.Column = 1;
            this.ResponsesLabel.Text = getString(message('Control:viewer:strSystems'));
            this.ResponsesDropDown = uidropdown(distinguishGrid);
            this.ResponsesDropDown.Layout.Row = 1;
            this.ResponsesDropDown.Layout.Column = 2;
            this.ResponsesDropDown.Items = distinguishItems;
            this.ResponsesDropDown.Value = getString(message('Control:viewer:strColor'));
            this.ResponsesDropDown.ValueChangedFcn = @(es,ed) cbResponsesDropDownChanged(this,ed);
            this.InputsLabel = uilabel(distinguishGrid);
            this.InputsLabel.Layout.Row = 2;
            this.InputsLabel.Layout.Column = 1;
            this.InputsLabel.Text = getString(message('Control:viewer:strInputs'));
            this.InputsDropDown = uidropdown(distinguishGrid);
            this.InputsDropDown.Layout.Row = 2;
            this.InputsDropDown.Layout.Column = 2;
            this.InputsDropDown.Items = distinguishItems;
            this.InputsDropDown.Value = getString(message('Control:viewer:strNoDistinction'));
            this.InputsDropDown.ValueChangedFcn = @(es,ed) cbInputsDropDownChanged(this,ed);
            this.OutputsLabel = uilabel(distinguishGrid);
            this.OutputsLabel.Layout.Row = 3;
            this.OutputsLabel.Layout.Column = 1;
            this.OutputsLabel.Text = getString(message('Control:viewer:strOutputs'));
            this.OutputsDropDown = uidropdown(distinguishGrid);
            this.OutputsDropDown.Layout.Row = 3;
            this.OutputsDropDown.Layout.Column = 2;
            this.OutputsDropDown.Items = distinguishItems;
            this.OutputsDropDown.Value = getString(message('Control:viewer:strNoDistinction'));
            this.OutputsDropDown.ValueChangedFcn = @(es,ed) cbOutputsDropDownChanged(this,ed);

            this.OrderPanel = uipanel(figureGrid);
            this.OrderPanel.Layout.Row = 2;
            orderGrid = uigridlayout(this.OrderPanel,[2 3]);
            orderGrid.RowHeight = {'fit','1x'}; 
            orderGrid.ColumnWidth = {'1x','1x','1x'};
            this.ColorOrderLabel = uilabel(orderGrid);
            this.ColorOrderLabel.Layout.Row = 1;
            this.ColorOrderLabel.Layout.Column = 1;
            this.ColorOrderLabel.Text = getString(message('Control:viewer:strColorOrder'));
            this.ColorOrderLabel.HorizontalAlignment = 'center';
            this.MarkerOrderLabel = uilabel(orderGrid);
            this.MarkerOrderLabel.Layout.Row = 1;
            this.MarkerOrderLabel.Layout.Column = 2;
            this.MarkerOrderLabel.Text = getString(message('Control:viewer:strMarkerOrder'));
            this.MarkerOrderLabel.HorizontalAlignment = 'center';
            this.LineStyleOrderLabel = uilabel(orderGrid);
            this.LineStyleOrderLabel.Layout.Row = 1;
            this.LineStyleOrderLabel.Layout.Column = 3;
            this.LineStyleOrderLabel.Text = getString(message('Control:viewer:strLinestyleOrder'));
            this.LineStyleOrderLabel.HorizontalAlignment = 'center';
            colorGrid = uigridlayout(orderGrid,[4 2]);
            colorGrid.Layout.Row = 2;
            colorGrid.Layout.Column = 1;
            colorGrid.Padding = [0 0 0 0];
            colorGrid.RowHeight = {'1x','fit','fit','1x'};
            colorGrid.ColumnWidth = {'fit','1x'};
            this.ColorUpBtn = uibutton(colorGrid);
            this.ColorUpBtn.Layout.Row = 2;
            this.ColorUpBtn.Layout.Column = 1;
            this.ColorUpBtn.Text = '';
            this.ColorUpBtn.Enable = false;
            matlab.ui.control.internal.specifyIconID(this.ColorUpBtn,'arrowNavigationNorth',16,16);
            this.ColorUpBtn.ButtonPushedFcn = @(es,ed) cbColorUpBtnPushed(this);
            this.ColorDownBtn = uibutton(colorGrid);
            this.ColorDownBtn.Layout.Row = 3;
            this.ColorDownBtn.Layout.Column = 1;
            this.ColorDownBtn.Text = '';
            matlab.ui.control.internal.specifyIconID(this.ColorDownBtn,'arrowNavigationSouth',16,16);
            this.ColorDownBtn.ButtonPushedFcn = @(es,ed) cbColorDownBtnPushed(this);
            this.ColorList = uitable(colorGrid);
            this.ColorList.Layout.Row = [1 4];
            this.ColorList.Layout.Column = 2;
            this.ColorList.Data = strings(numel(this.StyleManager.ColorOrder),1);
            this.ColorList.ColumnName = [];
            this.ColorList.RowName = [];
            this.ColorList.Multiselect = false;
            this.ColorList.RowStriping = false;
            this.ColorList.SelectionType = 'row';
            for ii = 1:length(this.StyleManager.ColorOrder)
                colorStyle = uistyle(BackgroundColor=this.StyleManager.ColorOrder{ii});
                addStyle(this.ColorList,colorStyle,"row",ii);
            end
            this.ColorList.SelectionChangedFcn = @(es,ed) cbColorSelectionChanged(this);
            this.ColorList.Selection = 1;
            markerGrid = uigridlayout(orderGrid,[4 2]);
            markerGrid.Layout.Row = 2;
            markerGrid.Layout.Column = 2;
            markerGrid.Padding = [0 0 0 0];
            markerGrid.RowHeight = {'1x','fit','fit','1x'};
            markerGrid.ColumnWidth = {'fit','1x'};
            this.MarkerUpBtn = uibutton(markerGrid);
            this.MarkerUpBtn.Layout.Row = 2;
            this.MarkerUpBtn.Layout.Column = 1;
            this.MarkerUpBtn.Text = '';
            this.MarkerUpBtn.Enable = false;
            matlab.ui.control.internal.specifyIconID(this.MarkerUpBtn,'arrowNavigationNorth',16,16);
            this.MarkerUpBtn.ButtonPushedFcn = @(es,ed) cbMarkerUpBtnPushed(this);
            this.MarkerDownBtn = uibutton(markerGrid);
            this.MarkerDownBtn.Layout.Row = 3;
            this.MarkerDownBtn.Layout.Column = 1;
            this.MarkerDownBtn.Text = '';
            matlab.ui.control.internal.specifyIconID(this.MarkerDownBtn,'arrowNavigationSouth',16,16);
            this.MarkerDownBtn.ButtonPushedFcn = @(es,ed) cbMarkerDownBtnPushed(this);
            this.MarkerList = uilistbox(markerGrid);
            this.MarkerList.Layout.Row = [1 4];
            this.MarkerList.Layout.Column = 2;
            this.MarkerList.Items = this.MarkerStyleDictionary(this.StyleManager.MarkerOrder);
            this.MarkerList.ItemsData = this.StyleManager.MarkerOrder;
            this.MarkerList.ValueChangedFcn = @(es,ed) cbMarkerSelectionChanged(this);
            lineStyleGrid = uigridlayout(orderGrid,[5 2]);
            lineStyleGrid.Layout.Row = 2;
            lineStyleGrid.Layout.Column = 3;
            lineStyleGrid.Padding = [0 0 0 0];
            lineStyleGrid.RowHeight = {'1x','fit','fit','1x'};
            lineStyleGrid.ColumnWidth = {'fit','1x'};
            this.LineStyleUpBtn = uibutton(lineStyleGrid);
            this.LineStyleUpBtn.Layout.Row = 2;
            this.LineStyleUpBtn.Layout.Column = 1;
            this.LineStyleUpBtn.Text = '';
            this.LineStyleUpBtn.Enable = false;
            matlab.ui.control.internal.specifyIconID(this.LineStyleUpBtn,'arrowNavigationNorth',16,16);
            this.LineStyleUpBtn.ButtonPushedFcn = @(es,ed) cbLineStyleUpBtnPushed(this);
            this.LineStyleDownBtn = uibutton(lineStyleGrid);
            this.LineStyleDownBtn.Layout.Row = 3;
            this.LineStyleDownBtn.Layout.Column = 1;
            this.LineStyleDownBtn.Text = '';
            matlab.ui.control.internal.specifyIconID(this.LineStyleDownBtn,'arrowNavigationSouth',16,16);
            this.LineStyleDownBtn.ButtonPushedFcn = @(es,ed) cbLineStyleDownBtnPushed(this);
            this.LineStyleList = uilistbox(lineStyleGrid);
            this.LineStyleList.Layout.Row = [1 4];
            this.LineStyleList.Layout.Column = 2;
            this.LineStyleList.Items = this.LineStyleDictionary(this.StyleManager.LineStyleOrder);
            this.LineStyleList.ItemsData = this.StyleManager.LineStyleOrder;
            this.LineStyleList.ValueChangedFcn = @(es,ed) cbLineStyleSelectionChanged(this);

            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["help" "ok" "cancel" "apply"]);
            btnCont = getWidget(this.ButtonPanel);
            btnCont.Layout.Row = 3;
            this.OKButton = this.ButtonPanel.OKButton;
            this.HelpButton = this.ButtonPanel.HelpButton;
            this.CancelButton = this.ButtonPanel.CancelButton;
            this.ApplyButton = this.ButtonPanel.ApplyButton;
            this.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            this.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(this);
            this.CancelButton.ButtonPushedFcn = @(es,ed) close(this);
            this.ApplyButton.ButtonPushedFcn = @(es,ed) cApplyButtonPushed(this);

            this.ColorAxes = axes(figureGrid,Visible=false); %invisible axes for theming
            this.ColorAxes.Layout.Row = 4;
        end
        function connectUI(this)
            L1 = addlistener(getWidget(this), 'ObjectBeingDestroyed',@(es,ed) delete(this));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) close(this)); 
            registerUIListeners(this,L2);
            L3 = addlistener(this.UIFigure,"ThemeChanged",@(es,ed) cbFigureThemeChanged(this));
            registerUIListeners(this,L3);
        end
    end
    methods (Access=protected)
        function cbFigureThemeChanged(this)
            colorOrder = mat2cell(this.ColorAxes.ColorOrder,ones(1,size(this.ColorAxes.ColorOrder,1)),3);
            this.StyleManager.ColorOrder = colorOrder(this.ColorOrder);
            for ii = length(this.StyleManager.ColorOrder):-1:1
                removeStyle(this.ColorList,ii);
            end
            for ii = 1:length(this.StyleManager.ColorOrder)
                colorStyle = uistyle(BackgroundColor=this.StyleManager.ColorOrder{ii});
                addStyle(this.ColorList,colorStyle,"row",ii);
            end
        end
        function cbOKButtonPushed(this)
            applyStyleManager(this.App,this.StyleManager,this.ColorOrder);
            close(this);
        end
        function cApplyButtonPushed(this)
            applyStyleManager(this.App,this.StyleManager,this.ColorOrder);
        end
        function cbHelpButtonPushed(this) %#ok<MANU>
            helpview('control','lti_viewer_line_styles')
        end
        function cbResponsesDropDownChanged(this,ed)
            color = getString(message('Control:viewer:strColor'));
            marker = getString(message('Control:viewer:strMarker'));
            lineStyle = getString(message('Control:viewer:strLinestyle'));
            none = getString(message('Control:viewer:strNoDistinction'));
            switch ed.PreviousValue
                case color
                    this.StyleManager.SortByColor = "none";
                case marker
                    this.StyleManager.SortByMarker = "none";
                case lineStyle
                    this.StyleManager.SortByLineStyle = "none";
            end
            switch ed.Value
                case color
                    this.StyleManager.SortByColor = "response";
                    if strcmp(this.InputsDropDown.Value,color)
                        this.InputsDropDown.Value = none;
                    end
                    if strcmp(this.OutputsDropDown.Value,color)
                        this.OutputsDropDown.Value = none;
                    end
                case marker
                    this.StyleManager.SortByMarker = "response";
                    if strcmp(this.InputsDropDown.Value,marker)
                        this.InputsDropDown.Value = none;
                    end
                    if strcmp(this.OutputsDropDown.Value,marker)
                        this.OutputsDropDown.Value = none;
                    end
                case lineStyle
                    this.StyleManager.SortByLineStyle = "response";
                    if strcmp(this.InputsDropDown.Value,lineStyle)
                        this.InputsDropDown.Value = none;
                    end
                    if strcmp(this.OutputsDropDown.Value,lineStyle)
                        this.OutputsDropDown.Value = none;
                    end
            end
        end
        function cbInputsDropDownChanged(this,ed)
            color = getString(message('Control:viewer:strColor'));
            marker = getString(message('Control:viewer:strMarker'));
            lineStyle = getString(message('Control:viewer:strLinestyle'));
            none = getString(message('Control:viewer:strNoDistinction'));
            switch ed.PreviousValue
                case color
                    this.StyleManager.SortByColor = "none";
                case marker
                    this.StyleManager.SortByMarker = "none";
                case lineStyle
                    this.StyleManager.SortByLineStyle = "none";
            end
            switch ed.Value
                case color
                    this.StyleManager.SortByColor = "input";
                    if strcmp(this.ResponsesDropDown.Value,color)
                        this.ResponsesDropDown.Value = none;
                    end
                    if strcmp(this.OutputsDropDown.Value,color)
                        this.OutputsDropDown.Value = none;
                    end
                case marker
                    this.StyleManager.SortByMarker = "input";
                    if strcmp(this.ResponsesDropDown.Value,marker)
                        this.ResponsesDropDown.Value = none;
                    end
                    if strcmp(this.OutputsDropDown.Value,marker)
                        this.OutputsDropDown.Value = none;
                    end
                case lineStyle
                    this.StyleManager.SortByLineStyle = "input";
                    if strcmp(this.ResponsesDropDown.Value,lineStyle)
                        this.ResponsesDropDown.Value = none;
                    end
                    if strcmp(this.OutputsDropDown.Value,lineStyle)
                        this.OutputsDropDown.Value = none;
                    end
            end
        end
        function cbOutputsDropDownChanged(this,ed)
            color = getString(message('Control:viewer:strColor'));
            marker = getString(message('Control:viewer:strMarker'));
            lineStyle = getString(message('Control:viewer:strLinestyle'));
            none = getString(message('Control:viewer:strNoDistinction'));
            switch ed.PreviousValue
                case color
                    this.StyleManager.SortByColor = "none";
                case marker
                    this.StyleManager.SortByMarker = "none";
                case lineStyle
                    this.StyleManager.SortByLineStyle = "none";
            end
            switch ed.Value
                case color
                    this.StyleManager.SortByColor = "output";
                    if strcmp(this.ResponsesDropDown.Value,color)
                        this.ResponsesDropDown.Value = none;
                    end
                    if strcmp(this.InputsDropDown.Value,color)
                        this.InputsDropDown.Value = none;
                    end
                case marker
                    this.StyleManager.SortByMarker = "output";
                    if strcmp(this.ResponsesDropDown.Value,marker)
                        this.ResponsesDropDown.Value = none;
                    end
                    if strcmp(this.InputsDropDown.Value,marker)
                        this.InputsDropDown.Value = none;
                    end
                case lineStyle
                    this.StyleManager.SortByLineStyle = "output";
                    if strcmp(this.ResponsesDropDown.Value,lineStyle)
                        this.ResponsesDropDown.Value = none;
                    end
                    if strcmp(this.InputsDropDown.Value,lineStyle)
                        this.InputsDropDown.Value = none;
                    end
            end
        end
        function cbColorUpBtnPushed(this)
            currentIdx = this.ColorList.Selection;
            if currentIdx ~= 1
                colorStyle = uistyle(BackgroundColor=this.StyleManager.ColorOrder{currentIdx});
                idx = find(cellfun(@(x) x==currentIdx-1,this.ColorList.StyleConfigurations.TargetIndex),1);
                removeStyle(this.ColorList,idx);
                addStyle(this.ColorList,colorStyle,"row",currentIdx-1);
                colorStyle = uistyle(BackgroundColor=this.StyleManager.ColorOrder{currentIdx-1});
                idx = find(cellfun(@(x) x==currentIdx,this.ColorList.StyleConfigurations.TargetIndex),1);
                removeStyle(this.ColorList,idx);
                addStyle(this.ColorList,colorStyle,"row",currentIdx);
                this.StyleManager.ColorOrder = this.StyleManager.ColorOrder([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
                this.ColorOrder = this.ColorOrder([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
                this.ColorList.Selection = currentIdx-1;
            end
            this.ColorUpBtn.Enable = this.ColorList.Selection ~= 1;
            this.ColorDownBtn.Enable = this.ColorList.Selection ~= length(this.ColorList.Data);
        end
        function cbColorDownBtnPushed(this)
            currentIdx = this.ColorList.Selection;
            if currentIdx ~= length(this.ColorList.Data)
                colorStyle = uistyle(BackgroundColor=this.StyleManager.ColorOrder{currentIdx});
                idx = find(cellfun(@(x) x==currentIdx+1,this.ColorList.StyleConfigurations.TargetIndex),1);
                removeStyle(this.ColorList,idx);
                addStyle(this.ColorList,colorStyle,"row",currentIdx+1);
                colorStyle = uistyle(BackgroundColor=this.StyleManager.ColorOrder{currentIdx+1});
                idx = find(cellfun(@(x) x==currentIdx,this.ColorList.StyleConfigurations.TargetIndex),1);
                removeStyle(this.ColorList,idx);
                addStyle(this.ColorList,colorStyle,"row",currentIdx);
                this.StyleManager.ColorOrder = this.StyleManager.ColorOrder([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
                this.ColorOrder = this.ColorOrder([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
                this.ColorList.Selection = currentIdx+1;
            end
            this.ColorUpBtn.Enable = this.ColorList.Selection ~= 1;
            this.ColorDownBtn.Enable = this.ColorList.Selection ~= length(this.ColorList.Data);
        end
        function cbColorSelectionChanged(this)
            this.ColorUpBtn.Enable = this.ColorList.Selection ~= 1;
            this.ColorDownBtn.Enable = this.ColorList.Selection ~= length(this.ColorList.Data);
        end
        function cbMarkerUpBtnPushed(this)
            currentIdx = this.MarkerList.ValueIndex;
            if currentIdx ~= 1
                this.MarkerList.Items = this.MarkerList.Items([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
                this.MarkerList.ItemsData = this.MarkerList.ItemsData([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
                this.StyleManager.MarkerOrder = this.StyleManager.MarkerOrder([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
            end
            this.MarkerUpBtn.Enable = this.MarkerList.ValueIndex ~= 1;
            this.MarkerDownBtn.Enable = this.MarkerList.ValueIndex ~= length(this.MarkerList.Items);
        end
        function cbMarkerDownBtnPushed(this)
            currentIdx = this.MarkerList.ValueIndex;
            if currentIdx ~= length(this.MarkerList.Items)
                this.MarkerList.Items = this.MarkerList.Items([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
                this.MarkerList.ItemsData = this.MarkerList.ItemsData([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
                this.StyleManager.MarkerOrder = this.StyleManager.MarkerOrder([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
            end
            this.MarkerUpBtn.Enable = this.MarkerList.ValueIndex ~= 1;
            this.MarkerDownBtn.Enable = this.MarkerList.ValueIndex ~= length(this.MarkerList.Items);
        end
        function cbMarkerSelectionChanged(this)
            this.MarkerUpBtn.Enable = this.MarkerList.ValueIndex ~= 1;
            this.MarkerDownBtn.Enable = this.MarkerList.ValueIndex ~= length(this.MarkerList.Items);
        end
        function cbLineStyleUpBtnPushed(this)
            currentIdx = this.LineStyleList.ValueIndex;
            if currentIdx ~= 1
                this.LineStyleList.Items = this.LineStyleList.Items([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
                this.LineStyleList.ItemsData = this.LineStyleList.ItemsData([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
                this.StyleManager.LineStyleOrder = this.StyleManager.LineStyleOrder([1:currentIdx-2 currentIdx currentIdx-1 currentIdx+1:end]);
            end
            this.LineStyleUpBtn.Enable = this.LineStyleList.ValueIndex ~= 1;
            this.LineStyleDownBtn.Enable = this.LineStyleList.ValueIndex ~= length(this.LineStyleList.Items);
        end
        function cbLineStyleDownBtnPushed(this)
            currentIdx = this.LineStyleList.ValueIndex;
            if currentIdx ~= length(this.LineStyleList.Items)
                this.LineStyleList.Items = this.LineStyleList.Items([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
                this.LineStyleList.ItemsData = this.LineStyleList.ItemsData([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
                this.StyleManager.LineStyleOrder = this.StyleManager.LineStyleOrder([1:currentIdx-1 currentIdx+1 currentIdx currentIdx+2:end]);
            end
            this.LineStyleUpBtn.Enable = this.LineStyleList.ValueIndex ~= 1;
            this.LineStyleDownBtn.Enable = this.LineStyleList.ValueIndex ~= length(this.LineStyleList.Items);
        end
        function cbLineStyleSelectionChanged(this)
            this.LineStyleUpBtn.Enable = this.LineStyleList.ValueIndex ~= 1;
            this.LineStyleDownBtn.Enable = this.LineStyleList.ValueIndex ~= length(this.LineStyleList.Items);
        end
    end
    methods (Hidden)
        function widgets = qeGetWidgets(this)
            widgets.DistinguishPanel = this.DistinguishPanel;
            widgets.ResponsesLabel = this.ResponsesLabel;
            widgets.ResponsesDropDown = this.ResponsesDropDown;
            widgets.InputsLabel = this.InputsLabel;
            widgets.InputsDropDown = this.InputsDropDown;
            widgets.OutputsLabel = this.OutputsLabel;
            widgets.OutputsDropDown = this.OutputsDropDown;
            widgets.OrderPanel = this.OrderPanel;
            widgets.ColorOrderLabel = this.ColorOrderLabel;
            widgets.MarkerOrderLabel = this.MarkerOrderLabel;
            widgets.LineStyleOrderLabel = this.LineStyleOrderLabel;
            widgets.ColorUpBtn = this.ColorUpBtn;
            widgets.ColorDownBtn = this.ColorDownBtn;
            widgets.ColorList = this.ColorList;
            widgets.MarkerUpBtn = this.MarkerUpBtn;
            widgets.MarkerDownBtn = this.MarkerDownBtn;
            widgets.MarkerList = this.MarkerList;
            widgets.LineStyleUpBtn = this.LineStyleUpBtn;
            widgets.LineStyleDownBtn = this.LineStyleDownBtn;
            widgets.LineStyleList = this.LineStyleList;
            widgets.OKButton = this.OKButton;
            widgets.HelpButton = this.HelpButton;
            widgets.CancelButton = this.CancelButton;
            widgets.ApplyButton = this.ApplyButton;
        end
    end
end