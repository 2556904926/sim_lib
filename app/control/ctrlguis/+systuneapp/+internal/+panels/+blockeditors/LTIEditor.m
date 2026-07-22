classdef LTIEditor < controllib.ui.internal.dialog.AbstractContainer
    % systuneapp.internal.panels.blockeditors.PIDEditorPanel

    properties
        Parent
    end

    properties (GetAccess = public, SetAccess = protected)
        Type string
    end

    properties(Dependent)
        VariableValue
    end

    properties(Access = protected)
        InitialVariableValue
    end

    properties(Access = private)
        ParameterEditor         controllib.widget.internal.parametereditor.ParameterEditorPanel
        NameText                matlab.ui.control.Label
        NameLabel               matlab.ui.control.Label
        TypeText                matlab.ui.control.Label
        TypeLabel               matlab.ui.control.Label
    end

    events
        VariableValueChanged
    end

    %% Public Methods
    methods
        function this = LTIEditor(variableValue)
            arguments
                variableValue
            end
            this.InitialVariableValue = variableValue;
            updateParameterData(this);
        end

        function widget = getWidget(this)
            widget = getWidget@controllib.ui.internal.dialog.AbstractContainer(this);
            updateUI(this);
        end

        function Text = generateMATLABCode(this)
            %% Title
            Text = cell(0,1);
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Controllib:gui:CodegenSetParam'))));
        end

        function delete(this)
            delete(this.ParameterEditor);
        end
    end

    %% Get/Set Methods
    methods
        % Variable Value
        function variableValue = get.VariableValue(this)
            variableValue = getCurrentVariableValue(this);
        end

        function set.VariableValue(this,variableValue)
            arguments
                this
                variableValue
            end
            this.InitialVariableValue = variableValue;
            updateParameterData(this);
            updateUI(this);
        end

        % Parent
        function Parent = get.Parent(this)
            Parent = this.Parent;
        end
        
        function set.Parent(this,Parent)
            % Reparent widget
            if this.IsWidgetValid
                w = getWidget(this);
                w.Parent = Parent;
            end
            this.Parent = Parent;
        end
    end

    %% Protected Methods
    methods (Access = protected, Sealed)
        function container = createContainer(this)
            % Main Container
            container = uigridlayout([5,1],"Parent",this.Parent);
            container.RowHeight = {'fit','fit','fit','1x'};
            container.ColumnWidth = {'1x'};

            % Top Row Widget
            topRowContainer = uigridlayout(container,[1 1]);
            topRowContainer.Layout.Row = 1;
            topRowContainer.Layout.Column = 1;
            topRowContainer.Padding = 0;
            addTopRowWidget(this,topRowContainer);

            % Bottom Row Widget
            bottomRowContainer = uigridlayout(container,[1 1]);
            bottomRowContainer.Layout.Row = 3;
            bottomRowContainer.Layout.Column = 1;
            bottomRowContainer.Padding = 0;
            addBottomRowWidget(this,bottomRowContainer);
        end

        function variableParameter = updateVariableValue(this,variableParameter,newParameter)
            variableParameter.Value = newParameter.Value;
            variableParameter.Minimum = newParameter.Minimum;
            variableParameter.Maximum = newParameter.Maximum;
            variableParameter.Free = newParameter.Free;
        end

        function updateParameterEditorWidget(this,data)
            arguments
                this
                data
            end
            
            parent = this.Container;
            if ~isempty(this.ParameterEditor) && isvalid(this.ParameterEditor)
                update(this.ParameterEditor,data);
            else
                pEditor = controllib.widget.internal.parametereditor.ParameterEditorPanel(...
                    data,"Parent",parent,"ShowEstimate",false,"ShowFree",true,...
                    "VariableEditorLocation",'CENTER',"ColumnSortable",false);
                pEditorWidget = getWidget(pEditor);
                pEditorWidget.Layout.Row = 2;
                pEditorWidget.Layout.Column = 1;
                this.ParameterEditor = pEditor;
            end
        end
    end

    methods (Access = protected)
        function addTopRowWidget(this,parent) %#ok<*INUSD> 

        end

        function addBottomRowWidget(this,parent)

        end
    end
    
    %% Abstract Methods
    methods (Abstract, Access = protected)
        updateParameterData(this)
        variableValue = getCurrentVariableValue(this);
    end

    %% Private Methods
    methods (Access = private)
        
    end

    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets = qeGetAdditionalWidgets(this);
            widgets.ParameterEditor = this.ParameterEditor;
        end

        function widgets = qeGetAdditionalWidgets(this) %#ok<*MANU> 
            widgets = [];
        end
    end
end