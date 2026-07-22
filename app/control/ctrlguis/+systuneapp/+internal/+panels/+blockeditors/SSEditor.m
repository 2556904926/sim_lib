classdef SSEditor < systuneapp.internal.panels.blockeditors.LTIEditor
    % systuneapp.internal.panels.blockeditors.SSEditorPanel
    %
    % blk = tunableSS('sys',3);
    % pnl = systuneapp.internal.panels.blockeditors.SSEditor(blk,"Parent",uigridlayout([1 1]));
    % getWidget(pnl);

    properties(Access = private)
        A   controllib.widget.internal.parametereditor.ParameterData
        B   controllib.widget.internal.parametereditor.ParameterData
        C   controllib.widget.internal.parametereditor.ParameterData
        D   controllib.widget.internal.parametereditor.ParameterData

        SystemOrderLabel        matlab.ui.control.Label
        SystemOrderSpinner      matlab.ui.control.Spinner
    end

    %% Public Methods
    methods
        function this = SSEditor(variableValue,optionalArguments)
            arguments
                variableValue tunableSS
                optionalArguments.Parent = []
            end
            this = this@systuneapp.internal.panels.blockeditors.LTIEditor(variableValue);
            this.Parent = optionalArguments.Parent;
            this.Type = "State space";
        end

        function updateUI(this)
            updateParameterEditorWidget(this,[this.A, this.B, this.C, this.D]);
            updateSystemOrderEditfield(this)
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function connectUI(this)
            % Add callbacks to editfields for changing system order 
            this.SystemOrderSpinner.ValueChangedFcn = @(es,ed) cbSystemOrderSpinnerValueChanged(this,ed);
        end

        function variableValue = getCurrentVariableValue(this)
            % Create a copy of the initial variable stored, and modify the
            % A,B,C and D fields
            variableValue = this.InitialVariableValue;
            variableValue.A = updateVariableValue(this,variableValue.A,this.A);
            variableValue.B = updateVariableValue(this,variableValue.B,this.B);
            variableValue.C = updateVariableValue(this,variableValue.C,this.C);
            variableValue.D = updateVariableValue(this,variableValue.D,this.D);
        end

        function updateParameterData(this)
            % Create controllib.widget.internal.parametereditor.ParameterData from
            % stored tunableSS variable.
            variableValue = this.InitialVariableValue;
            this.A = controllib.widget.internal.parametereditor.ParameterData(...
                'A',variableValue.A);
            this.B = controllib.widget.internal.parametereditor.ParameterData(...
                'B',variableValue.B);
            this.C = controllib.widget.internal.parametereditor.ParameterData(...
                'C',variableValue.C);
            this.D = controllib.widget.internal.parametereditor.ParameterData(...
                'D',variableValue.D);
        end

        function addTopRowWidget(this,parent)
            % Create widgets for editing number of poles and zeros.

            % Widget Layout
            layout = uigridlayout([1,2],"Parent",parent);
            layout.RowHeight = {'fit'};
            layout.ColumnWidth = {'fit',60};
            layout.Padding = 0;

            % Order of the system
            this.SystemOrderLabel = uilabel(layout,"Text",...
                getString(message('Controllib:gui:lblSSEditor_Order')));
            this.SystemOrderLabel.Layout.Row = 1;
            this.SystemOrderLabel.Layout.Column = 1;
            this.SystemOrderSpinner = uispinner(layout);
            this.SystemOrderSpinner.Layout.Row = 1;
            this.SystemOrderSpinner.Layout.Column = 2;
            this.SystemOrderSpinner.Limits = [0 Inf];
            this.SystemOrderSpinner.LowerLimitInclusive = 'on';
            this.SystemOrderSpinner.UpperLimitInclusive = 'off';
        end
    end

    %% Private Methods
    methods(Access = private)
        function updateSystemOrder(this,nx)
            % updateTFStructure(this,"NumberOfPoles",3,"NumberOfZeros",2)
            arguments
                this
                nx
            end

            if nx ~= order(this.VariableValue)
                % If new order is different
                try
                    % Create new tunableTF
                    [ny,nu] = size(this.VariableValue);
                    newVariableValue = tunableSS(this.VariableValue.Name,nx,ny,nu);
                    % Store new variable value
                    this.InitialVariableValue = newVariableValue;
                    % Update data
                    updateParameterData(this);
                    % Update widget
                    updateParameterEditorWidget(this,[this.A, this.B, this.C, this.D]);
                catch ex
                    % Revert edit field for number of poles/zeros to reflect
                    % current VariableValue
                    updateSystemOrderEditfield(this);
                    throw(ex);
                end
            end
        end

        function updateSystemOrderEditfield(this)
            % Update editfield for system order to reflect current
            % VariableValue
            this.SystemOrderSpinner.Value = length(this.A.Value);
        end

        function cbSystemOrderSpinnerValueChanged(this,ed)
            % Create new Denominator parameter
            updateSystemOrder(this,ed.Value);
        end
    end

    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetAdditionalWidgets(this)
            widgets.SystemOrderSpinner = this.SystemOrderSpinner;
            widgets.SystemOrderLabel = this.SystemOrderLabel;
        end

        function Text = generateMATLABCode(this,variableName,useTitle)
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

            this_ss = this.VariableValue;
            [num_out, num_in] = iosize(this_ss);
            num_states = order(this_ss);
            default = tunableSS(LTIBlockName, num_states, num_out, num_in);
            Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunableSS(''', LTIBlockName, ''',', mat2str(num_states), ',', mat2str(num_out), ',' mat2str(num_in) ');']);
            
            %% A
            A_Text = generateMATLABCode(this.A,default.A,variableName);
            if ~isempty(A_Text)
                Text = [Text; A_Text];
            end
            %% B
            B_Text = generateMATLABCode(this.B,default.B,variableName);
            if ~isempty(B_Text)
                Text = [Text; B_Text];
            end
            %% C
            C_Text = generateMATLABCode(this.C,default.C,variableName);
            if ~isempty(C_Text)
               Text = [Text; C_Text];
            end
            %% D
            D_Text = generateMATLABCode(this.D,default.D,variableName);
            if ~isempty(D_Text)
                Text = [Text; D_Text];
            end
        end
    end
end