classdef IMCTuningDlg < ctrlguis.csdesignerapp.dialogs.internal.AutomatedTuningDialog
    %

    % Copyright 2014 The MathWorks, Inc.
    
    % Dialog class that manages the IMC tuning dialog
    methods
        
        function this = IMCTuningDlg(DesignerData, varargin)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.dialogs.internal. ...
                    AutomatedTuningDialog(DesignerData, varargin{:});
            this.Name = 'CSD_IMCTuningDialog' + matlab.lang.internal.uuid;
            % Set dialog title
            this.Title = sprintf('%s', getString(message ...
                ('Control:designerapp:IMCTuningDesc')));
            this.CloseMode = 'destroy';
            this.DialogHeight = 425;
        end
    end
    
    methods (Access = protected)
        %% Create spec panel and related listeners
        function getSpecPanel(this, Parent, SpecData)
            % Create the IMC spec panel if panel is empty
            if isempty(this.TuningSpecPanel)
                this.TuningSpecPanel = ctrlguis.csdesignerapp.panels.internal.IMCSpecPanel(...
                    this, Parent, SpecData);
                addSpecDataListeners(this);
            end
        end
        
        function cbHelpButton(this)
            % HELP CALLBACK
            if isSimulink(this.ControlDesignData.getArchitecture)
                ctrlguihelp('CSD_SL_IMCTuningHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_IMCTuningHelp','CSHelpWindow');
            end
        end
        
        function Plant = getSelectedOpenLoopPlant(this)
            % Overloaded getOpenLoopPlant for IMC
            Arch = getArchitecture(this.ControlDesignData);
            if getConfiguration(Arch) == 5
                Plant = getPrivateData(getLoopSign(Arch)*getValue( ...
                    getFixedBlocks(Arch,'G2')));
            else
                Idx = ismember(this.LoopsToTune(this.SelectedIdx).ResponseNames, ...
                    this.Widgets.LoopsToTuneDropdown.Value);
                Response = this.LoopsToTune(this.SelectedIdx).Responses(Idx);
                Compensator = this.LoopsToTune(this.SelectedIdx).Compensator;
                Plant = getOpenLoopPlant(Response,Compensator);
            end
        end
        
        function C = tuneCompensator(this, OpenLoopPlant, SpecData)
            
            % Disable all warnings
            sw = warning('off'); [lw,lwid] = lastwarn; lastwarn(''); %#ok<*WNOFF>
            % check if plant exists
            if isempty(OpenLoopPlant)
                C = [];
            else
                % get plant model (always assuming negative feedback) and approximate
                % time delays
                Model = utCreateLTI(this.utApproxDelay(-OpenLoopPlant));
                % calculate C
                try
                    if isempty(SpecData.Tau)
                        Tau = [];
                    else
                        errorTauMsg = getString(message('Control:designerapp:IMCTauRequirement'));
                        icon = 'error';
                        try
                            Tau = SpecData.Tau;
                            if ~isreal(Tau) || ~isfinite(Tau) || Tau<=0
                                
                                uialert(this.UIFigure, ...
                                    ltipack.utStripErrorHeader(errorTauMsg), ...
                                    this.Title, 'Icon', icon);
                                C = [];
                                return
                            end
                        catch ME %#ok<NASGU>
                            uialert(this.UIFigure, ...
                                ltipack.utStripErrorHeader(errorTauMsg), ...
                                this.Title, 'Icon', icon);
                            C = [];
                            return
                        end
                    end
                    % compute full order feedback controller and IMC controller
                    [C, q] = utTuningIMC(Model,Tau);
                    % obtain selected last warning message
                    WarningList = {'control:autotuning:unstablec','control:autotuning:pzcancel'};
                    [warnmsg,warnid] = lastwarn;
                    if ~isscalar(strcmp(warnid,WarningList))
                        warnmsg = '';
                    end
                    
                    Config = getConfiguration(getArchitecture(this.ControlDesignData));
                    
                    if Config == 5
                        C = q;
                    else
                        % carry out order reduction for C when applicable
                        FullOrder = order(C);
                        DO = str2double(SpecData.DesiredOrder);
                        % when desired order is lower than full order, reduce the order
                        if DO<FullOrder
                            % reduce controller order
                            [C, ReducedMSG] = ctrlguis.csdesignerapp. ...
                                utils.internal.utModelOrderReduction( ...
                                Model,C,DO);
                            % obtain warning message from reduction
                            if ~isempty(ReducedMSG)
                                if isempty(warnmsg)
                                    warnmsg = sprintf('%s',ReducedMSG);
                                else
                                    warnmsg = sprintf('%s\n\n%s',warnmsg,ReducedMSG);
                                end
                            end
                        end
                    end
                    % obtain last warning message
                    icon = 'warning';
                    if ~isempty(warnmsg)
                        uialert(this.UIFigure, warnmsg, this.Title, ...
                            'Icon', icon);
                    end

                catch ME
                    icon = 'error';
                    uialert(this.UIFigure, ...
                        ltipack.utStripErrorHeader(ME.message), ...
                        this.Title, 'Icon', icon);
                    C = [];
                end
            end
            % Reset warnings
            warning(sw); lastwarn(lw,lwid);
        end
        
        function [bool,Message] = isCompensatorTunable(this,compensator,Response)
            Message = [];
            isConstraint = ~isTunable(compensator) || (~isempty(compensator.Constraints) && ...
                (~compensator.Constraints.isStaticGainTunable || ...
                ~isinf(compensator.Constraints.MaxZeros)));
            isFixedDynamics = ~isempty(compensator.FixedDynamics) && ~isstatic(compensator.FixedDynamics);
            if isConstraint
                bool = false;
                Message = getString(message('Control:compDesignTask:IMCConstrained'));
            elseif isFixedDynamics
                bool = false;
                Message = getString(message('Control:compDesignTask:IMCFixedDynamics'));
            else
                % OL = getOpenLoopPlant(Response, compensator);
                OL = utCreateLTI(getOpenLoopPlant(Response, compensator));
                if isa(OL,'frd') || isa(OL, 'genfrd')
                    % If FRD Plant
                    bool = false;
                    Message = getString(message('Control:compDesignTask:AutomatedTuningFRDPlant'));
                elseif isproper(OL)
                    bool = true;
                    if hasdelay(OL) && isequal(OL.Ts,0)
                        % If has delays
                        Message = getString(message('Control:compDesignTask:strNotificationTuningTimeDelay'));
                    elseif isUncertain(Response)
                        % If is uncertain
                        Message = getString(message('Control:compDesignTask:strNotificationNominalModelDesign'));
                    end
                else
                    % If improper plant
                    bool = false;
                    Message=getString(message('Control:compDesignTask:AutomatedTuningImproperPlant'));
                end
            end
        end
    end
    methods (Static = true, Access = protected)
        function Title = getTransactionTitle
            Title = getString(message('Control:designerapp:notifyIMCTuning'));
        end
    end
    %% Hidden QE methods
    methods (Hidden = true)
        function OL = qeGetSelectedOpenLoopPlant(this)
            try
                OL = getSelectedOpenLoopPlant(this);
            catch ME
                error(message(ME));
            end
        end
    end

end