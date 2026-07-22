classdef PIDTuner < handle
    %PIDTUNER
    
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties
        Parent
        TC
        TabGC
        TabGroupGC
        ResponsePlots
        ImportDialog
        MessagePanel
        isGroupActionClosing = false
        ResponsePlotTags = []
        
        Version = 1
    end
    
    methods
        function this = PIDTuner(tooldesktop, desiredtype, baselinecontroller)
            %PIDTUNER
            this.Parent = tooldesktop;
            this.TC = pidtool.desktop.pidtuner.PIDTunerTC(this.Parent.PlantList, desiredtype, baselinecontroller, this.Parent.SimulinkGateway, this.Parent.Type, this.Parent.TPComponent);
            TabGC = pidtool.desktop.pidtuner.PIDTunerTabGC(this.TC);
            this.TabGC = TabGC;
            this.TabGroupGC = matlab.ui.internal.toolstrip.TabGroup();
            this.TabGroupGC.Tag = 'PIDTunerTabGroup';
            this.Parent.TPComponent.addTabGroup(this.TabGroupGC);
            this.TabGroupGC.add(this.TabGC.TPComponent);
            addlistener(this.TabGC.DesignSection,'AddNewPlot',@(~,evnt)this.addResponsePlot(evnt.PlotType, evnt.ResponseType));
            addlistener(this.Parent.PlantList, 'ImportRequested', @(~,~)this.launchImportDialog());
            addlistener(this.Parent.PlantList, 'SelectedPlantIndex', 'PostSet', @(~,~)cbSelectedPlantChanged(this));
        end
        function addResponsePlot(this, plottype, responsetype)
            %ADDRESPONSEPLOT
            this.Parent.configureTiling(this);
            responseplot = pidtool.desktop.pidtuner.ResponsePlotGC(plottype, responsetype, this.TC.DataSourcePlot, this.Parent.FigureDocGroup.Tag);

            % Make unique tag
            newPlotTag = matlab.lang.makeUniqueStrings(responseplot.FigureDocument.Tag, this.ResponsePlotTags);
            responseplot.FigureDocument.Tag = newPlotTag;
            this.ResponsePlotTags = [this.ResponsePlotTags newPlotTag];

            this.Parent.TPComponent.add(responseplot.FigureDocument);
            responseplot.FigureDocument.Figure.AutoResizeChildren = 'off';
            % responseplot.PlotHandle.reset % NOTE: CHECK IF THIS IS CORRECT AND NEEDED (USED TO BE REFRESH)
            addlistener(responseplot, 'FigureCloseRequested', @(src, ~) cbCloseFigureRequest(src, this));
            this.ResponsePlots = [this.ResponsePlots; responseplot];
            WarningState = warning('off');
            set(responseplot.Figure,'visible','on');
            warning(WarningState);

        end
        
        %% Button Callbacks
        function launchImportDialog(this)
            isRegisterDlg = false;
            if isempty(this.ImportDialog)
                if strcmp(this.TC.ToolType, 'MATLAB')
                    this.ImportDialog = pidtool.desktop.pidtuner.gc.ImportDialogGC(this.TC);
                else
                    this.ImportDialog = slctrlguis.pidtuner.gc.ImportDialogGC(this.TC);
                end
                isRegisterDlg = true;
            end
            show(this.ImportDialog,this.TabGC.PlantSection.PlantSelector.ButtonTPComponent);
            if isRegisterDlg
                registerDialog(this.TC.DialogManager,this.ImportDialog);
            end
            centerDialog(this.TC.DialogManager,this.ImportDialog.Name)
        end
        
        %% Messages
        function postMessageOnPanel(this, str)
            if false % NOTE: REDO THIS
            show = true;
            if isempty(this.MessagePanel) || ~isvalid(this.MessagePanel)
                this.MessagePanel = ctrluis.toolstrip.MessagePanel(this.TC.DataSourcePlot.ActiveFigure);
            else
                show = ~this.MessagePanel.Minimized;
            end
            this.MessagePanel.Message = str;
            this.MessagePanel.Visible = true;
            if show
                this.MessagePanel.Minimized = false;
            else
                this.MessagePanel.Minimized = true;
            end
            end
        end
        function removeMessagePanel(this)
            if false % NOTE: REDO THIS
            if ~isempty(this.MessagePanel) && isvalid(this.MessagePanel)
                this.MessagePanel.Visible = false;
            end
            end
        end
        function updateMessagePanel(this)
            if this.Parent.PlantList.isSelectedPlantZero
                if this.Parent.PlantList.isSelectedPlantAdded
                    if this.Parent.PlantList.isSelectedPlantLinearized
                        txt = ctrlMsgUtils.message('Slcontrol:pidtuner:strLinearizedPlantZero');
                    else
                        txt = ctrlMsgUtils.message('Control:pidtool:strSelectedPlantZero');
                    end
                else
                    txt = ctrlMsgUtils.message('Control:pidtool:strSelectedPlantZero');
                end
%                 this.postMessageOnPanel(txt);
                uialert(this.Parent.TPComponent,txt,'')
            else
                this.removeMessagePanel();
            end
        end
        
    end
end

function cbSelectedPlantChanged(this)
this.updateMessagePanel();
end

function cbCloseFigureRequest(src, this)
if ishghandle(src.Figure) && ~this.isGroupActionClosing
        this.ResponsePlots(this.ResponsePlots == src).FigureCloseSuccess = true;
        this.ResponsePlots(this.ResponsePlots == src) = [];
        this.ResponsePlotTags(this.ResponsePlots == src) = [];
        src.closeFigureCleanup();
else
    src.closeFigureCleanup();
end
end

