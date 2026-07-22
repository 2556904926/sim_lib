classdef ControllerList < handle
    %CONTROLLERLIST manage controllers data relevant for PID Tuner
    
    % Author(s): Baljeet Singh 18-Nov-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties (SetObservable = true)
        % Do not use (AbortSet = true) for these controllers as even if the
        % controller values remains the same, there could be views that
        % need refreshed. For example, Parameters Table needs to be
        % refreshed for n/a parameters even if the tuned PI and PID
        % controllers have same values.
        TunedController = pid()
        BaselineController = []
    end
    properties (SetObservable = true, SetAccess = private)
        DesiredController = pid(1,0,0,0,1) % represented in discrete form as TimeUnit, Ts are
        % never used for tuning
    end
    properties (Dependent = true, AbortSet = true)
        % Properties derived from DesiredController
        DesiredForm
        DesiredTypeStr
        DesiredIFormula
        DesiredDFormula
        % There are no DesiredSampleTime or DesiredTimeUnit as Ts and
        % TimeUnit are derived from the Plant for which the controller is
        % tuned.
        SampledBaselineController
    end
    
    properties (SetAccess = private)
        DesiredType % cache desired controller type for performance in getTunedPIDData
        fixBC = false
        TunedDOF
        BaselineDOF
        blockBC = [1 1] % cached b,c values from PID Block
    end
    
    properties
        TunerTC
    end
    
    properties(Access = private)
        DesiredTypeStr_
    end
    
    methods
        function this = ControllerList(tunertc, desiredtype, baseline, desiredform)
            %CONTROLLERLIST
            if nargin > 0
                this.TunerTC = tunertc;
            end
            if nargin > 1
                this.DesiredTypeStr = desiredtype;
            else
                this.DesiredTypeStr = 'p';
            end
            if nargin > 2
                if ~isempty(baseline)
                    if isa(baseline, 'pidstd')
                        this.DesiredForm = 'ideal';
                    else
                        this.DesiredForm = 'parallel';
                    end
                    if nargin > 3 && ~isempty(desiredform)
                        this.DesiredForm = desiredform;
                    end
                    if ~isct(baseline) % do not use isdt because it returns true for discrete time P-only
                        this.DesiredIFormula = baseline.IFormula(1);
                        this.DesiredDFormula = baseline.DFormula(1);
                    end
                end
                this.BaselineController = baseline;
            end
        end
        %========================================================================(Tuned Controller)
        function set.TunedController(this,val)
            %SET_TUNEDCONTROLLER
            this.TunedController = val;
        end
        
        function val = getTunedPIDData(this, block)
            %GETTUNEDPIDDATA obtain tuned controller data that will be displayed
            %in the tuner. For Simulink case, thge data displayed has to be
            %compatible with the PID Blocks format and for MATLAB case, it
            %has to be equivalent to the @pid objects.
            val = struct('Type',this.DesiredType,'DOF',this.TunedDOF,'P', [], 'I', [], 'D', [],'FC', [],'b', 1, 'c', 1);
            % Simulink case
            if nargin ==2
                if block
                    [val.P, val.I, val.D, val.FC, val.b, val.c] = pidtool.desktop.SimulinkGateway.getPIDNfromPIDObj(this.TunedController);
                    return
                end
            end
            % MATLAB case
            if strcmp(class(this.TunedController),'pid') %#ok<*STISA>
                [val.P, val.I, val.D, val.FC] = piddata(this.TunedController);
            elseif strcmp(class(this.TunedController),'pidstd')
                [val.P, val.I, val.D, val.FC] = pidstddata(this.TunedController);
            elseif strcmp(class(this.TunedController),'pid2')
                [val.P, val.I, val.D, val.FC, val.b, val.c] = piddata2(this.TunedController);
            else % pidstd2
                [val.P, val.I, val.D, val.FC, val.b, val.c] = pidstddata2(this.TunedController);
            end
        end
        %=====================================================================(Baseline Controller)
        function set.BaselineController(this,C)
            %SET_BASELINECONTROLLER
            % Assume that C is either [1 1] or [1 2]
            if ischar(C)
                % there is no baseline controller to compare with
                this.BaselineController = [];
            else
                % baseline controller is C
                if ~isempty(C)
                    if issiso(C)
                        try %#ok<*TRYNC>
                            if strcmp(this.DesiredForm,'parallel') %#ok<*MCSUP>
                                C = pid(C);
                            else
                                C = pidstd(C);
                            end
                        end
                        this.BaselineDOF = 1;
                    else
                        try %#ok<*TRYNC>
                            if strcmp(this.DesiredForm,'parallel')
                                C = pid2(C);
                            else
                                C = pidstd2(C);
                            end
                        end
                        this.BaselineDOF = 2;
                    end
                    this.BaselineController = C;
                end
            end
        end
        
        function val = getBaselinePIDData(this, block)
            %GETBASELINEPIDDATA obtain baseline controller data that will be displayed
            %in the tuner. For Simulink case, thge data displayed has to be
            %compatible with the PID Blocks format and for MATLAB case, it
            %has to be equivalent to the @pid objects.
            val = struct('Type',this.DesiredType,'DOF',this.BaselineDOF,'P', [], 'I', [], 'D', [],'FC', [],'b', 1, 'c', 1);
            % Simulink case
            if nargin ==2
                if block
                    [val.P, val.I, val.D, val.FC, val.b, val.c] = this.TunerTC.SLGateway.getPIDNfromPIDBlock();
                    val.Type = this.TunerTC.SLGateway.PIDBlockData.Controller;
                    return
                end
            end
            if isa(this.BaselineController,'pid') || isa(this.BaselineController,'pidstd') % also covers pid2 pidstd2
                val.Type = lower(getType(this.BaselineController));
            end
            % MATLAB case
            if ~isempty(this.BaselineController)
                if strcmp(class(this.BaselineController),'pid') %#ok<*STISA>
                    [val.P, val.I, val.D, val.FC] = piddata(this.BaselineController);
                elseif strcmp(class(this.BaselineController),'pidstd')
                    [val.P, val.I, val.D, val.FC] = pidstddata(this.BaselineController);
                elseif strcmp(class(this.BaselineController),'pid2')
                    [val.P, val.I, val.D, val.FC, val.b, val.c] = piddata2(this.BaselineController);
                elseif strcmp(class(this.BaselineController),'pidstd2')
                    [val.P, val.I, val.D, val.FC, val.b, val.c] = pidstddata2(this.BaselineController);
                else
                    % ignore
                end
            end
        end
        
        function val = getBaselineType(this, block)
            %GETBASELINEPIDDATA
            if block % Simulink case
                val = lower(this.DesiredType);
            else % MATLAB case
                if isa(this.BaselineController,'pid') || isa(this.BaselineController,'pidstd')
                    val = lower(getType(this.BaselineController));
                else
                    val = '';
                end
            end
        end
        %======================================================================(Desired Controller)
        function set.DesiredController(this,val)
            %SET_DESIREDCONTROLLER
            this.DesiredController = val;
        end
        
        function set.DesiredTypeStr(this, val)
            %SET_DESIREDTYPESTR
            % DesiredTypeStr can be ay of the following:
            % p,i,pi,pd,pid,pdf,pidf
            % pi2,pd2,pid2,pdf2,pidf2
            % i-pd,id-p,pi-d,i-pdf,idf-p,pi-df
            
            % Invalid cases
            if strcmpi(this.DesiredForm, 'standard') && strcmpi(val, 'i')
                this.setTunerStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_typechanged_warn'),'warn');
                return;
            end
            if this.TunedController.Ts >0 && any(strcmpi(val,{'pid','pid2','i-pd','id-p','pi-d','pd','pd2'})) && ...
                    strcmp(this.DesiredDFormula,'Trapezoidal')
                this.setTunerStatusText(pidtool.utPIDgetStrings('cst','notsupportedpid'),'warn');
                return;
            end
            
            DC = this.DesiredController;
            typestr = lower(val);
            
            switch typestr
                case 'i-pd'
                    type = 'pid2';
                    bc = [0 0];
                    this.fixBC = true;
                    this.DesiredTypeStr_ = 'i-pd';
                case 'id-p'
                    type = 'pid2';
                    bc = [0 1];
                    this.fixBC = true;
                    this.DesiredTypeStr_ = 'id-p';
                case 'pi-d'
                    type = 'pid2';
                    bc = [1 0];
                    this.fixBC = true;
                    this.DesiredTypeStr_ = 'pi-d';
                case 'i-pdf'
                    type = 'pidf2';
                    bc = [0 0];
                    this.fixBC = true;
                    this.DesiredTypeStr_ = 'i-pdf';
                case 'idf-p'
                    type = 'pidf2';
                    bc = [0 1];
                    this.fixBC = true;
                    this.DesiredTypeStr_ = 'idf-p';
                case 'pi-df'
                    type = 'pidf2';
                    bc = [1 0];
                    this.fixBC = true;
                    this.DesiredTypeStr_ = 'pi-df';
                otherwise
                    bc = [];
                    this.fixBC = false;
                    type = typestr;
            end
            this.DesiredType = type;
            this.DesiredTypeStr_ = typestr;
            % set desired DOF
            if strcmp(type(end),'2')
                this.TunedDOF = 2;
            else
                this.TunedDOF = 1;
            end
            % set desired controller
            newDC = ltipack.getPIDfromType(type,this.DesiredForm,DC.Ts,DC.TimeUnit);
            newDC.IFormula = DC.IFormula;
            newDC.DFormula = DC.DFormula;
            newDC = localMatchBC(newDC,DC,bc);
            this.DesiredController = newDC;
            this.setTunerStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_typechanged_info'),'info');
        end
        
        function set.DesiredForm(this, form)
            %SET_DESIREDFORM
            DC = this.DesiredController;
            if strcmpi(this.DesiredType, 'i') && strcmpi(form, 'standard')
                this.setTunerStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_formchanged_warn'),'warn');
            else
                newDC = ltipack.getPIDfromType(getType(DC),lower(form),DC.Ts,DC.TimeUnit);
                newDC.IFormula = DC.IFormula;
                newDC.DFormula = DC.DFormula;
                newDC = localMatchBC(newDC,DC,[]);
                %                 BC = this.DesiredBC;
                this.DesiredController = newDC;
                %                 this.DesiredBC = BC;
                this.setTunerStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_formchanged_info'),'info');
            end
        end
        
        function set.DesiredIFormula(this, val)
            %SET_DESIREDIFORMULA
            this.DesiredController.IFormula = val;
            this.setTunerStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_pidchanged_info'),'info');
        end
        
        function set.DesiredDFormula(this, val)
            %SET_DESIREDDFORMULA
            this.DesiredController.DFormula = val;
            this.setTunerStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_pidchanged_info'),'info');
        end
        
        function val = get.DesiredTypeStr(this)
            %GET_DESIREDTYPE
            val = this.DesiredTypeStr_;
        end
        
        function val = get.DesiredForm(this)
            %GET_DESIREDFORM
            if isa(this.DesiredController, 'pid') % also covers pid2
                val = 'parallel';
            else
                val = 'standard';
            end
        end
        
        function val = get.DesiredIFormula(this)
            %GET_DESIREDIFORMULA
            val = this.DesiredController.IFormula;
        end
        
        function val = get.DesiredDFormula(this)
            %GET_DESIREDDFORMULA
            val = this.DesiredController.DFormula;
        end
        %================================================================================(Utilities)
        function val = get.SampledBaselineController(this)
            %GET_SAMPLEDBASELINECONTROLLER
            val = localSampleControllerForTimeUnit(this.BaselineController, this.TunedController.TimeUnit);
            val = localSampleControllerForSampleTime(val, this.TunedController.Ts);
        end
        
        function [dup, closedlg] = exportTunedController(this, name, force)
            %EXPORTTUNEDCONTROLLER
            dup = [];
            closedlg = true;
            tunedC = this.TunedController;
            if (evalin('base',['exist(''', name,''', ''var'');']) == 0)
                try
                    assignin('base', name, tunedC);
                catch E %#ok<NASGU>
                    ErrorMessage = getString(message('MATLAB:uistring:export2wsdlg:NotValidMATLABVariableNamesOneVariables', name));
                    ErrorTitle = getString(message('MATLAB:uistring:export2wsdlg:InvalidVariableName'));
                    uialert(this.TunerTC.AppGroup,ErrorMessage,ErrorTitle);
                    closedlg = false;
                end
            else
                if force
                    assignin('base', name, tunedC);
                else
                    dup = name;
                end
            end
        end
        %=====================================================================(2-DOF parameters b,c)
        function fixBCtoValue(this,val)
            %FIXBCTOVALUE
            % Fix value of b,c parameters to a given value
            this.fixBC = true;
            if this.TunedDOF == 2
                if isequal(val,[1 1])
                    this.DesiredTypeStr_ = strrep(this.DesiredType,'2',''); % 2-DOF is equivalent to corresponding 1-dof type
                else
                    this.DesiredTypeStr_ = [this.DesiredType '-manual'];
                end
                DC = this.DesiredController;
                DC.b = val(1);
                DC.c = val(2);
                this.DesiredController = DC;
            end
        end
        
        function fixBCtoBlockValue(this)
            %FIXBCTOVALUE
            % Set b,c values to the corresponding block values as stored in
            % the objects blockBC property.
            this.fixBC = true;
            if this.TunedDOF == 2
                this.DesiredTypeStr_ = [this.DesiredType '-fixbc'];
                DC = this.DesiredController;
                DC.b = this.blockBC(1);
                DC.c = this.blockBC(2);
                this.DesiredController = DC;
            end
        end
        
        function freeBC(this)
            %FREEBC
            % Set b,c values to be tunable
            this.fixBC = false;
            % Changing fixBC should send the DesiredController PostSet
            % event.
            if this.TunedDOF == 2
                this.DesiredTypeStr_ = this.DesiredType; % true 2-DOF controller type
                DC = this.DesiredController;
                this.DesiredController = DC;
            end
        end
        
        function setBlockBC(this,val)
            %SETBLOCKBC
            % Set the value of blockBC property. If derised controller had
            % fixed b,c to the block value, update desired controller
            this.blockBC = val;
            if ~isempty(strfind(this.DesiredTypeStr,'-fixbc'))
                this.fixBCtoBlockValue();
            end
        end
        %==================================================================================(Utility)
        function setTunerStatusText(this,msg,type)
            if ~isempty(this.TunerTC)
               this.TunerTC.setStatusText(msg,type); 
            end
        end
    end
end

function val = localSampleControllerForSampleTime(controller, TS)
% Utility to change sample time of a controller
if isempty(controller)
    val = controller;
    return
end
WarningState = warning('off'); %#ok<WNOFF>
if TS == 0
    if controller.Ts <= 0
        val =  controller;
    else
        val = d2c(controller, 'Tustin');
    end
else
    if controller.Ts == TS || controller.Ts == -1
        val =  controller;
    elseif controller.Ts == 0
        val = c2d(controller,TS,'Tustin');
    else
        val = d2d(controller,TS,'Tustin');
    end
end
warning(WarningState);
end

function val = localSampleControllerForTimeUnit(controller, TU)
% Utility to change TimeUnit of a controller
if isempty(controller)
    val = controller;
    return
end
if ~strcmp(controller.TimeUnit,TU)
    val = chgTimeUnit(controller, TU);
else
    val = controller;
end
end

function newDC = localMatchBC(newDC,DC,bc)
% Copy b,c values from current desired controller to the new desired
% controller
if isa(newDC,'pid2') || isa(newDC,'pidstd2')
    if isempty(bc)
        if  isa(DC,'pid2') || isa(DC,'pidstd2')
            b = DC.b; c = DC.c;
        else
            b = 1; c = 1;
        end
        newDC.b = b;
        newDC.c = c;
    else
        newDC.b = bc(1);
        newDC.c = bc(2);
    end
end
end
