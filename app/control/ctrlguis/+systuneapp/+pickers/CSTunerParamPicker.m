classdef (Hidden) CSTunerParamPicker < slctrlguis.lintool.widgets.ParamPickerV2
% CSTUNERPARAMPICKER  Widget to set parameter variation from Linearization
% Section (TOOLSTRIP VERSION)

% Copyright 2016-2022 The MathWorks, Inc.
    
    %% Private properties
    properties (Access = private)
        ControlDesignData
    end
    
    %% Events
    events
        ExportParams
    end
    
    %% Public methods
    methods
        % Constructor
        function this = CSTunerParamPicker(tool)
            this@slctrlguis.lintool.widgets.ParamPickerV2(tool);
            this.ControlDesignData = tool.ControlDesignData;
        end
    end
    
    %% Protected methods
    methods (Access = protected)
        % overrided 
        function showTable(this)
            if ~isempty(this.ParamTableTool) && isvalid(this.ParamTableTool) && ...
                    ~isvalid(this.ParamTableTool.Document)
                % Delete the ParamTableTool if its document has been
                % deleted. This will allow recreation in the code below.
                delete(this.ParamTableTool);
                this.ParamTableTool = [];
            end
            if isempty(this.ParamTableTool) || ~isvalid(this.ParamTableTool)
                this.CachedParameterData = this.Parent.ControlDesignData.Architecture.Parameters;
                this.ParamTableTool = systuneapp.tabs.CSTunerParamTableTab(...
                    this.Parent,...
                    getString(message('Slcontrol:lintool:ParamClientTitle')),...
                    getString(message('Slcontrol:lintool:ParamTabTitle')),...
                    getModel(this.Parent),...
                    this.CachedParameterData);
                addlistener(this.ParamTableTool,'ExportParams',@(es,ed) exportParams(this));
                addlistener(this.ParamTableTool,'ParamsChanged',@(es,ed) updateData(this,ed));
            else
                
            end
        end
        % overrided
        function selectItem(this,idx)
            if idx == 1
                % None chosen
                selectDefault(this);
                if ~isempty(this.ParamTableTool) && isvalid(this.ParamTableTool)
                    close(this.ParamTableTool.Document);
                end
                if ~isempty(this.ControlDesignData.getParameters)
                    this.ControlDesignData.setParameters([])
                end
            else
                selectParameterVariation(this);
            end
        end
        % overrided
        function updatePickerText(this,~)
            if this.CurrentSelection
                if isempty(this.ControlDesignData.getParameters)
                    label = getString(message('Control:systunegui:ParameterVariationNone'));
                else
                    label = getString(message('Control:systunegui:ParameterVariationEnabled'));
                end
                this.DropDown.Text = label;
            end
        end
    end
    
    %% Private methods
    methods (Access = private)
        % Callback for ParamTableTool
        function exportParams(this)
            notify(this,'ExportParams');
            updatePickerText(this);
        end
    end
end

