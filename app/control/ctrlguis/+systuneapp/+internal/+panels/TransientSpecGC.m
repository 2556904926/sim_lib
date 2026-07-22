classdef TransientSpecGC < systuneapp.internal.panels.GenericTuningGoalSpecGC
    % Graphical component for Step Rejection tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    methods
        function this = TransientSpecGC(tcpeer)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecGC(tcpeer); 
            this.ShowFocusWidget = false;
        end
        
        function updateUI(this)
            update(this);
        end
    end
    
    methods(Access= protected)
        function container = createContainer(this)
            %% Create base class widgets
            createWidgets(this);
            
            %% Container
            container = uigridlayout([2 1],'Parent',[],'Padding',0);
            container.RowHeight = {'fit','fit','fit'};
                
            %% Input Signal Selection panel
            accInputSignalSelection = matlab.ui.container.internal.Accordion('Parent',container);
            pnlInputSignalSelection = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accInputSignalSelection);
            pnlInputSignalSelection.Title = ...
                getString(message('Control:systunegui:TransientTuningGoalSpecInitialSignalSelection'));
            layoutInputSignalSelection = uigridlayout(pnlInputSignalSelection,...
                'RowHeight',{'fit','fit'},'ColumnWidth',{'fit','1x'},'Padding',0);
            % Input Selection Row
            lblInputSignalSelection = uilabel (layoutInputSignalSelection,'Text', ...
                getString(message('Control:systunegui:TransientTuningGoalSpecSpecifyInputSignal')));
            lblInputSignalSelection.Layout.Row = 1;
            lblInputSignalSelection.Layout.Column = 1;
            InputSignalSelectionItems = { ... 
                getString(message('Control:systunegui:TransientTuningGoalSpecImpulse'))
                getString(message('Control:systunegui:TransientTuningGoalSpecStep'))
                getString(message('Control:systunegui:TransientTuningGoalSpecRamp'))
                getString(message('Control:systunegui:TransientTuningGoalSpecOther'))};
            cmbInputSignalSelection = uidropdown(layoutInputSignalSelection,...
                'Items',InputSignalSelectionItems);
            cmbInputSignalSelection.Value = InputSignalSelectionItems{1};  
            cmbInputSignalSelection.Layout.Row = 1;
            cmbInputSignalSelection.Layout.Column = 2;
            % Filter Response Row
            lblUseFilter = uilabel (layoutInputSignalSelection,'Text', ...
                getString(message('Control:systunegui:TransientTuningGoalSpecUseFilter')));
            lblUseFilter.Layout.Row = 2;
            lblUseFilter.Layout.Column = 1;
            txtUseFilter = uieditfield(layoutInputSignalSelection);
            txtUseFilter.Tag = 'txtUseFilter';
            txtUseFilter.Layout.Row = 2;
            txtUseFilter.Layout.Column = 2;
            
            %% Desired Transient Response panel
            accReferenceModel = matlab.ui.container.internal.Accordion('Parent',container);
            pnlReferenceModel = matlab.ui.container.internal.AccordionPanel(...
                'Parent',accReferenceModel);
            pnlReferenceModel.Title = ...
                getString(message('Control:systunegui:TransientTuningGoalSpecDesiredTransientResponse'));
            layoutReferenceModel = uigridlayout(pnlReferenceModel,'RowHeight',{'fit','fit'},...
                                    'ColumnWidth',{'fit','1x'},'Padding',0);
            
            lbl1ReferenceModel = uilabel(layoutReferenceModel,'Text', ...
                getString(message('Control:systunegui:TransientSpecReferenceModelText')));
            lbl1ReferenceModel.Layout.Row = 1;
            lbl1ReferenceModel.Layout.Column = [1 2];
            lbl2ReferenceModel = uilabel(layoutReferenceModel,'Text',...
                getString(message('Control:systunegui:TransientSpecReferenceModel')));
            lbl2ReferenceModel.Tag = 'lblReferenceModel';
            lbl2ReferenceModel.Layout.Row = 2;
            lbl2ReferenceModel.Layout.Column = 1;
            txtReferenceModel = uieditfield(layoutReferenceModel);
            txtReferenceModel.Tag = 'txtReferenceModel';
            txtReferenceModel.Layout.Row = 2;
            txtReferenceModel.Layout.Column = 2;
                                               
            %% Options panel
            accOptions = matlab.ui.container.internal.Accordion('Parent',container);
            pnlOptions = matlab.ui.container.internal.AccordionPanel('Parent',accOptions);
            pnlOptions.Title = ...
                getString(message('Control:systunegui:TuningGoalSpecOptions'));
            pnlOptions.Collapsed = true;
            layoutOptions = uigridlayout(pnlOptions,[6 4]);
            layoutOptions.Padding = 0;
            layoutOptions.RowHeight = {'fit','fit','fit','fit','fit','fit'};
            layoutOptions.ColumnWidth = {20,'fit','1x'};
            
            % Relative gap
            lblRelGap = uilabel(layoutOptions);
            lblRelGap.Text = getString(message('Control:systunegui:StepRespSpecRelGap'));
            lblRelGap.Tag = 'lblRelGap';
            lblRelGap.Layout.Row = 1;
            lblRelGap.Layout.Column = [1 2];
            txtRelGap = uieditfield(layoutOptions);
            txtRelGap.Tag = 'txtRelGap';
            txtRelGap.Layout.Row = 1;
            txtRelGap.Layout.Column = 3;
                        
            % InputScaling
            lblInputScaling = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:TransientSpecInputSignalScaling')));
            lblInputScaling.Layout.Row = 2;
            lblInputScaling.Layout.Column = [1 2];
            lblInputScalingAmplitude = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:TransientSpecSignalInputScalingAmplitude')));
            lblInputScalingAmplitude.Layout.Row = 3;
            lblInputScalingAmplitude.Layout.Column = 2;
            txtInputScalingAmplitude = uieditfield(layoutOptions);
            txtInputScalingAmplitude.Tag = 'txtInputScalingAmplitude';
            txtInputScalingAmplitude.Layout.Row = 3;
            txtInputScalingAmplitude.Layout.Column = 3;
            Items = {  getString(message('Control:systunegui:YesLabel')), ...
                       getString(message('Control:systunegui:NoLabel'))};
            cmbYesNoInput = uidropdown(layoutOptions,'Items',Items);
            cmbYesNoInput.Value = getString(message('Control:systunegui:NoLabel'));
            cmbYesNoInput.Layout.Row = 2;
            cmbYesNoInput.Layout.Column = 3;
           
            % OutputScaling
            lblOutputScaling = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:TransientSpecOutputSignalScaling')));
            lblOutputScaling.Layout.Row = 4;
            lblOutputScaling.Layout.Column = [1 2];
            lblOutputScalingAmplitude = uilabel(layoutOptions,'Text',...
                getString(message('Control:systunegui:TransientSpecSignalOutputScalingAmplitude')));
            lblOutputScalingAmplitude.Layout.Row = 5;
            lblOutputScalingAmplitude.Layout.Column = 2;
            
            txtOutputScalingAmplitude = uieditfield(layoutOptions);
            txtOutputScalingAmplitude.Tag = 'txtOutputScalingAmplitude';
            txtOutputScalingAmplitude.Layout.Row = 5;
            txtOutputScalingAmplitude.Layout.Column = 3;
            
            cmbYesNoOutput = uidropdown(layoutOptions,'Items',Items);
            cmbYesNoOutput.Value = getString(message('Control:systunegui:NoLabel'));  
            cmbYesNoOutput.Layout.Row = 4;
            cmbYesNoOutput.Layout.Column = 3;
           
            % Models
            this.Widgets.Advanced.pnlRadio.Parent = layoutOptions;
            this.Widgets.Advanced.pnlRadio.Layout.Row = 6;
            this.Widgets.Advanced.pnlRadio.Layout.Column = [1 3];
            
            %% store widgets for easy access
            this.Widgets.Transient = struct(...
                'lblInputSignalSelection',  lblInputSignalSelection,...
                'cmbInputSignalSelection',  cmbInputSignalSelection,...
                'lblUseFilter',             lblUseFilter,...
                'txtUseFilter',             txtUseFilter,...
                'pnlInputSignalSelection',  pnlInputSignalSelection,...
                'layoutInputSignalSelection',layoutInputSignalSelection,...
                'lbl1ReferenceModel',       lbl1ReferenceModel,...
                'lbl2ReferenceModel',       lbl2ReferenceModel,...
                'txtReferenceModel',        txtReferenceModel,...  
                'pnlReferenceModel',        pnlReferenceModel,... 
                'lblRelGap',                lblRelGap,...
                'txtRelGap',                txtRelGap,... 
                'lblInputScaling',          lblInputScaling,...
                'lblInputScalingAmplitude', lblInputScalingAmplitude,...
                'txtInputScalingAmplitude', txtInputScalingAmplitude, ...
                'cmbYesNoInput',            cmbYesNoInput,...
                'lblOutputScaling',         lblOutputScaling,...
                'lblOutputScalingAmplitude',lblOutputScalingAmplitude,...                
                'txtOutputScalingAmplitude',txtOutputScalingAmplitude, ...
                'cmbYesNoOutput',           cmbYesNoOutput,...                
                'pnlOptions',               pnlOptions,...                
                'layoutOptions',            layoutOptions,...            
                'pnl',                      container...
                );
        end
        
        function connectUI(this)
            % Add listeners for the text fields and the radio button
            connectUI@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            % GUI listeners
            this.Widgets.Transient.txtReferenceModel.ValueChangedFcn = ...
                @(hSrc, hData)cbReferenceModelEdit(this, this.Widgets.Transient.txtReferenceModel.Value);
            this.Widgets.Transient.txtRelGap.ValueChangedFcn = ...
                @(hSrc, hData)cbRelGapEdit(this, this.Widgets.Transient.txtRelGap.Value);
            this.Widgets.Transient.txtUseFilter.ValueChangedFcn = ...
                @(hSrc,hData) cbUseFilter(this,this.Widgets.Transient.txtUseFilter.Value);
            this.Widgets.Transient.cmbInputSignalSelection.ValueChangedFcn = ...
                @(hSrc,hData) cbcmbInputSignalSelection(this);
            this.Widgets.Transient.cmbYesNoInput.ValueChangedFcn = ...
                @(hSrc,hData) cbcmbYesNoInputChange(this);            
            this.Widgets.Transient.txtInputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbInputScalingAmplitudeEdit(this, this.Widgets.Transient.txtInputScalingAmplitude.Value);
            this.Widgets.Transient.cmbYesNoOutput.ValueChangedFcn = ...
                @(hSrc,hData) cbcmbYesNoOutputChange(this);
            this.Widgets.Transient.txtOutputScalingAmplitude.ValueChangedFcn = ...
                @(hSrc, hData)cbOutputScalingAmplitudeEdit(this, this.Widgets.Transient.txtOutputScalingAmplitude.Value);            
        end        
        
        function update(this)
            % Call parent update
            update@systuneapp.internal.panels.GenericTuningGoalSpecGC(this);
            
            % Get the current value of the TCpeer
            Value = getValue(this.TCPeer);
            
            % Update the text fields to the current value of TC
            this.Widgets.Transient.txtReferenceModel.Value = Value.MetaData.ReferenceModel;
            this.Widgets.Transient.txtUseFilter.Value = Value.MetaData.OtherInputShaping;
            this.Widgets.Transient.cmbInputSignalSelection.Value = Value.MetaData.InputSignalString;
            this.Widgets.Transient.txtRelGap.Value = mat2str(Value.Data.RelGap*100);
            this.Widgets.Transient.txtInputScalingAmplitude.Value = mat2str(Value.MetaData.InputScaling);
            this.Widgets.Transient.txtOutputScalingAmplitude.Value = mat2str(Value.MetaData.OutputScaling);
            
            % Update input shaping combo boxes
            if isempty(Value.MetaData.InputSignalString)
                this.Widgets.Transient.cmbInputSignalSelection.Value = getString(message('Control:systunegui:TransientTuningGoalSpecImpulse'));
            else
                this.Widgets.Transient.cmbInputSignalSelection.Value = Value.MetaData.InputSignalString;
            end
            
            % Update input and output scaling combo boxes
            if isempty(Value.Data.InputScaling)
                this.Widgets.Transient.cmbYesNoInput.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.Transient.cmbYesNoInput.Value = getString(message('Control:systunegui:YesLabel'));
            end

            if isempty(Value.Data.OutputScaling)
                this.Widgets.Transient.cmbYesNoOutput.Value = getString(message('Control:systunegui:NoLabel'));
            else
                this.Widgets.Transient.cmbYesNoOutput.Value = getString(message('Control:systunegui:YesLabel'));
            end
            
            % Call dropdown changes
            cbcmbInputSignalSelection(this);
            cbcmbYesNoInputChange(this);
            cbcmbYesNoOutputChange(this);
        end
    end
    
    methods (Access = private)
        %% GUI Listener callbacks         
        function cbReferenceModelEdit(this, fieldValue)
            % Instant apply to TC when Reference Model text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % ReferenceModel cannot be empty
                    update(this);
                else
                    setReferenceModel(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this), ME.message);
                return;
            end
        end
        
        function cbRelGapEdit(this, fieldValue)
            % Instant apply to TC when RelGap text field changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % RelGap cannot be empty
                    update(this);
                else
                    setRelGap(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end          
        
        function cbInputScalingAmplitudeEdit(this, fieldValue)
            % Instant apply to TC when InputScaling text field changes
            try
                if nargin == 1
                    % Scaling amplitude can be empty. Account for it.
                    setInputScalingAmplitude(this.TCPeer);
                elseif isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setInputScalingAmplitude(this.TCPeer, fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end
        
        function cbOutputScalingAmplitudeEdit(this, fieldValue)
            % Instant apply to TC when outputScaling text field changes
            try
                if nargin == 1
                    % Scaling amplitude can be empty. Account for it.
                    setOutputScalingAmplitude(this.TCPeer);
                elseif isempty(fieldValue) || all(isspace(fieldValue))
                    update(this);
                else
                    setOutputScalingAmplitude(this.TCPeer, fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this),ME.message);
                return;
            end
        end
        
        function cbcmbInputSignalSelection(this)
            % update TC's Input Signal Selection
            if strcmp(this.Widgets.Transient.cmbInputSignalSelection.Value, ...
                    getString(message('Control:systunegui:TransientTuningGoalSpecOther')))
                this.Widgets.Transient.layoutInputSignalSelection.RowHeight{2} = 'fit';
                this.TCPeer.MetaData.InputSignalString = this.Widgets.Transient.cmbInputSignalSelection.Value; 
            else
                this.Widgets.Transient.layoutInputSignalSelection.RowHeight{2} = 0;
                this.TCPeer.MetaData.InputSignalString = this.Widgets.Transient.cmbInputSignalSelection.Value;                
            end
            update(this.TCPeer.Data);
        end   
        
        function cbUseFilter(this, fieldValue)
            % Instant apply to TC when filter value of text field in input signal changes
            try
                if isempty(fieldValue) || all(isspace(fieldValue))
                    % UseFilter cannot be empty
                    update(this);
                else
                    setOtherInputShaping(this.TCPeer,fieldValue);
                end
            catch ME
                update(this);
                systuneapp.util.openUIAlert(getParentFigure(this), ME.message);
                return;
            end
        end        
        
        function cbcmbYesNoInputChange(this)
            % update TC's InputScaling when scaling combo box changes
            switch this.Widgets.Transient.cmbYesNoInput.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.Transient.layoutOptions.RowHeight{3} = 'fit';
                    cbInputScalingAmplitudeEdit(this, this.Widgets.Transient.txtInputScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.Transient.layoutOptions.RowHeight{3} = 0;
                    cbInputScalingAmplitudeEdit(this);
            end
            update(this.TCPeer.Data);
        end 
        
        function cbcmbYesNoOutputChange(this)
            % update TC's OutputScaling when scaling combo box changes
            switch this.Widgets.Transient.cmbYesNoOutput.Value
                case getString(message('Control:systunegui:YesLabel'))
                    this.Widgets.Transient.layoutOptions.RowHeight{5} = 'fit';
                    cbOutputScalingAmplitudeEdit(this, this.Widgets.Transient.txtOutputScalingAmplitude.Value);
                case getString(message('Control:systunegui:NoLabel'))
                    this.Widgets.Transient.layoutOptions.RowHeight{5} = 0;
                    cbOutputScalingAmplitudeEdit(this);
            end
            update(this.TCPeer.Data);
        end                  
    end

end
