classdef RelinearizationTool < ctrluis.toolstrip.FigureTool
    %RELINEARIZATIONTOOL
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        Parent
        TC
        hPlot
        TabGC
        SnapshotTimeModifier
        FigureUtilsTab
    end
    properties (Access = private)
        Listener
    end
    methods
        function this = RelinearizationTool(tc, tooldesktop)
            %RELINEARIZATIONTOOL                     
            
            this = this@ctrluis.toolstrip.FigureTool('TabVersion',2,'ContainerVersion',2);
            this.Parent = tooldesktop;
            this.TC = tc;
            switch this.TC.Type
                case 'openloop'
                    this.TabGC = pidtool.desktop.relinearizetool.OpenLoopReLinTabGC(this.TC);
                case 'closedloop'
                    this.TabGC = pidtool.desktop.relinearizetool.ClosedLoopReLinTabGC(this.TC);
            end
            
            % Add Tag to Contextual Tab Group so it can be added to
            % AppContainer
            this.TabGroup.Tag = 'PIDTunerRelinPlotTabGroup';

            this.Tab = this.TabGC.TPComponent;
            this.createFigure();
            this.hPlot = createPlot(this);
            this.TC.hPlot = this.hPlot;
            this.SnapshotTimeModifier = pidtool.desktop.relinearizetool.gc.SnapshotTimeModifier(this.hPlot, this.TC.SnapshotTime);
            add(this,this.Parent.TPComponent);
            addlistener(this.SnapshotTimeModifier, 'Position', 'PostSet', @(~,~)cbSnapshotTimeModifier(this));
            addlistener(this.TC, 'SnapshotTime', 'PostSet', @(~,~) cbSnapshotTimeTC(this));
            AxesHandle = get(this.Figure,'CurrentAxes');
            % Add Floating Palette to Figure
            controllib.plot.internal.createToolbar(AxesHandle);
            AxesHandle.Toolbar.Children(4).Value = 'on';
            legend(AxesHandle, 'show');
        end
        function delete(this)
            %DELETE
            
            close(this);
        end
        function canClose = close(this)
            %CLOSE
            
            % Needed For AppContainer
            canClose = true;
            
            remove(this)
            if ishandle(this.hPlot)
                delete(this.hPlot);
            end
            this.hPlot = [];
            if ~isempty(this.TabGC)
                cmp = this.TabGC.TPComponent;
                if ~isempty(cmp) && isvalid(cmp)
                    delete(cmp)
                end
                this.TabGC = [];
            end
            if ishghandle(this.Figure)
                delete(this.Figure);
            end
        end
    end
    methods (Access = private)
        function createFigure(this)
            %CREATEFIGURE
            if strcmp(this.TC.Type, 'closedloop')
                figName = pidtool.utPIDgetStrings('scd','strCLSnapshotReLin');
            else
                figName = pidtool.utPIDgetStrings('scd','strOLSnapshotReLin');
            end
            this.FigureDocument = matlab.ui.internal.FigureDocument;
            this.FigureDocument.Title = figName;
            this.FigureDocument.CanCloseFcn = @(es,ed) close(this);

            % Create document tag
            docTag = 'RelinFigure';
            this.FigureDocument.Tag = docTag;
            this.FigureDocument.DocumentGroupTag = 'PIDTunerRelinFigDocGroup'; % NOTE: REPLACE HARD CODED STRING
            this.Figure = this.FigureDocument.Figure;
        end
        function h = createPlot(this)
            %CREATEPLOT
            
            datasrc = this.TC.IODataSource;
            [ynames,unames] = getIONames(datasrc);
            ax = axes('Parent',this.Figure, 'Units', 'normalized');
            h = iodataplot(ax,'time',unames,ynames,[],cstprefs.tbxprefs);
            h.AxesGrid.Title = '';
            r = h.addwave(datasrc);
            DefinedCharacteristics = datasrc.getCharacteristics('time');
            r.setCharacteristics(DefinedCharacteristics);
            r.DataFcn = {'getData' datasrc r};
            r.setstyle('b');
            r.Visible = 'off';
            hgroup = handle(r.Group);
            hgroup(1).Annotation.LegendInformation.IconDisplayStyle = r.Visible; %#ok<NASGU>
            this.Listener = handle.listener(r,r.findprop('Visible'),'PropertyPostSet',{@this.updateLegend r});
            iodataplotmenu(h, 'time');
            h.AxesGrid.Grid = 'on';
        end
        
        function updateLegend(this,~,~,r)
            hgroup = handle(r.Group);
            hgroup(1).Annotation.LegendInformation.IconDisplayStyle = r.Visible; %#ok<NASGU>
        end
    end
end
function cbSnapshotTimeModifier(this)
%CBSNAPSHOTTIMEMODIFIER

this.TC.SnapshotTime = this.SnapshotTimeModifier.Position;
end
function cbSnapshotTimeTC(this)
%CBSNAPSHOTTIMETC

this.SnapshotTimeModifier.Position = this.TC.SnapshotTime;
end
