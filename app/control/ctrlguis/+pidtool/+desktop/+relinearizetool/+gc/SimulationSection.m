classdef SimulationSection < handle
    %SIMULATIONSECTION

    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TPComponent
        TC
        SimulationButton
        SimulationTimeTextField
    end
    properties (Access = private)
        strSimulationTime
        isRunning = false
        Listener
    end
    methods
        function this = SimulationSection(relintc)
            %SIMULATIONSECTION
            
            this.TPComponent = matlab.ui.internal.toolstrip.Section(pidtool.utPIDgetStrings('scd','strSimulation'));
            this.TPComponent.Tag = 'Simulation';
            this.TC = relintc;
            this.layout();
            this.initialize();
            this.update();
        end
        function layout(this)
            %LAYOUT
            import matlab.ui.internal.toolstrip.*
            
            % Simulation Time
            ColWidth = 100;
            col1 = this.TPComponent.addColumn('width',ColWidth);
            simLabel = Label(pidtool.utPIDgetStrings('scd','strSimulationTime'));
            col1.add(simLabel);
            this.SimulationTimeTextField = EditField('');
            this.SimulationTimeTextField.ValueChangedFcn = @(~,~) cbSimulationTimeTextField(this);
            col1.add(this.SimulationTimeTextField);
            
            % Simulation Button
            col2 = this.TPComponent.addColumn();
            this.SimulationButton = Button(pidtool.utPIDgetStrings('scd','strRunSimulation'),Icon.PLAY_24);
            col2.add(this.SimulationButton);
            
        end
        function initialize(this)
            %INITIALIZE
            
            addlistener(this.TC, 'SimulationTime', 'PostSet', @(~,~) this.update());
            this.Listener = addlistener(this.SimulationButton, 'ButtonPushed', @(~,~)cbSimulationButton(this));
            this.Listener.Recursive = 1;
        end
        function update(this)
            %UPDATE
            
            this.strSimulationTime = sprintf('%0.3g', this.TC.SimulationTime);
            this.SimulationTimeTextField.Value = this.strSimulationTime;
        end
    end
end
function cbSimulationTimeTextField(this)
%CBSIMULATIONTIMETEXTFIELD

pidtool.utPIDassignDataFromView(this.TC,'SimulationTime',this.SimulationTimeTextField,'Value', true);
end

function cbSimulationButton(this)
%CBSIMULATIONBUTTON

if false % NOTE: REDO THIS
this.TC.MessagePanel.Minimized = true;
end
if ~this.isRunning
    this.SimulationButton.Icon = matlab.ui.internal.toolstrip.Icon.STOP_24;
    this.SimulationButton.Text = pidtool.utPIDgetStrings('scd', 'strStopSim');
    drawnow % Needed for updating Icon/Text of button
    this.isRunning = true;
    str = pidtool.utPIDgetStrings('scd', 'strSimModel');
    Msg = [str,': ' this.TC.SLGateway.TopModel,' '];
    this.TC.StatusBar.reset();
    this.TC.StatusBar.showWaitBar(Msg);
    try
        Message = this.TC.simulateModel();
    catch E
        title = getString(message('Slcontrol:pidtuner:strSimError'));
        % NOTE: Can't use uialert or uiconfirm since SimulationSection has
        % no knowledge of AppContainer
        errordlg(E.message,title);
        Message = getString(message('Slcontrol:pidtuner:strSnapshotSimFailed'));
    end
    Success = isempty(Message);
    this.SimulationButton.Icon = matlab.ui.internal.toolstrip.Icon.PLAY_24;
    this.SimulationButton.Text = pidtool.utPIDgetStrings('scd', 'strRunSim');
    if Success
        msg = getString(message('Slcontrol:pidtuner:strSnapshotSimSuccessful'));
        Icon = matlab.ui.internal.toolstrip.Icon(fullfile(pidtool.getIconResourcePath('pidtuner'),'Success.png'));
        this.TC.StatusBar.setText(msg, Icon, 'west');
    else
        this.TC.StatusBar.setText(Message, 'erro', 'west')
    end
    this.TC.StatusBar.hideWaitBar;
    this.isRunning = false;
else
    try
        set_param(gcs, 'simulationcommand', 'stop');
    catch E
        disp(E.Message);
    end
    this.SimulationButton.Icon = matlab.ui.internal.toolstrip.Icon.PLAY_24;
    this.SimulationButton.Text = pidtool.utPIDgetStrings('scd', 'strRunSim');
    this.isRunning = false;
    this.TC.StatusBar.reset();
    msg = getString(message('Slcontrol:pidtuner:strSnapshotSimAborted'));
    this.TC.StatusBar.setText(msg, 'erro', 'west');
end
end
