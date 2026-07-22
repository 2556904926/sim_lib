classdef SimulinkGateway < handle
    %SIMULINKGATEWAY

    % Copyright 2013-2021 The MathWorks, Inc.

    properties
        TopModel
        PIDModel
        PIDBlockHandle
        LinearizedPlant
        InspectorData
        PIDBlockData
        ModelStopTime
        is2DOF
        StatusBar
    end
    properties(Dependent = true)
        I0
        u0
    end
    properties (Dependent = true, SetObservable = true)
        PIDBlockName
        PIDBlockController
    end
    properties (Dependent = true, SetAccess = public, GetAccess = private)
        SnapshotTime
        OperatingPoint
    end
    properties (Access = private)
        streamingDataToPlot = false
        SimStatusListener
        PIDBlockInputOutput
        PIDBlockInputOutputClosedLoop
        ObserevedOutputs
        AxesHandle
        Line
        RTO
        OutputsListener
        TData
        YData
        Ymin = 0
        Ymax = 0
        PlotHandle
        u0_
        WaitBar
    end
    events
        PIDBlockDataChanged
        ModelLinearizationChanged
    end
    methods
        function this = SimulinkGateway(GCBH)
            %SIMULINKGATEWAY
            %====================================(Block Dialog Checks)
            % check if there is any unapplied change in the block dialog
            [HasUnappliedChanges, ~] = slctrlguis.pidtuner.utPIDhasUnappliedChanges(GCBH);
            if HasUnappliedChanges
                uiwait(errordlg(pidtool.utPIDgetStrings('scd','tunerdlg_unappliedchanges'),...
                    pidtool.utPIDgetStrings('cst','errordlgtitle'),'modal'));
                error(message('Slcontrol:pidtuner:tunerdlg_unappliedchanges'))
            end
            if ~any(strcmp(get(GCBH,'MaskType'),{'PID 1dof','PID 2dof'}))
                uiwait(errordlg(pidtool.utPIDgetStrings('scd','tunerdlg_blktypeerror'),...
                    pidtool.utPIDgetStrings('cst','errordlgtitle'),'modal'));
                error(message('Slcontrol:pidtuner:tunerdlg_blktypeerror'))
            end
            %==========================================(Find the Right Model)
            this.PIDBlockHandle = GCBH;
            this.is2DOF = strcmp(get_param(GCBH,'MaskType'), 'PID 2dof');
            this.PIDModel = get_param(bdroot(GCBH),'Name');
            this.TopModel = slctrlguis.util.utilGetTopLevelModel(GCBH,1,this.PIDBlockName,this.PIDModel);

            try
                this.ModelStopTime = slResolve(get_param(this.TopModel,'StopTime'),this.TopModel);
            catch
                this.ModelStopTime = 10;
            end
            %=====================================(PID Block I/Os)
            input_blk = getfullname(GCBH);
            input_point = linio(input_blk,1,'in','on');
            output_port = find_system(GCBH,'SearchDepth',1,'LookUnderMasks','all','FollowLinks','on','BlockType','Inport');
            if strcmp(get(GCBH,'MaskType'),'PID 1dof')
                output_blk = getfullname(output_port(1));
                output_point = linio(output_blk,1,'out','on');
                io = [input_point; output_point];
                for ct=1:length(output_port)-1
                    output_blk = getfullname(output_port(ct+1));
                    output_point = linio(output_blk,1,'none','on');
                    io = [io; output_point]; %#ok<*AGROW>
                end
            else
                output_blk_r = getfullname(output_port(1));
                output_blk_y = getfullname(output_port(2));
                output_point_r = linio(output_blk_r,1,'none','on');
                output_point_y = linio(output_blk_y,1,'out','on');
                io = [input_point; output_point_y; output_point_r];
                for ct=1:length(output_port)-2
                    output_blk = getfullname(output_port(ct+2));
                    output_point = linio(output_blk,1,'none','on');
                    io = [io; output_point];
                end
            end
            this.PIDBlockInputOutput = io;
            iocl = copy(io);
            iocl(1).Type = 'input';
            iocl(2).Type = 'output';
            this.PIDBlockInputOutputClosedLoop = iocl;
            %==============(Linearize)
            mdl = this.TopModel;
            cmgr = slcontrollib.internal.utils.getCompilationMgr(mdl);
            pmgr = getParameterManager(cmgr);

            % check if FR is on
            isfastrestarton = isFastRestartOn(cmgr);

            % turn fast restart on
            try
                if ~isfastrestarton
                    % turn fast restart on
                    fastRestartOn(cmgr,io,[],[]);
                    % g2592904 make sure fastRestart is turned off in case of
                    % compilation errors
                    cln1 = onCleanup(@() fastRestartOff(cmgr));
                end
                % the model may already be compiled if the user turned on fast
                % restart
                if ~isCompiled(pmgr)
                    % compile the model
                    compile(pmgr,'lincompile');
                end
                success = true;
            catch ME
                slcontrollib.internal.utils.nagctlr(this.TopModel,...
                    getString(message('SLControllib:general:SimulinkControlDesignProduct')),...
                    getString(message('SLControllib:general:SCDLinearization')),ME);
                success = false;
            end
            if success
                this.updatePIDBlockData(true);
                this.updateLinearizationData();
                %=============(listener to activate RTO)
                hRoot = get_param(this.TopModel,'Object');
                this.SimStatusListener = Simulink.listener(hRoot, 'StartEvent',@(~,~)activateRTO(this));
            end
        end
        function updatePIDBlockData(this, compiled)
            %UPDATEPIDBLOCKDATA
            [s.Controller, s.Form, s.TimeDomain, s.BlockSampleTime, s.IntegratorMethod, s.FilterMethod,...
                s.P, s.I, s.D, s.N, s.b, s.c] = slctrlguis.pidtuner.utPIDgetBlockParameters(this.PIDBlockHandle);
            if strcmpi(s.TimeDomain,'continuous-time')
                s.CompiledSampleTime = 0;
            else
                if s.BlockSampleTime==-1
                    % if pid block sample time is inherited (-1), need to compile
                    if ~compiled
                        try
                            s.CompiledSampleTime = slcontrollib.internal.utils.fevalCompiled(this.TopModel, @localEvalCompiled, this);
                        catch ME
                            slcontrollib.internal.utils.nagctlr(this.TopModel,...
                                getString(message('SLControllib:general:SimulinkControlDesignProduct')),...
                                getString(message('SLControllib:general:SCDLinearization')),ME);
                            s.CompiledSampleTime = 0;
                        end
                    else
                        s.CompiledSampleTime = localEvalCompiled(this);
                    end
                else
                    s.CompiledSampleTime = s.BlockSampleTime;
                end
            end
            this.PIDBlockData = s;
            notify(this, 'PIDBlockDataChanged');
        end
        function success = updateLinearizationData(this,input)
            %UPDATELINEARIZATIONDATA

            opt = linearizeOptions('UseExactDelayModel','on','SampleTime',this.PIDBlockData.CompiledSampleTime);
            mdl = this.TopModel;
            io = this.PIDBlockInputOutput;
            this.postLinearizationMessage;
            try
                if nargin == 1
                    % Default linearization at t=0
                    G = linearize(mdl,io,opt);
                elseif all(isa(input,'double'))
                    % Snapshot linearization
                    G = linearize(mdl,input,io,opt);
                else
                    % Operating point linearization
                    G = linearize(mdl,input,io,opt);
                end
                % if the snapshot linearizations could not be reached,
                % throw an error g1533143
                if iscell(G) && isempty(G)
                    % Note, the new linearization engine will not generate
                    % empty linearization results if the snapshot time
                    % cannot be reached.
                    error(message('Slcontrol:pidtuner:tunerdlg_snapshoterror',num2str(input)))
                end
                if strcmp(get(this.PIDBlockHandle,'MaskType'),'PID 1dof')
                    G = -G;
                end
                if isempty(G)
                    error(message('Slcontrol:pidtuner:tunerdlg_planterror'))
                end
                if ~issiso(G)
                    error(message('Slcontrol:pidtuner:tunerdlg_sisoerror'))
                end
                if isstatic(G) && dcgain(G)==0
                    error(message('Slcontrol:pidtuner:tunerdlg_planterror'))
                end
                if G.Ts<0
                    error(message('Slcontrol:pidtuner:tunerdlg_tserror'))
                end
                this.clearLinearizationMessage;
                this.InspectorData = slctrlguis.lintool.dialogs.results.LinInspectorTC(this.TopModel, '', '',[],[]);
                success = true;
            catch ME
                G = zpk([],[],0);
                err = [];
                switch ME.identifier
                    case 'Slcontrol:pidtuner:tunerdlg_planterror'
                        this.InspectorData = slctrlguis.lintool.dialogs.results.LinInspectorTC(this.TopModel,'','',[],[]);
                    case 'Slcontrol:sllinearizer:ModelSimTerminatesBeforeSnapshotCapture'
                        err = MException(message('Slcontrol:pidtuner:tunerdlg_snapshoterror',num2str(input)));
                    otherwise
                        err = ME;
                end
                if ~isempty(err)
                    slcontrollib.internal.utils.nagctlr(this.TopModel,...
                        getString(message('SLControllib:general:SimulinkControlDesignProduct')),...
                        getString(message('SLControllib:general:SCDLinearization')),err);
                    this.InspectorData = nan;
                end
                this.clearLinearizationMessage;
                success = false;
            end
            this.LinearizedPlant = G;
            notify(this, 'ModelLinearizationChanged');
        end
        %=====================================(Snapshot Linearization)
        function set.SnapshotTime(this, val)
            %SET_SNAPSHOTTIME
            this.updateLinearizationData(val);
        end
        function val = get.SnapshotTime(this) %#ok<*MANU>
            %GET_SNAPSHOTTIME
            val = [];
        end
        %===============================================================================(Operating Point based Linearization)
        function set.OperatingPoint(this, val)
            %SET_OPERATINGPOINT
            this.updateLinearizationData(val);
        end
        function val = get.OperatingPoint(this)
            %GET_OPERATINGPOINT
            val = [];
        end
        %===========================(PID Controller Object -> PID Block)
        function setPIDBlockController(this,C)
            %SET_PIDBLOCKCONTROLLER
            [P, I, D, N, b, c] = this.getPIDNfromPIDObj(C);
            [HasUnappliedChanges, hDialog] = slctrlguis.pidtuner.utPIDhasUnappliedChanges(this.PIDBlockHandle);
            [BlockType, BlockForm, BlockTimeDomain, BlockSampleTime, BlockIntMethod, BlockDerMethod] ...
                = slctrlguis.pidtuner.utPIDgetBlockParameters(this.PIDBlockHandle);
            if ~strcmpi(BlockType,this.PIDBlockData.Controller) || ...
                    ~strcmpi(BlockForm,this.PIDBlockData.Form) || ...
                    ~((strcmpi(BlockTimeDomain,'continuous-time') && this.PIDBlockData.CompiledSampleTime==0) ||...
                    (strcmpi(BlockTimeDomain,'discrete-time') && (this.PIDBlockData.CompiledSampleTime==BlockSampleTime ||...
                    BlockSampleTime==-1))) || ...
                    ~strcmpi(BlockIntMethod,this.PIDBlockData.IntegratorMethod) || ...
                    ~strcmpi(BlockDerMethod,this.PIDBlockData.FilterMethod)
                if this.PIDBlockData.CompiledSampleTime == 0
                    DataSrcTimeDomain = 'continuous-time';
                else
                    DataSrcTimeDomain = 'discrete-time';
                end
                question0 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question0');
                question1 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question1');
                question2 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question2');
                question3 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question3');
                question4 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question4');
                question5 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question5');
                question6 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question6');
                question7 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question7');
                question8 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question8');
                question9 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question9');
                question10 = pidtool.utPIDgetStrings('scd','tunerdlg_mask_question10');
                titlestr = pidtool.utPIDgetStrings('scd','tunerdlg_mask_title');
                uiwait(errordlg(sprintf('%s\n\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n\n%s',...
                    question0,...
                    question1,...
                    [question5 ' ',strrep(this.PIDBlockData.Controller,'f','')],...
                    [question6 ' ',this.PIDBlockData.Form],...
                    [question7 ' ',DataSrcTimeDomain],...
                    [question8 ' ',num2str(this.PIDBlockData.CompiledSampleTime)],...
                    [question9 ' ',this.PIDBlockData.IntegratorMethod],...
                    [question10 ' ',this.PIDBlockData.FilterMethod],...
                    question2,...
                    [question5 ' ',strrep(BlockType,'f','')],...
                    [question6 ' ',BlockForm],...
                    [question7 ' ',BlockTimeDomain],...
                    [question8 ' ',num2str(BlockSampleTime)],...
                    [question9 ' ',BlockIntMethod],...
                    [question10 ' ',BlockDerMethod],...
                    question3,...
                    question4),titlestr,'modal'));
                return
            end
            switch lower(BlockType)
                case 'p'
                    params = {'P'}; strVal = {mat2str(P)};
                case 'i'
                    params = {'I'}; strVal = {mat2str(I)};
                case 'pi'
                    params = {'P','I'}; strVal = {mat2str(P),mat2str(I)};
                case 'pdf'
                    params = {'P','D','N'}; strVal = {mat2str(P),mat2str(D),mat2str(N)};
                case 'pidf'
                    params = {'P','I','D','N'}; strVal = {mat2str(P),mat2str(I),mat2str(D),mat2str(N)};
                case 'pd'
                    params = {'P','D'}; strVal = {mat2str(P),mat2str(D)};
                case 'pid'
                    params = {'P','I','D'}; strVal = {mat2str(P),mat2str(I),mat2str(D)};
                case 'pi2'
                    params = {'P','I','b'}; strVal = {mat2str(P),mat2str(I),mat2str(b)};
                case 'pd2'
                    params = {'P','D','b','c'}; strVal = {mat2str(P),mat2str(D),mat2str(b),mat2str(c)};
                case 'pid2'
                    params = {'P','I','D','b','c'}; strVal = {mat2str(P),mat2str(I),mat2str(D),mat2str(b),mat2str(c)};
                case 'pdf2'
                    params = {'P','D','N','b','c'}; strVal = {mat2str(P),mat2str(D),mat2str(N),mat2str(b),mat2str(c)};
                case 'pidf2'
                    params = {'P','I','D','N','b','c'}; strVal = {mat2str(P),mat2str(I),mat2str(D),mat2str(N),mat2str(b),mat2str(c)};
            end

            slctrlguis.updateBlockParameter(this.PIDBlockHandle,params,strVal);
            if HasUnappliedChanges
                this.setStatusText(pidtool.utPIDgetStrings('scd','tunerdlg_apply_warning'),'warning');
            else
                if ~isempty(hDialog)
                    hDialog.apply;
                    this.setStatusText(pidtool.utPIDgetStrings('scd','tunerdlg_apply_info'),'info');
                end
                this.updatePIDBlockData(true);
            end
        end
        %===============================(PID Block -> PID Controller Object)
        function val = get.PIDBlockController(this)
            %GET_PIDBLOCKCONTROLLER
            blockdata = this.PIDBlockData;
            % Update Controller field if 2DOF
            blockdata.Controller = strrep(blockdata.Controller,'2','');
            % Set N to inf if controller type is "pid" (g1522700, revisit)
            if strcmpi(blockdata.Controller,'pid')
                blockdata.N = inf;
            end
            [~,~,C] = utPID1dof_getCfreeCfixedfromPIDN(blockdata.P,...
                blockdata.I,...
                blockdata.D,...
                blockdata.N,...
                blockdata.CompiledSampleTime,...
                blockdata);
            try % try getting controller as @pid, @pidstd, @pid2 or @pidstd2
                if strcmpi(blockdata.Form, 'parallel')
                    val = pid(C,'IF',blockdata.IntegratorMethod(1),'DF',blockdata.FilterMethod(1));
                else
                    val = pidstd(C,'IF',blockdata.IntegratorMethod(1),'DF',blockdata.FilterMethod(1));
                end
                if this.is2DOF
                    val = make2DOF(val,blockdata.b,blockdata.c);
                end
            catch % controller cannot be converted to object form
                if this.is2DOF
                    [~,~,C2] = utPID1dof_getCfreeCfixedfromPIDN(blockdata.P*blockdata.b,...
                        blockdata.I,...
                        blockdata.D*blockdata.c,...
                        blockdata.N,...
                        blockdata.CompiledSampleTime,...
                        blockdata);
                    val = [C2 -C];
                else
                    val = C;
                end
            end
        end
        function val = getCFFfromPIDBlock(this)
            blockdata = this.PIDBlockData;
            % Set N to inf if controller type is "pid" (g1522700, revisit)
            if strcmpi(blockdata.Controller,'pid')
                blockdata.N = inf;
            end
            [~,~,val] = utPID1dof_getCfreeCfixedfromPIDN(blockdata.P*blockdata.b,...
                blockdata.I,...
                blockdata.D*blockdata.c,...
                blockdata.N,...
                blockdata.CompiledSampleTime,...
                blockdata);
            val.TimeUnit = 'seconds';
            val.InputName = 'r';
            val.OutputName = 'uff';
        end
        %==============(Open-Loop Simulation with inputsignal -> output data)
        function val = generateIOData(this, inputsignal, hplot)
            %GENERATEIODATA
            tfinal = inputsignal.Time(end);
            if nargin == 3
                this.streamingDataToPlot = true;
                this.TData = [];
                this.YData = [];
                this.PlotHandle = hplot;
                this.AxesHandle = this.PlotHandle.AxesGrid.getaxes;
                set(this.AxesHandle(1),'XLim',[0 tfinal]);
                this.Line = this.PlotHandle.Waves(1).View.Curves(1);
            else
                this.streamingDataToPlot = false;
            end
            Was = warning('off');
            try
                [~,tsout] = frestimate(this.TopModel,this.PIDBlockInputOutput,this.OperatingPoint,inputsignal - this.u0);
            catch E
                warning(Was)
                if strcmp(E.identifier,'Slcontrol:frest:FrestimateInterrupt')
                    tsout{1} = [];
                else
                    throw(E)
                end
            end
            warning(Was)
            val = tsout{1};
            if isempty(val)
                if ~isempty(this.PlotHandle)
                    tgrid = this.TData;
                    inftimes = isinf(tgrid);
                    tgrid(inftimes) = [];
                    yout = this.YData;
                    yout(inftimes) = [];
                    tfinal = tgrid(end);
                    tsampled = inputsignal.Time(inputsignal.Time <= tfinal);
                    ysampled = interp1(tgrid, yout, tsampled, 'nearest');
                    val = timeseries(ysampled, tsampled);
                else
                    val = timeseries(0, 0, 'Name', 'ModelResponse');
                end
            end
            this.streamingDataToPlot = false;
            this.PlotHandle = [];
        end
        %====================(Closed-Loop Simulation -> output data)
        function out = simulateModel(this, inputsignal, hplot)
            %GENERATEIODATA
            tfinal = inputsignal.Time(end);
            if nargin == 3
                this.streamingDataToPlot = true;
                this.TData = [];
                this.YData = [];
                this.PlotHandle = hplot;
                this.AxesHandle = this.PlotHandle.AxesGrid.getaxes;
                set(this.AxesHandle(1),'XLim',[0 tfinal]);
                this.Line = this.PlotHandle.Waves(1).View.Curves(1);
            else
                this.streamingDataToPlot = false;
            end
            % sim(this.TopModel,'StopTime', num2str(tfinal));
            Was = warning('off');
            try
                [~,tsout] = frestimate(this.TopModel,this.PIDBlockInputOutputClosedLoop,0*inputsignal);
            catch E
                warning(Was)
                if strcmp(E.identifier,'Slcontrol:frest:FrestimateInterrupt')
                    tsout{1} = [];
                else
                    throw(E)
                end
            end
            warning(Was)
            out = tsout{1};
            this.streamingDataToPlot = false;
            if isempty(out)
                if ~isempty(this.PlotHandle)
                    out = timeseries(this.YData, this.TData);
                else
                    out = timeseries(0, 0);
                end
            end
            this.PlotHandle = [];
        end
        %===========(Update SimulinkGateway state for Block Dialog changes)
        function update(this)
            % If there is any unapplied change in the block dialog, stop
            if slctrlguis.pidtuner.utPIDhasUnappliedChanges(this.PIDBlockHandle)
                uiwait(errordlg(pidtool.utPIDgetStrings('scd','tunerdlg_unappliedchanges'),...
                    pidtool.utPIDgetStrings('cst','errordlgtitle'),'modal'));
                return;
            end
            % Get current block parameters
            [BlockType, BlockForm, BlockTimeDomain, BlockSampleTime, BlockIntMethod, BlockDerMethod, ...
                BlockP_Blk, BlockI_Blk, BlockD_Blk, BlockN_Blk, Blockb_Blk, Blockc_Blk] ...
                = slctrlguis.pidtuner.utPIDgetBlockParameters(this.PIDBlockHandle);
            % If PID configuration changes in the block, redesign
            if ~strcmpi(BlockType,this.PIDBlockData.Controller) || ...
                    ~strcmpi(BlockForm,this.PIDBlockData.Form) || ...
                    ~((strcmpi(BlockTimeDomain,'continuous-time') && this.PIDBlockData.CompiledSampleTime==0) ||...
                    (strcmpi(BlockTimeDomain,'discrete-time') && this.PIDBlockData.CompiledSampleTime==BlockSampleTime)) ||...
                    ~strcmpi(BlockIntMethod,this.PIDBlockData.IntegratorMethod) || ...
                    ~strcmpi(BlockDerMethod,this.PIDBlockData.FilterMethod)
                % set sample time if necessary
                this.updateLinearizationData();
                this.updatePIDBlockData(true);
                % Else if controller gains change, refresh block response
            elseif BlockP_Blk~=this.PIDBlockData.P || ...
                    BlockI_Blk~=this.PIDBlockData.I || ...
                    BlockD_Blk~=this.PIDBlockData.D || ...
                    BlockN_Blk~=this.PIDBlockData.N || ...
                    Blockb_Blk~=this.PIDBlockData.b || ...
                    Blockc_Blk~=this.PIDBlockData.c
                this.updatePIDBlockData(false);
                this.setStatusText(pidtool.utPIDgetStrings('scd','tunerdlg_newgains_info'),'info');
            end
            this.u0_ = [];
        end
        %=====================================(Helper Functions)
        function val = get.PIDBlockName(this)
            %GET_PIDBLOCKNAME
            val = get_param(this.PIDBlockHandle,'Name');
        end
        function ctrlstruct = getCtrlStruct(this)
            %GETCTRLSTRUCT
            s = this.PIDBlockData;
            ctrlstruct = struct('Controller',s.Controller,...
                'Form',s.Form,...
                'IntegratorMethod',s.IntegratorMethod,...
                'FilterMethod',s.FilterMethod);
            if s.CompiledSampleTime == 0
                ctrlstruct.TimeDomain = 'Continuous-time';
            else
                ctrlstruct.TimeDomain = 'Discrete-time';
            end
        end
        function val = get.I0(this)
            try
                val = slResolve(get_param(this.PIDBlockHandle,'InitialConditionForIntegrator'),this.TopModel);
            catch
                val = 0;
            end
        end
        function setStatusText(this, text, type)
            if isempty(this.StatusBar)
                return
            elseif ~isempty(text)
                this.StatusBar.setText(text,type,'west');
            else
                reset(this.StatusBar);
            end
        end
        function val = get.u0(this)
            val = this.u0_;
            if isempty(val)
                val = getSignalLevel(this.PIDBlockHandle,1);
            end
        end
        function [P, I, D, N, b, c] = getPIDNfromPIDBlock(this)
            data = this.PIDBlockData;
            P = data.P;
            I = data.I;
            D = data.D;
            N = data.N;
            b = data.b;
            c = data.c;
        end
        function postLinearizationMessage(this)
            if isempty(this.StatusBar)
                this.WaitBar = waitbar(0.5,pidtool.utPIDgetStrings('scd','tunerdlg_wb_str1'),...
                    'Name',pidtool.utPIDgetStrings('scd','importplantdlg_title'));
            else
                this.StatusBar.showWaitBar(pidtool.utPIDgetStrings('scd','tunerdlg_wb_str1'));
            end
        end
        function clearLinearizationMessage(this)
            if ~isempty(this.WaitBar)
                closewb(this.WaitBar);
            end
            if ~isempty(this.StatusBar)
                this.StatusBar.hideWaitBar;
            end
        end
    end
    methods (Static = true)
        function [P, I, D, N, b, c] = getPIDNfromPIDObj(C)
            %GETPIDNFROMPIDOBJ
            b = 1; c = 1;
            if isa(C,'pid') || isa(C,'pid2') % parallel forms
                P = C.Kp;
                I = C.Ki;
                D = C.Kd;
                N = 1/C.Tf;
            else % standard forms
                P = C.Kp;
                I = 1/C.Ti;
                D = C.Td;
                N = C.N/C.Td;
            end

            if isa(C,'pid2') || isa(C,'pidstd2') % 2-dof
                b = C.b;
                c = C.c;
            end

            if D==0
                N = 100;
            end
        end
    end
