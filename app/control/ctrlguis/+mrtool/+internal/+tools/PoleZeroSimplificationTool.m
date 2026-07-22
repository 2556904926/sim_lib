classdef (Hidden) PoleZeroSimplificationTool < mrtool.internal.tools.AbstractTool
    % Pole/Zero Simplification Tool consisting its tab, plot and data
    % compatible with MATLAB Online       
    
    % Author(s): A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.    
       
    %% Properties
    properties (SetAccess=immutable)
        Tab
        Document
        DocumentGroupTag
    end

    %% Constructor
    methods
        function this = PoleZeroSimplificationTool(App,Model)  
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
                Model (1,1) mrtool.data.ModelWrapper
            end
            toolData = mrtool.data.PoleZeroSimplificationData(Model);
            this = this@mrtool.internal.tools.AbstractTool(toolData,App.PZDocGrpTag);
            this.Document = mrtool.internal.plots.toolplot.PoleZeroSimplificationPlot(...
                this.ToolData,this.DocumentGroupTag+this.ID);
            this.Tab = mrtool.internal.tabs.PoleZeroSimplificationTab(...
                this.ToolData,this.Document,App, this.ID);
        end  
    end
end