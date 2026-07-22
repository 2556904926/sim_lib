classdef (Hidden) SystuneToolManager < handle
    % The singleton manager that makes Control System Tuner App singleton
    % for a Simulink Model.
    
    % Copyright 2013-2021 The MathWorks, Inc.    
    
    properties (Access = private)
        ToolList
    end
    methods (Access = protected)
        % Constructor: Protected for singleton implementation
        function this = SystuneToolManager()
        end
        function tool = findTool(this,model)
            % Return tool for a given model
            ind = getToolIndex(this,model);
            if ~isempty(ind)
                tool = this.ToolList(ind);
            else
                % Create one and return
                if systuneapp.util.openJavaApp
                    tool = systuneapp.SystuneTool(model);
                else
                    tool = systuneapp.SystuneApp(model);
                end
                this.ToolList = [this.ToolList;tool];
            end
        end
        function ind = getToolIndex(this,model)
            % Return the index in the registry for the tool, empty if tool not
            % found
            allM = this.getModelsForOpenTools();
            ind = strcmp(model,allM);
            if ~any(ind)
                ind = [];
            end
        end
    end   
    methods (Access = protected,Static = true)
        function mgr = getSystuneToolManager()
            persistent theManager
            mlock
            if isempty(theManager)
                theManager = systuneapp.SystuneToolManager;
            end
            mgr = theManager;
        end
    end
    methods (Static = true)
        function tool = getSystuneTool(model)
            % Return the linear analysis tool for a given model
            mgr = systuneapp.SystuneToolManager.getSystuneToolManager();
            tool = mgr.findTool(model);
        end
        function bool = isToolOpen(model)
            mgr = systuneapp.SystuneToolManager.getSystuneToolManager();
            bool = ~isempty(getToolIndex(mgr,model));
        end
        function allM = getModelsForOpenTools()
            allM = '';
            mgr = systuneapp.SystuneToolManager.getSystuneToolManager();
            if ~isempty(mgr.ToolList)
                % Remove deleted ones from the list
                mgr.ToolList = mgr.ToolList(isvalid(mgr.ToolList));
                if ~isempty(mgr.ToolList)
                    allM = arrayfun(@getModel,mgr.ToolList,'UniformOutput',false);
                end
            end
        end
    end
end
