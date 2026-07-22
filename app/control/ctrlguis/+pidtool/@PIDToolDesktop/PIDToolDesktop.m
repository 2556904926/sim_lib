classdef PIDToolDesktop < handle
    %PIDTOOLDESKTOP
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TPComponent
        PlantListBrowser
        PlantList
        PIDTuner
        SimulinkGateway
        PlantIdentifier
        OpenLoopRelinearizer
        ClosedLoopRelinearizer
        
        Version = 2
        AppDefaultLayout = []
        FigureDocGroup
        FigureDocGroupPlantID
        FigureDocGroupRelin
        FigureDocument
        FigureAxes
        PreviewPanel
    end
    properties (SetAccess = private)
        Type = 'MATLAB' % Must be 'MATLAB' or 'Simulink'
        StatusBar
    end
    properties(Access = private)
        Listeners
        GroupName
        MD
    end
    
    methods
        function this = PIDToolDesktop(varargin)
            %PIDTOOLDESKTOP
            if nargin == 1
                this.SimulinkGateway = pidtool.desktop.SimulinkGateway(varargin{1});
                Plant = this.SimulinkGateway.LinearizedPlant;
                plantname = '';
                desiredtype = this.SimulinkGateway.PIDBlockData.Controller;
                baselinecontroller = this.SimulinkGateway.PIDBlockController;
                inspectordata = this.SimulinkGateway.InspectorData;
                this.Type = 'Simulink';
                if strcmp(this.SimulinkGateway.PIDModel, this.SimulinkGateway.TopModel)
                    grptitle = sprintf('%s (%s)',pidtool.utPIDgetStrings('cst','tunerdlg_title'),...
                        getfullname(this.SimulinkGateway.PIDBlockHandle));
                else
                    grptitle = sprintf('%s (%s) (%s)',pidtool.utPIDgetStrings('cst','tunerdlg_title'),...
                        getfullname(this.SimulinkGateway.PIDBlockHandle),...
                        ctrlMsgUtils.message('Slcontrol:pidtuner:toplevelmodel',this.SimulinkGateway.TopModel));
                end
                addlistener(this.SimulinkGateway, 'ModelLinearizationChanged', @(~,~)cbModelLinearizationChanged(this));
            elseif nargin == 3
                Plant = varargin{1};
                plantname = inputname(1);
                desiredtype = varargin{2};
                baselinecontroller = varargin{3};
                inspectordata = [];
                this.Type = 'MATLAB';
                grptitle = pidtool.utPIDgetStrings('cst', 'tunerdlg_title');
            else
                error('Invalid number of input arguments');
            end

            %====================================================================================================(Plant List)
            this.PlantList = pidtool.desktop.PIDToolPlantList();
            this.PlantListBrowser = pidtool.desktop.PlantListBrowser(this.PlantList);
            this.PlantList.addPlant(Plant,0, inspectordata, plantname);
            if strcmp(this.Type, 'Simulink')
                this.PlantList.SampleTime = this.SimulinkGateway.PIDBlockData.CompiledSampleTime;
            end
            %=================================================================================================(Desktop Group)
            appOptions.Title = grptitle;
            appOptions.Tag = sprintf('PIDTUNERAPP(%s)',matlab.lang.internal.uuid);
            appOptions.EnableTheming = true;
            this.TPComponent = matlab.ui.container.internal.AppContainer(appOptions);

            qabHelpBtn = matlab.ui.internal.toolstrip.qab.QABHelpButton();
            qabHelpBtn.ButtonPushedFcn = @(~,~) cbHelp();
            this.TPComponent.add(qabHelpBtn);
            this.GroupName = this.TPComponent.Tag;
            addToAppContainer(this.PlantListBrowser, this.TPComponent);

            % Add PreviewPanel
            this.PreviewPanel = matlab.ui.internal.databrowser.PreviewPanel('previewpanel',ctrlMsgUtils.message('Controllib:gui:DatabrowserPreview'));
            addToAppContainer(this.PreviewPanel, this.TPComponent);
            monitor(this.PreviewPanel, this.PlantListBrowser)
            
            %=====================================================================================================(PID Tuner)
            % PIDTuner contains tab and tabgroups
            this.PIDTuner = pidtool.desktop.PIDTuner(this, desiredtype, baselinecontroller);

            % Add a document group
            this.FigureDocGroup = matlab.ui.internal.FigureDocumentGroup(); 
            this.FigureDocGroup.Title = 'ResponsePlots';  % This line can be removed once the FigureDocumentGroup is modified to have a default title
            this.FigureDocGroup.Tag = 'PIDTunerResponsePlotsFigDocGroup';
            this.TPComponent.add(this.FigureDocGroup);
            
            %=======================================================================================(Initial design and Open)
            % Set status to busy and create CanCloseFcn to prevent PID
            % Tuner from closing during opening
            this.TPComponent.Busy = true;
            this.TPComponent.CanCloseFcn = @(~,~) canPIDTunerCloseFcn(this);

            try
                this.open();
                drawnow;
                if this.PIDTuner.TC.DataSourcePlot.hasBaseline && ~this.PIDTuner.TC.DataSourcePlot.showBaseline
                    if strcmp(this.Type, 'MATLAB')
                        this.PIDTuner.TC.setStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_unstablebase_warning'),'warning');
                    else
                        this.PIDTuner.TC.setStatusText(pidtool.utPIDgetStrings('scd','tunerdlg_unstableblock_warning'),'warning');
                    end
                end
                this.PIDTuner.TC.oneClick();
                if isa(Plant,'frd')
                    this.PIDTuner.addResponsePlot('bode','r2y');
                else
                    this.PIDTuner.addResponsePlot('step','r2y');
                end
                this.PIDTuner.updateMessagePanel();
                %=====================================================================================================(Listeners)
                addlistener(this.TPComponent, 'StateChanged',@(src, evnt) cbCloseGroup(this, src));
    
                addlistener(this.PlantList, 'OpenLoopRelinearizationRequested', ...
                    @(es,ed)showOpenLoopRelinearizationTab(this));
                addlistener(this.PlantList, 'ClosedLoopRelinearizationRequested', ...
                    @(es,ed)showClosedLoopRelinearizationTab(this));
                addlistener(this.PlantList, 'PlantIdentificationRequested', ...
                    @(es,ed)showIdentificationTab(this));
                try
                addlistener(this.PlantListBrowser, 'ComponentRequest', ...
                    @(es,ed)cbPlantListBrowserRequest(this,ed));
                end
                this.TPComponent.Busy = false;

            catch ME
                this.TPComponent.Busy = false;
                throwAsCaller(ME)       
            end
        end

        function open(this)
            %OPEN
            this.StatusBar = ctrluis.toolstrip.StatusMessage(this.GroupName,2);
            this.TPComponent.add(this.StatusBar.StatusBar)

            % Make app visible 
            this.TPComponent.WindowBounds = [100 100 1080 720];
            this.TPComponent.Visible = true;

            this.PIDTuner.TC.StatusBar = this.StatusBar;
            this.PlantList.StatusBar = this.StatusBar;
            if ~strcmp(this.Type, 'MATLAB')
                this.SimulinkGateway.StatusBar = this.StatusBar;
            end
        end
        function close(this)
            %CLOSE
            this.PIDTuner.isGroupActionClosing = true;
            close(this.TPComponent);
            if isvalid(this)
                % When CLOSE is called through command line this is not
                % required.  Deleting ResponsePlots is only necessary when
                % closing the app normally
                delete(this.PIDTuner.ResponsePlots);
                delete(this.PIDTuner.TC);
            end
        end
        function val = getPIDBlockHandle(this)
            %GETPIDBLOCKHANDLE
            val = this.SimulinkGateway.PIDBlockHandle;
        end
        function show(this)
            %SHOW
            if ~isempty( this.SimulinkGateway)
                this.SimulinkGateway.update();
            end
            this.TPComponent.Visible = true;
        end
        function configureTiling(this,~)
            
            if isempty(this.PIDTuner.ResponsePlots)
                return;
            end

        end

        function result = canPIDTunerCloseFcn(this)
            result = ~this.TPComponent.Busy;
        end

    end
    methods (Hidden)
        function plant = getSelectedPlant(this)
            plant = this.PlantList.SelectedPlant;
        end
    end
