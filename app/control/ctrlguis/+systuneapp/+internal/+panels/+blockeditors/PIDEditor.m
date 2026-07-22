classdef PIDEditor < systuneapp.internal.panels.blockeditors.LTIEditor
    % systuneapp.internal.panels.blockeditors.PIDEditorPanel
    
    %   Copyright 2022-2023 The MathWorks, Inc. 
    properties(Access = protected)
        Kp
        Ki
        Kd
        Tf
    end

    properties(Access = private)
        PIDStructureLabel       matlab.ui.control.Label
        PIDStructureDropdown    matlab.ui.control.DropDown
        PIDFormulaImage         matlab.ui.control.Image
    end

    %% Public Methods
    methods
        function this = PIDEditor(variableValue,optionalArguments)
            arguments
                variableValue tunablePID
                optionalArguments.Parent = []
            end
            this = this@systuneapp.internal.panels.blockeditors.LTIEditor(variableValue);
            this.Parent = optionalArguments.Parent;
            this.Type = "PID";
        end

        function updateUI(this)
            updatePIDStructure(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function variableValue = getCurrentVariableValue(this)
            variableValue = this.InitialVariableValue;
            variableValue.Kp = updateVariableValue(this,variableValue.Kp,this.Kp);
            variableValue.Ki = updateVariableValue(this,variableValue.Ki,this.Ki);
            variableValue.Kd = updateVariableValue(this,variableValue.Kd,this.Kd);
            variableValue.Tf = updateVariableValue(this,variableValue.Tf,this.Tf);
        end

        function updateParameterData(this)
            variableValue = this.InitialVariableValue;
            this.Kp = controllib.widget.internal.parametereditor.ParameterData('Kp',variableValue.Kp);
            this.Ki = controllib.widget.internal.parametereditor.ParameterData('Ki',variableValue.Ki);
            this.Kd = controllib.widget.internal.parametereditor.ParameterData('Kd',variableValue.Kd);
            this.Tf = controllib.widget.internal.parametereditor.ParameterData('Tf',variableValue.Tf);
        end
        
        function addTopRowWidget(this,parent)
            % Main Layout
            layout = uigridlayout([3,3],"Parent",parent);
            layout.RowHeight = {5,22,5};
            layout.ColumnWidth = {'fit','fit','1x'};
            layout.Padding = 0;
            
            % PID Structure Row
            this.PIDStructureLabel = uilabel(layout,'Text',...
                getString(message('Controllib:gui:lblPIDEditor_Structure')));
            this.PIDStructureLabel.Layout.Row = 2;
            this.PIDStructureLabel.Layout.Column = 1;
            this.PIDStructureDropdown = uidropdown(layout);
            this.PIDStructureDropdown.Layout.Row = 2;
            this.PIDStructureDropdown.Layout.Column = 2;
            this.PIDStructureDropdown.Items = {'P','PI','PID','PD'};
            this.PIDStructureDropdown.Value = getType(this.VariableValue);
            this.PIDFormulaImage = uiimage(layout);
            this.PIDFormulaImage.Layout.Row = [1 3];
            this.PIDFormulaImage.Layout.Column = 3;
            this.PIDFormulaImage.ScaleMethod = 'none';
            this.PIDFormulaImage.ImageSource = fullfile(getIconFolder(),'PIDFormula.png');
            this.PIDFormulaImage.HorizontalAlignment = 'left';
            this.PIDFormulaImage.ScaleMethod = 'none';
        end

        function connectUI(this)
            this.PIDStructureDropdown.ValueChangedFcn = ...
                @(es,ed) updatePIDStructure(this,ed.Value);
        end
    end

    %% Private Methods
    methods (Access = private)
        function updatePIDStructure(this,pidType)
            arguments
                this
                pidType = this.PIDStructureDropdown.Value
            end

            switch pidType
                case 'PID'
                    this.Ki.Free = true;
                    this.Kd.Free = true;
                    this.Tf.Free = true;
                    data = [this.Kp, this.Ki, this.Kd, this.Tf];
                    this.PIDFormulaImage.ImageSource = fullfile(getIconFolder(),'PIDFormula.png');
                case 'P'
                    this.Ki.Free = false;
                    this.Ki.Value = 0;
                    this.Kd.Free = false;
                    this.Kd.Value = 0;
                    this.Tf.Free = false;
                    this.Tf.Value = 1;
                    data = this.Kp;
                    this.PIDFormulaImage.ImageSource = fullfile(getIconFolder(),'PFormula.png');
                case 'PI'
                    this.Ki.Free = true;
                    this.Kd.Free = false;
                    this.Kd.Value = 0;
                    this.Tf.Free = false;
                    this.Tf.Value = 1;
                    data = [this.Kp, this.Ki];
                    this.PIDFormulaImage.ImageSource = fullfile(getIconFolder(),'PIFormula.png');
                case 'PD'
                    this.Ki.Free = false;
                    this.Ki.Value = 0;
                    this.Kd.Free = true;
                    this.Tf.Free = true;
                    data = [this.Kp, this.Kd, this.Tf];
                    this.PIDFormulaImage.ImageSource = fullfile(getIconFolder(),'PDFormula.png');
            end
            updateParameterEditorWidget(this,data);
        end
    end

    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetAdditionalWidgets(this)
            widgets.PIDStructureLabel = this.PIDStructureLabel;
            widgets.PIDStructureDropdown = this.PIDStructureDropdown;
            widgets.PIDFormulaImage = this.PIDFormulaImage;
        end

        function Text = generateMATLABCode(this, variableName, useTitle)
            arguments
                this
                variableName char
                useTitle logical = false
            end
            %% Title
            Text = cell(0,1);
            if useTitle
                Text = generateMATLABCode@systuneapp.internal.panels.blockeditors.LTIEditor(this);
            end
            
            %% Name
%             LTIBlockName = ltipack.createVarName(getLTIBlockName(this));    
            LTIBlockName = this.VariableValue.Name;
            
            KiFree = this.VariableValue.Ki.Free;
            KdFree = this.VariableValue.Kd.Free;
            
            if KiFree && KdFree
                default = tunablePID(LTIBlockName, 'pid');
                Kp_Text = generateMATLABCode(this.Kp,default.Kp,variableName);
                Ki_Text = generateMATLABCode(this.Ki,default.Ki,variableName);
                Kd_Text = generateMATLABCode(this.Kd,default.Kd,variableName);
                Tf_Text = generateMATLABCode(this.Tf,default.Tf,variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunablePID(''', LTIBlockName, ''',''pid'');']);
                Text = [Text; Kp_Text; Ki_Text; Kd_Text; Tf_Text];
            elseif KiFree && ~KdFree
                default = tunablePID(LTIBlockName, 'pi');
                Kp_Text = generateMATLABCode(this.Kp,default.Kp,variableName);
                Ki_Text = generateMATLABCode(this.Ki,default.Ki,variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunablePID(''', LTIBlockName, ''',''pi'');']);
                Text = [Text; Kp_Text; Ki_Text];
            elseif ~KiFree && KdFree
                default = tunablePID(LTIBlockName, 'pd');
                Kp_Text = generateMATLABCode(this.Kp,default.Kp,variableName);
                Kd_Text = generateMATLABCode(this.Kd,default.Kd,variableName);
                Tf_Text = generateMATLABCode(this.Tf,default.Tf,variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunablePID(''', LTIBlockName, ''',''pd'');']);
                Text = [Text; Kp_Text; Kd_Text; Tf_Text];
            else
                default = tunablePID(LTIBlockName, 'p');
                Kp_Text = generateMATLABCode(this.Kp,default.Kp,variableName);
                Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunablePID(''', LTIBlockName, ''',''p'');']);
                Text = [Text; Kp_Text];
            end
        end
    end
end

function folder = getIconFolder()
folder = fullfile(matlabroot,'toolbox','shared','controllib','graphics','resources');
end