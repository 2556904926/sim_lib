classdef LQGTuningDlg < ctrlguis.csdesignerapp.dialogs.internal.AutomatedTuningDialog
% 
%
    methods
        function this = LQGTuningDlg(DesignerData, varargin)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.dialogs.internal. ...
                    AutomatedTuningDialog(DesignerData, varargin{:});
            this.Name = 'CSD_LQGTuningDialog' + matlab.lang.internal.uuid;
%             % Set dialog title
            this.Title = sprintf('%s', getString(message ...
                ('Control:designerapp:LQGTuningDesc')));
            this.CloseMode = 'destroy';
        end
   end
    
   methods (Access = protected)
        %% Create spec panel and related listeners
        function getSpecPanel(this, Parent, SpecData)
            Dlg = this;
            % Create the LQG spec panel if panel is empty
            if isempty(this.TuningSpecPanel)
                this.TuningSpecPanel = ctrlguis.csdesignerapp.panels.internal.LQGSpecPanel(Dlg, Parent, SpecData);
                addSpecDataListeners(this);
            end
        end
        
        % Callbacks for specific UI Components
        function cbHelpButton(this)
            if isSimulink(this.ControlDesignData.getArchitecture)
                ctrlguihelp('CSD_SL_LQGTuningHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_LQGTuningHelp','CSHelpWindow');
            end
        end
       %% Back end logic calculations 
        % abstract methods in Automated Tuning Dialog
        function [bool,Message] = isCompensatorTunable(this, ...
                compensator, Response)
            
            Message = [];
            
            isConstraint = ~isTunable(compensator) || ...
                (~isempty(compensator.Constraints) && ...
                (~compensator.Constraints.isStaticGainTunable || ...
                ~isinf(compensator.Constraints.MaxZeros)));
            
            isFixedDynamics = ~isempty(compensator.FixedDynamics) ...
                && ~isstatic(compensator.FixedDynamics);
            
            if isConstraint
                bool = false;
                Message = getString(message...
                    ('Control:designerapp:LQGConstrained'));
            elseif isFixedDynamics
                bool = false;
                Message = getString(message...
                    ('Control:compDesignTask:IMCFixedDynamics'));
            else
                OL = utCreateLTI(getOpenLoopPlant(Response, compensator));
                if isa(OL,'frd') || isa(OL, 'genfrd')
                    % If FRD Plant
                     bool = false;
                    Message = getString(message...
                        ('Control:compDesignTask:AutomatedTuningFRDPlant'));
                elseif isproper(OL)
                    bool = true;
                    if hasdelay(OL) && isequal(OL.Ts,0)
                        % If has delays
                        % TO-DO: double check the reson to swap tabs in
                        % Preferences Dialog?
                        Message = getString(message...
                            ('Control:compDesignTask:strNotificationTuningTimeDelay'));
                    elseif isUncertain(Response)
                        % If is uncertain
                        Message = getString(message...
                            ('Control:compDesignTask:strNotificationNominalModelDesign'));
                    end
                else
                    % If improper plant
                    bool = false;
                    Message = getString(message...
                        ('Control:compDesignTask:AutomatedTuningImproperPlant'));
                end
            end
        end
        
        function C = tuneCompensator(this, OpenLoopPlant, SpecData)
            % Disable all warnings
            sw = warning('off'); [lw,lwid] = lastwarn; lastwarn(''); %#ok<*WNOFF>
            % check if plant exists
            if isempty(OpenLoopPlant)
                C = [];
            else
                % get plant model (always assuming negative feedback)
                % and convert model into SS format for LQG design
                % model has to be (bi)proper
                Model = utCreateLTI(this.utApproxDelay(-OpenLoopPlant));
                [AA, BB, CC, DD] = ssdata(Model);
                
                % nu ny represents the order of the plant model, number of u and y
                [ny,nu] = size(DD);
                % prepare model with input disturbance for Kalman estimator: assume d = u
                KalmanModel = subsref(Model,struct('type','()','subs',{{':'  [1:nu 1:nu]}}));
                % calculate all the weights based on two sliders
                WQXU = SpecData.ControllerResponse/100; % from 0 to 1
                WQWV = SpecData.MeasurementNoise/100; % from 0 to 1
                wy = 10^(-12*WQXU+6);
                WeightY = wy*eye(ny);
                WeightU = 10^(12*WQXU-6)*eye(nu);
                WeightYN = 10^(8*WQWV-6)*eye(ny);
                WeightUN = 10^(-8*WQWV+4)*eye(nu);
                % calculate C
                try
                    % compute full order feedback controller
                    K = lqi(ss(Model), blkdiag(CC'*WeightY*CC,wy), WeightU);
                    Kest = kalman(ss(KalmanModel),WeightUN,WeightYN);
                    C = lqgtrack(Kest,K,'1dof');
                    % obtain selected last warning message
                    WarningList = {'control:autotuning:lackofmv'};
                    [warnmsg,warnid] = lastwarn;
                    if ~isscalar(strmatch(warnid,WarningList,'exact'))
                        warnmsg = '';
                    end
                    % carry out order reduction for C when applicable
                    FullOrder = order(C);
                    % when desired order is lower than full order, reduce the order
                    DO = SpecData.DesiredOrder;
                    if DO<FullOrder
                        % reduce controller order
                        [C, ReducedMSG] = ctrlguis.csdesignerapp.utils.internal.utModelOrderReduction(Model,C,DO);
                        % obtain warning message from reduction
                        if ~isempty(ReducedMSG)
                            if isempty(warnmsg)
                                warnmsg = sprintf('%s',ReducedMSG);
                            else
                                warnmsg = sprintf('%s\n\n%s',...
                                    warnmsg, ReducedMSG);
                            end
                        end
                    end
                    % obtain last warning message
                    icon = 'warning';
%                     ctrlguis.csdesignerapp.utils.internal.utDisplayMessage('warning',warnmsg);
                    if ~isempty(warnmsg)
                        uialert(this.UIFigure, warnmsg, this.Title, ...
                            'Icon', icon);
                    end
                catch ME
                    icon = 'error';
                    uialert(this.UIFigure, ...
                        ltipack.utStripErrorHeader(ME.message), ...
                        this.Title, 'Icon', icon);
%                     ctrlguis.csdesignerapp.utils.internal.utDisplayMessage('error',ltipack.utStripErrorHeader(ME.message));
                    C = [];
                end
            end
            % Reset warnings
            warning(sw); lastwarn(lw,lwid);
        end

        
   end

   methods (Access = protected, Static = true)

        %% Status message
        function Title = getTransactionTitle
             Title = getString(message('Control:designerapp:notifyLQGTuning'));
        end
   end

end
