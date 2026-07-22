classdef (Hidden) CSTunerParamTableTab < ctrluis.paramtable.ParamTableTabVTwo   
% CSTUNERPARAMTABLE and its contextual tab (TOOLSTRIP)    

% Copyright 2016-2022 The MathWorks, Inc.   
    
    %% Private properties
    properties (Access = private)
        % Widgets
        Tool
    end

    properties(Hidden, GetAccess = public, SetAccess = protected)
        SaveButton
    end
    
    %% Events
    events
        ExportParams
    end
    
    %% Plublic methods
    methods
        % Constructor
        function this = CSTunerParamTableTab(tool,clienttitle,tabtitle,model,paramdata)            
            this@ctrluis.paramtable.ParamTableTabVTwo(getToolGroup(tool),clienttitle,tabtitle,model,paramdata);
            this.Tool = tool;
            % Set CanCloseFcn to ask user for saving parameters
            this.Document.CanCloseFcn = @(es,ed) notifyOnClose(this);
            % Make table editable
            setTableEditable(this.ParamTableGC,true);
            % Add document and tabs to AppContainer
            tool.addClientTabGroup(this.Document,this.Tabs);
        end
        
        function tool = getTool(this)
            tool = this.Tool;
        end
           
        %% Testing API
        function s = getTesters(this)
            s = getTesters@ctrluis.paramtable.ParamTableTabVTwo(this);
            s.ApplyButton = this.SaveButton;
        end        
    end
    
    %% Protected methods
    methods (Access = protected)
        % overloaded method
        function sections = createWidgets(this, varargin)
            % Create base class widgets(sections)
            sections = createWidgets@ctrluis.paramtable.ParamTableTabVTwo(this, varargin);
            import matlab.ui.internal.toolstrip.*

            % Add an update section for "Apply" button to save the parameterization data
            UpdateSection = Section(getString(message('Controllib:dataprocessing:lblUpdate')));
            UpdateSection.Tag = 'secUpdate';
            
            this.SaveButton = Button(...
                getString(message('Control:systunegui:ApplyLabel')), ...
                Icon.CONFIRM_24);
            this.SaveButton.Tag = 'btnSave';
            
            column1 = Column();
            add(column1, this.SaveButton);
            add(UpdateSection,column1);

            sections = [sections,UpdateSection];
        end
        % overloaded method
        function installListeners(this, varargin)
            installListeners@ctrluis.paramtable.ParamTableTabVTwo(this, varargin);
            addlistener(this.SaveButton,'ButtonPushed',@(es,ed) export(this));
        end
    end
    
    %% Private methods
    methods (Access = private)
        % Callabck for Figure
        function canClose = notifyOnClose(this)
            canClose = true;
            if isequal(getParameterData(this),this.Tool.ControlDesignData.Architecture.Parameters)
                delete(this.Tabs);
            else
                selection = questdlg(...
                    getString(message('Control:systunegui:SaveParamsQuestion')), ...
                    getString(message('Control:systunegui:SaveSession')), ...
                    getString(message('Control:systunegui:YesLabel')),...
                    getString(message('Control:systunegui:NoLabel')),...
                    getString(message('Control:systunegui:YesLabel')));
                if strcmp(selection,getString(message('Control:systunegui:YesLabel')))
                    export(this)
                end
                delete(this.Tabs);
            end
        end
        % Callback for Save Button
        function export(this)
            notify(this,'ExportParams');
        end
    end
end

