classdef MRDocTool < controllib.ui.internal.figuretool.FigureTool
    % MRDocTool for managing documents

    % Copyright 2020-2024 The MathWorks, Inc.
    methods
        function this = MRDocTool(tag, tab, doc)
            arguments
                tag (1,1) string
                tab (1,1) matlab.ui.internal.toolstrip.Tab
                doc (1,1) matlab.ui.internal.FigureDocument
            end
            this = this@controllib.ui.internal.figuretool.FigureTool(tag, tab, doc);
        end
        function doc = getDocument(this)
            doc = this.Document;
        end
    end
end