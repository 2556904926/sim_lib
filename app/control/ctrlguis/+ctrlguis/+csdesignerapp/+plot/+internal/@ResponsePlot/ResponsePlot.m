classdef ResponsePlot < controllib.plot.internal.AbstractCompareDesignPlot
    % ResponsePlot class for Response Plots.
    
    % Copyright 2014-2023 The MathWorks, Inc.
    
    properties (Access = protected)
        Response % Primary Response
        Type % Plot Type
        ResponseWaveform % Response WaveForm
        DesignWaveforms % Design Waveforms
        Preferences
        ConstraintEditor
    end
    
    properties (Access = protected, Transient = true)
        DataChangedListeners
        DesignChangedListeners
        Figure
        Document
        MultiModelMenu
        IsMultiModel = false
        ShowMultiModelBounds = false
        ShowMultiModelResponses = false
    end
    
    properties (Hidden)
        ResponseUpdateEnabled = true
    end
    
    methods
        function this = ResponsePlot(Response,Type)
            % Constructor
            this@controllib.plot.internal.AbstractCompareDesignPlot();
            this.Response = Response;
            this.Type = Type;
        end
        
        function Resp = getResponse(this)
            % Return the response object
            Resp = this.Response;
        end
        function Type = getType(this)
            Type = this.Type.Tag;
        end
        function setPreferences(this,Preferences)
            this.Preferences = Preferences;
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
                                    getName(this.Response) + "_" + matlab.lang.internal.uuid;
                    this.Document.Figure.AutoResizeChildren = 'off';
                    hfig = this.Document.Figure;
                    hfig.Tag = "CSDAppResponsePlot";
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
				
                this.PlotHandle = h;

                % Add palette
                controllib.plot.internal.createToolbar(getaxes(h));  

                if controllib.chart.internal.utils.isChart(h)
                    this.ResponseWaveform = this.PlotHandle.Responses(1);
                else
                    this.ResponseWaveform = this.PlotHandle.Response(1);               
                end

                % Show input/output labels for SISO plots too
                if any(strcmp(h.Type,{'step','impulse','bode','nyquist','nichols','iopzmap'}))
                    h.InputLabels.Visible = true;
                    h.OutputLabels.Visible = true;
                end
				
                % Title