end
%=================================================================================================================(Callbacks)
function cbCloseGroup(this, container)
%CBCLOSEGROUP
ET = container.State;

if strcmp(ET,'TERMINATED')
    L = this.Listeners;
    for ct = 1:numel(L)
        delete(L{ct})
    end
    delete(this.PIDTuner.TC)
    delete(this)
end

end
function cbModelLinearizationChanged(this)
%CBMODELLINEARIZATIONCHANGED
this.PlantList.addPlant(this.SimulinkGateway.LinearizedPlant, 0, this.SimulinkGateway.InspectorData,'');
end
function cbClientAction(this, evnt)
% Selected tab changed callback
ET = evnt.EventData.EventType;
if strcmp(ET, 'ACTIVATED')
    fig = evnt.EventData.Client;
    if ~isempty(fig)
        tunertool = this.PIDTuner;
        plantidtool = this.PlantIdentifier;
        relintool = this.ClosedLoopRelinearizer;
        tooltag = get(fig,'Tag');
        if ~isempty(tunertool) && isvalid(tunertool) && strcmp(tooltag, 'PIDTunerFigure')
            tunertool.TC.updateStatusBar();
            tunertool.TC.DataSourcePlot.setActiveFigure(fig);
            tunertool.updateMessagePanel();
        elseif ~isempty(plantidtool) && isvalid(plantidtool) && ...
                strcmp(tooltag, sprintf('PIDIdentificationPlot:%s',plantidtool.Name))
            if ~strcmp(this.StatusBar.ParentTool,'plantid')
                this.StatusBar.setText('',[],'west');
                this.StatusBar.ParentTool = 'plantid';
            end
            showStatus(plantidtool.Data);
        elseif ~isempty(relintool) && isvalid(relintool) && strcmp(tooltag, 'RelinFigure')
            relintool.TC.updateStatusBar();
        else
            % ignore
        end
    end
