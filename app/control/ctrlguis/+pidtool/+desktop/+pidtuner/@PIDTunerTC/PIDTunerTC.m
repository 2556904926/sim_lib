classdef PIDTunerTC < handle
    %PIDTUNERTC
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        PlantList
        ControllerList
        InputVariables
        DataSourcePlot
        ExportDialogTC
        InspectorTC
        NeedsIntegrator
        IsTunedStable
        SLGateway
        ToolType = 'MATLAB'
        AutoUpdateMode = false
        NyquistFreq
        
        AppGroup % Needed for uiconfirm/uialert
        DialogManager
    end
    
    properties(SetObservable = true)
        DesignFocus = 'balanced'
    end
    
    properties (Dependent = true)
        IsBaselineStable
    end
    
    properties
        StatusBar
    end
    
    properties(Access = private)
        PIDTuningData
        addingNewPlant = false
        selectedNewPlant = false
        makePIDFcn = @pid.make
    end
    
    methods
        function this = PIDTunerTC(plantlist, desiredtype, baselinecontroller, sg, type, appgroup)
            %PIDTUNERTC
            this.PlantList = plantlist;
            this.AppGroup = appgroup;
            if nargin >= 5
                this.ToolType = type;
            end
            desiredform = [];
            blockbc = [1 1];
            if nargin > 3
                this.SLGateway = sg;
                if ~isempty(sg)
                    addlistener(this.SLGateway, 'PIDBlockDataChanged', @(~,~)cbPIDBlockDataChanged(this));
                    desiredform = sg.PIDBlockData.Form;
                    if sg.is2DOF
                        b = this.SLGateway.PIDBlockData.b;
                        c = this.SLGateway.PIDBlockData.c;
                        blockbc = [b c];
                    end
                end
            end
            this.ControllerList = pidtool.desktop.pidtuner.tc.ControllerList(this, desiredtype, baselinecontroller, desiredform);
            this.ControllerList.setBlockBC(blockbc);
            this.InputVariables = pidtool.desktop.pidtuner.tc.InputVariables();
            this.build();
            this.DataSourcePlot = pidtool.desktop.pidtuner.tc.DataSourcePlot(this);
            
            % Add Dialog Manager
            this.DialogManager = controllib.ui.internal.dialog.DialogManager();
            this.DialogManager.attachDialogManagerToAppContainer(appgroup)

            this.ExportDialogTC = pidtool.desktop.pidtuner.tc.ExportDialogTC(this);
            addlistener(this.DataSourcePlot, 'QuickRefreshMode', 'PostSet', @(~,~) this.updateBlockParameters(true));
        end
        
        function build(this)
            %BUILD
            this.InspectorTC = this.PlantList.SelectedPlantInspectorData;
            this.setPIDTuningData();
            this.oneClick();
        end
        
        function delete(this)
            %DELETE
            delete(this.DialogManager)
        end
        
        function setPIDTuningData(this)
            %SETPIDTUNINGDATA
            
            % Desired PID characteristics
            PID = this.ControllerList.DesiredController;
            % Options
            Options = pidtuneOptions('NumUnstablePoles',this.PlantList.SelectedPlantNUP,...
                'DesignFocus',this.DesignFocus);
            % Plant data
            if isempty(this.PlantList.SelectedPlant)
                G = tf(0);
            else
                G = this.PlantList.SelectedPlant;
            end
            % PIDTuningData
            this.PIDTuningData = getPIDTuningData(G,PID,Options);
            Ts = G.Ts;
            if Ts > 0
                this.NyquistFreq = 3.14159/G.Ts;
            else
                this.NyquistFreq = realmax;
            end
            % cache PID conversion method
            switch class(PID)
                case 'pid'
                    this.makePIDFcn = @pid.make; %#ok<*MCSUP>
                case 'pid2'
                    this.makePIDFcn = @pid2.make;
                case 'pidstd'
                    this.makePIDFcn = @pidstd.make;
                case 'pidstd2'
                    this.makePIDFcn = @pidstd2.make;
            end
        end
        
        function oneClick(this)
            %ONECLICK
            PM = this.InputVariables.PM;
            % tune controller
            [PIDdata, info] = tune(this.PIDTuningData,pidtuneOptions('PhaseMargin',PM),true,this.ControllerList.fixBC);
            % convert to object form
            PID = this.makePIDFcn(PIDdata);
            PID.TimeUnit = this.PlantList.SelectedPlantTimeUnit;
            this.clearWaitBar();
            % stability information must be updated before refreshing table
            this.IsTunedStable = info.Stable;
            this.NeedsIntegrator = info.NeedsIntegrator;
            % update tuned controller and refresh parameter table
            this.ControllerList.TunedController = PID;
            this.InputVariables.setWC_(info.wc);
            this.InputVariables.resetMinMaxWC();
            if (this.addingNewPlant || this.selectedNewPlant) && isa(this.PlantList.SelectedPlant,'frd')...
                    && strcmp(this.DataSourcePlot.ActiveFigureType,'Step')
                this.setStatusText(pidtool.utPIDgetStrings('cst', 'strUseBodeWarn'), 'warn');
                this.addingNewPlant = false;
                this.selectedNewPlant = false;
                return;
            end
            if this.addingNewPlant
                this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strAddedPlantInfo',this.PlantList.SelectedPlantName),'info');
                this.addingNewPlant = false;
            elseif this.selectedNewPlant
                this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strSelectedPlantChangedInfo',this.PlantList.SelectedPlantName),'info');
                this.selectedNewPlant = false;
            else
            end
            if ~this.IsTunedStable
                this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strInitialControllerUnstable',this.PlantList.SelectedPlantName),'warning');
            elseif this.NeedsIntegrator
                this.setStatusText(ctrlMsgUtils.message('Control:design:pidtune11'),'warning');
            else
            end
        end
        
        function fastDesign(this)
            %FASTDESIGN
            this.clearStatusText(); % Clear stale status messages
            WC = this.InputVariables.WC;
            PM = this.InputVariables.PM;
            % tune controller
            [PIDdata,info] = tune(this.PIDTuningData, pidtuneOptions('PhaseMargin',PM,'CrossoverFrequency',WC),true,this.ControllerList.fixBC);
            % convert to object form
            PID = this.makePIDFcn(PIDdata);
            PID.TimeUnit = this.PlantList.SelectedPlantTimeUnit;
            % stability information must be updated before refreshing table
            this.IsTunedStable = info.Stable; 
            this.NeedsIntegrator = info.NeedsIntegrator;
            % update tuned controller and refresh parameter table
            this.ControllerList.TunedController = PID; 
            if ~this.IsTunedStable
                this.setStatusText(pidtool.utPIDgetStrings('cst','strControllerUnstable'),'warning');
            elseif this.NeedsIntegrator
                this.setStatusText(ctrlMsgUtils.message('Control:design:pidtune11'),'warning');
            end
        end
        
        function set.ControllerList(this, val)
            %SET
            this.ControllerList = val;
            addlistener(this.ControllerList, 'DesiredController', 'PostSet', @(~,~)cbDesiredControllerChanged(this));
        end
        
        function set.InputVariables(this, val)
            %SET
            this.InputVariables = val;
            addlistener(this.InputVariables,'WC', 'PostSet', @(x,y)fastDesign(this));
            addlistener(this.InputVariables,'PM', 'PostSet', @(x,y)fastDesign(this));
        end
        
        function set.PlantList(this, val)
            %SET
            this.PlantList = val;
            addlistener(this.PlantList, 'SelectedPlantIndex', 'PostSet', @this.callbackSelectedPlantIndex);
            addlistener(this.PlantList,'PlantsEvent', @this.callbackPlants);
            addlistener(this.PlantList, 'SampleTime', 'PostSet', @this.callbackSampleTime);
        end
        
        function val = get.IsBaselineStable(this)
            %GET_ISBASELINESTABLE
            G = this.PlantList.SelectedPlant;
            BCtf = tf(this.ControllerList.BaselineController);
            NUP = this.PlantList.SelectedPlantNUP;
            if ~isempty(BCtf) && G.Ts == BCtf.Ts
                if this.ControllerList.BaselineDOF == 1
                    C1 = BCtf;
                else
                    C1 = -BCtf(2); % 2-dof controller  = [C2 -C1]
                end
                val = checkNyquistStability(G*C1,-1,NUP);
            else
                val = 2;
            end
        end
        
        function set.DesignFocus(this,val)
            %SET_DESIGNFOCUS
            this.DesignFocus = val;
            this.setPIDTuningData();
            this.fastDesign();
            
            %Get translated string for status message
            switch val
                case 'balanced'
                    designFocusStr = getString(message('Control:pidtool:strDesignFocusCombo_1'));
                case 'reference-tracking'
                    designFocusStr = getString(message('Control:pidtool:strDesignFocusCombo_2'));
                case 'disturbance-rejection'
                    designFocusStr = getString(message('Control:pidtool:strDesignFocusCombo_3'));
            end
            this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strDesignFocusInfo',designFocusStr),'info');
        end
        
        function updateBlockParameters(this, auto)
            %UPDATEBLOCKPARAMETERS
            if auto
                if this.AutoUpdateMode && ~this.DataSourcePlot.QuickRefreshMode
                    this.SLGateway.setPIDBlockController(this.ControllerList.TunedController);
                end
            else
                this.SLGateway.setPIDBlockController(this.ControllerList.TunedController);
            end
        end
        
        function updateStatusBar(this)
            %UPDATESTATUSBAR
            if isempty(this.StatusBar)
                return
            else
                if ~strcmp(this.StatusBar.ParentTool, 'pidtuner')
                    this.clearStatusText();
                    this.StatusBar.ParentTool = 'pidtuner';
                end
                this.DataSourcePlot.showPIDGains();
            end
        end
        
        function clearStatusText(this, val)
            %CLEARSTATUSTEXT
            if isempty(this.StatusBar) || this.StatusBar.isWestMessageClear
                return
            else
                if nargin == 1
                    this.StatusBar.setText('',[],'west');
                elseif this.StatusBar.isWestMessageText(val)
                    this.StatusBar.setText('',[],'west');
                end
            end
        end
        
        function clearWaitBar(this)
            %CLEARWAITBAR
            if isempty(this.StatusBar)
                return
            else
                this.StatusBar.hideWaitBar();
            end
        end
        
        function setStatusText(this, text, type, varargin)
            %SETSTATUSTEXT
            if isempty(this.StatusBar)
                return
            elseif isempty(text)
                reset(this.StatusBar);
            else
                % Check if priority of messages are to be considered
                if nargin==4
                    enPriorityCheck = varargin{1};
                else
                    enPriorityCheck = false;
                end
                % Check that new message is of higher priority than existing
                % message
                currMsgType = this.StatusBar.WestIconType;
                currMsgPriority = sum(strcmp({'info','warning','error'},currMsgType).* [1 2 4]);
                newMsgPriority = sum(strcmp({'info','warning','error'},type).* [1 2 4]);
                if ~enPriorityCheck || ( newMsgPriority >= currMsgPriority )
                    this.StatusBar.setText(text,type,'west');
                end
            end
        end
        
        function callbackSelectedPlantIndex(this, ~,~)
            %CALLBACKSELECTEDPLANTINDEX
            this.DataSourcePlot.handleSelectedPlantIndexEvent();
            this.selectedNewPlant = true;
            this.build();
            this.DataSourcePlot.update(true, true); % update controller data
            this.DataSourcePlot.QuickRefreshMode = false;
            this.hideBaselineResponseIfUnstable();
        end
        
        function callbackPlants(this, ~,evnt)
            %CALLBACKPLANTS
            this.DataSourcePlot.handlePlantsEvent(evnt);
            this.addingNewPlant = true;
        end
        
        function callbackSampleTime(this, ~,~)
            %CALLBACKSAMPLETIME
            this.DataSourcePlot.updatePlantsInfo();
            this.selectedNewPlant = false;
            this.addingNewPlant = false;
            this.build();
        end
        
        function hideBaselineResponseIfUnstable(this)
            %HIDEBASELINERESPONSEIFUNSTABLE
            this.PlantList.SelectedPlantName;
            % Other error messages change display settings of the PID Tuner and should not be overwritten
            if ~isempty(this.StatusBar)
                isMsgFRD = strcmp(pidtool.utPIDgetStrings('cst','strUseBodeWarn'),this.StatusBar.WestMessage);
                isMsgImproper = strcmp(pidtool.utPIDgetStrings('cst','tunerdlg_improperbase_warning'),this.StatusBar.WestMessage) || ...
                                strcmp(pidtool.utPIDgetStrings('scd','tunerdlg_improperblock_warning'),this.StatusBar.WestMessage);
            else
                isMsgFRD = false;
                isMsgImproper = false;
            end
            if this.DataSourcePlot.hasBaseline && ~this.IsBaselineStable && ...
                    ~(isMsgFRD || isMsgImproper) && strcmp(this.DataSourcePlot.ActiveFigureType,'Step')
                this.DataSourcePlot.showBaseline = false;
                    if strcmp(this.ToolType, 'MATLAB')
                        this.setStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_unstablebase_warning'),'warning');
                    else
                        this.setStatusText(pidtool.utPIDgetStrings('scd','tunerdlg_unstableblock_warning'),'warning');
                    end
            else
                %Do Nothing and use the default, user selected, setting
            end
        end
    end
end

function cbPIDBlockDataChanged(this)
% Callback for PID block changes:
% 1. Update plant sample time
% 2. Update baseline controller
% 3. Update desired form and type of tuned controller
% 4. Update any changes to b,c if fixed b,c are desired

this.PlantList.SampleTime = this.SLGateway.PIDBlockData.CompiledSampleTime;
this.ControllerList.BaselineController = this.SLGateway.PIDBlockController;
if this.SLGateway.is2DOF
    b = this.SLGateway.PIDBlockData.b;
    c = this.SLGateway.PIDBlockData.c;
    this.ControllerList.setBlockBC([b c]);
end
this.ControllerList.DesiredForm = this.SLGateway.PIDBlockData.Form;
this.ControllerList.DesiredTypeStr = this.SLGateway.PIDBlockData.Controller;
end

function cbDesiredControllerChanged(this)
%CBDESIREDCONTROLLERCHANGED
this.setPIDTuningData();
this.fastDesign();
end
