classdef (Hidden) GenericResponsePlot < handle & matlab.mixin.Heterogeneous
    % Abstract class for Response Plots Plots.
 
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties(Hidden,SetAccess=private)
        ControlDesignData % Used to compute responses genss or slTuner
        ResponseWrapper % ResponseWrapper                        
        PlotHandle
        Designs
        DesignStyles = cell(0,2);
        Type
        
        ResponseWaveform
        DesignWaveforms
    end
    properties (Hidden,SetAccess=private,Transient)
        DataChangedListener
        ResponseChangedListener
        ResponseDeleteListener
        DesignChangedListener
        PlotDeleteListener
        Document
        Figure
    end
    
    methods
        function this = GenericResponsePlot(ResponseWrapper,CDD,Type)
            % GenericResponsePlot Contstructor
            this.ResponseWrapper = ResponseWrapper;
            this.ControlDesignData = CDD;
            this.Type = Type;
        end
    end
    
    methods
        function addDataChangedListeners(this)
            this.DataChangedListener = [addlistener(this.ControlDesignData,'CompensatorValueChanged',@(es,ed) updateResponseData(this));
                addlistener(this.ControlDesignData,'PlantValueChanged',@(es,ed) updatePlot(this))];
            this.ResponseChangedListener = addlistener(this.ResponseWrapper,'Response','PostSet',@(es,ed) updatePlot(this));
            this.ResponseDeleteListener = addlistener(this.ResponseWrapper,'ObjectBeingDestroyed',@(es,ed) delete(this));
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                this.PlotDeleteListener = event.listener(this.PlotHandle,'ObjectBeingDestroyed',@(es,ed) delete(this));
            else
                this.PlotDeleteListener = handle.listener(this.PlotHandle,'ObjectBeingDestroyed',@(es,ed) delete(this));
            end            
        end
        
        function delete(this)
            delete(this.PlotDeleteListener);
            delete(this.DataChangedListener);
            delete(this.ResponseChangedListener);
            delete(this.ResponseDeleteListener);
            
            if ishandle(this.PlotHandle)
                if controllib.chart.internal.utils.isChart(this.PlotHandle)
                    delete(this.PlotHandle);
                else
                    delete(this.PlotHandle.AxesGrid.Parent);
                end
            end
        end
        
        function CL = getCL(this,Design)
            % Returns the genss or slTuner
            if nargin == 2
                CL = getCL(this.ControlDesignData,Design);
            else
                CL = getCL(this.ControlDesignData);
            end
        end
        
        function Response = getResponse(this)
            % Extract Resposne from Wrapper
            Response = this.ResponseWrapper.Response;
        end
        
        function ResponseWrapper = getResponseWrapper(this)
            % Get ResponseWrapper
            ResponseWrapper = this.ResponseWrapper;
        end
        
        function Value = getResponseValue(this,DesignSnapshot)
            if nargin == 1
                CL = getCL(this.ControlDesignData);
                Name = getName(this.ResponseWrapper);
            else
                CL = getCL(this.ControlDesignData,DesignSnapshot);
                Name = sprintf('%s: %s',getName(this.ResponseWrapper),getName(DesignSnapshot));
            end
            Value = this.ResponseWrapper.Response.getValue(CL);
            Value = convertToSystemWithShortNames(this.ControlDesignData, Value);
            Value.Name = Name;
        end
        
        function show(this)
            if ishandle(this.PlotHandle)
                figure(this.PlotHandle.AxesGrid.Parent)
            else
                createPlot(this)
            end        
        end
        
        function hide(this)
            if ishandle(this.PlotHandle)
                set(this.PlotHandle.AxesGrid.Parent,'Visible','off')
            end
        end
        
        function updatePlot(this)
            try
                updateResponse(this)
                updateDesign(this)
            catch
                recreatePlot(this);
            end
        end
               
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
        
        function recreatePlot(this)
            % Get designs as this are deleted when plot is recreated
            StoredDesigns = this.Designs;
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                Fig = this.PlotHandle.Parent;
            else
                Fig = this.PlotHandle.AxesGrid.Parent;
            end
            
            delete(this.PlotDeleteListener);
            delete(this.DataChangedListener);
            delete(this.ResponseChangedListener);
            delete(this.ResponseDeleteListener);
            
            delete(this.PlotHandle);
            
            createPlot(this,Fig);
            
            for ct =1:length(StoredDesigns)
                this.addDesign(StoredDesigns(ct))
            end

        end
        
        function Fig = getFigure(this)
            if isempty(this.PlotHandle) || ~isvalid(this.PlotHandle)
                Fig = [];
            else
                if controllib.chart.internal.utils.isChart(this.PlotHandle)
                    Fig = this.PlotHandle.Parent;
                else
                    Fig = this.PlotHandle.AxesGrid.Parent;
                end                
            end
        end
        
        function updateResponse(this)
            updateResponseData(this)
            % update plot name, inputs and outputs
            set(getFigure(this),'Name',sprintf('%s: %s',getName(this.ResponseWrapper),this.Type.Tag));
            if controllib.chart.internal.utils.isChartResponse(this.ResponseWaveform)
                this.PlotHandle.InputNames=this.ResponseWaveform.Model.InputName;
                this.PlotHandle.OutputNames=this.ResponseWaveform.Model.OutputName;
                this.ResponseWaveform.Name = this.ResponseWaveform.Model.Name;
            else
                this.PlotHandle.InputName=this.ResponseWaveform.DataSrc.Model.InputName;
                this.PlotHandle.OutputName=this.ResponseWaveform.DataSrc.Model.OutputName;
                this.ResponseWaveform.Name = this.ResponseWaveform.DataSrc.Model.Name;
            end
            
        end
                
        function updateResponseData(this)
            % update response portion of the plot
            sw = ctrlMsgUtils.SuspendWarnings;
            NewValue = getResponseValue(this);
            
            if controllib.chart.internal.utils.isChartResponse(this.ResponseWaveform)
                OldValue = this.ResponseWaveform.Model;
            else
                OldValue = this.ResponseWaveform.DataSrc.Model;
            end
            
            if isequal(size(NewValue),size(OldValue)) && isequal(NewValue.Ts,OldValue.Ts)
                if controllib.chart.internal.utils.isChart(this.PlotHandle)
                    this.ResponseWaveform.Model = NewValue;
                else
                    this.ResponseWaveform.DataSrc.Model = NewValue;
                end
            else
                % Error to catch size changed so caller can recreate plot
                error('SystuneApp:data:sizechanged','Size changed error')
            end
            delete(sw);
        end
        
        function updateDesign(this,Designs)
            sw = ctrlMsgUtils.SuspendWarnings;
            if nargin == 1
                Designs = this.Designs;
            end
            for ct = 1:length(Designs)
                idx = find(Designs(ct)==this.Designs);
                Value = getResponseValue(this,Designs(ct));
                this.DesignWaveforms(idx).DataSrc.Model = Value;
                this.DesignWaveforms(idx).Name = Value.Name;
            end
            delete(sw);
        end
              
        function addDesign(this,Design,Style)
            sw = ctrlMsgUtils.SuspendWarnings;
            if nargin == 2
                NewStyle = findNextAvailableDesignStyle(this);
                Style = NewStyle;
            end
            
            Value = getResponseValue(this,Design);
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                addResponse(this.PlotHandle,Value,Name=Value.Name);
                if ~any(strcmp(this.PlotHandle.Type,{'iopzmap','pzmap'}))
                    % Set semantic color (blue) if plot is not pole-zero
                    % based. For pzplot and iopzplot, designs will follow
                    % color order
                    this.PlotHandle.Responses(end).LineStyle = Style{1,1};
                    this.PlotHandle.Responses(end).Style.SemanticColor = ...
                        controllib.plot.internal.utils.GraphicsColor(1,"quaternary").SemanticName;
                end
                
            else
                src = resppack.ltisource(Value, 'Name', Value.Name);
                r = this.PlotHandle.addresponse(src);
                
                type = this.PlotHandle.Tag;
                % Define characteristics
                chars = src.getCharacteristics(type);
                r.setCharacteristics(chars);
                % Set data function based on type
                switch type
                    case {'bode',systuneapp.PlotEnum.Bode,...
                            systuneapp.PlotEnum.Nichols}
                        r.DataFcn = {'magphaseresp' src type r []};
                        DesignColor = 'b';
                        DesignLineStyle = Style{1,1};

                    case {'nyquist',systuneapp.PlotEnum.Nyquist}
                        r.DataFcn = {type src r []};
                        DesignColor = 'b';
                        DesignLineStyle = Style{1,1};

                    case {'step','impulse',systuneapp.PlotEnum.Step,...
                            systuneapp.PlotEnum.Impulse}
                        r.DataFcn = {'timeresp' src type r};
                        r.Context = struct('Type',type,'Time',[],'Config',RespConfig());
                        DesignColor = 'b';
                        DesignLineStyle = Style{1,1};

                    case {'pzmap',systuneapp.PlotEnum.PoleZeroMap}
                        r.DataFcn = {'pzmap' src r};
                        DesignColor =  Style{1,2};
                        DesignLineStyle = '-';

                    case {'sigma',systuneapp.PlotEnum.SingularValue}
                        r.DataFcn =  {'sigma' src r [] 0};
                        DesignColor = 'b';
                        DesignLineStyle = Style{1,1};

                    case {'iopzmap',systuneapp.PlotEnum.IOPoleZeroMap}
                        r.DataFcn =  {'pzmap' src r 'io'};
                        DesignColor =  Style{1,2};
                        DesignLineStyle = '-';
                end
                initsysresp(r,type,this.PlotHandle.Options,[]);

                r.setstyle('LineStyle',DesignLineStyle,'Color',DesignColor);

                draw(this.PlotHandle);
            end
            
            L = addlistener(Design,'Name','PostSet',@(es,ed) updateDesign(this,Design));
                      
            this.Designs = [this.Designs;Design];
            this.DesignStyles = [this.DesignStyles;NewStyle];
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                this.DesignWaveforms = [this.DesignWaveforms,this.PlotHandle.Responses(end)];
            else
                this.DesignWaveforms = [this.DesignWaveforms; r];
            end
            
            this.DesignChangedListener = [this.DesignChangedListener; L];
            delete(sw);
        end
        
        function removeDesign(this,Design)
            idx = find(Design == this.Designs);
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                delete(this.DesignWaveforms(idx));
            else
                rmresponse(this.PlotHandle,this.DesignWaveforms(idx));
            end            
            this.DesignWaveforms(idx) = [];
            this.Designs(idx) = [];
            this.DesignStyles(idx,:) = [];
            this.DesignChangedListener(idx) = [];
        end
        
        function clearDependentData(this)
            % Clear dependent data
            this.DesignWaveforms = [];
            this.Designs = [];
            this.DesignStyles = ones(0,1);
            this.DesignChangedListener = [];
        end
        
        function createPlot(this,Fig)
            % Clear dependent data
            clearDependentData(this)
            
            sw = ctrlMsgUtils.SuspendWarnings;
            if isempty(this.PlotHandle) || ~ishandle(this.PlotHandle)
                if nargin == 1
                    hfig = figure('IntegerHandle','off',...
                        'NumberTitle','off',...
                        'HandleVisibility','callback',...
                        'Toolbar','none',...
                        'Menu','none');
                else
                    hfig = Fig;
                end
                ax = axes('Parent',hfig);
                               
                % Compute Data
                Value = getResponseValue(this);

                % Switch CSTPlots version to 2.0 to use control charts
                currentCSTPlotsVersion = controllibutils.CSTCustomSettings.setCSTPlotsVersion(2);
                
                switch this.Type
                    case systuneapp.PlotEnum.Step
                        h = stepplot(ax,Value);
                    case systuneapp.PlotEnum.Bode
                        h = bodeplot(ax,Value);
                    case systuneapp.PlotEnum.Impulse
                        h = impulseplot(ax,Value);
                    case systuneapp.PlotEnum.Nyquist
                        h = nyquistplot(ax,Value);
                    case systuneapp.PlotEnum.Nichols
                        h = nicholsplot(ax,Value);
                    case systuneapp.PlotEnum.SingularValue
                        h = sigmaplot(ax,Value);
                    case systuneapp.PlotEnum.PoleZeroMap
                        h = pzplot(ax,Value);
                    case systuneapp.PlotEnum.IOPoleZeroMap
                        h = iopzplot(ax,Value);
                end

                % Revert CSTPlots version
                controllibutils.CSTCustomSettings.setCSTPlotsVersion(currentCSTPlotsVersion);
 
                this.PlotHandle = h;

                if controllib.chart.internal.utils.isChart(this.PlotHandle)
                    this.ResponseWaveform = this.PlotHandle.Responses(1);
                    fig = this.PlotHandle.Parent;
                else
                    this.ResponseWaveform = this.PlotHandle.Response(1);
                    fig = ancestor(h.AxesGrid.Parent,'figure');
                end

                % Title
                set(fig,'Name',sprintf('%s: %s',Value.Name,this.Type.Tag));
                
                addDataChangedListeners(this);
            end
            delete(sw);
        end
        
        function createPlot_(this,Fig)
            % Clear dependent data
            clearDependentData(this)
            
            sw = ctrlMsgUtils.SuspendWarnings;
            if isempty(this.PlotHandle) || ~ishandle(this.PlotHandle)
                value = getResponseValue(this);
                if nargin == 1
                    figOptions.Title = sprintf('%s: %s',value.Name,this.Type.Tag);
                    document = matlab.ui.internal.FigureDocument(figOptions);
                    postfix = "_" + string(this.Type) + "_" + ...
                        getName(this.ResponseWrapper) + ...
                        "_" + matlab.lang.internal.uuid;
                    document.Tag = "CSTAppResponsePlotDocument"+postfix;                        
                    document.Figure.AutoResizeChildren = 'off';
                    hfig = document.Figure;
                    hfig.Tag = "CSTAppResponsePlotFigure"+postfix;
                    this.Document = document;
                else
                    hfig = Fig;
                end
                this.Figure = hfig;
                ax = axes('Parent',hfig);
                
                % Switch CSTPlots version to 2.0 to use control charts
                currentCSTPlotsVersion = controllibutils.CSTCustomSettings.setCSTPlotsVersion(2);

                % Compute Data
                switch this.Type
                    case systuneapp.PlotEnum.Step
                        h = stepplot(ax,value);
                    case systuneapp.PlotEnum.Bode
                        h = bodeplot(ax,value);
                    case systuneapp.PlotEnum.Impulse
                        h = impulseplot(ax,value);
                    case systuneapp.PlotEnum.Nyquist
                        h = nyquistplot(ax,value);
                    case systuneapp.PlotEnum.Nichols
                        h = nicholsplot(ax,value);
                    case systuneapp.PlotEnum.SingularValue
                        h = sigmaplot(ax,value);
                    case systuneapp.PlotEnum.PoleZeroMap
                        h = pzplot(ax,value);
                    case systuneapp.PlotEnum.IOPoleZeroMap
                        h = iopzplot(ax,value);
                end

                % Revert CSTPlots version
                controllibutils.CSTCustomSettings.setCSTPlotsVersion(currentCSTPlotsVersion);
 
                this.PlotHandle = h;
                if controllib.chart.internal.utils.isChart(h)
                    this.ResponseWaveform = this.PlotHandle.Responses(1);
                    if ~any(strcmp(this.PlotHandle.Type,["iopzmap","pzmap"]))
                        % Set semantic color (blue) if plot is not
                        % pole-zero based. For pzplot and iopzplot, designs
                        % will follow color order
                        this.ResponseWaveform.Style.SemanticColor = ...
                            controllib.plot.internal.utils.GraphicsColor(1,"primary").SemanticName;
                    end
                else
                    this.ResponseWaveform = this.PlotHandle.Response(1);
                end

                % Title
                %fig = ancestor(h.AxesGrid.Parent,'figure');
                %set(fig,'Name',sprintf('%s: %s',value.Name,this.Type.Tag));
                
                addDataChangedListeners(this);
            end
            delete(sw);
        end
        

        
    end

end