end
end
function cbPlantListBrowserRequest(this,ed)
switch ed.Request
    case 'export'
        success = this.PIDTuner.TC.ExportDialogTC.exportControllerAndSelectedPlants('', ed.Variables);
        if success
            this.StatusBar.setText(pidtool.utPIDgetStrings('cst','strPlantExported'),'info','west');
        else
            this.StatusBar.setText('',[],'west');
        end
    case 'select'
        this.PlantList.SelectedPlant = ed.Variables{1};
end
end

function cbHelp(~,~)
%CBHELP Manage help button events
helpview('control','PIDTunerGeneralHelp');
end

%====================================================================================(Launch Open Loop Re-Linearization Tool)
function showOpenLoopRelinearizationTab(this)
% show tab for plant identification
if isempty(this.OpenLoopRelinearizer) || ~isvalid(this.OpenLoopRelinearizer)
    if false % NOTE: Disable Old Relin for now
        relintc = pidtool.desktop.relinearizetool.ReLinTC(this.SimulinkGateway, 'openloop');
        relintc.StatusBar = this.StatusBar;
        this.OpenLoopRelinearizer = pidtool.desktop.RelinearizationTool(relintc,this);
        L = handle.listener(this.OpenLoopRelinearizer.hPlot, 'ObjectBeingDestroyed',...
            {@localReleaseOpenLoopRelinearizer,this});
        this.Listeners{1} = L;
    else
        % Store Current Layout
        this.AppDefaultLayout = this.TPComponent.Layout;      

        if isempty(this.FigureDocGroupRelin)
            % Create new Figure Document Group for Sys ID Tab
            groupOptions.Title = "Relinearization";  % This line can be removed once the FigureDocumentGroup is modified to have a default title
            groupOptions.Tag = 'PIDTunerRelinFigDocGroup';
            groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            groupOptions.Context.ToolstripTabGroupTags = 'PIDTunerRelinPlotTabGroup';
            groupOptions.DefaultRegion = "right";

            this.FigureDocGroupRelin = matlab.ui.internal.FigureDocumentGroup(groupOptions); 
            this.TPComponent.add(this.FigureDocGroupRelin); 

        end
        this.TPComponent.DocumentGridDimensions = [2 1];

        % Create Open Loop ID Tab
        relintc = pidtool.desktop.relinearizetool.ReLinTC(this.SimulinkGateway, 'openloop', this.StatusBar);
        this.OpenLoopRelinearizer = pidtool.desktop.RelinearizationTool(relintc, this);
        L = handle.listener(this.OpenLoopRelinearizer.hPlot, 'ObjectBeingDestroyed',...
            {@localReleaseOpenLoopRelinearizer,this});
        this.Listeners{2} = L;
     end
else
    figure(this.OpenLoopRelinearizer.hPlot.AxesGrid.Parent);
