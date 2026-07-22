classdef LoopShapeTuningDlg < ctrlguis.csdesignerapp.dialogs.internal.AutomatedTuningDialog
    %

    % Copyright 2014 The MathWorks, Inc.
    
    properties (SetAccess = private)
        hasRobustToolboxLicense = ~isempty(ver('robust')) || license('test','Robust_Toolbox');
    end
    % Dialog class that manages the LQG tuning dialog
    methods
        
        function this = LoopShapeTuningDlg(DesignerData, varargin)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.dialogs.internal. ...
                AutomatedTuningDialog(DesignerData, varargin{:});
            this.Name = 'CSD_LoopShapeTuningDialog' + matlab.lang.internal.uuid;
            % Set dialog title 
            this.Title = sprintf('%s', getString(...
                message('Control:designerapp:LoopSynTuningDesc')));
            this.CloseMode = 'destroy';
            this.DialogHeight = 570;
        end
    end
    
    methods (Access = protected)
        
        function getSpecPanel(this, Parent, SpecData)
            % Create the LQG spec panel if panel is empty
            if isempty(this.TuningSpecPanel)
                this.TuningSpecPanel = ctrlguis.csdesignerapp.panels. ...
                    internal.LoopShapeSpecPanel(this, Parent, SpecData);
                addSpecDataListeners(this);
            end
%             
%             % Return the spec panel
%             pnl = getPanel(this.TuningSpecPanel);
        end

        function cbHelpButton(this)
            % HELP CALLBACK
            if isSimulink(this.DesignerData.getArchitecture)
                ctrlguihelp('CSD_SL_LoopShapeTuningHelp','CSHelpWindow');
            else
                ctrlguihelp('CSD_ML_LoopShapeTuningHelp','CSHelpWindow');
            end
        end
        
        function [bool,Message] = isCompensatorTunable(this, ...
                compensator, Response)
            bool = true;
            Message = [];
            isTunable = utIsTunable(this, compensator);
            if isTunable
                OL = utCreateLTI(getOpenLoopPlant(Response, compensator));
                switch isproper(OL)
                    case true && isa(OL, 'frd') || isa(OL, 'genfrd')
                        % If frd plant
                        bool = false;
                        Message = getString(message('Control:compDesignTask:AutomatedTuningFRDPlant'));
                    case true && hasdelay(OL) && isequal(OL.Ts,0)
                        % If delayed
                        bool = true;
                        Message = getString(message('Control:compDesignTask:strNotificationTuningTimeDelay'));
                    case true && isUncertain(Response)
                        % If uncertain
                        Message = getString(message('Control:compDesignTask:strNotificationNominalModelDesign'));
                    case false
                        bool = false;
                        Message = getString(message('Control:compDesignTask:AutomatedTuningImproperPlant'));
                end
            else
                bool = false;
                Message = getString(message('Control:compDesignTask:LoopSynRobustConstrained'));
            end
        end
        
        function b = utIsTunable(this, C)
            %utIsTunable Determines if compensator is tunable using loopsyn
            
            if C.isTunable && (isempty(C.FixedDynamics) || ...
                    isstatic(C.FixedDynamics))
                Constraints = C.Constraints;
                if isempty(Constraints) || ...
                        (isinf(Constraints.MaxZeros) && ...
                        isinf(Constraints.MaxPoles))
                    b = true;
                else
                    b = false;
                end
            else
                b = false;
            end
            
        end
        
        function C = tuneCompensator(this, OpenLoopPlant, SpecData)
            % Disable all warnings
            sw = warning('off'); [lw,lwid] = lastwarn; lastwarn(''); %#ok<*WNOFF>
            
            try
                % check if plant exists
                if isempty(OpenLoopPlant)
                    ctrlMsgUtils.error('Control:designerapp:AutomatedTuningUndefinedPlant')
                else
                    % Switch between loopsyn and looptune
                    switch SpecData.Compensator
                        case 'free'
                            G = utCreateLTI(this.utApproxDelay(-OpenLoopPlant));
                            GTs = G.Ts;
                            if strcmp(SpecData.Preference,'LoopShape')
                                Gd = evalin('base', SpecData.LoopShape);
                                % Target Loop Shape
                                FreqRange = evalin('base', ...
                                    SpecData.FrequencyRange);

                                if isequal(FreqRange, [0,inf])
                                    C = loopsyn(G, Gd);
                                else
                                    C = loopsyn(G, Gd, FreqRange);
                                end
                            else
                                % Target bandwidth
                                B = evalin('base', SpecData.BandWidth);
                                Gd = zpk([], 0, B);
                                if isdt(G)
                                    Gmod = d2c(G, 'Tustin');
                                    C = loopsyn(Gmod, Gd);
                                    C = c2d(C, GTs, 'Tustin');
                                else
                                    C = loopsyn(G, Gd);
                                end
                            end
                            % carry out order reduction for C when applicable
                            % when desired order is lower than full order, reduce the order
                            FullOrder = order(C);
                            % when desired order is lower than full order, reduce the order
                            DO = str2double(SpecData.DesiredOrder);
                            if DO < FullOrder
                                % reduce controller order
                                [C, ReducedMSG] = ctrlguis.csdesignerapp. ...
                                    utils.internal. ...
                                    utModelOrderReduction(G,C,DO);
                                % obtain warning message from reduction
                                if ~isempty(ReducedMSG)
                                   icon = 'warning';
                                   uialert(this.UIFigure, ...
                                       ReducedMSG, 'Icon', icon);
                                end
                            end
                            
                        case 'fixed'
                            % Plant
                            G = utCreateLTI(this. ...
                                utApproxDelay(OpenLoopPlant));
                            % Compensator
                            C0 = this.LoopsToTune(this.SelectedIdx).Compensator;
                            
                            %common for gain, filt. frd object
                            %gets rejects on a higher level,
                            %choosing TF since TunedLTI is in ZPK form
                            C0 = tunableTF('C',getValue(C0));
                            
                            %in the event of loopshaping, set i/o names
                            G.y = 'y'; C0.y = 'u'; 
                            G.u = 'u'; C0.u = 'y'; 
                            
                            %silence display
                            opts = looptuneOptions; opts.Display = 'off';
                            
                            % Switch between Target Bandwidth and
                            % Loopshape
                            if strcmp(SpecData.Preference,'LoopShape')
                                FreqRange = evalin('base', ...
                                    SpecData.FrequencyRange);
                                LoopShape = evalin('base', ...
                                    SpecData.LoopShape);
                                Req = TuningGoal.LoopShape('u', LoopShape);
                                Req.Focus = FreqRange;
                                [~, Cr] = looptune(G, C0, [], Req, opts);
                            else
                                % Target bandwidth
                                B = evalin('base', SpecData.BandWidth);
                                [~, Cr] = looptune(G, C0, B, opts);
                            end
                            
                            % Convert to zpk format to maintain structure
                            C = zpk(Cr);
                    end
                end
            catch ME
                icon = 'error';
                uialert(this.UIFigure, ...
                    ltipack.utStripErrorHeader(ME.message), ...
                    this.Title, 'Icon', icon);
                C = [];
            end
            % Reset warnings
            warning(sw); lastwarn(lw,lwid);
        end
    end
    
    methods (Static = true, Access = protected)
       
        function Title = getTransactionTitle
           Title = getString(message('Control:designerapp:notifyLoopShapeTuning'));
        end
    end
end