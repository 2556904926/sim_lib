classdef NewTuningGoalPlot < handle & matlab.mixin.Heterogeneous
    % Tuning goal plot class
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    %% Properties
    properties
        PlotHandle
        Designs
        DesignStyles
    end
    
    properties (Access = private)              
        DataChangedListener
        TuningGoalChangedListener
        TuningGoalDeleteListener
        TGPlotDeleteListener
        DesignChangedListener
    end
    
    properties (Access = protected)
       Fig
    end

    properties(SetAccess=private,Transient,Hidden)
        Document
    end

    properties (Dependent)
        TGPlot
    end

    properties (WeakHandle)
        TuningGoalWrapper (1,1) systuneapp.data.TuningGoalWrapper
        ControlDesignData (1,1) systuneapp.data.ControlDesignData
    end

    %% Constructor/destructor
    methods
        function this = NewTuningGoalPlot(TuningGoalWrapper,ControlDesignData)
            this.ControlDesignData = ControlDesignData;
            this.TuningGoalWrapper = TuningGoalWrapper;
        end

        function delete(this)
           % Delete listeners
            delete(this.TGPlotDeleteListener);
            delete(this.DataChangedListener);
            delete(this.TuningGoalChangedListener);
            delete(this.TuningGoalDeleteListener);
            delete(this.DesignChangedListener);
            delete(this.Fig);
        end
    end

    %% Public methods
    methods
        % Create plot       
        function createPlot(this)
            
            sw = ctrlMsgUtils.SuspendWarnings; %% REVISIT
            
            % Get the system on which tuning goal is evaluated
            CL = getSystem(this);
            
            % Create the axes
            this.Fig = figure('IntegerHandle','off',...
               'NumberTitle','off',...
               'HandleVisibility','callback',...
               'Toolbar','none',...
               'Menu','none');

            ax = axes('Parent',this.Fig);
            
            % Create the shared plot handle
            tgPlot = controllib.chart.internal.utils.TuningGoalPlotManager(getTuningGoal(this),CL);
            createPlot(tgPlot,ax);
            this.PlotHandle = getPlotHandle(tgPlot);
            addDataChangedListeners(this);

            delete(sw)
        end
        
        function createPlot_(this)
            
            sw = ctrlMsgUtils.SuspendWarnings; %% REVISIT
            
            % Get the system on which tuning goal is evaluated
            CL = getSystem(this);
            
            % Create the axes
            figOptions.Title = this.TuningGoalWrapper.getName;
            document = matlab.ui.internal.FigureDocument(figOptions);
            type = systuneapp.util.getTuningGoalType(this.getTuningGoal);
            postfix = "_" + type + "_" + matlab.lang.internal.uuid;
            document.Tag = "CSTAppTuningGoalDocument"+postfix;
            document.Figure.AutoResizeChildren = 'off';
            hfig = document.Figure;
            hfig.Tag = "CSTAppTuningGoalFigure"+postfix;
            
            this.Fig = hfig;
            this.Document = document;
            
            ax = axes('Parent',hfig);
            
            % Create the shared plot handle
            tgPlot = controllib.chart.internal.utils.TuningGoalPlotManager(getTuningGoal(this),CL);
            createPlot(tgPlot,ax);
            this.PlotHandle = getPlotHandle(tgPlot);            
            addDataChangedListeners(this);

            delete(sw)
        end

        function TGPlot = get.TGPlot(this)
            TGPlot = this.PlotHandle.TuningGoalPlotManager;
        end
        
        % Add listeners
        function addDataChangedListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            this.DataChangedListener = [addlistener(this.ControlDesignData,'CompensatorValueChanged',@(es,ed) updateCurrentDesign(weakThis.Handle));
                addlistener(this.ControlDesignData,'PlantValueChanged',@(es,ed) updateSystem(weakThis.Handle))]; 
            this.TuningGoalChangedListener = addlistener(this.TuningGoalWrapper,'TuningGoal','PostSet',@(es,ed) updateTG(weakThis.Handle));
            this.TuningGoalDeleteListener = addlistener(this.TuningGoalWrapper,'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
            this.TGPlotDeleteListener = addlistener(this.TGPlot,'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
        end
        % Update system
        function updateSystem(this)
            % Called during PlantValueChanged
            this.TGPlot.System = getSystem(this);
        end
        
        function updateCurrentDesign(this)
            % Update only current design when Compensator Value Changes
            updateCurrentDesignData(this.TGPlot,getSystem(this));
        end
        
        % Update tuning goal
        function updateTG(this)
            % Called during TuningGoalWrapper's PostSet
            this.TGPlot.TuningGoal = this.TuningGoalWrapper.TuningGoal;
        end
        % Get system 
        function CL = getSystem(this,Design)
            % Returns the genss or slTuner
            if nargin == 2
                CL = getCL(this.ControlDesignData,Design);
            else
                CL = getCL(this.ControlDesignData);
            end
        end
        % Rename 
        % Get tuning goal
        function TuningGoal = getTuningGoal(this)
            % Extract TuningGoal from Wrapper 
            TuningGoal = this.TuningGoalWrapper.TuningGoal;
        end
        % Get TuningGoalWrapper
        function TuningGoalWrapper = getTuningGoalWrapper(this)
            TuningGoalWrapper = this.TuningGoalWrapper;
        end
        % Add design
        function addDesign(this,Design)
            % Add a design to the existing tuning goal plot (used by
            % compare design dialog)
            this.Designs = [this.Designs;Design];
            CL = getSystem(this,Design);
            DesignName = Design.Name;
            addDesign(this.TGPlot,CL,DesignName); %% REVISIT
            this.DesignStyles = getDesignStyles(this.TGPlot);
            weakThis = matlab.lang.WeakReference(this);
            L = addlistener(Design,'Name','PostSet',@(es,ed) cbDesignChanged(weakThis.Handle,Design));
            this.DesignChangedListener = [this.DesignChangedListener; L];
        end
        % Remove design
        function removeDesign(this,idx) 
            % Remove a design from exisiting tuning goal plot (used by
            % compare design dialog)
            this.Designs(idx) = [];
            removeDesign(this.TGPlot,idx);
            this.DesignStyles = getDesignStyles(this.TGPlot);
            this.DesignChangedListener(idx) = []; % REVISIT
        end
%         % Update Design %% REVIST
%         function updateDesign(this,Design)
%            NewSys = getSystem(this,Design);
%            updateCurrentDesignData(this.TGPlot,NewSys);
%         end
        % Call back 
        function cbDesignChanged(this,Design)
           % Needs to be implemented
           % Callback to update title of tuning goal plot when tuning goal
           % name changes
           
        end
        % Show the plot
        function show(this)
            if isempty(this.PlotHandle)
                createPlot(this);
            else
                this.PlotHandle.Visible = 'on';
            end
        end
        % Hide the plot
        function hide(this)
            if ~isempty(this.PlotHandle)
                this.PlotHandle.Visible = 'off';
            end
        end
    end

end

