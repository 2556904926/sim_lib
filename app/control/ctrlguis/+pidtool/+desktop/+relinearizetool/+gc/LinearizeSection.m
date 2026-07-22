classdef LinearizeSection < handle
    %LINEARIZESECTION
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties
        TPComponent
        ReLinTC
        LinearizeButton
        SnapshotTimeTextField
    end
    properties (Access = private)
        strSnapshotTime
    end
    methods
        function this = LinearizeSection(relintc)
            %LINEARIZESECTION
            
            this.TPComponent = matlab.ui.internal.toolstrip.Section(pidtool.utPIDgetStrings('scd','strLinearize'));
            this.TPComponent.Tag = 'Linearize';
            this.ReLinTC = relintc;
            this.layout();
            this.initialize();
            this.update();
        end
        function layout(this)
            %LAYOUT
            import matlab.ui.internal.toolstrip.*
            
            % Snapshot Time
            ColWidth = 100;
            col1 = this.TPComponent.addColumn('width',ColWidth);
            snapshotLabel = Label(pidtool.utPIDgetStrings('scd','strSnapshotTime'));
            col1.add(snapshotLabel);
            this.SnapshotTimeTextField = EditField('');
            this.SnapshotTimeTextField.ValueChangedFcn = @(~,~) cbSnapshotTimeTextField(this);
            col1.add(this.SnapshotTimeTextField);
            
            % Linearize Button
            col2 = this.TPComponent.addColumn();
            this.LinearizeButton = Button(pidtool.utPIDgetStrings('scd','strLinearize'),Icon.RUN_24);
            col2.add(this.LinearizeButton);

        end
        function initialize(this)
            %INITIALIZE
            
            addlistener(this.ReLinTC, 'SnapshotTime', 'PostSet', @(~,~) this.update());
            addlistener(this.LinearizeButton,'ButtonPushed', @(~,~)cbLinearizeButton(this));
        end
        function update(this)
            %UPDATE
            
            this.strSnapshotTime = sprintf('%0.3g', this.ReLinTC.SnapshotTime);
            this.SnapshotTimeTextField.Value = this.strSnapshotTime;
        end
    end
end
function cbSnapshotTimeTextField(this)
%CBSNAPSHOTTIMETEXTFIELD

pidtool.utPIDassignDataFromView(this.ReLinTC,'SnapshotTime',this.SnapshotTimeTextField,'Value', true);
end

function cbLinearizeButton(this)
%CBLINEARIZEBUTTON

this.ReLinTC.linearizeModelAtSnapshot();
end
