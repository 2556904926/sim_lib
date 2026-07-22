classdef SparsePlotOptionsDialog < controllib.ui.internal.dialog.AbstractDialog
    % Sparse Plot Options Dialog  The dialog to enter time and frequency
    % vectors for sparse model response plotting
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc.
    
    %% Properties
    properties (SetAccess=private)
        Initialized = false
    end

    properties (AbortSet,SetObservable)
        VectorType = "freq"
    end

    properties (Access = protected)
        Widgets
        InputLayout
        FreqLayout
    end

    properties (Dependent,SetAccess=private)
        Vector
    end

    properties (Access = private)
        TimeVector = 0:0.01:10
        FreqVector = logspace(-1,3,100)
    end

    properties (AbortSet,WeakHandle)
        ModelWrapper (1,1) mrtool.data.ModelWrapper
    end

    %% Events
    events
        DialogClosed
    end

    %% Constructor
    methods
        function this = SparsePlotOptionsDialog(ModelWrapper)
            arguments
                ModelWrapper (1,1) mrtool.data.ModelWrapper
            end
            this = this@controllib.ui.internal.dialog.AbstractDialog; 
            this.Title = getString(message('Control:mrtool:PlotSparseSpecifyVectorsTitle'));
            this.ModelWrapper = ModelWrapper;
        end
    end

    %% Get/Set
    methods
        % VectorType
        function set.VectorType(this,VectorType)
            arguments
                this (1,1) mrtool.dialogs.SparsePlotOptionsDialog
                VectorType (1,1) string {mustBeMember(VectorType,["time";"freq"])}
            end
            this.VectorType = VectorType;
            updateUI(this);
        end

        %Vector
        function Vector = get.Vector(this)
            switch this.VectorType
                case "time"
                    Vector = this.TimeVector;
                case "freq"
                    Vector = this.FreqVector;
            end            
        end
    end

    %% Public methods
    methods
        function updateUI(this)   
            % Initialize dialog type based on type: 'freq' or 'time'
            switch this.VectorType
                case 'time'
                    this.InputLayout.RowHeight{1} = 'fit';
                    this.InputLayout.RowHeight{2} = 'fit';
                    this.InputLayout.RowHeight{3} = 0;
                    this.InputLayout.RowHeight{4} = 0;
                    this.Widgets.TimeMessageLabel.Visible = 'on';
                    this.Widgets.TimeVectorLabel.Visible = 'on';
                    this.Widgets.TimeVectorEditField.Visible = 'on';
                    this.Widgets.FreqMessageLabel.Visible = 'off';
                    this.Widgets.FreqVectorLabel.Visible = 'off';
                    this.Widgets.FreqVectorEditField.Visible = 'off';
                case 'freq'
                    this.InputLayout.RowHeight{1} = 0;
                    this.InputLayout.RowHeight{2} = 0;
                    this.InputLayout.RowHeight{3} = 'fit';
                    this.InputLayout.RowHeight{4} = 'fit';
                    this.Widgets.TimeMessageLabel.Visible = 'off';
                    this.Widgets.TimeVectorLabel.Visible = 'off';
                    this.Widgets.TimeVectorEditField.Visible = 'off';
                    this.Widgets.FreqMessageLabel.Visible = 'on';
                    this.Widgets.FreqVectorLabel.Visible = 'on';
                    this.Widgets.FreqVectorEditField.Visible = 'on';
            end
            this.Widgets.TimeMessageLabel.Text = getString(message('Control:mrtool:PlotSparseSpecifyTimeVectorsMessage',this.ModelWrapper.Name));
            this.Widgets.FreqMessageLabel.Text = getString(message('Control:mrtool:PlotSparseSpecifyFreqVectorsMessage',this.ModelWrapper.Name));
            this.Widgets.TimeVectorEditField.Value = this.makeTimeVectorString(this.TimeVector);
            this.Widgets.FreqVectorEditField.Value = this.makeFrequencyVectorString(this.FreqVector);
        end

        function close(this)
            close@controllib.ui.internal.dialog.AbstractDialog(this)
            notify(this,'DialogClosed')
        end
    end

    %% Protected methods
    methods (Access = protected)
        function buildUI(this)
            this.UIFigure.Tag = 'SparsePlotOptionsDialog';

            % Basic Dialog Layout
            figureGrid = uigridlayout(this.UIFigure,[2 1]);
            figureGrid.RowHeight = {'fit','fit'};

            % Time Vector
            this.InputLayout = uigridlayout(figureGrid,[4 3]);
            this.InputLayout.RowHeight = {'fit','fit','fit','fit'};
            this.InputLayout.ColumnWidth = {'fit','1x','fit'};
            this.InputLayout.Layout.Row = 1;
            this.InputLayout.Layout.Column = 1;

            TimeMessageLabel = uilabel(this.InputLayout);
            TimeMessageLabel.WordWrap = 'on';
            TimeMessageLabel.Layout.Row = 1;
            TimeMessageLabel.Layout.Column = [1 3];
            TimeMessageLabel.Text = getString(message('Control:mrtool:PlotSparseSpecifyTimeVectorsMessage',this.ModelWrapper.Name));
            TimeMessageLabel.Tag = 'MR_SparsePlotOptions_TimeMessageLabel';

            TimeVectorLabel = uilabel(this.InputLayout);
            TimeVectorLabel.Text =  getString(message('Control:mrtool:PlotSparseSpecifyTimeVectorLabel'));
            TimeVectorLabel.Layout.Row = 2;
            TimeVectorLabel.Layout.Column = 1;
            TimeVectorLabel.Tag = 'MR_SparsePlotOptions_TimeVectorLabel';
            TimeVectorEditField = uieditfield(this.InputLayout);
            TimeVectorEditField.Layout.Row = 2;
            TimeVectorEditField.Layout.Column = 3;
            TimeVectorEditField.Tag = 'MR_SparsePlotOptions_TimeVectorEditField';
            TimeVectorEditField.Value = this.makeTimeVectorString(this.TimeVector);

            % Freq Vector
            FreqMessageLabel = uilabel(this.InputLayout);
            FreqMessageLabel.WordWrap = 'on';
            FreqMessageLabel.Layout.Row = 3;
            FreqMessageLabel.Layout.Column = [1 3];
            FreqMessageLabel.Text = getString(message('Control:mrtool:PlotSparseSpecifyFreqVectorsMessage',this.ModelWrapper.Name));
            FreqMessageLabel.Tag = 'MR_SparsePlotOptions_FreqMessageLabel';

            FreqVectorLabel = uilabel(this.InputLayout);
            FreqVectorLabel.Text =  getString(message('Control:mrtool:PlotSparseSpecifyFreqVectorLabel'));
            FreqVectorLabel.Layout.Row = 4;
            FreqVectorLabel.Layout.Column = 1;
            FreqVectorLabel.Tag = 'MR_SparsePlotOptions_FreqVectorLabel';
            FreqVectorEditField = uieditfield(this.InputLayout);
            FreqVectorEditField.Layout.Row = 4;
            FreqVectorEditField.Layout.Column = 3;
            FreqVectorEditField.Tag = 'MR_SparsePlotOptions_FreqVectorEditField';
            FreqVectorEditField.Value = this.makeFrequencyVectorString(this.FreqVector);

            % Buttons
            buttonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(...
                figureGrid, ["ok" "cancel"]);
            btnCont = getWidget(buttonPanel);
            btnCont.Layout.Row = 2;
            btnCont.Layout.Column = 1;

            % Define Widgets in Dialog
            this.Widgets.TimeMessageLabel = TimeMessageLabel;
            this.Widgets.TimeVectorLabel = TimeVectorLabel;
            this.Widgets.TimeVectorEditField = TimeVectorEditField;
            this.Widgets.FreqMessageLabel = FreqMessageLabel;
            this.Widgets.FreqVectorLabel = FreqVectorLabel;
            this.Widgets.FreqVectorEditField = FreqVectorEditField;
            this.Widgets.ButtonPanel = buttonPanel;
            this.Widgets.OKButton = buttonPanel.OKButton;
            this.Widgets.CancelButton = buttonPanel.CancelButton;
        end
        
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(this.UIFigure, 'ObjectBeingDestroyed',@(es,ed) delete(weakThis.Handle));
            registerUIListeners(this,L1);
            L2 = addlistener(this,'CloseEvent', @(es,ed) cbCloseEvent(weakThis.Handle)); 
            registerUIListeners(this,L2);   
            this.Widgets.TimeVectorEditField.ValueChangedFcn = @(es,ed) cbTimeVectorChanged(weakThis.Handle,ed);
            this.Widgets.FreqVectorEditField.ValueChangedFcn = @(es,ed) cbFreqVectorChanged(weakThis.Handle,ed);
            this.Widgets.OKButton.ButtonPushedFcn = @(es,ed) cbOKButtonPushed(weakThis.Handle);
            this.Widgets.CancelButton.ButtonPushedFcn = @(es,ed) cbCloseEvent(weakThis.Handle);
        end

        function cbCloseEvent(this)
            this.Initialized = false;
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            close(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end

        function cbTimeVectorChanged(this,ed)
            if isempty(ed.Value)
                this.Widgets.TimeVectorEditField.Value = ed.PreviousValue;
            else
                oldVector = this.TimeVector;
                try
                    this.TimeVector = evalin('base',this.Widgets.TimeVectorEditField.Value);
                catch ME
                    this.Widgets.TimeVectorEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                    end
                    return;
                end
                if (isempty(this.TimeVector) ...
                        || numel(this.TimeVector) < 2 || ~(isnumeric(this.TimeVector) &&...
                        isvector(this.TimeVector) && isreal(this.TimeVector) &&...
                        all(this.TimeVector>=0)) && all(diff(this.TimeVector)>0))
                    this.TimeVector = oldVector;
                    this.Widgets.TimeVectorEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,getString(message('Control:mrtool:SparseErrorTimeVector')),getString(message('Control:mrtool:Error')));
                    end
                else
                    this.TimeVector = sort(unique(this.TimeVector));
                end
            end
        end

        function cbFreqVectorChanged(this,ed)
            if isempty(ed.Value)
                this.Widgets.FreqVectorEditField.Value = ed.PreviousValue;
            else
                oldVector = this.FreqVector;
                try
                    this.FreqVector = evalin('base',this.Widgets.FreqVectorEditField.Value);
                catch ME
                    this.Widgets.FreqVectorEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,ME.message,getString(message('Control:mrtool:Error')));
                    end
                    return;
                end
                if (isempty(this.FreqVector) ...
                        || ~(isnumeric(this.FreqVector) && isvector(this.FreqVector) && ...
                        isreal(this.FreqVector) && numel(this.FreqVector) > 1 &&...
                        all(this.FreqVector>=0)) && all(diff(this.FreqVector)>0))
                    this.FreqVector = oldVector;
                    this.Widgets.FreqVectorEditField.Value = ed.PreviousValue;
                    if strcmp(this.UIFigure.Visible,'on')
                        uialert(this.UIFigure,getString(message('Control:mrtool:SparseErrorFreqVector')),getString(message('Control:mrtool:Error')));
                    end
                else
                    this.FreqVector = sort(unique(this.FreqVector));
                end
            end        
        end

        function cbOKButtonPushed(this)
            this.Initialized = true;
            currentPointer = controllib.widget.internal.utils.setPointer(this.UIFigure,'watch');
            drawnow limitrate nocallbacks
            switch this.VectorType
                case 'time'
                    this.ModelWrapper.SparseTimeVector = this.TimeVector;
                case 'freq'
                    this.ModelWrapper.SparseFreqVector = this.FreqVector;
            end
            close(this);
            controllib.widget.internal.utils.setPointer(this.UIFigure,currentPointer);
            drawnow limitrate nocallbacks
        end
    end

    methods (Static,Access=private)
        function str = makeTimeVectorString(val)
            % Build a nice display string for val
            if isempty(val)
                str = '';
            elseif isscalar(val)
                str = num2str(val);
            elseif length(val)==2
                str = sprintf('[%0.3g %0.3g]',val(1),val(2));
            else
                %---Fix vector if not evenly spaced
                t0 = val(1);
                dt = val(2)-val(1);
                nt0 = round(t0/dt);
                t0 = nt0*dt;
                val = dt*(0:1:nt0+length(val)-1);
                if t0>0
                    val = val(val>=t0);
                end
                %---Build compact vector (even step size)
                str = sprintf('%s:%s:%s',num2str(val(1)),num2str(val(2)-val(1)),num2str(val(end)));
            end
        end

        function str = makeFrequencyVectorString(val)
            % Build a nice display string for val
            if isempty(val)
                str = '';
            elseif isscalar(val)
                str = num2str(val);
            elseif length(val)==2
                str = sprintf('[%0.3g %0.3g]',val(1),val(2));
            else
                dval   = diff(val);
                val10  = log10(val);
                dval10 = diff(val10);
                tol    = 100*eps*max(abs(val));
                tol10  = 100*eps*max(abs(val10));
                if all(abs(dval-dval(1))<tol)
                    %---Build compact vector (even step size)
                    str = sprintf('%s:%s:%s',num2str(val(1)),num2str(dval(1)),num2str(val(end)));
                elseif all(abs(dval10-dval10(1))<tol10)
                    %---Build logspace string
                    str = sprintf('logspace(%s,%s,%d)',num2str(val10(1)),num2str(val10(end)),length(val));
                else
                    %---Generic case (show all values)
                    str = sprintf('%g ',val);
                    str = sprintf('[%s]',str(1:end-1));
                end
            end
        end
    end

    %% Hidden methods
    methods (Hidden = true)
        function Widgets = qeGetWidgets(this)
            Widgets = this.Widgets;
        end
    end
end