end
this.OpenLoopRelinearizer.hPlot.Visible = 'on';
end
%==================================================================================(Launch Closed Loop Re-Linearization Tool)
function showClosedLoopRelinearizationTab(this)
% show tab for plant identification
if isempty(this.ClosedLoopRelinearizer) || ~isvalid(this.ClosedLoopRelinearizer)
    if false % NOTE: Disable Old Relin for now
        this.configureTiling([]);
        relintc = pidtool.desktop.relinearizetool.ReLinTC(this.SimulinkGateway, 'closedloop', this.StatusBar);
        this.ClosedLoopRelinearizer = pidtool.desktop.RelinearizationTool(relintc, this);
        L = handle.listener(this.ClosedLoopRelinearizer.hPlot, 'ObjectBeingDestroyed',...
            {@localReleaseClosedLoopRelinearizer,this});
        this.Listeners{2} = L;
    
    else
        % Store Current Layout
        this.AppDefaultLayout = this.TPComponent.Layout;      
        
        if isempty(this.FigureDocGroupRelin)
            % Create new Figure Document Group for Sys ID Tab
            groupOptions.Title = "Relinearization";  % This line can be removed once the FigureDocumentGroup is modified to have a default title
            groupOptions.Tag = 'PIDTunerRelinFigDocGroup';
            groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
            groupOptions.Context.ToolstripTabGroupTags = 'PIDTunerRelinPlotTabGroup';
            groupOptions.DefaultRegion = "right";

            this.FigureDocGroupRelin = matlab.ui.internal.FigureDocumentGroup(groupOptions); 
            this.TPComponent.add(this.FigureDocGroupRelin); 
        
        end
        this.TPComponent.DocumentGridDimensions = [2 1];
        
        % Create Closed Loop ID Tab
        relintc = pidtool.desktop.relinearizetool.ReLinTC(this.SimulinkGateway, 'closedloop', this.StatusBar);
        this.ClosedLoopRelinearizer = pidtool.desktop.RelinearizationTool(relintc, this);
        L = handle.listener(this.ClosedLoopRelinearizer.hPlot, 'ObjectBeingDestroyed',...
            {@localReleaseClosedLoopRelinearizer,this});
        this.Listeners{2} = L;
    end
else
    figure(this.ClosedLoopRelinearizer.hPlot.AxesGrid.Parent);
end
this.ClosedLoopRelinearizer.hPlot.Visible = 'on';
end
%========================================================================================================(Launch Sys-ID Tool)
function showIdentificationTab(this)
% show tab for plant identification

if ~controllibutils.isSITBInstalled
    TaskName = getString(message('Control:pidtool:strIdentifyNewPlant'));
    Msg = getString(message('Control:pidtool:requiresSITB',TaskName));
    uialert(this.TPComponent,Msg,'')
    return
end
if strcmp(this.Type, 'Simulink')
    isMatlab = false;
    is2DOF = this.SimulinkGateway.is2DOF;
else
    isMatlab = true;
    is2DOF = false;
end
if isempty(this.PlantIdentifier) || ~isvalid(this.PlantIdentifier)
   % check if final simulation time is finite
   sg = this.SimulinkGateway;
   if ~isMatlab && isinf(sg.ModelStopTime)
      Msg = getString(message('Control:pidtool:identifierNersFiniteEndTime'));
      uialert(this.TPComponent,Msg,'')
      return
   end
    % Store Current Layout
    this.AppDefaultLayout = this.TPComponent.Layout;

    if isempty(this.FigureDocGroupPlantID)
        % Create new Figure Document Group for Sys ID Tab
        groupOptions.Title = "PlantIdentification";  % This line can be removed once the FigureDocumentGroup is modified to have a default title
        groupOptions.Tag = 'PIDTunerPlantIDFigDocGroup';
        groupOptions.Context = matlab.ui.container.internal.appcontainer.ContextDefinition();
        groupOptions.Context.ToolstripTabGroupTags = 'PIDTunerIdentPlotTabGroup';
        groupOptions.DefaultRegion = "right";

        this.FigureDocGroupPlantID = matlab.ui.internal.FigureDocumentGroup(groupOptions); 
        this.TPComponent.add(this.FigureDocGroupPlantID); 

    end
    this.TPComponent.DocumentGridDimensions = [2 1];

    % Add Plant Data to Plant ID Tab
    Data = iduis.pid.TaskData(isMatlab,is2DOF,this.PlantList);
    Data.StatusBar = this.StatusBar;

    % Create Plant ID Tab
    this.PlantIdentifier = iduis.pid.IdentificationPlot(pidtool.utPIDgetStrings('cst','strIdentification'),...
        Data, this.TPComponent, this.PIDTuner.TC.DialogManager);
    this.PlantIdentifier.DataGenerationMode.setSLGateway(sg);
    L1 = handle.listener(this.PlantIdentifier.hPlot, 'ObjectBeingDestroyed',...
        {@localReleaseIdentifier,this});
    this.Listeners{3} = L1;
        
else
    figure(this.PlantIdentifier.hPlot.AxesGrid.Parent);
end
this.PlantIdentifier.hPlot.Visible = 'on';
showInstructionBanner(this.PlantIdentifier, true)
end
%==================================================================================================================(Clean-up)
function localReleaseOpenLoopRelinearizer(~,~,this)
% Release plant identifier.
this.OpenLoopRelinearizer = [];
end
function localReleaseClosedLoopRelinearizer(~,~,this)
% Release plant identifier.
this.ClosedLoopRelinearizer = [];
end
function localReleaseIdentifier(~,~,this)
% Release plant identifier.
this.PlantIdentifier = [];
end

