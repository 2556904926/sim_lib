classdef PIDClassicTuningDlg < ctrlguis.csdesignerapp.dialogs.internal.AutomatedTuningDialog
    %

    % Copyright 2014 The MathWorks, Inc.
    
    % Dialog class that manages the LQG tuning dialog
    methods
        function this = PIDClassicTuningDlg(DesignerData, varargin)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.dialogs.internal. ...
                    AutomatedTuningDialog(DesignerData, varargin{:});
            this.Name = 'CSD_PIDTuningDialog' + matlab.lang.internal.uuid;
            % Set dialog title
            this.Title = sprintf('%s', getString(...
                message('Control:designerapp:strDesignMethodPID')));
            this.CloseMode = 'destroy';
            this.DialogHeight = 630;
            this.DialogWidth = 530;
        end
    end
    
    methods (Access = protected)
        %% Create spec panel and related listeners
        function getSpecPanel(this, Parent, SpecData)
            % Create the LQG spec panel if panel is empty
            if isempty(this.TuningSpecPanel)
                this.TuningSpecPanel = ctrlguis.csdesignerapp.panels.internal.PIDSpecPanel(...
                    this, Parent, SpecData);
                addSpecDataListeners(this);
            end
        end
        
        % Callbacks for specific UI Components
        function cbHelpButton(this)
            % HELP CALLBACK
            if isSimulink(this.ControlDesignData.getArchitecture)
                ctrlguihelp('CSD_SL_PIDTuningHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_PIDTuningHelp','CSHelpWindow');
            end
        end
        
        function [bool, Message] = isCompensatorTunable(this, ...
                compensator,Response)
            Message = [];
            if isTunable(compensator)
                if isempty(compensator.Constraints)
                    order = inf;
                else
                    order = compensator.Constraints.MaxPoles;
                end
                isConstraint = ~isempty(compensator.Constraints) && ...
                    (~compensator.Constraints.isStaticGainTunable || ...
                    (compensator.Constraints.MaxZeros<order));
            else
                isConstraint = true;
            end
            
            if isConstraint
                bool = false;
                Message = getString(message('Control:compDesignTask:strPIDNoConstrained'));
            else
                OL = getOpenLoopPlant(Response, compensator);
                if isproper(OL)
                    bool = true;
                    if hasdelay(OL) && isequal(OL.Ts,0)
                        % If has delays
                        Message = getString(message('Control:compDesignTask:strNotificationTuningTimeDelay'));
                    elseif isUncertain(Response)
                        % If is uncertain
                        Message = getString(message('Control:compDesignTask:strNotificationNominalModelDesign'));
                    end
                else
                    bool = false;
                   Message = getString(message('Control:compDesignTask:AutomatedTuningImproperPlant'));
                end
            end
        end
        
        function C = tuneCompensator(this, OpenLoopPlant, SpecData)
            
            % Disable all warnings
            hw = ctrlMsgUtils.SuspendWarnings;  %#ok<NASGU>
            % check if plant exists
            C = [];
            if ~isempty(OpenLoopPlant)
                % tuning method
                % get plant model (always assuming negative feedback)
                Model = utCreateLTI(-OpenLoopPlant);
                % get controller type
                Type = SpecData.PIDType;
                switch SpecData.Preference
                    case 'RRT'
                        % check whether the selected controller type is supported by
                        % the block based on the constraints
                        if ~localCheckConstraints(Type, this.TuningSpecPanel.Compensator.Constraints)
                            msg = ctrlMsgUtils.message('Control:designerapp:strPIDNoHigherOrder');
                            icon = 'error';
                            uialert(this.UIFigure, ...
                                ltipack.utStripErrorHeader(msg), ...
                                this.Title, 'Icon', icon);
                            return
                        end
                        % get formula
                        % create data src object
                        DataSrc = pidtool.DataSrcLTI(Model,Type,[]);
                        % manual mode
                        WC = SpecData.WC;
                        PM = SpecData.PM;
                        DataSrc.fastdesign(WC, PM);
                        
                        C = DataSrc.C;
                        IsStable = DataSrc.IsStable;
                    otherwise
                        Formula = SpecData.Formula;
                        try
                            C = utTuningPID(Model,Type,Formula);
                            if isempty(C)
                                IsStable = false;
                            else
                                IsStable = checkNyquistStability(Model*C);
                            end
                            
                        catch ME
                            icon = 'error';
                            uialert(this.UIFigure, ...
                                ltipack.utStripErrorHeader(ME.message), ...
                                this.Title, 'Icon', icon);
                            return
                        end
                end
            end
            % check closed-loop stability
            if isempty(C) || ~IsStable
                msg = ctrlMsgUtils.message('Control:designerapp:TuningFailedToStabilize','PID');
                icon = 'error';
                uialert(this.UIFigure, ...
                    ltipack.utStripErrorHeader(msg), ...
                    this.Title, 'Icon', icon);
                C = [];
            end
        end
    end
    
    methods (Static = true, Access = protected)
        %% Tune compensator
        
        
        %% Status message
        function Title = getTransactionTitle
            Title = getString(message('Control:designerapp:notifyPIDTuning'));
        end
    end
end

function OK = localCheckConstraints(Type,Constraints)
if isempty(Constraints)
    OK = true;
else
    MaxZeros = Constraints.MaxZeros;
    MaxPoles = Constraints.MaxPoles;
    switch lower(Type)
        case 'p'
            OK = (MaxZeros >= 0) && (MaxPoles >= 0);
        case 'i'
            OK = (MaxZeros >= 0) && (MaxPoles >= 1);
        case 'pi'
            OK = (MaxZeros >= 1) && (MaxPoles >= 1);
        case 'pd'
            OK = (MaxZeros >= 1) && (MaxPoles >= 0);
        case 'pdf'
            OK = (MaxZeros >= 1) && (MaxPoles >= 1);
        case 'pid'
            OK = (MaxZeros >= 2) && (MaxPoles >= 1);
        case 'pidf'
            OK = (MaxZeros >= 2) && (MaxPoles >= 2);
    end
end
end
