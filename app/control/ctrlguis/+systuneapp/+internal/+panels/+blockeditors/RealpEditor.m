classdef RealpEditor < systuneapp.internal.panels.blockeditors.LTIEditor
    % systuneapp.internal.panels.blockeditors.GainEditor
    %
    % blk = tunableGain('sys',2,3);
    % pnl = systuneapp.internal.panels.blockeditors.GainEditor(blk,"Parent",uigridlayout([1 1]));
    % getWidget(pnl);

    properties(Access = private)
        Parameter   controllib.widget.internal.parametereditor.ParameterData
    end

    %% Public Methods
    methods
        function this = RealpEditor(variableValue,optionalArguments)
            arguments
                variableValue realp
                optionalArguments.Parent = []
            end
            this = this@systuneapp.internal.panels.blockeditors.LTIEditor(variableValue);
            this.Parent = optionalArguments.Parent;
            this.Type = 'Realp';
        end

        function updateUI(this)
            updateParameterEditorWidget(this,this.Parameter);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function variableValue = getCurrentVariableValue(this)
            % Create a copy of the initial variable stored, and modify Gain
            % field.
            variableValue = this.InitialVariableValue;
            variableValue = updateVariableValue(this,variableValue,this.Parameter);
        end

        function updateParameterData(this)
            % Create controllib.widget.internal.parametereditor.ParameterData from
            % stored tunableGain variable.
            variableValue = this.InitialVariableValue;
            this.Parameter = controllib.widget.internal.parametereditor.ParameterData(...
                'Parameter',variableValue);
        end
    end

    %% Hidden Methods
    methods(Hidden)
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
            
            % Gain
            default = tunableGain(LTIBlockName, 1, 1);
            this_gain = this.VariableValue;
            [num_in, num_out] = iosize(this_gain);
            Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = tunableGain(''', LTIBlockName, ''',', mat2str(num_in), ',' mat2str(num_out) ');']);
            Gain_Text = generateMATLABCode(this.Parameter,default.Gain,variableName);
            if ~isempty(Gain_Text)
                Text = [Text; Gain_Text];
            end
        end
    end
end