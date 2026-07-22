classdef (Hidden) DocumentToolManager < controllib.ui.internal.figuretool.FigureToolManager
% Figure Tool Manager

% Copyright 2020-2023 The MathWorks, Inc.

    properties
        MRTab
    end

    methods
        function this = DocumentToolManager(tag, appcontainer, title)
            this = this@controllib.ui.internal.figuretool.FigureToolManager(tag, ...
                appcontainer);
            setTitle(this, title);            
        end
                
        function tool = addMRDocTool(this, tab, doc)
            this.MRTab = tab;
            tool = mrtool.internal.tools.MRDocTool(doc.DocumentGroupTag, tab.Tabs, doc.Document);
            addFigureTool(this, tool);
        end

        function removeMRDocTool(this,id)
            lookupValue = strcat(this.Tag, id);
            if isvalid(this) && hasFigureTool(this,lookupValue)
                deleteFigureTool(this, lookupValue);
                delete(this.MRTab);
            end
        end
    end
end