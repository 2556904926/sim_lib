classdef InputSection < handle
    %INPUTSECTION
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties
        TPComponent
        ReLinTC
        InputLevelTextField
    end
    properties (Access = private)
        strInputLevel
    end
    methods
        function this = InputSection(relintc)
            %INPUTSECTION
            
            this.TPComponent = matlab.ui.internal.toolstrip.Section('Input');
            this.TPComponent.Tag = 'Input';
            this.ReLinTC = relintc;
            this.layout();
            this.initialize();
            this.update();
        end
        function layout(this)
            %LAYOUT
            import matlab.ui.internal.toolstrip.*
            ColWidth = 60;
            col = this.TPComponent.addColumn('width',ColWidth);
            inputLabel = Label('Input Level:');
            col.add(inputLabel);
            this.InputLevelTextField = EditField('');
            this.InputLevelTextField.ValueChangedFcn = @(~,~) cbInputLevelTextField(this);
            col.add(this.InputLevelTextField);
        end
        function initialize(this)
            %INITIALIZE
            
            addlistener(this.ReLinTC, 'InputLevel', 'PostSet', @(~,~) this.update());
        end
        function update(this)
            %UPDATE
            
            this.strInputLevel = sprintf('%0.3g', this.ReLinTC.InputLevel);
            this.InputLevelTextField.Value = this.strInputLevel;
        end
    end
end
function cbInputLevelTextField(this)
%CBINPUTLEVELTEXTFIELD

pidtool.utPIDassignDataFromView(this.ReLinTC,'InputLevel',this.InputLevelTextField,'Value',false);
end
