classdef (Hidden) BalancedTruncationTool < mrtool.internal.tools.AbstractTool
    % Balanced Truncation Tool consisting its tab, plot and data
    % compatible with MATLAB Online       
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2016-2024 The MathWorks, Inc.  

    %% Properties
    properties (SetAccess=immutable)
        Tab
        Document
        DocumentGroupTag
    end

    %% Constructor
    methods
        function this = BalancedTruncationTool(App,Model,InitData)  
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
                Model (1,1) mrtool.data.ModelWrapper
                InitData struct {mustBeScalarOrEmpty} = struct.empty
            end
            toolData = mrtool.data.BalancedTruncationData(Model);
            if ~isempty(InitData)
                toolData.Method = InitData.Method;
                toolData.PlotFreqVector = InitData.FreqVector;
                toolData.SparseOptions = InitData.Options;
            end
            this = this@mrtool.internal.tools.AbstractTool(toolData,App.BTDocGrpTag);
            this.Document = mrtool.internal.plots.toolplot.BalancedTruncationPlot(...
                this.ToolData,this.DocumentGroupTag+this.ID); 
            this.Tab = mrtool.internal.tabs.BalancedTruncationTab(...
                this.ToolData,this.Document,App, this.ID); 
        end  
    end
end