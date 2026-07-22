classdef PreferencesDialog < controllib.ui.internal.dialog.AbstractDialog & ...
        matlab.mixin.SetGet
    % Preferences dialog for the Control System Designer

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (SetObservable,AbortSet)
        Data
    end

    properties (Access = private)
        TabGroup
        UnitsTab
        UnitsContainer
        TimeDelaysTab
        PadeOrderRadioButton
        PadeOrderEditField
        BandwidthAccuracyRadioButton
        BandwidthAccuracyEditField
        BandwidthPadeLabel
        StyleTab
        GridContainer
        FontsContainer
        ColorContainer
        OptionsTab
        CompensatorFormatContainer
        BodeOptionsContainer
        PlotUpdateTitle
        PlotUpdateCheckbox
        LineColorsTab
        LineColorsGrid
        PlantComponentsLineColorCheckbox
        PlantComponentsLineColorPreview
        PlantComponentsLineColorEditField
        FeedbackCompensatorsLineColorCheckbox
        FeedbackCompensatorsLineColorPreview
        FeedbackCompensatorsLineColorEditField
        FeedforwardCompensatorsLineColorCheckbox
        FeedforwardCompensatorsLineColorPreview
        FeedforwardCompensatorsLineColorEditField
        OpenLoopLineColorCheckbox
        OpenLoopLineColorPreview
        OpenLoopLineColorEditField
        ClosedLoopLineColorCheckbox
        ClosedLoopLineColorPreview
        ClosedLoopLineColorEditField
        MarginsLineColorCheckbox
        MarginsLineColorPreview
        MarginsLineColorEditField
        PlantComponentsButton
        FeedbackCompensatorsButton
        FeedforwardCompensatorsButton
        OpenLoopButton
        ClosedLoopButton
        MarginsButton
        HelpButton
        OKButton
        ApplyButton
        CancelButton
        Listeners
    end

    methods
        function this = PreferencesDialog(data)
            this.Data = data;
            this.Title = m('Control:designerapp:strEditorPreferences');
            this.Name = "CSDApp_PreferencesDialog";
        end

        function updateUI(this)
            % Units
            this.UnitsContainer.FrequencyUnits = this.Data.FrequencyUnits;
            this.UnitsContainer.FrequencyScale = this.Data.FrequencyScale;
            this.UnitsContainer.MagnitudeUnits = this.Data.MagnitudeUnits;
            this.UnitsContainer.MagnitudeScale = this.Data.MagnitudeScale;
            this.UnitsContainer.PhaseUnits = this.Data.PhaseUnits;
            % TimeDelay
            if this.Data.PadeOrderSelectionData.UseBandwidth
                this.BandwidthAccuracyRadioButton.Value = true;
                cbTimeDelayRadioButtonSelectionChanged(this);
            else
                this.PadeOrderRadioButton.Value = true;
                cbTimeDelayRadioButtonSelectionChanged(this);
            end
            this.PadeOrderEditField.Value = this.Data.PadeOrderSelectionData.PadeOrder;
            this.BandwidthAccuracyEditField.Value = this.Data.PadeOrderSelectionData.Bandwidth;
            % Style
            this.GridContainer.Value = this.Data.Grid;
            this.FontsContainer.TitleFontSize = this.Data.TitleFontSize;
            this.FontsContainer.TitleFontWeight = this.Data.TitleFontWeight;
            this.FontsContainer.TitleFontAngle = this.Data.TitleFontAngle;
            this.FontsContainer.XYLabelsFontSize = this.Data.XYLabelsFontSize;
            this.FontsContainer.XYLabelsFontWeight = this.Data.XYLabelsFontWeight;
            this.FontsContainer.XYLabelsFontAngle = this.Data.XYLabelsFontAngle;
            this.FontsContainer.AxesFontSize = this.Data.AxesFontSize;
            this.FontsContainer.AxesFontWeight = this.Data.AxesFontWeight;
            this.FontsContainer.AxesFontAngle = this.Data.AxesFontAngle;
            this.ColorContainer.Value = this.Data.AxesForegroundColor;
            % Options
            this.CompensatorFormatContainer.Value = this.Data.CompensatorFormat;
            this.BodeOptionsContainer.Value = this.Data.ShowSystemPZ;
            this.PlotUpdateCheckbox.Value = this.Data.RealTimePlotUpdateEnabled;
            % Line Colors
            updateLineColorWidgets(this,"all");
        end

        function pack(this,varargin)
            this.LineColorsGrid.ColumnWidth{3} = 20;
            pack@controllib.ui.internal.dialog.AbstractDialog(this,varargin{:});
            this.LineColorsGrid.ColumnWidth{3} = '1x';
        end
    end

    methods (Access = protected)
        function buildUI(this)
            % Parent Grid (UITabGroup and Buttons)
            parentGrid = uigridlayout(this.UIFigure);
            parentGrid.RowHeight = {'1x','fit'};
            parentGrid.ColumnWidth = {'1x'};
            parentGrid.Padding = [0 0 0 0];
            parentGrid.RowSpacing = 0;
            parentGrid.Scrollable = 'on';
            % UITabGroup
            tabGroup = uitabgroup(parentGrid);
            tabGroup.Layout.Row = 1;
            tabGroup.Layout.Column = 1;
            this.TabGroup = tabGroup;
            % Units tab
            createUnitsTab(this,tabGroup);
            % Time Delays tab
            createTimeDelaysTab(this,tabGroup);
            % Style tab
            createStyleTab(this,tabGroup);
            % Options Tab
            createOptionsTab(this,tabGroup);
            % Line Colors Tab
            createLineColorsTab(this,tabGroup);
            % Buttons
            createButtonPanel(this,parentGrid);
            % Dialog size and tag
            this.UIFigure.Position(3:4) = [430 340];
        end

        function connectUI(this)
            
        end
    end

    methods (Access = private)

        function updateData(this)
            % Units
            this.Data.FrequencyUnits        = this.UnitsContainer.FrequencyUnits;
            this.Data.FrequencyScale        = this.UnitsContainer.FrequencyScale;
            this.Data.MagnitudeUnits        = this.UnitsContainer.MagnitudeUnits;
            this.Data.MagnitudeScale        = this.UnitsContainer.MagnitudeScale;
            this.Data.PhaseUnits            = this.UnitsContainer.PhaseUnits;

            % Time Delays
            if this.PadeOrderRadioButton.Value
                this.Data.PadeOrderSelectionData.PadeOrder = this.PadeOrderEditField.Value;
                this.Data.PadeOrderSelectionData.UseBandwidth = false;
                this.Data.PadeOrder = this.PadeOrderEditField.Value;
            else
                this.Data.PadeOrderSelectionData.Bandwidth = this.BandwidthAccuracyEditField.Value;
                this.Data.PadeOrderSelectionData.UseBandwidth = true;
                this.Data.PadeOrder = 0;
            end

            % Style
            this.Data.Grid                      = this.GridContainer.Value;
            this.Data.TitleFontSize             = this.FontsContainer.TitleFontSize;
            this.Data.TitleFontWeight           = this.FontsContainer.TitleFontWeight;
            this.Data.TitleFontAngle            = this.FontsContainer.TitleFontAngle;
            this.Data.XYLabelsFontSize          = this.FontsContainer.XYLabelsFontSize;
            this.Data.XYLabelsFontWeight        = this.FontsContainer.XYLabelsFontWeight;
            this.Data.XYLabelsFontAngle         = this.FontsContainer.XYLabelsFontAngle;
            this.Data.AxesFontSize              = this.FontsContainer.AxesFontSize;
            this.Data.AxesFontWeight            = this.FontsContainer.AxesFontWeight;
            this.Data.AxesFontAngle             = this.FontsContainer.AxesFontAngle;
            this.Data.AxesForegroundColor       = this.ColorContainer.Value;

            % Options
            this.Data.CompensatorFormat         = this.CompensatorFormatContainer.Value;
            this.Data.ShowSystemPZ              = this.BodeOptionsContainer.Value;
            this.Data.RealTimePlotUpdateEnabled = this.PlotUpdateCheckbox.Value;

            % Line Colors
            if this.ClosedLoopLineColorCheckbox.Value
                this.Data.LineStyle.Color.ClosedLoop = ...
                    str2num(this.ClosedLoopLineColorEditField.Value); %#ok<*ST2NM>
            else
                resetLineColor(this.Data,"ClosedLoop");
            end

            if this.FeedbackCompensatorsLineColorCheckbox.Value
                this.Data.LineStyle.Color.Compensator = ...
                    str2num(this.FeedbackCompensatorsLineColorEditField.Value);
            else
                resetLineColor(this.Data,"Compensator");
            end

            if this.MarginsLineColorCheckbox.Value
                this.Data.LineStyle.Color.Margin = ...
                    str2num(this.MarginsLineColorEditField.Value);
            else
                resetLineColor(this.Data,"Margin");
            end

            if this.FeedforwardCompensatorsLineColorCheckbox.Value
                this.Data.LineStyle.Color.PreFilter = ...
                    str2num(this.FeedforwardCompensatorsLineColorEditField.Value);
            else
                resetLineColor(this.Data,"PreFilter");
            end

            if this.OpenLoopLineColorCheckbox.Value
                this.Data.LineStyle.Color.Response = ...
                    str2num(this.OpenLoopLineColorEditField.Value);
            else
                resetLineColor(this.Data,"Response");
            end

            if this.PlantComponentsLineColorCheckbox.Value
                this.Data.LineStyle.Color.System = ...
                    str2num(this.PlantComponentsLineColorEditField.Value);
            else
                resetLineColor(this.Data,"System");
            end
        end

        function createUnitsTab(this,tabGroup)
            % Tab and Layout
            this.UnitsTab = uitab(tabGroup);
            this.UnitsTab.Title = m('Controllib:gui:strUnits');
            unitsGrid = uigridlayout(this.UnitsTab);
            unitsGrid.RowHeight = {'fit'};
            unitsGrid.ColumnWidth = {'1x'};
            unitsGrid.Scrollable = 'on';
            % Units
            this.UnitsContainer = controllib.widget.internal.cstprefs.UnitsContainer(...
                'FrequencyUnits','FrequencyScale',...
                'MagnitudeUnits','MagnitudeScale',...
                'PhaseUnits');
            wdgt = getWidget(this.UnitsContainer);
            wdgt.Parent = unitsGrid;
            validFrequencyUnits = controllibutils.utGetValidFrequencyUnits;
            this.UnitsContainer.ValidFrequencyUnits = [validFrequencyUnits(:,1),...
                cellfun(@(x) m(x),validFrequencyUnits(:,2),'UniformOutput',false)];
        end

        function createTimeDelaysTab(this,tabGroup)
            % Tab and Layout
            this.TimeDelaysTab = uitab(tabGroup);
            this.TimeDelaysTab.Title = m('Control:compDesignTask:strTimeDelaysLabel');
            timeDelayGrid = uigridlayout(this.TimeDelaysTab,[4 4]);
            timeDelayGrid.RowHeight = {'fit','fit',22,22};
            timeDelayGrid.ColumnWidth = {10,220,'1x','fit'};
            timeDelayGrid.Scrollable = 'on';
            % Title and Description
            titleLabel = uilabel(timeDelayGrid,'Text',m('Control:compDesignTask:strApproxLabel'),...
                'FontWeight','bold');
            titleLabel.Layout.Row = 1;
            titleLabel.Layout.Column = [1 4];
            descriptionLabel = uilabel(timeDelayGrid,'Text',...
                m('Control:compDesignTask:strPadeDescLabel'));
            descriptionLabel.Layout.Row = 2;
            descriptionLabel.Layout.Column = [1 4];
            descriptionLabel.WordWrap = 'on';
            % Radio Button
            buttonGroup = uibuttongroup(timeDelayGrid);
            buttonGroup.Layout.Row = [3 4];
            buttonGroup.Layout.Column = 2;
            buttonGroup.BorderType = 'none';
            buttonGroup.SelectionChangedFcn = ...
                @(es,ed) cbTimeDelayRadioButtonSelectionChanged(this);
            this.PadeOrderRadioButton = uiradiobutton(buttonGroup,'Text',...
                m('Control:compDesignTask:strPadeLabel'));
            this.PadeOrderRadioButton.Position = [1 30 200 25];
            this.BandwidthAccuracyRadioButton = uiradiobutton(buttonGroup,'Text',...
                m('Control:compDesignTask:strBandWidthLabel'));
            this.BandwidthAccuracyRadioButton.Position = [1 0 200 25];
            % Edit Fields
            this.PadeOrderEditField = uieditfield(timeDelayGrid,'numeric');
            this.PadeOrderEditField.Layout.Row = 3;
            this.PadeOrderEditField.Layout.Column = 3;
            this.PadeOrderEditField.Limits = [0 Inf];
            this.PadeOrderEditField.UpperLimitInclusive = 'off';
            this.BandwidthAccuracyEditField = uieditfield(timeDelayGrid,'numeric');
            this.BandwidthAccuracyEditField.Layout.Row = 4;
            this.BandwidthAccuracyEditField.Layout.Column = 3;
            this.BandwidthAccuracyEditField.Limits = [0 Inf];
            this.BandwidthAccuracyEditField.LowerLimitInclusive = 'off';
            this.BandwidthAccuracyEditField.UpperLimitInclusive = 'off';
            this.BandwidthPadeLabel = uilabel(timeDelayGrid,'Text',...
                sprintf('(%s %d)',m('Control:compDesignTask:strPadeLabel'),0));
            this.BandwidthPadeLabel.Layout.Row = 4;
            this.BandwidthPadeLabel.Layout.Column = 4;
        end

        function createStyleTab(this,tabGroup)
            % Tab and Layout
            this.StyleTab = uitab(tabGroup);
            this.StyleTab.Title = m('Controllib:gui:strStyle');
            styleGrid = uigridlayout(this.StyleTab);
            styleGrid.RowHeight = {'fit','fit','fit','fit','fit'};
            styleGrid.ColumnWidth = {'fit'};
            styleGrid.Scrollable = 'on';
            % Grid
            this.GridContainer = controllib.widget.internal.cstprefs.GridContainer();
            wdgt = getWidget(this.GridContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 1;
            wdgt.Layout.Column = 1;
            % Fonts
            this.FontsContainer = controllib.widget.internal.cstprefs.FontsContainer('Title','XYLabels','AxesLabels');
            wdgt = getWidget(this.FontsContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 3;
            wdgt.Layout.Column = 1;
            % Color
            this.ColorContainer = controllib.widget.internal.cstprefs.ColorContainer();
            wdgt = getWidget(this.ColorContainer);
            wdgt.Parent = styleGrid;
            wdgt.Layout.Row = 5;
            wdgt.Layout.Column = 1;
        end

        function createOptionsTab(this,tabGroup)
            % Tab and Layout
            this.OptionsTab = uitab(tabGroup);
            this.OptionsTab.Title = m('Controllib:gui:strOptions');
            optionsGrid = uigridlayout(this.OptionsTab);
            optionsGrid.RowHeight = {'fit','fit','fit'};
            optionsGrid.ColumnWidth = {'1x'};
            optionsGrid.Scrollable = 'on';
            % Compensator Format
            this.CompensatorFormatContainer = ...
                controllib.widget.internal.cstprefs.CompensatorFormatContainer();
            wdgt = getWidget(this.CompensatorFormatContainer);
            wdgt.Parent = optionsGrid;
            % Bode Options
            this.BodeOptionsContainer = ...
                controllib.widget.internal.cstprefs.BodeOptionsContainer();
            wdgt = getWidget(this.BodeOptionsContainer);
            wdgt.Parent = optionsGrid;
            wdgt.Layout.Row = 2;
            % Plot Update Options
            plotUpdateGrid = uigridlayout(optionsGrid,[2 2]);
            plotUpdateGrid.RowHeight = {'fit','fit'};
            plotUpdateGrid.ColumnWidth = {10,'1x'};
            plotUpdateGrid.Padding = 0;
            this.PlotUpdateTitle = uilabel(plotUpdateGrid,...
                'Text',m('Control:designerapp:lblPlotUpdateOptions'),...
                'FontWeight','bold');
            this.PlotUpdateTitle.Layout.Row = 1;
            this.PlotUpdateTitle.Layout.Column = [1 2];
            this.PlotUpdateCheckbox = uicheckbox(plotUpdateGrid,...
                'Text',m('Control:designerapp:strUpdatePlotsRealTime'));
            this.PlotUpdateCheckbox.Layout.Row = 2;
            this.PlotUpdateCheckbox.Layout.Column = 2;
            this.PlotUpdateCheckbox.Value = this.Data.RealTimePlotUpdateEnabled;
        end

        function createLineColorsTab(this,tabGroup)
            % Tab and Layout
            this.LineColorsTab = uitab(tabGroup);
            this.LineColorsTab.Title = m('Control:compDesignTask:strLineColors');
            lineColorsGrid = uigridlayout(this.LineColorsTab,[7 5]);
            lineColorsGrid.RowHeight = {'fit','fit','fit','fit','fit','fit','fit'};
            lineColorsGrid.ColumnWidth = {10,'fit','fit','1x','fit'};
            lineColorsGrid.Scrollable = 'on';
            this.LineColorsGrid = lineColorsGrid;
            lineColorsTitle = uilabel(lineColorsGrid,'Text',...
                m('Control:designerapp:strCustomizeLineColors'),...
                'FontWeight','bold');
            lineColorsTitle.Layout.Row = 1;
            lineColorsTitle.Layout.Column = [1 5];

            % Labels, EditFields and Buttons (all rows)
            [this.PlantComponentsLineColorCheckbox, this.PlantComponentsLineColorPreview,...
                this.PlantComponentsLineColorEditField, this.PlantComponentsButton] = ...
                createLineColorRow(this,lineColorsGrid,...
                m('Control:compDesignTask:lblPlantComponents'),2,'Plant');
            this.PlantComponentsLineColorCheckbox.ValueChangedFcn = @(es,ed) updateLineColorWidgets(this,"System");

            [this.FeedbackCompensatorsLineColorCheckbox, this.FeedbackCompensatorsLineColorPreview,...
                this.FeedbackCompensatorsLineColorEditField, this.FeedbackCompensatorsButton] = ...
                createLineColorRow(this,lineColorsGrid,...
                m('Control:compDesignTask:lblFeedbackCompensators'),3,'Feedback');
            this.FeedbackCompensatorsLineColorCheckbox.ValueChangedFcn = @(es,ed) updateLineColorWidgets(this,"Compensator");

            [this.FeedforwardCompensatorsLineColorCheckbox, this.FeedforwardCompensatorsLineColorPreview,...
                this.FeedforwardCompensatorsLineColorEditField, this.FeedforwardCompensatorsButton] = ...
                createLineColorRow(this,lineColorsGrid,...
                m('Control:compDesignTask:lblFeedforwardCompensators'),4,'Feedforward');
            this.FeedforwardCompensatorsLineColorCheckbox.ValueChangedFcn = @(es,ed) updateLineColorWidgets(this,"PreFilter");

            [this.OpenLoopLineColorCheckbox, this.OpenLoopLineColorPreview,...
                this.OpenLoopLineColorEditField,this.OpenLoopButton] = ...
                createLineColorRow(this,lineColorsGrid,...
                m('Control:compDesignTask:lblOpenLoop'),5,'OpenLoop');
            this.OpenLoopLineColorCheckbox.ValueChangedFcn = @(es,ed) updateLineColorWidgets(this,"Response");

            [this.ClosedLoopLineColorCheckbox, this.ClosedLoopLineColorPreview, ...
                this.ClosedLoopLineColorEditField, this.ClosedLoopButton] = ...
                createLineColorRow(this,lineColorsGrid,...
                m('Control:compDesignTask:lblClosedLoop'),6,'ClosedLoop');
            this.ClosedLoopLineColorCheckbox.ValueChangedFcn = @(es,ed) updateLineColorWidgets(this,"ClosedLoop");

            [this.MarginsLineColorCheckbox, this.MarginsLineColorPreview, ...
                this.MarginsLineColorEditField,this.MarginsButton] = ...
                createLineColorRow(this,lineColorsGrid,...
                m('Control:compDesignTask:lblMargins'),7,'Margins');
            this.MarginsLineColorCheckbox.ValueChangedFcn = @(es,ed) updateLineColorWidgets(this,"Margin");
        end

        function [lineColorCheckBox,lineColorPreview,lineColorEditField,lineColorButton] = ...
                createLineColorRow(this,lineColorsGrid,labelText,rowIdx,tag)
            % Checkbox
            lineColorCheckBox = uicheckbox(lineColorsGrid,'Text',labelText);
            lineColorCheckBox.Layout.Row = rowIdx;
            lineColorCheckBox.Layout.Column = 2;

            lineColorPreview = uigridlayout(lineColorsGrid,[1 1],Padding=0);
            lineColorPreview.RowHeight = {20};
            lineColorPreview.ColumnWidth = {20};
            lineColorPreview.Layout.Row = rowIdx;
            lineColorPreview.Layout.Column = 3;

            % Editfield
            lineColorEditField = uieditfield(lineColorsGrid);
            lineColorEditField.Layout.Row = rowIdx;
            lineColorEditField.Layout.Column = 4;
            lineColorEditField.ValueChangedFcn = ...
                @(es,ed) cbLineColorEditFieldValueChanged(this,es,ed,lineColorPreview);
            lineColorEditField.Tag = ['CSDPrefs_LineColorTab_',tag,'_EditField'];

            % Button
            lineColorButton = uibutton(lineColorsGrid,'Text',...
                m('Control:compDesignTask:lblSelectEllipsis'));
            lineColorButton.Layout.Row = rowIdx;
            lineColorButton.Layout.Column = 5;
            lineColorButton.ButtonPushedFcn = @(es,ed) cbLineColorButtonPushed(this,es,lineColorPreview);
            lineColorButton.Tag = ['CSDPrefs_LineColorTab_',tag,'_Button'];
        end

        function buttonGrid = createButtonPanel(this,parentGrid)
            buttonGrid = uigridlayout(parentGrid);
            buttonGrid.RowHeight = {'fit'};
            buttonGrid.ColumnWidth = {'fit','1x','fit','fit','fit'};
            buttonGrid.Padding = 10;
            buttonGrid.RowSpacing = 0;
            this.HelpButton = uibutton(buttonGrid);
            this.HelpButton.Layout.Row = 1;
            this.HelpButton.Layout.Column = 1;
            this.HelpButton.Text = m('Controllib:general:strHelp');
            this.HelpButton.ButtonPushedFcn = @(es,ed) callbackHelpButton(this);
            this.OKButton = uibutton(buttonGrid);
            this.OKButton.Layout.Row = 1;
            this.OKButton.Layout.Column = 3;
            this.OKButton.Text = m('Controllib:general:strOK');
            this.OKButton.ButtonPushedFcn = @(es,ed) callbackOKButton(this);
            this.CancelButton = uibutton(buttonGrid);
            this.CancelButton.Layout.Row = 1;
            this.CancelButton.Layout.Column = 4;
            this.CancelButton.Text = m('Controllib:general:strCancel');
            this.CancelButton.ButtonPushedFcn = @(es,ed) callbackCancelButton(this);
            this.ApplyButton = uibutton(buttonGrid);
            this.ApplyButton.Layout.Row = 1;
            this.ApplyButton.Layout.Column = 5;
            this.ApplyButton.Text = m('Controllib:general:strApply');
            this.ApplyButton.ButtonPushedFcn = @(es,ed) callbackApplyButton(this);
        end

        function cbTimeDelayRadioButtonSelectionChanged(this)
            if this.PadeOrderRadioButton.Value
                % Pade order approximation selected
                this.PadeOrderEditField.Enable = 'on';
                this.BandwidthAccuracyEditField.Enable = 'off';
                this.BandwidthPadeLabel.Enable = 'off';
            else
                % Bandwidth of accuracy selected
                this.PadeOrderEditField.Enable = 'off';
                this.BandwidthAccuracyEditField.Enable = 'on';
                this.BandwidthPadeLabel.Enable = 'on';
            end
        end

        function cbLineColorEditFieldValueChanged(this,es,ed,lineColorPreview)
            try
                localValidateColorValue(ed.Value);
                controllib.plot.internal.utils.setColorProperty(lineColorPreview,...
                    "BackgroundColor",ed.Value);
            catch
                es.Value = ed.PreviousValue;
            end
        end

        function cbLineColorButtonPushed(this,es,lineColorPreview)
            switch es.Tag
                case 'CSDPrefs_LineColorTab_Plant_Button'
                    editField = this.PlantComponentsLineColorEditField;
                case 'CSDPrefs_LineColorTab_Feedback_Button'
                    editField = this.FeedbackCompensatorsLineColorEditField;
                case 'CSDPrefs_LineColorTab_Feedforward_Button'
                    editField = this.FeedforwardCompensatorsLineColorEditField;
                case 'CSDPrefs_LineColorTab_OpenLoop_Button'
                    editField = this.OpenLoopLineColorEditField;
                case 'CSDPrefs_LineColorTab_ClosedLoop_Button'
                    editField = this.ClosedLoopLineColorEditField;
                case 'CSDPrefs_LineColorTab_Margins_Button'
                    editField = this.MarginsLineColorEditField;
            end
            colorValue = uisetcolor(str2num(editField.Value)); %#ok<ST2NM>
            editField.Value = mat2str(colorValue,3);
            controllib.plot.internal.utils.setColorProperty(lineColorPreview,...
                "BackgroundColor",colorValue);
        end

        function callbackHelpButton(this)
            ctrlguihelp('CSD_PreferencesHelp','CSHelpWindow');
        end

        function callbackApplyButton(this)
            updateData(this);
        end

        function callbackOKButton(this)
            callbackApplyButton(this);
            close(this);
        end

        function callbackCancelButton(this)
            close(this);
        end

        function callbackPhaseUnitsChanged(this,ed)
            this.PhaseResponseContainer.PhaseUnits = ed.AffectedObject.PhaseUnits;
        end

        function callbackMagnitudeUnitsChanged(this,ed)
            this.MagnitudeResponseContainer.MagnitudeUnits = ed.AffectedObject.MagnitudeUnits;
        end

        function updateLineColorWidgets(this,colorType)
            arguments
                this
                colorType string
            end

            if strcmp(colorType,"all")
                colorType = ["ClosedLoop","Compensator","Margin","PreFilter","Response","System"];
            end

            if any(strcmp(colorType,"ClosedLoop"))
                localEnableDisableEditField(this.ClosedLoopLineColorEditField,...
                    this.ClosedLoopButton,this.ClosedLoopLineColorCheckbox.Value,...
                    this.ClosedLoopLineColorPreview,'ClosedLoop');
            end

            if any(strcmp(colorType,"Compensator"))
                localEnableDisableEditField(this.FeedbackCompensatorsLineColorEditField,...
                    this.FeedbackCompensatorsButton,this.FeedbackCompensatorsLineColorCheckbox.Value,...
                    this.FeedbackCompensatorsLineColorPreview,'Compensator');
            end

            if any(strcmp(colorType,"Margin"))
                localEnableDisableEditField(this.MarginsLineColorEditField,...
                    this.MarginsButton,this.MarginsLineColorCheckbox.Value,...
                    this.MarginsLineColorPreview,'Margin');
            end

            if any(strcmp(colorType,"PreFilter"))
                localEnableDisableEditField(this.FeedforwardCompensatorsLineColorEditField,...
                    this.FeedforwardCompensatorsButton,this.FeedforwardCompensatorsLineColorCheckbox.Value,...
                    this.FeedforwardCompensatorsLineColorPreview,'PreFilter');
            end

            if any(strcmp(colorType,"Response"))
                localEnableDisableEditField(this.OpenLoopLineColorEditField,...
                    this.OpenLoopButton,this.OpenLoopLineColorCheckbox.Value,...
                    this.OpenLoopLineColorPreview,'Response');
            end

            if any(strcmp(colorType,"System"))
                localEnableDisableEditField(this.PlantComponentsLineColorEditField,...
                    this.PlantComponentsButton,this.PlantComponentsLineColorCheckbox.Value,...
                    this.PlantComponentsLineColorPreview,'System');
            end

            % Local function to enable/disable edit field and button
            function localEnableDisableEditField(editField,button,editFieldEnable,colorPreview,colorType)
                colorValue = this.Data.LineStyle.Color.(colorType);
                if isnumeric(colorValue)
                    editFieldValue = mat2str(colorValue,3);
                else
                    fig = ancestor(editField,'figure');
                    currentTheme = fig.Theme;
                    if isempty(currentTheme)
                        currentTheme = matlab.graphics.internal.themes.lightTheme;
                    end
                    editFieldValue = mat2str(matlab.graphics.internal.themes.getAttributeValue(...
                        currentTheme,colorValue),3);
                end

                if editFieldEnable
                    button.Enable = true;
                    editField.Enable = true;
                    editField.Value = editFieldValue;
                    controllib.plot.internal.utils.setColorProperty(colorPreview,...
                        "BackgroundColor",colorValue);
                else
                    button.Enable = false;
                    editField.Enable = false;
                    editField.Value = '';
                    controllib.plot.internal.utils.setColorProperty(colorPreview,...
                        "BackgroundColor",this.Data.SemanticLineStyle.Color.(colorType));
                end
            end
        end

    end

    methods(Hidden)
        function widgets = qeGetWidgets(this)
            % Tabs
            widgets.Tabs.TabGroup = this.TabGroup;
            widgets.Tabs.Units = this.UnitsTab;
            widgets.Tabs.Style = this.StyleTab;
            widgets.Tabs.TimeDelaysTab = this.TimeDelaysTab;
            widgets.Tabs.OptionsTab = this.OptionsTab;
            widgets.Tabs.LineColorsTab = this.LineColorsTab;
            % Buttons
            widgets.Buttons.Help = this.HelpButton;
            widgets.Buttons.OK = this.OKButton;
            widgets.Buttons.Apply = this.ApplyButton;
            widgets.Buttons.Cancel = this.CancelButton;
            % Containers/Panels
            widgets.Units = qeGetWidgets(this.UnitsContainer);
            widgets.Grid = qeGetWidgets(this.GridContainer);
            widgets.Fonts = qeGetWidgets(this.FontsContainer);
            widgets.Color = qeGetWidgets(this.ColorContainer);
            % Time Delay tab
            widgets.TimeDelays.PadeOrderEditField = this.PadeOrderEditField;
            widgets.TimeDelays.PadeOrderRadioButton = this.PadeOrderRadioButton;
            widgets.TimeDelays.BandwidthAccuracyEditField = this.BandwidthAccuracyEditField;
            widgets.TimeDelays.BandwidthAccuracyRadioButton = this.BandwidthAccuracyRadioButton;
            widgets.TimeDelays.BandwidthPadeLabel = this.BandwidthPadeLabel;
            % Options tab
            widgets.CompensatorFormat = qeGetWidgets(this.CompensatorFormatContainer);
            widgets.BodeOptions = qeGetWidgets(this.BodeOptionsContainer);
            % Line Colors tab
            widgets.LineColors.PlantComponentsLineColorEditField = this.PlantComponentsLineColorEditField;
            widgets.LineColors.FeedbackCompensatorsLineColorEditField = this.FeedbackCompensatorsLineColorEditField;
            widgets.LineColors.FeedforwardCompensatorsLineColorEditField = this.FeedforwardCompensatorsLineColorEditField;
            widgets.LineColors.OpenLoopLineColorEditField = this.OpenLoopLineColorEditField;
            widgets.LineColors.ClosedLoopLineColorEditField = this.ClosedLoopLineColorEditField;
            widgets.LineColors.MarginsLineColorEditField = this.MarginsLineColorEditField;
            widgets.LineColors.PlantComponentsButton = this.PlantComponentsButton;
            widgets.LineColors.FeedbackCompensatorsButton = this.FeedbackCompensatorsButton;
            widgets.LineColors.FeedforwardCompensatorsButton = this.FeedforwardCompensatorsButton;
            widgets.LineColors.OpenLoopButton = this.OpenLoopButton;
            widgets.LineColors.ClosedLoopButton = this.ClosedLoopButton;
            widgets.LineColors.MarginsButton = this.MarginsButton;
        end

        function selectedTab = qeGetSelectedTab(this)
            selectedTab = this.TabGroup.SelectedTab;
        end

        function selectTab(this,tabName)
            arguments
                this
                tabName char {mustBeMember(tabName,{'Units','Style','Options',...
                    'TimeDelays','LineColors'})} = 'Units'
            end
            if this.IsWidgetValid
                switch tabName
                    case 'Units'
                        this.TabGroup.SelectedTab = this.UnitsTab;
                    case 'Style'
                        this.TabGroup.SelectedTab = this.StyleTab;
                    case 'Options'
                        this.TabGroup.SelectedTab = this.OptionsTab;
                    case 'TimeDelays'
                        this.TabGroup.SelectedTab = this.TimeDelaysTab;
                    case 'LineColors'
                        this.TabGroup.SelectedTab = this.LineColorsTab;
                end
            end
        end
    end
end


function s = m(id, varargin)
% Reads strings from the resource bundle
m = message(id, varargin{:});
s = m.getString;
end

function localValidateColorValue(value)
evaluatedValue = eval(value);
validateattributes(evaluatedValue,{'numeric'},{'size',[1 3],'>=',0,'<=',1});
end