%                 set(hfig,'Name',sprintf('%s: %s',Value.Name,this.Type.Tag));
                
                % Interpreter
                setInterpreter(this,'none');
                
                % Update multimodel menu
                updateMultiModelMenus(this)
                
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
                    this.DesignWaveforms(idx).NominalIndex = getNominalIndex(this.Response);
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
            updateMultiModelMenus(this);
        end
        
        
        function updateResponse(this)
            % Check for ResponseUpdateEnabled
            if this.ResponseUpdateEnabled
                if controllib.chart.internal.utils.isChartResponse(this.ResponseWaveform)
                    [NomValue,Value] = getResponseValue(this);
                    OldValue = this.ResponseWaveform.Model;
                    if isequal(size(Value),size(OldValue))
                        this.ResponseWaveform.Model = Value;
                    else
                        % Error to catch size changed so caller can recreate plot
                        error(message('Controllib:general:UnexpectedError','Size changed error'));
                    end

                    if ~any(strcmp(this.PlotHandle.Type,{'pzmap','sigma','rlocus'}))
                        this.PlotHandle.InputNames = Value.InputName;
                        this.PlotHandle.OutputNames = Value.OutputName;
                    end
                    this.ResponseWaveform.Name = Value.Name;
                    this.ResponseWaveform.NominalIndex = getNominalIndex(this.Response);
                else
                    sw = ctrlMsgUtils.SuspendWarnings;
                    [NomValue,Value] = getResponseValue(this);
                    OldValue = this.ResponseWaveform.DataSrc.Model;
                    if isequal(size(NomValue),size(OldValue))
                        this.ResponseWaveform.DataSrc.UncertainModel = Value;
                        this.ResponseWaveform.DataSrc.Model = NomValue;
                    else
                        % Error to catch size changed so caller can recreate plot
                        error(message('Controllib:general:UnexpectedError','Size changed error'))
                    end
                    delete(sw);
                    this.PlotHandle.InputName=this.ResponseWaveform.DataSrc.Model.InputName;
                    this.PlotHandle.OutputName=this.ResponseWaveform.DataSrc.Model.OutputName;
                    this.ResponseWaveform.Name = this.ResponseWaveform.DataSrc.Model.Name;
                end
                
                this.Document.Title = sprintf('%s: %s',NomValue.Name,this.Type.Tag);
            end
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
            delete(this.DataChangedListeners);
            delete(this.PlotHandle);
            
            createPlot_(this,Fig);
            
            for ct =1:length(StoredDesigns)
                this.addDesign(StoredDesigns(ct))
            end
        end
        function setInterpreter(this,Interpreter)
            if controllib.chart.internal.utils.isChart(this.PlotHandle)
                this.PlotHandle.Title.Interpreter = Interpreter;
                if isa(this.PlotHandle,'controllib.chart.internal.foundation.MixInInputOutputPlot')
                    this.PlotHandle.InputLabels.Interpreter = Interpreter;
                    this.PlotHandle.OutputLabels.Interpreter = Interpreter;
                end
            else
                Options = getoptions(this.PlotHandle);
                CurrentOptions = Options;
                CurrentOptions.Title.Interpreter = Interpreter;
                CurrentOptions.InputLabels.Interpreter = Interpreter;
                CurrentOptions.OutputLabels.Interpreter = Interpreter;
                setoptions(this.PlotHandle,CurrentOptions);
            end
        end
        
        function updateMultiModelMenus(this)
            %updateMultiModelMenus  updates the multimodel menus for the SISO Tool LTI
            %Viewer.
            [~,Val] = this.Response.getValue;
            s = size(Val);
            if prod(s(3:end)) > 1
                EnableFlag = 'on';
            else
                EnableFlag = 'off';
            end

            try
                if controllib.chart.internal.utils.isChart(this.PlotHandle)
                    set(this.MultiModelMenu,'Enable',EnableFlag);
                else
                    ax = this.PlotHandle.AxesGrid.getaxes;
                    hmenu = findobj(get(ax(1),'UIContextMenu'),'Tag','MultiModel');
                    set(hmenu,'Enable',EnableFlag)
                    if strcmp(EnableFlag,'off') && hasCharacteristic(this.PlotHandle,'MultipleModelView');
                        this.PlotHandle.hideCharacteristic('MultipleModelView');
                    end
                end
            end
        end
    end
    
    methods (Access = public)
        function showDesign(this,Design,styleOrColor)
            if nargin == 2
                addDesign(this,Design)
            else
                addDesign(this,Design,styleOrColor)
            end
        end
        
        
    end
    
    methods (Access = protected)
        function [NominalValue, Value] = getResponseValue(this,DesignSnapshot)
            if nargin == 1
                Name = getName(this.Response);
                [NominalValue,Value] = getValue(this.Response);
            else
                Name = sprintf('%s: %s',getName(this.Response),getName(DesignSnapshot));
                [NominalValue,Value] = getValue(this.Response,DesignSnapshot);
            end
            % REVISIT
            %             Value = convertToSystemWithShortNames(this.ControlDesignData, Value);
            NominalValue.Name = Name;
            
        end
        
        function addDataChangedListeners(this)
            delete(this.DataChangedListeners);
            weakThis = matlab.lang.WeakReference(this);
            this.DataChangedListeners = addlistener(this.Response,'ValueChanged',@(es,ed) updateResponse(weakThis.Handle));
            this.DataChangedListeners = [this.DataChangedListeners; addlistener(this.Response,'DefinitionChanged',@(es,ed) updatePlot(weakThis.Handle))];
            this.DataChangedListeners = [this.DataChangedListeners; addlistener(this.Response,'PlantValueChanged',@(es,ed) updatePlot(weakThis.Handle))];
            this.DataChangedListeners = [this.DataChangedListeners; addlistener(this.Response,'RefreshModeChanged',@(es,ed) setRefreshMode(weakThis.Handle,ed))];
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
                addResponse(this.PlotHandle,Value);
                this.PlotHandle.Responses(end).ArrayVisible = this.PlotHandle.Responses(1).ArrayVisible;
                this.PlotHandle.Responses(end).NominalIndex = this.PlotHandle.Responses(1).NominalIndex;
                this.PlotHandle.Responses(end).Style.SemanticColor = DesignColor;
                this.PlotHandle.Responses(end).NominalIndex = getNominalIndex(this.Response);
                this.DesignWaveforms = [this.DesignWaveforms; this.PlotHandle.Responses(end)];
                weakThis = matlab.lang.WeakReference(this);
                L = addlistener(Design,'Name','PostSet',@(es,ed) updateDesign(weakThis.Handle,Design));
                this.DesignChangedListeners = [this.DesignChangedListeners; L];
            else
                
                src = resppack.ltisource(NomValue, 'Name', NomValue.Name);
                src.UncertainModel = Value;

                Styles = wavepack.wavestyle;
                setstyle(Styles,'LineStyle',DesignLineStyle,'Color',DesignColor);

                r = createResponse(this,getPlotHandle(this),src,Styles);

                draw(this.PlotHandle);

                L = addlistener(Design,'Name','PostSet',@(es,ed) updateDesign(weakThis.Handle,Design));

                this.DesignWaveforms = [this.DesignWaveforms; r];
                
                delete(sw);
            end
            
            
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
            if controllib.chart.internal.utils.isChartResponse(this.ResponseWaveform)
                setRefreshMode(this.PlotHandle,ed.Data);
            else
                % REVISIT: Is this the best way to clear data src to trigger
                % update of focus
                this.ResponseWaveform.RefreshMode = ed.Data;
                if strcmpi(ed.Data,'normal')
                    this.ResponseWaveform.DataSrc.send('SourceChanged')
                end
                if ~isempty(this.DesignWaveforms)
                    for ct = 1:numel(this.DesignWaveforms)
                        this.DesignWaveforms(ct).RefreshMode = ed.Data;
                    end
                end
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
    
    methods (Access = private)
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
                    % Edit constraints in editor if there are constraints to edit.
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
    
    methods (Hidden = true)
        function CE = qeGetConstraintEditor(this)
            CE = this.ConstraintEditor;
        end
        
        function qeOpenDesignConstraintDialog(this,ActionType)
            % Open design constraint dialog to edit existing requirement or create a new one
            %
            % qeOpenDesignConstraintDialog(Viewer,'new')
            % qeOpenDesignConstraintDialog(Viewer,'edit')
            designConstr(this,this.PlotHandle,ActionType);
        end
    end
end



%