end
%====================(Streaming data during simulation)
function activateRTO(this)
%ACTIVATERTO
if this.streamingDataToPlot
    PC = get_param(this.PIDBlockHandle, 'PortConnectivity');
    srcblk = getfullname(PC(1).SrcBlock);
    this.RTO = get_param(srcblk, 'RuntimeObject');
    this.OutputsListener = add_exec_event_listener(this.RTO, 'PostOutputs', @(src,evnt)blockOutputCallback(this));
end
end
function blockOutputCallback(this)
%BLOCKOUTPUTCALLBACK
if this.RTO.IsMajorTimeStep
    this.TData = [this.TData ; this.RTO.CurrentTime];
    this.YData = [this.YData ; this.RTO.OutputPort(1).Data];
    set(this.Line, 'XData', this.TData, 'YData', this.YData);
    if this.RTO.OutputPort(1).Data > this.Ymax
        this.Ymax = this.RTO.OutputPort(1).Data+localrange([this.Ymin this.Ymax]);
        set(this.AxesHandle(1), 'YLim', [this.Ymin this.Ymax]);
    elseif this.RTO.OutputPort(1).Data < this.Ymin
        this.Ymin = this.RTO.OutputPort(1).Data-localrange([this.Ymin this.Ymax]);
        set(this.AxesHandle(1), 'YLim', [this.Ymin this.Ymax]);
    end
