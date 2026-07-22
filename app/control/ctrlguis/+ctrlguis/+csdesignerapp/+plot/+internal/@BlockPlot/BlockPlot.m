classdef BlockPlot < controllib.plot.internal.AbstractCompareDesignPlot 
    % ResponsePlot class for Response Plots.
    
    % Copyright 2014-2020 The MathWorks, Inc.
    
    properties (Access = protected)
        Block % Primary Response
        Type % Plot Type
        ResponseWaveform % Response WaveForm
        DesignWaveforms % Design Waveforms
        Preferences
        ConstraintEditor
        Document
        MultiModelMenu
    end
    
    properties (Access = protected, Transient = true)
        DataChangedListeners
        DesignChangedListeners
        Figure
    end
    
    properties (Hidden)
        ResponseUpdateEnabled = true
    end    
    
    methods
        function this = BlockPlot(Block,Type)
            % Constructor
            this@controllib.plot.internal.AbstractCompareDesignPlot();
            this.Block = Block;
            this.Type = Type;
        end
        
        function Resp = getBlock(this)
            % Return the response object
            Resp = this.Block;
        end
        function Type = getType(this)
            Type = this.Type.Tag;
        end
        function setPreferences(this,Preferences)
            this.Preferences = Preferences;
        end
        function Resp = getResponse(this)
            % Return the response object
            Resp = this.Block;
        end
        function setConstraintEditor(this,CE)
            this.ConstraintEditor = CE;
        end
        function Document = getDocument(this)
            Document = this.Document;
        end
    end
    
    %% Set Methods
    methods
        function set.ResponseUpdateEnabled(this,value)
            this.ResponseUpdateEnabled = value;
            if value
                updateResponse(this);
            end
        end
    end
    
    
    %% Implement Abstract Methods
    methods (Access = protected)
        function h = createPlot_(this,Fig)
            import ctrlguis.csdesignerapp.plot.internal.PlotEnum;
            
            sw = ctrlMsgUtils.SuspendWarnings;
            if ~isPlotValid(this)
                Value = getResponseValue(this);
                if nargin == 1
                    figOptions.Title = sprintf('%s: %s',Value.Name,this.Type.Tag);
                    figOptions.DocumentGroupTag = ...
                        ctrlguis.csdesignerapp.utils.internal.getAppContainerTag('ResponsePlotDocumentGroup');
                    this.Document = matlab.ui.internal.FigureDocument(figOptions);
                    this.Document.Tag = "ResponsePlot_"  + string(this.Type) + "_" + ...
                                            matlab.lang.internal.uuid;
                    this.Document.Figure.AutoResizeChildren = 'off';
                    hfig = this.Document.Figure;
                    hfig.Tag = "CSDAppBlockPlot";
                else
                    hfig = Fig;
                end
                this.Figure = hfig;
 
                % Compute Data
                if this.PlotVersion == 2
                    h = createChart(this,this.Type.Tag);
                else
                    h = createView(this,this.Type.Tag);
                end
                
                % Add palette
                controllib.plot.internal.createToolbar(getaxes(h));
                
                this.PlotHandle = h;
                h.Visible = 'on';

                if controllib.chart.internal.utils.isChart(h)
                    this.ResponseWaveform = this.PlotHandle.Responses(1);
                else
                    this.ResponseWaveform = this.PlotHandle.Response(1);
                end
                
                % Title
                set(hfig,'Name',sprintf('%s: %s',Value.Name,this.Type.Tag));
                
                addDataChangedListeners(this);
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
                [NominalValue, Value] = getResponseValue(this,Designs(ct));
                if controllib.chart.internal.utils.isChartResponse(this.DesignWaveforms(idx))
                    this.DesignWaveforms(idx).Model = Value;
                    this.DesignWaveforms(idx).Name = NominalValue.Name;
                    this.DesignWaveforms(idx).NominalIndex = getNominalIndex(this.Block);
                else
                    this.DesignWaveforms(idx).DataSrc.UncertainModel = Value;
                    this.DesignWaveforms(idx).DataSrc.Model = NominalValue;
                    this.DesignWaveforms(idx).Name = NominalValue.Name;
                end
            end
            delete(sw);
        end
        
        
        function updatePlot(this)
            try
                updateResponse(this)
                updateDesign(this)
            catch
                recreatePlot(this);
            end
        end
        
        
        function updateResponse(this)
            % Check for ResponseUpdateEnabled flag (Set by Response
            % Optimization object)
            if this.ResponseUpdateEnabled
                [NomValue,Value] = getResponseValue(this);
                if controllib.chart.internal.utils.isChartResponse(this.ResponseWaveform)
                    this.ResponseWaveform.Model = Value;
                    this.ResponseWaveform.NominalIndex = getNominalIndex(this.Block);
                else
                    this.ResponseWaveform.DataSrc.UncertainModel = Value;
                    this.ResponseWaveform.DataSrc.Model = NomValue;
                end
            end
        end
        
        function recreatePlot(this)
             % Get designs as this are deleted when plot is recreated
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                Fig = this.PlotHandle.Parent;
            else
                Fig = this.PlotHandle.AxesGrid.Parent;
            end
            delete(this.PlotDeleteListener);
            delete(this.DataChangedListeners);           
            delete(this.PlotHandle);
            
            createPlot_(this,Fig);
            
            for ct =1:length(StoredDesigns)
                this.addDesign(StoredDesigns(ct))
            end
        end
    end
    
    
    
    methods (Access = public)
        function showDesign(this,Design,Style)
            if nargin == 2
                addDesign(this,Design)
            else
                addDesign(this,Design,Style)
            end
        end
        

    end
    
    methods (Access = protected)
        function [NominalValue, Value] = getResponseValue(this,DesignSnapshot)
            if nargin == 1
                Name = this.Block.Name;
                NominalValue = getValue(this.Block);
            else
                Name = sprintf('%s: %s',this.Block.Name,getName(DesignSnapshot));
                NominalValue = DesignSnapshot.getValueStructure.(this.Block.Name);
            end
            % REVISIT
            %             Value = convertToSystemWithShortNames(this.ControlDesignData, Value);
            NominalValue.Name = Name;
            Value = NominalValue;
        end
        
        function addDataChangedListeners(this)
            delete(this.DataChangedListeners);
            this.DataChangedListeners = addlistener(this.Block,'ValueChanged',@(es,ed) updateResponse(this));
            
            %             this.DataChangedListeners = [this.DataChangedListeners; addlistener(this.Block,'RefreshModeChanged',@(es,ed) setRefreshMode(this,ed))];
        end
        
        function addDesign_(this,Design,styleOrColor)
            sw = ctrlMsgUtils.SuspendWarnings;

            % %Revisit need to handle pzmap correctly
            if iscell(styleOrColor)
                DesignColor = styleOrColor{1,2};
            else
                DesignColor = styleOrColor;
            end
            DesignLineStyle = '-';
            
            [NomValue, Value] = getResponseValue(this,Design);
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                % Ignoring style/color input and letting color order of
                % charts manage the colors of designs added
                addSystem(this.PlotHandle,Value);
                this.PlotHandle.Responses(end).Style.SemanticColor = DesignColor;
                this.PlotHandle.Responses(end).NominalIndex = getNominalIndex(this.Block);
                this.DesignWaveforms = [this.DesignWaveforms; this.PlotHandle.Responses(end)];
                L = addlistener(Design,'Name','PostSet',@(es,ed) updateDesign(this,Design));
                this.DesignChangedListeners = [this.DesignChangedListeners; L];
            else
                src = resppack.ltisource(NomValue, 'Name', NomValue.Name);
                src.UncertainModel = Value;

                Styles = wavepack.wavestyle;
                setstyle(Styles,'LineStyle',DesignLineStyle,'Color',DesignColor);

                r = createResponse(this,getPlotHandle(this),src,Styles);

                draw(this.PlotHandle);
                L = addlistener(Design,'Name','PostSet',@(es,ed) updateDesign(this,Design));

                this.DesignWaveforms = [this.DesignWaveforms; r];
                this.DesignChangedListeners = [this.DesignChangedListeners; L];
            end            
            
            delete(sw);

        end
        
        function removeDesign_(this,Design)
            [~,~,idx] = intersect(Design,this.Designs);
            for k = 1:length(idx)
                if controllib.chart.internal.utils.isChart(this.PlotHandle)
                    delete(this.DesignWaveforms(idx(k)));
                else
                    rmresponse(this.PlotHandle,this.DesignWaveforms(idx(k)));
                end                
            end
            this.DesignWaveforms(idx) = [];
            this.DesignChangedListeners(idx) = [];
        end
        
        function setRefreshMode(this,ed)
            this.ResponseWaveform.RefreshMode = ed.Data;
            this.ResponseWaveform.Parent.AxesGrid.send('ViewChanged');
            if ~isempty(this.DesignWaveforms)
                this.DesignWaveforms.RefreshMode = ed.Data;
                this.DesignWaveforms.Parent.AxesGrid.send('ViewChanged');
            end
        end
        
        function cleanup(this)
            % REVISIT
            for ct = numel(this.DataChangedListeners):-1:1
                delete(this.DataChangedListeners);
                this.DataChangedListeners(ct) = [];
            end
            
            for ct = numel(this.DesignChangedListeners):-1:1
                delete(this.DesignChangedListeners);
                this.DesignChangedListeners(ct) = [];
            end
        end
        
        
    end
    
    methods(Access = private)
        function designConstr(this,View,ActionType)
            % Opens dialogs to add/edit design constraints
            switch ActionType
                case 'new'
                    % Add new constraint
                    if controllib.chart.internal.utils.isChart(View)
                        editconstr.NewRequirementDialog.getInstance(View,View.Parent);
                    else
                        editconstr.newdlg.getInstance(View, View.Axes.Parent);
                    end
                case 'edit'
                    if controllib.chart.internal.utils.isChart(View)
                        Constr = View.Requirements;
                    else
                        Constr = View.findconstr;
                    end
                    
                    if isempty(Constr)
                        % No constraints to show in this View
                        warnstr = getString(message('Control:designerapp:msgNoRequirementToEdit'));
                        uialert(this.Document.Figure,warnstr,...
                            getString(message('Control:designerapp:strEditRequirementWarning')),...
                            'Icon','warning');
                    else
                        %Have global constraint editor to use
                        this.ConstraintEditor.show(View);
                    end
            end
        end
    end
    
    methods(Hidden)
        function qeOpenDesignConstraintDialog(this,ActionType)
            % Open design constraint dialog to edit existing requirement or create a new one
            %
            % qeOpenDesignConstraintDialog(Viewer,'new')
            % qeOpenDesignConstraintDialog(Viewer,'edit')
            designConstr(this,this.PlotHandle,ActionType);
        end
    end
end