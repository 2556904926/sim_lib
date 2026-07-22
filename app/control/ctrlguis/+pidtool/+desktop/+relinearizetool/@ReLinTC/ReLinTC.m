classdef ReLinTC < handle
    %
    
    % Author(s): Baljeet Singh 24-Sep-2013
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        StatusBar
        MessagePanel
    end
    properties (SetObservable, Dependent, AbortSet)
        SnapshotTime
        SimulationTime
    end
    properties (SetObservable)
        Type
        hPlot
        InputLevel = 0
        SampleTime = 0.1
        IODataSource
        SLGateway
    end
    properties (Dependent = true)
        InputSignal
    end
    properties (Access = private)
        Input
        SnapshotTime_ = 8
        SimulationTime_ = 10
        StreamDataToPlot = false;
        showMsgPanel = true
    end
    events
        CreatedNewPlant
    end
    methods
        function this = ReLinTC(sg, type, statusbar)
            %RELINTC constructor
            %
            
            this.SLGateway = sg;
            addlistener(this.SLGateway, 'PIDBlockDataChanged', @(~,~)this.updateSampleTime);
            this.updateSampleTime();
            this.Type = type;
            this.SimulationTime_ = sg.ModelStopTime;
            this.SnapshotTime_ = sg.ModelStopTime/2;
            if this.SLGateway.is2DOF
                ystr = getString(message('Control:pidtool:strOutput'));
                ystr = sprintf('%s (y)', ystr);
            else
                ystr = getString(message('Control:pidtool:strError'));
                ystr = sprintf('%s (e)', ystr);
            end
            t = timeseries(0);
            t.Name = ystr;
            S = struct('Input', [], 'Output', t);
            Data = pidtool.desktop.relinearizetool.InputOutputData(S);
            this.IODataSource = iodatapack.IODataSource(Data, 'Name', 'Simulation Data');
            
            this.Input = pidtool.desktop.relinearizetool.PulseTrain([0 this.InputLevel; this.SimulationTime this.InputLevel]);
            addlistener(this.Input, 'StateChanged',@(~,~)this.updateInputSignalView());
            
            if nargin > 2
                this.StatusBar = statusbar;
            end
            
        end
        
        function val = get.InputSignal(this)
            val = getTimeSeries(this.Input, this.InputLevel, 0, 0, this.SampleTime, this.SimulationTime);
        end
        function Message = simulateModel(this)
            Message = '';
            assert(~isempty(this.SLGateway),'No model is available for simulation')
            if this.StreamDataToPlot
                if strcmp(this.Type, 'openloop')
                    tsout = this.SLGateway.generateIOData(this.InputSignal, this.hPlot);
                else
                    tsout = this.SLGateway.simulateModel(this.InputSignal, this.hPlot);
                end
            else
                if strcmp(this.Type, 'openloop')
                    tsout = this.SLGateway.generateIOData(this.InputSignal);
                else
                    tsout = this.SLGateway.simulateModel(this.InputSignal);
                end
            end
            outname = this.hPlot.Waves(1).DataSrc.IOData.getOutputName;
            tout = timeseries(tsout.Data, tsout.Time, 'Name', outname);
            r = this.hPlot.Waves(1);
            if (this.SimulationTime-tout.Time(end)) > this.SampleTime
                Message = getString(message('Slcontrol:pidtuner:strSnapshotSimAborted'));
                return
            end
            r.DataSrc.IOData.setSignalData(outname,tout);
            r.Visible = 'on';
            this.hPlot.draw();
            this.hPlot.AxesGrid.updatelims('manual','auto');
        end
        function linearizeModelAtSnapshot(this)
            if strcmp(this.Type, 'openloop')
                error('Not implemented yet')
            else
                this.SLGateway.SnapshotTime = this.SnapshotTime;
            end
        end
        function set.hPlot(this, val)
            this.hPlot = val;
            this.updateInputSignalView();
            this.addMessagePanel();
        end
        function set.InputLevel(this, val)
            this.InputLevel = val;
            this.updateInput();
        end
        function set.SimulationTime(this, val)
            this.SimulationTime_ = val;
            if val < this.SnapshotTime_
                this.SnapshotTime = val;
            end
            this.updateSampleTime();
            this.updateInput();
        end
        function val = get.SimulationTime(this)
            val = this.SimulationTime_;
        end
        function updateInput(this)
            this.Input.BreakPoints = [0 this.InputLevel; this.SimulationTime this.InputLevel];
        end
        function updateInputSignalView(this)
            tfinal = this.InputSignal.Time(end);
            if ~isempty(this.hPlot)
                ax = this.hPlot.AxesGrid.getaxes;
                set(ax(1),'XLim',[0 tfinal]);
            end
        end
        function val = get.SnapshotTime(this)
            val = this.SnapshotTime_;
        end
        function set.SnapshotTime(this, val)
            this.SnapshotTime_ = val;
            if val > this.SimulationTime
                this.SimulationTime = val;
            end
        end
        
        function updateStatusBar(this)
            if isempty(this.StatusBar)
                return
            else
                if ~strcmp(this.StatusBar.ParentTool, 'relintool')
                    this.StatusBar.reset;
                    this.StatusBar.ParentTool = 'relintool';
                end
            end
        end
        function updateSampleTime(this)
            Ts = this.SLGateway.PIDBlockData.CompiledSampleTime;
            if Ts == 0
                this.SampleTime = this.SLGateway.ModelStopTime/100;
            else
                this.SampleTime = Ts;
            end
        end
        function addMessagePanel(this)
            if false %% NOTE: DISABLE MESSAGE PANEL
                if this.SLGateway.is2DOF
                    txt = ctrlMsgUtils.message('Slcontrol:pidtuner:strCLReLinInfo2DOF');
                    pic = fullfile(pidtool.getIconResourcePath('pidtuner'), 'CLReLinearization2DOF.png');
                else
                    txt = ctrlMsgUtils.message('Slcontrol:pidtuner:strCLReLinInfo1DOF');
                    pic = fullfile(pidtool.getIconResourcePath('pidtuner'), 'CLReLinearization1DOF.png');
                end
                f = this.hPlot.AxesGrid.Parent;
                this.MessagePanel = ctrluis.toolstrip.MessagePanel(f, txt, pic);
                this.MessagePanel.Visible = true;
                if this.showMsgPanel
                    this.MessagePanel.Minimized = false;
                else
                    this.MessagePanel.Minimized = true;
                end
            end
        end
    end
end


