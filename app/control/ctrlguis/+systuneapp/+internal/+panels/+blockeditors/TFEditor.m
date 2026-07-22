classdef TFEditor < systuneapp.internal.panels.blockeditors.LTIEditor
    % systuneapp.internal.panels.blockeditors.TFEditorPanel
    %
    % blk = tunableTF('sys',2,4);
    % pnl = systuneapp.internal.panels.blockeditors.TFEditor(blk,"Parent",uigridlayout([1 1]));
    % getWidget(pnl);

    properties(Access = private)
        Numerator      controllib.widget.internal.parametereditor.ParameterData
        Denominator    controllib.widget.internal.parametereditor.ParameterData

        NumberOfPolesLabel      matlab.ui.control.Label
        NumberOfPolesSpinner  matlab.ui.control.Spinner  
        NumberOfZerosLabel      matlab.ui.control.Label
        NumberOfZerosSpinner  matlab.ui.control.Spinner
    end

    %% Public Methods
    methods
        function this = TFEditor(variableValue,optionalArguments)
            arguments
                variableValue tunableTF
                optionalArguments.Parent = []
            end
            this = this@systuneapp.internal.panels.blockeditors.LTIEditor(variableValue);
            this.Parent = optionalArguments.Parent;
            this.Type = "Transfer function";
        end

        function updateUI(this)
            updateParameterEditorWidget(this,[this.Numerator, this.Denominator]);
            updateNumDenSpinner(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function variableValue = getCurrentVariableValue(this)
            % Create a copy of the initial variable stored, and modify the
            % Numerator and Denominator fields
            variableValue = this.InitialVariableValue;
            variableValue.Numerator = updateVariableValue(this,variableValue.Numerator,...
                this.Numerator);
            variableValue.Denominator = updateVariableValue(this,variableValue.Denominator,...
                this.Denominator);
        end

        function updateParameterData(this)
            % Create controllib.widget.internal.parametereditor.ParameterData from
            % stored tunableTF variable.
            variableValue = this.InitialVariableValue;
            this.Numerator = controllib.widget.internal.parametereditor.ParameterData(...
                'Numerator',variableValue.Numerator);
            this.Denominator = controllib.widget.internal.parametereditor.ParameterData(...
                'Denominator',variableValue.Denominator);
        end

        function addTopRowWidget(this,parent)
            % Create widgets for editing number of poles and zeros.

            % Widget Layout
            layout = uigridlayout([1,4],"Parent",parent);
            layout.RowHeight = {'fit'};
            layout.ColumnWidth = {'fit',60,'fit',60};
            layout.Padding = 0;

            % Number of poles
            this.NumberOfPolesLabel = uilabel(layout,"Text",...
                getString(message('Controllib:gui:lblTFEditor_Poles')));
            this.NumberOfPolesLabel.Layout.Row = 1;
            this.NumberOfPolesLabel.Layout.Column = 1;
            this.NumberOfPolesSpinner = uispinner(layout,"Value",...
                length(this.Denominator.Value)-1);
            this.NumberOfPolesSpinner.Layout.Row = 1;
            this.NumberOfPolesSpinner.Layout.Column = 2;
            this.NumberOfPolesSpinner.Limits = [0 Inf];
            this.NumberOfPolesSpinner.LowerLimitInclusive = 'on';
            this.NumberOfPolesSpinner.UpperLimitInclusive = 'off';
            this.NumberOfPolesSpinner.RoundFractionalValues = 'on';
            
            % Number of zeros
            this.NumberOfZerosLabel = uilabel(layout,"Text",...
                getString(message('Controllib:gui:lblTFEditor_Zeros')));
            this.NumberOfZerosLabel.Layout.Row = 1;
            this.NumberOfZerosLabel.Layout.Column = 3;
            this.NumberOfZerosSpinner = uispinner(layout,"Value",...
                length(this.Numerator.Value)-1);
            this.NumberOfZerosSpinner.Layout.Row = 1;
            this.NumberOfZerosSpinner.Layout.Column = 4;
            this.NumberOfZerosSpinner.Limits = [0 Inf];
            this.NumberOfZerosSpinner.LowerLimitInclusive = 'on';
            this.NumberOfZerosSpinner.UpperLimitInclusive = 'off';
            this.NumberOfZerosSpinner.RoundFractionalValues = 'on';
        end

        function connectUI(this)
            % Add callbacks to editfields for changing number of poles and zeros. 
            this.NumberOfPolesSpinner.ValueChangedFcn = ...
                @(es,ed) cbNumberOfPolesSpinnerValueChanged(this,ed);
            this.NumberOfZerosSpinner.ValueChangedFcn = ...
                @(es,ed) cbNumberOfZerosSpinnerValueChanged(this,ed);
        end
    end

    %% Private Methods
    methods (Access = private)
        function updateTFStructure(this,optionalArguments)
            % updateTFStructure(this,"NumberOfPoles",3,"NumberOfZeros",2)
            arguments
                this
                % Use current VariableValue for default number of
                % poles/zeros
                optionalArguments.NumberOfPoles = length(this.VariableValue.Denominator.Value)-1
                optionalArguments.NumberOfZeros = length(this.VariableValue.Numerator.Value)-1
            end
            try
                % Create new tunableTF
                newVariableValue = tunableTF(this.VariableValue.Name,...
                    optionalArguments.NumberOfZeros,optionalArguments.NumberOfPoles);
                % Copy current Numerator parameter if order is the same
                if length(newVariableValue.Numerator.Value) == length(this.VariableValue.Numerator.Value)
                    newVariableValue.Numerator = updateVariableValue(this,...
                        newVariableValue.Numerator,this.Numerator);
                end
                % Copy current Denominator parameter if order is the same
                if length(newVariableValue.Denominator.Value) == length(this.VariableValue.Denominator.Value)
                    newVariableValue.Denominator = updateVariableValue(this,...
                        newVariableValue.Denominator,this.Denominator);
                end
                % Store new variable value
                this.InitialVariableValue = newVariableValue;
                % Update data
                updateParameterData(this);
                % Update widget
                updateParameterEditorWidget(this,[this.Numerator, this.Denominator]);
            catch ex
                % Revert edit field for number of poles/zeros to reflect
                % current VariableValue
                updateNumDenSpinner(this);
                throw(ex);
            end
        end

        function updateNumDenSpinner(this)
            % Update spinners for number of poles/zeros to reflect
            % current VariableValue

            this.NumberOfPolesSpinner.Limits(1) = length(this.Numerator.Value)-1;
            this.NumberOfZerosSpinner.Limits(2) = length(this.Denominator.Value);

            this.NumberOfPolesSpinner.Value = length(this.Denominator.Value)-1;
            this.NumberOfZerosSpinner.Value = length(this.Numerator.Value)-1;
        end

        function cbNumberOfPolesSpinnerValueChanged(this,ed)
            % Create new Denominator parameter
            this.NumberOfZerosSpinner.Limits(2) = ed.Value + 1;
            updateTFStructure(this,"NumberOfPoles",ed.Value);
        end

        function cbNumberOfZerosSpinnerValueChanged(this,ed)
            % Create new Numerator parameter
            this.NumberOfPolesSpinner.Limits(1) = ed.Value;
            updateTFStructure(this,"NumberOfZeros",ed.Value);
        end
    end

    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetAdditionalWidgets(this)
            widgets.NumberOfPolesSpinner = this.NumberOfPolesSpinner;
            widgets.NumberOfPolesLabel = this.NumberOfPolesLabel;
            widgets.NumberOfZerosSpinner = this.NumberOfZerosSpinner;
            widgets.NumberOfZerosLabel = this.NumberOfZerosLabel;
        end

        function Text = generateMATLABCode(this,variableName,useTitle)
            arguments
                this
                variableName char
                useTitle logical = false
            end
            
            % Title
            Text = cell(0,1);
            if useTitle
                Text = generateMATLABCode@systuneapp.internal.panels.blockeditors.LTIEditor(this);
            end
            
            % Name
%             LTIBlockName = ltipack.createVarName(getLTIBlockName(this));
            LTIBlockName = this.VariableValue.Name;
            this_tf = this.VariableValue;
            num_z = length(this_tf.num.Value) - 1;
            num_p = length(this_tf.den.Value) - 1;
            default = tunableTF(LTIBlockName, num_z, num_p);
            Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunableTF(''', LTIBlockName, ''',', mat2str(num_z), ',' mat2str(num_p) ');']);
            
            % Numerator
            Num_Text = generateMATLABCode(this.Numerator,default.Numerator,variableName);
            if ~isempty(Num_Text)
                Text = [Text; Num_Text];
            end
            
            % Denominator
            Den_Text = generateMATLABCode(this.Denominator,default.Denominator,variableName);
            if ~isempty(Den_Text)
                Text = [Text; Den_Text];
            end
        end
    end
end