end
end

%===================(Signal Level at PID Block output)
function out = getSignalLevel(blk,portnum)
% Internal utility: This function returns the signal at the PORTNUMth
% output port of the block BLK. The model should NOT be compiled when
% calling this function.
%  Author(s): Erman Korkut
%  Copyright 2003-2013 The MathWorks, Inc.
% Get the model from block
mdl = get_param(bdroot(blk),'Name');
% Model should not be compiled when calling this function
assert(strcmp(get_param(mdl,'SimulationStatus'),'stopped'));
iscompiled = false;
% Turn on engine interface and other parameters storing original values
sess = Simulink.CMI.EIAdapter(Simulink.EngineInterfaceVal.byFiat);
store.BlockReduction = get_param(mdl,'BlockReduction');
store.BufferReuse = get_param(mdl,'BufferReuse');
store.Dirty = get_param(mdl,'Dirty');
activeConfig = getActiveConfigSet(mdl);
if isa(activeConfig, 'Simulink.ConfigSetRef')
    activeConfig = activeConfig.getRefConfigSet;
end

try
    % Set the parameters
    set_param(activeConfig,'BlockReduction','off');
    set_param(activeConfig,'BufferReuse','off');
    % Compile and evaluate outputs
    feval(mdl,[],[],[],'compile');
    iscompiled = true;
    feval(mdl,0,[],[],'outputs');
    ph = get_param(blk,'PortHandles');
catch Ex
    LocalRestore(mdl,store,iscompiled,activeConfig);
    rethrow(Ex);
end
p = get_param(ph.Outport(portnum),'Object');
out = p.getOutput.Values;
LocalRestore(mdl,store,iscompiled,activeConfig);
delete(sess);
end

function LocalRestore(mdl,store,iscompiled,activeConfig)
%LOCALRESTORE
if iscompiled
    feval(mdl,[],[],[],'term');
end
set_param(activeConfig,'BufferReuse',store.BufferReuse);
set_param(activeConfig,'BlockReduction',store.BlockReduction);
set_param(mdl,'Dirty',store.Dirty);
end

function y = localrange(x)
%LOCALRANGE
y = max(x) - min(x);
end

function cst = localEvalCompiled(this)
%LOCALEVALCOMPILED
cst = slcontrollib.internal.utils.processSampleTime(get_param(this.PIDBlockHandle, 'CompiledSampleTime'));
end
function closewb(wb)
%CLOSEWB
if ishghandle(wb)
    delete(wb);
end
end
