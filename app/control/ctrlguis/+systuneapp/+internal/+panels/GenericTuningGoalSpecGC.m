classdef GenericTuningGoalSpecGC < controllib.ui.internal.dialog.AbstractPanelGC
    % Generic graphical component tuning goal specifications

    % Copyright 2013-2021 The MathWorks, Inc.
    properties
        Widgets
    end

    properties (Access = protected)
        ShowFocusWidget = true
        ShowModelsWidget = true
    end

    methods
        function obj = GenericTuningGoalSpecGC(tcpeer)
            %Call parent constructor
            obj = obj@controllib.ui.internal.dialog.AbstractPanelGC(tcpeer);
        end






    end

    methods(Access= protected)
        function createWidgets(this)
            %Options Label
            lblOptions = uilabel('Parent',[]);
            lblOptions.Text = sprintf('%s: ',getString(message('Control:systunegui:TuningGoalSpecOptions')));

            % Focus
            if this.ShowFocusWidget
                lblFocus = uilabel('Parent',[]);
                lblFocus.Text = sprintf('%s ',getString(message('Control:systunegui:TuningGoalSpecFocus')));
                lblFocus.Tag = 'lblFocus';
                txtFocus = uieditfield('Parent',[]);
                txtFocus.Tag = 'txtFocus';
                lblFreqUnit = uilabel('Parent',[]);
                lblFreqUnit.Tag = 'lblFreqUnit';
                lblFreqUnit.Text = sprintf('%s/%s',controllibutils.utXlateUnitsString('rad','short'),this.TCPeer.Data.CDD.getTimeUnitString);
                % Store Widgets
                this.Widgets.Advanced.txtFocus =        txtFocus;
                this.Widgets.Advanced.lblFocus =        lblFocus;
                this.Widgets.Advanced.lblFreqUnit =     lblFreqUnit;
            end

            % Models
            if this.ShowModelsWidget
                lblApplyGoalTo = uilabel('Parent',[]);
                lblApplyGoalTo.Text = getString(message('Control:systunegui:TuningGoalSpecApplyGoalTo'));
                lblApplyGoalTo.Tag = 'lblApplyGoalTo';

%                 % Button group with the two radio buttons
%                 btnGroupModels = uibuttongroup('Parent',[]);
%                 btnGroupModels.BorderType = 'none';
% 
%                 % Radio buttons to choose between all models or specific models
%                 radioAllModels = uiradiobutton('Parent',btnGroupModels);
%                 radioAllModels.Tag = 'radioAllModels';
%                 radioAllModels.Text = sprintf('%s',getString(message('Control:systunegui:TuningGoalSpecAllModels')));
%                 %             radioAllModels.Value = true;
%                 radioAllModels.Position = [10 35 165 25];
% 
%                 radioOnlyModels = uiradiobutton('Parent',btnGroupModels);
%                 radioOnlyModels.Text =  sprintf('%s:',getString(message('Control:systunegui:TuningGoalSpecOnlyModels')));
%                 radioOnlyModels.Tag = 'radioOnlyModels';
%                 radioOnlyModels.Position = [10 5 165 25];
%                 radioOnlyModels.Value = false;
                
                checkboxAllModels = uicheckbox('Parent',[],...
                    'Text',getString(message('Control:systunegui:TuningGoalSpecAllModels')));
                checkboxAllModels.Value = true;
                checkboxAllModels.Tag = 'checkboxAllModels';
                txtModels = uieditfield('Parent',[]);
                txtModels.Tag = 'txtModels';
                txtModels.Enable = false;

                % Construct panel with radio buttons (related to Models)
                pnlRadio = uigridlayout('Parent',[],'RowHeight',{'fit'},...
                    'ColumnWidth',{'fit','1x','fit'});
                pnlRadio.Padding = 0;
                lblApplyGoalTo.Parent = pnlRadio;
                lblApplyGoalTo.Layout.Row = 1;
                lblApplyGoalTo.Layout.Column = 1;
                checkboxAllModels.Parent = pnlRadio;
                checkboxAllModels.Layout.Row = 1;
                checkboxAllModels.Layout.Column = 3;
                txtModels.Parent = pnlRadio;
                txtModels.Layout.Row = 1;
                txtModels.Layout.Column = 2;
                
                % Store widgets
                this.Widgets.Advanced.txtModels = txtModels;
                this.Widgets.Advanced.lblApplyGoalTo = lblApplyGoalTo;
                this.Widgets.Advanced.checkboxAllModels = checkboxAllModels;
                this.Widgets.Advanced.pnlRadio = pnlRadio;
                this.Widgets.Advanced.lblOptions = lblOptions;
            end
        end

        function update(this)

            %Get the current value of the TCpeer
            Value = getValue(this.TCPeer);

            %Update the text fields to the current value
            if this.ShowFocusWidget
                this.Widgets.Advanced.txtFocus.Value = mat2str(Value.Data.Focus);
            end

            % Update models radio button
            if this.ShowModelsWidget
                if isnan(Value.Data.Models)
                    this.Widgets.Advanced.checkboxAllModels.Value = true;
                    this.Widgets.Advanced.txtModels.Value = mat2str(Value.MetaData.Models);
                else
                    this.Widgets.Advanced.checkboxAllModels.Value = false;
                    this.Widgets.Advanced.txtModels.Value = mat2str(Value.Data.Models);
                end
            end

        end

        function cleanupGUI(this)
            this.Widgets = [];
        end

        function connectUI(this)
            % GUI listeners
            this.Widgets.Advanced.txtFocus.ValueChangedFcn = ...
                @(hSrc, hData) cbFocusEdit(this, this.Widgets.Advanced.txtFocus.Value);
            this.Widgets.Advanced.txtModels.ValueChangedFcn = ...
                @(hSrc, hData)cbModelsEdit(this, this.Widgets.Advanced.txtModels.Value);
            this.Widgets.Advanced.checkboxAllModels.ValueChangedFcn = ...
                @(hSrc, hData)cbModelSelected(this, hData);
        end
    end
    
    methods (Access = private)
        %% GUI Listener callbacks
        function cbModelSelected(this, hData)
            % update Models in TC when Models radio button switches.
            if hData.Value
                this.Widgets.Advanced.txtModels.Enable = false;
                cbModelsEdit(this, 'NaN');
            else
                this.Widgets.Advanced.txtModels.Enable = true;
                cbModelsEdit(this,this.Widgets.Advanced.txtModels.Value);
            end
        end

        function cbFocusEdit(this, fieldValue)
            % Instant apply to TC when Focus text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Focus cannot be empty
                    update(this);
                else
                    setFocus(this.TCPeer,fieldValue);
                end
            catch ME
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                update(this);
                return;
            end
        end

        function cbModelsEdit(this, fieldValue)
            % Instant apply to TC when Models text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % Models cannot be empty
                    update(this);
                else
                    setModels(this.TCPeer,fieldValue);
                end
            catch ME
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                update(this);
                return;
            end
            drawnow;
        end
    end

    methods (Hidden)
        function Widgets = qeGetWidgets(this)
            Widgets = this.Widgets;
        end
    end

end
