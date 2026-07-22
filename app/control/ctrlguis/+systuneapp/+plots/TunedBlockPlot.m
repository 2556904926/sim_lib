classdef (Hidden) TunedBlockPlot < handle
    % Class for Tuned Block Plots.
 
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        ControlDesignData % Used to compute responses genss or slTuner
        TunedBlock                        
        PlotHandle
        Designs
        DesignStyles = cell(0,2);
        ComputedData
        Type
        XResponse
    end
    properties (SetAccess=private,Transient,Hidden)
        DataChangedListener
        CompensatorDeleteListener
        PlotDeleteListener
        Document
        Figure
    end
    
    methods
        function this = TunedBlockPlot(TunedBlock,CDD,Type)
            % TuningGoalPlot Contstructor
            this.TunedBlock = TunedBlock;
            this.ControlDesignData = CDD;
            this.Type = Type;
        end
    end
    
    methods
        
        function addDataChangedListeners(this)
            this.DataChangedListener = addlistener(this.TunedBlock,'ParameterizationChanged',@(es,ed) updateResponse(this));
            this.CompensatorDeleteListener = [addlistener(this.ControlDesignData,'TunableBlocksListChanged',@(es,ed) deleteUnwantedPlots(this));
                addlistener(this.ControlDesignData,'ArchitectureChanged',@(es,ed) deleteUnwantedPlots(this))];
            this.PlotDeleteListener = addlistener(this.PlotHandle,'ObjectBeingDestroyed',@(es,ed) delete(this));
        end
        
        function delete(this)
            delete(this.PlotDeleteListener);
            delete(this.DataChangedListener);
            delete(this.CompensatorDeleteListener);
            
            if ishandle(this.PlotHandle)
                delete(this.PlotHandle.Parent)
            end
        end
        
        function show(this)
            if ishandle(this.PlotHandle)
                figure(this.PlotHandle.Parent)
            else
                createPlot(this)
            end        
        end
        
        function hide(this)
            if ishandle(this.PlotHandle)
                set(this.PlotHandle.Parent,'Visible','off')
            end
        end
        
        function deleteUnwantedPlots(this)
            TB = this.ControlDesignData.getTunableBlock;
            if isempty(TB)
                delete(this);
            elseif ~isvalid(this.TunedBlock) || ~ismember(this.TunedBlock.Name, {TB.Name})
                delete(this);
            end
        end
            
%         function updatePlot(this)
%             updateGoal(this)
%             updateResponse(this)
%             updateDesign(this)
%         end
               
        function StyleList = getDesignStyleList(this)
            StyleList = {...
                '--', 'g';
                '-.', 'c';
                ':' , 'r'};

        end
        
        function Style = findNextAvailableDesignStyle(this)
            StyleList = getDesignStyleList(this);
                        
            index = zeros(size(StyleList(:,1)));
            for ct=1:length(this.DesignStyles(:,1))
                [~,~,match] = intersect(this.DesignStyles(ct,1),StyleList(:,1));
                index(match) = index(match) + 1;
            end
            
            [~, StyleIdx] = min(index);
            Style = StyleList(StyleIdx,:);
        end
                
        function createPlot(this)
            if isempty(this.PlotHandle)
                hfig = figure('IntegerHandle','off',...
                    'NumberTitle','off',...
                    'HandleVisibility','callback',...
                    'Toolbar','none',...
                    'Menu','none');
                ax = axes('Parent',hfig);               
 
                CSTPlotVersion = controllibutils.CSTCustomSettings.setCSTPlotsVersion(2);
                this.PlotHandle = pzplot(ax, this.TunedBlock.getParameterization,'b');
                controllibutils.CSTCustomSettings.setCSTPlotsVersion(CSTPlotVersion);
                this.XResponse = this.PlotHandle.Responses(1);
                this.PlotHandle.Responses(1).Style.LineWidth=1.75;

                
                % REVISIT MOVE TO UPDATE LIMITS

                % Freeze Y limits (altered by patch)
                set(ax,'YLim',get(ax,'Ylim'))
                
                % Title
                this.PlotHandle.Title.String = sprintf('%s: poles and zeros', this.TunedBlock.Name);
                this.PlotHandle.AxesStyle.GridVisible = true;
                % Plot bounds
               
%                 r = this.PlotHandle.addSigmaBound(this.ComputedData.MaxG,'upper',...
%                     TuningGoal.Focus * funitconv('rad/TimeUnit','rad/s',this.ComputedData.MaxG.TimeUnit));
%                 r.Name = 'Max';
%                 r.setstyle('color','y');
%                 this.MaxGainDataSource = r.DataSrc;
                
                
                addDataChangedListeners(this);
            end
        end

        function createPlot_(this)
            if isempty(this.PlotHandle)

                figOptions.Title = this.TunedBlock.Name;
                this.Document = matlab.ui.internal.FigureDocument(figOptions);
                postfix = "_" + string(this.Type) + "_" + ...
                    matlab.lang.internal.uuid;
                this.Document.Tag = "CSTAppResponsePlotDocument"+postfix;
                this.Document.Figure.AutoResizeChildren = 'off';
                hfig = this.Document.Figure;
                hfig.Tag = "CSTAppResponsePlotFigure"+postfix;
                this.Figure = hfig;
 
                ax = axes('Parent',hfig);               
 
                CSTPlotVersion = controllibutils.CSTCustomSettings.setCSTPlotsVersion(2);
                this.PlotHandle = pzplot(ax, this.TunedBlock.getParameterization,'b');
                controllibutils.CSTCustomSettings.setCSTPlotsVersion(CSTPlotVersion);
                this.XResponse = this.PlotHandle.Responses(1);
                this.PlotHandle.Responses(1).Style.LineWidth=1.75;

                
                % REVISIT MOVE TO UPDATE LIMITS

                % Freeze Y limits (altered by patch)
                set(ax,'YLim',get(ax,'Ylim'))
                
                % Title
                this.PlotHandle.Title.String = sprintf('%s: poles and zeros', this.TunedBlock.Name);
                this.PlotHandle.AxesStyle.GridVisible = true;
                % Plot bounds
                addDataChangedListeners(this);
            end
        end
        
        function updateResponse(this)
            TB = this.ControlDesignData.getTunableBlock;
            for ct = 1:numel(TB)
                if TB(ct).Name == this.TunedBlock.Name
                    this.TunedBlock = TB(ct);
                     this.XResponse.Model = this.TunedBlock.getParameterization;
                    return;
                end
            end
        end
    end

end