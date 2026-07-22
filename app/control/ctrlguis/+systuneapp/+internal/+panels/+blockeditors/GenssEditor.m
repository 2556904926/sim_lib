classdef GenssEditor < systuneapp.internal.panels.blockeditors.LTIEditor
    % systuneapp.internal.panels.blockeditors.GainEditor
    %
    % blk = genss(rss(4,2,3);
    % pnl = systuneapp.internal.panels.blockeditors.GenssEditor(blk,"Parent",uigridlayout([1 1]));
    % getWidget(pnl);
    
    % Copyright 2021-2022 The MathWorks, Inc
    properties(Access = private)
        MetaData

        Label
        EditField
        Description
    end

    %% Public Methods
    methods
        function this = GenssEditor(variableValue,optionalArguments)
            arguments
                variableValue genss
                optionalArguments.Parent = []
            end
            this = this@systuneapp.internal.panels.blockeditors.LTIEditor(variableValue);
            this.Parent = optionalArguments.Parent;
            this.Type = 'Genss';
        end

        function updateUI(this)
            updateDescription(this);
        end
    end

    %% Protected Methods
    methods (Access = protected)
        function variableValue = getCurrentVariableValue(this)
            % Create a copy of the initial variable stored, and modify Gain
            % field.
            variableValue = this.InitialVariableValue;
        end

        function updateParameterData(this)

        end

        function addTopRowWidget(this,parent)
            % Create widgets for editing number of poles and zeros.

            % Widget Layout
            layout = uigridlayout([2,2],"Parent",parent);
            layout.RowHeight = {'fit','fit'};
            layout.ColumnWidth = {'fit','1x'};
            layout.Padding = 0;

            % Label
            this.Label = uilabel(layout,'Text',...
                getString(message('Controllib:gui:lblSLTunableBlock_Custom')));
            this.Label.Layout.Row = 1;
            this.Label.Layout.Column = 1;

            % EditField
            this.EditField = uieditfield(layout);
            this.EditField.Layout.Row = 1;
            this.EditField.Layout.Column = 2;

            % Description
            panel = uipanel(layout);
            panel.Layout.Row = 2;
            panel.Layout.Column = [1 2];
            layout2 = uigridlayout(panel,[1 1]);
            layout2.BackgroundColor = [0.98 0.98 0.98];
            this.Description = uilabel(layout2);
            this.Description.WordWrap = 'on';
            this.Description.FontName = 'Courier New';
        end

        function connectUI(this)
            % Add callbacks to editfields
            this.EditField.ValueChangedFcn = @(es,ed) cbEditFieldValueChanged(this,ed);
        end
    end

    %% Private Methods
    methods(Access = private)
        function cbEditFieldValueChanged(this,ed)
            try
                newMetaData = this.EditField.Value;
                if isempty(this.EditField.Value)
                    this.Data = genss;
                    this.VariableValue = this.InitialVariableValue;
                else
                    CustomData = evalin('base', this.EditField.Value);
                    if isa(CustomData, 'genss') && numel(CustomData) == 1
                        this.InitialVariableValue = CustomData;
                        this.VariableValue = CustomData;
                    elseif isa(genss(CustomData), 'genss') && numel(CustomData) == 1
                        this.InitialVariableValue = genss(CustomData);
                        this.VariableValue = genss(CustomData);
                    else
                        error(getString(message('Controllib:gui:lblSLTunableBlock_InvalidGenss')));
                    end
                end
                this.MetaData = newMetaData;
            catch ME
                fig = ancestor(getWidget(this),'figure');
                uialert(fig,ME.message,fig.Name);
                this.EditField.Value = ed.PreviousValue;
            end
        end

        function updateDescription(this)
            tempVal = this.VariableValue;
            VarName = 'tempVal';
            if ~isempty(tempVal) || isa(tempVal, 'genss')
%                 % tempVal can be non-empty or an empty-genss
%                 add(this.Widgets.CustomWidgets.pnl, this.Widgets.CustomWidgets.txtDescription, 'xy(2,6)');
                
                GenssDesc = evalc(VarName);
                
                % Remove unwanted strings from the description
                % Remove unwanted strings and empty lines from the description
                GenssDesc = strrep(GenssDesc, sprintf('\n%s =\n\n', VarName),'');
                GenssDesc = strrep(GenssDesc, sprintf('\n%s\n\n', getString(message('Control:lftmodel:genss13',VarName,VarName))),'');
                
                % Add block description
                nb = nblocks(tempVal);
                
                if nb == 0
                    BlockDesc = []; %#ok<NASGU>
                    this.Description.Text = sprintf('%s', GenssDesc);
                else
                    BlockDesc = evalc('showBlockValue(tempVal)');
                    this.Description.Text = sprintf('%s \n \n Block Description: \n \n %s', GenssDesc, BlockDesc);
                end
                
                dims = sprintf('%dx',iosize(tempVal));
                this.EditField.Value = sprintf('<%s %s>',dims(1:end-1),class(tempVal));
            end
        end
    end

    %% Hidden Methods
    methods(Hidden)
        function widgets = qeGetAdditionalWidgets(this)
            widgets.Label = this.Label;
            widgets.EditField = this.EditField;
            widgets.Description = this.Description;
        end

        function Text = generateMATLABCode(this,variableName,useTitle)
            arguments
                this
                variableName char
                useTitle logical = false
            end
            % Title
            Text = cell(0,1);
            if useTitle
                Text = generateMATLABCode@systuneapp.internal.panels.blockeditors.LTIEditor(this);
            end

            if isempty(this.MetaData)
                % Default genss
                Data = this.VariableValue;
                this.MetaData = ['genss(tf(ones([', num2str(iosize(Data)), '])))'];
            end
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, [variableName, ' = ', this.MetaData, ';']);
        end
    end
end