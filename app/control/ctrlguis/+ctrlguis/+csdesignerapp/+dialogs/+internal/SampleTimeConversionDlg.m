classdef SampleTimeConversionDlg < controllib.ui.internal.dialog.AbstractDialog
    % Sample time conversion dialog for CSD.
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties
        Tool
        Dialog
    end
    
    properties (Access = private)
        Widgets
        DesignerData
        NewTs = 1;
        AllMethods = {...
            'zoh' , getString(message('Control:compDesignTask:strZOH'));...
            'foh' , getString(message('Control:compDesignTask:strFOH'));...
            'imp', getString(message('Control:compDesignTask:strImpulseInvariant'));...
            'tustin' , getString(message('Control:compDesignTask:strTustin'));...
            'tustin' , getString(message('Control:compDesignTask:strTustinPrewarp'));...
            'matched' , getString(message('Control:compDesignTask:strMatchedPZ'))};
    end
    
    properties (Dependent)
        ConversionMethods
        Architecture
        BlockNames
        Blocks
    end
    
    methods
        function this = SampleTimeConversionDlg(Tool)
            this.Tool = Tool;
            this.DesignerData = getData(Tool);
            this.Title = getString(message('Control:compDesignTask:strSampleTimeConversion'));
            this.Name = 'CSDApp_SampleTimeConversionDlg';
            this.CloseMode = 'destroy';
        end
    end
    %% Get/Set
    methods
        function val = get.ConversionMethods(this)
            Ts = getTs(this.Architecture);
            if Ts == 0 %c2d
                val = this.AllMethods;
            elseif this.NewTs == 0 %d2c
                val = this.AllMethods([1,2,4,5,6],:);
            else %d2d
                val = this.AllMethods([1,4,5],:);
            end
        end
        
        function val = get.Architecture(this)
            val = this.DesignerData.Architecture;
        end
        
        function val = get.Blocks(this)
            val = getBlocks(this.Architecture);
        end
        
        function val = get.BlockNames(this)
            val = cellfun(@(x) getIdentifier(x),this.Blocks,...
                'UniformOutput',false);
        end
    end

    methods (Access = protected)
        function buildUI(this)
            figureGrid = uigridlayout(this.UIFigure,[3 1]);
            figureGrid.RowHeight = {'fit','fit','fit'};

            discretizationPanel = uipanel(figureGrid);
            discretizationPanel.Layout.Row = 1;
            discretizationPanel.Layout.Column = 1;
            Ts = getTs(this.Architecture);
            if Ts==0
                discretizationPanel.Title = getString(message('Control:compDesignTask:lblDiscretizeWith'));
            else
                discretizationPanel.Title = getString(message('Control:compDesignTask:lblConvertTo'));
            end
            discretizationGrid = uigridlayout(discretizationPanel,[2 4]);
            discretizationGrid.RowHeight = {70,'fit'};
            discretizationGrid.ColumnWidth = {'1x','fit','fit','2x'};
            c2dButtonGroup = uibuttongroup(discretizationGrid);
            c2dButtonGroup.Layout.Row = 1;
            c2dButtonGroup.Layout.Column = [1 4];
            c2dButtonGroup.BorderType = 'none';
            discreteButton = uiradiobutton(c2dButtonGroup);
            discreteButton.Text = getString(message('Control:compDesignTask:lblDiscreteTimeNewRate'));
            discreteButton.Position(3) = 300;
            continousButton = uiradiobutton(c2dButtonGroup);
            continousButton.Text = getString(message('Control:compDesignTask:lblContinuousTime'));
            continousButton.Position = [discreteButton.Position(1) discreteButton.Position(2)+discreteButton.Position(4)+10 discreteButton.Position(3:4)];
            sampleTimeLabel = uilabel(discretizationGrid);
            sampleTimeLabel.Layout.Row = 2;
            sampleTimeLabel.Layout.Column = 2;
            sampleTimeLabel.Text = getString(message('Control:compDesignTask:lblSampleTime'));
            sampleTimeEditField = uieditfield(discretizationGrid,"numeric");
            sampleTimeEditField.Layout.Row = 2;
            sampleTimeEditField.Layout.Column = 3;
            if Ts == 0
                sampleTimeEditField.Value = 1;
            else
                sampleTimeEditField.Value = Ts;
            end
            sampleTimeEditField.Limits = [0 inf];
            sampleTimeEditField.LowerLimitInclusive = 'off';
            sampleTimeEditField.UpperLimitInclusive = 'off';
            if Ts == 0
                discretizationGrid.RowHeight{1} = 0;
                discretizationGrid.ColumnWidth{1} = 0;
                discretizationGrid.ColumnWidth{end} = '1x';
            end

            conversionMethodPanel = uipanel(figureGrid);
            conversionMethodPanel.Layout.Row = 2;
            conversionMethodPanel.Layout.Column = 1;
            conversionMethodPanel.Title = getString(message('Control:compDesignTask:strConversionMethod'));

            conversionMethodGrid = uigridlayout(conversionMethodPanel,[length(this.BlockNames) 6]);
            conversionMethodGrid.RowHeight = repmat({'fit'},1,length(this.BlockNames));
            conversionMethodGrid.ColumnWidth = {'fit','fit','fit','fit','fit','1x'};

            sz = [length(this.BlockNames) 1];
            blockLabels = createArray(sz,'matlab.ui.control.Label');
            methodDropDowns = createArray(sz,'matlab.ui.control.DropDown');
            prewarpLabels = createArray(sz,'matlab.ui.control.Label');
            prewarpEditFields = createArray(sz,'matlab.ui.control.NumericEditField');
            prewarpUnitLabels = createArray(sz,'matlab.ui.control.Label');
            for ii = 1:sz(1)
                blockLabel = uilabel(conversionMethodGrid);
                blockLabel.Text = [this.BlockNames{ii},':'];
                blockLabel.Layout.Row = ii;
                blockLabel.Layout.Column = 1;
                methodDropDown = uidropdown(conversionMethodGrid);
                methodDropDown.Layout.Row = ii;
                methodDropDown.Layout.Column = 2;
                methodDropDown.Items = this.ConversionMethods(:,2);
                prewarpLabel = uilabel(conversionMethodGrid);
                prewarpLabel.Text = getString(message('Control:compDesignTask:strAt'));
                prewarpLabel.Layout.Row = ii;
                prewarpLabel.Layout.Column = 3;
                prewarpLabel.Visible = false;
                prewarpEditField = uieditfield(conversionMethodGrid,"numeric");
                prewarpEditField.Layout.Row = ii;
                prewarpEditField.Layout.Column = 4;
                prewarpEditField.Value = 1;
                prewarpEditField.Limits = [0 inf];
                prewarpEditField.LowerLimitInclusive = 'off';
                prewarpEditField.UpperLimitInclusive = 'off';
                prewarpEditField.Visible = false;
                prewarpUnitLabel = uilabel(conversionMethodGrid);
                prewarpUnitLabel.Text = getString(message('Control:compDesignTask:strFreqUnit'));
                prewarpUnitLabel.Layout.Row = ii;
                prewarpUnitLabel.Layout.Column = 5;
                prewarpUnitLabel.Visible = false;
                
                blockLabels(ii) = blockLabel;
                methodDropDowns(ii) = methodDropDown;
                prewarpLabels(ii) = prewarpLabel;
                prewarpEditFields(ii) = prewarpEditField;
                prewarpUnitLabels(ii) = prewarpUnitLabel;
            end

            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["help" "ok" "cancel"]);
            btnCont = getWidget(buttonPanel);
            btnCont.Layout.Row = 3;
            btnCont.Layout.Column = 1;
            buttonPanel.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(this);
            buttonPanel.HelpButton.ButtonPushedFcn = @(es,ed) cbHelpButtonPushed(this);
            buttonPanel.CancelButton.ButtonPushedFcn = @(es,ed) cbCloseEvent(this);

            this.Widgets = struct('ButtonPanel',buttonPanel,...
                'HelpButton',buttonPanel.HelpButton,...
                'OKButton',buttonPanel.OKButton,...
                'CancelButton',buttonPanel.CancelButton,...
                'PanelGrid',figureGrid,...
                'DiscretizationPanel',discretizationPanel,...
                'DiscretizationGrid',discretizationGrid,...
                'c2dButtonGroup',c2dButtonGroup,...
                'ContinousButton',continousButton,...
                'DiscreteButton',discreteButton,...
                'SampleTimeLabel',sampleTimeLabel,...
                'SampleTimeEditField',sampleTimeEditField,...
                'ConversionMethodPanel',conversionMethodPanel,...
                'ConversionMethodGrid',conversionMethodGrid,...
                'BlockLabels',blockLabels,...
                'MethodDropDowns',methodDropDowns,...
                'PrewarpLabels',prewarpLabels,...
                'PrewarpEditFields',prewarpEditFields,...
                'PrewarpUnitLabels',prewarpUnitLabels);
        end

        function connectUI(this)
            L1 = addlistener(this.DesignerData,'ArchitectureChanged',@(es,ed) cbCloseEvent(this)); 
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) cbCloseEvent(this)); 
            registerUIListeners(this,L2);    
            this.Widgets.c2dButtonGroup.SelectionChangedFcn = @(es,ed) cbc2dRadioChanged(this,ed.NewValue.Text);    
            this.Widgets.SampleTimeEditField.ValueChangedFcn = @(es,ed) cbSampleTimeChanged(this,ed.Value);
            for ii = 1:length(this.BlockNames)
                this.Widgets.MethodDropDowns(ii).ValueChangedFcn = @(es,ed) cbMethodDropDownChanged(this,ed.Value,ii);
            end
        end
    end
    
    methods (Access = private)
        function cbOKButtonPushed(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            % Post Action as updating architecture
            postActionStatus(this.Tool.getEventManager, 'on', ...
                getString(message('Control:designerapp:convertBlockSampleTime')));
            try
                updateArchitecture(this);
                close(this);
            catch ME
                uialert(this.UIFigure,ME.message,getString(message('Control:compDesignTask:errConversionError')),'Icon','error');
            end
            % Clear action status
            clearActionStatus(this.Tool.getEventManager);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end
        
        function cbCloseEvent(this)
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            close(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end
        
        function cbHelpButtonPushed(~)
            helpview('control','CSD_SampleTimeConversionHelp','CSHelpWindow');
        end
        
        function cbc2dRadioChanged(this,Selection)
            switch Selection
                case getString(message('Control:compDesignTask:lblContinuousTime')) %continuous
                    this.Widgets.SampleTimeLabel.Enable = 0;
                    this.Widgets.SampleTimeEditField.Enable = 0;
                    this.NewTs = 0;
                case getString(message('Control:compDesignTask:lblDiscreteTimeNewRate')) %discrete
                    this.Widgets.SampleTimeLabel.Enable = 1;
                    this.Widgets.SampleTimeEditField.Enable = 1;
                    this.NewTs = this.Widgets.SampleTimeEditField.Value;
            end
            updateMethodDropDownItems(this);
        end

        function cbSampleTimeChanged(this,Value)
            this.NewTs = Value;
            updateMethodDropDownItems(this);
        end

        function cbMethodDropDownChanged(this,Value,idx)
            isPreWarp = strcmp(Value,getString(message('Control:compDesignTask:strTustinPrewarp')));
            this.Widgets.PrewarpLabels(idx).Visible = isPreWarp;
            this.Widgets.PrewarpEditFields(idx).Visible = isPreWarp;
            this.Widgets.PrewarpUnitLabels(idx).Visible = isPreWarp;
        end
        
        % Update Architecture in app
        function updateArchitecture(this)
            % Update all components
            if ~isequal(getTs(this.Architecture),this.NewTs)
                for ii = 1:length(this.Blocks)
                    method = this.Widgets.MethodDropDowns(ii).Value;
                    methodIdx = find(cellfun(@(x) strcmp(x,method),this.AllMethods(:,2)),1);
                    if strcmp(method,getString(message('Control:compDesignTask:strTustinPrewarp')))
                        prewarpFreq = this.Widgets.PrewarpEditFields(ii).Value;
                    else
                        prewarpFreq = 0;
                    end
                    newBlockValue = localConvertBlock(this.Blocks{ii},this.AllMethods{methodIdx,1},this.NewTs,prewarpFreq);
                    setValue(this.Blocks{ii},newBlockValue,true);
                end
                % Update architecture
                updateArchitecture(this.Architecture);
            end
            function newBlockValue = localConvertBlock(blk,conversionMethod,newTs,prewarpFreq)
                % Get conversion function handle.
                if isct(getValue(blk))  % Current system continuous, newTs>0
                    optionsStruct = c2dOptions('Method',conversionMethod,...
                        'PrewarpFrequency',prewarpFreq);
                    newBlockValue = c2d(blk.getValue,newTs,optionsStruct);
                elseif newTs == 0 % Current system discrete, newTs == 0
                    optionsStruct = d2cOptions('Method',conversionMethod,...
                        'PrewarpFrequency',prewarpFreq);
                    newBlockValue = d2c(blk.getValue,optionsStruct);
                else % Current system discrete, newTs > 0
                    optionsStruct = d2dOptions('Method',conversionMethod,...
                        'PrewarpFrequency',prewarpFreq);
                    newBlockValue = d2d(blk.getValue,newTs,optionsStruct);
                end
            end
        end        
        
        % Update method dropdowns based on sample time
        function updateMethodDropDownItems(this)
            for ii = 1:length(this.BlockNames)
                this.Widgets.MethodDropDowns(ii).Items = this.ConversionMethods(:,2);
                isPreWarp = strcmp(this.Widgets.MethodDropDowns(ii).Value,getString(message('Control:compDesignTask:strTustinPrewarp')));
                this.Widgets.PrewarpLabels(ii).Visible = isPreWarp;
                this.Widgets.PrewarpEditFields(ii).Visible = isPreWarp;
                this.Widgets.PrewarpUnitLabels(ii).Visible = isPreWarp;
            end
        end
    end
    
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
        end
        function qeMethodDropDownChanged(this, Value, idx)
            cbMethodDropDownChanged(this, Value, idx)
        end
    end    
end