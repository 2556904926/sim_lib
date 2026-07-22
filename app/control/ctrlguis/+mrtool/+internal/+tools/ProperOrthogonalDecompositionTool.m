classdef (Hidden) ProperOrthogonalDecompositionTool < mrtool.internal.tools.AbstractTool
    % Proper Orthogonal Decomposition Tool consisting its tab, plot and data
    % compatible with MATLAB Online       
    
    % Author(s): A. Ouellette
    % Copyright 2024 The MathWorks, Inc.  

    %% Properties
    properties (SetAccess=immutable)
        Tab
        Document
        DocumentGroupTag
    end

    %% Constructor
    methods
        function this = ProperOrthogonalDecompositionTool(App,Model,InitData)  
            arguments
                App (1,1) mrtool.internal.ModelReducerApp
                Model (1,1) mrtool.data.ModelWrapper
                InitData struct {mustBeScalarOrEmpty} = struct.empty
            end
            toolData = mrtool.data.ProperOrthogonalDecompositionData(Model);
            if ~isempty(InitData)
                toolData.Method = InitData.Method;
                toolData.Options = InitData.Options;
                if isfield(InitData,'FreqVector') %sparse
                    toolData.PlotFreqVector = InitData.FreqVector;
                end
            end
            this = this@mrtool.internal.tools.AbstractTool(toolData,App.PODDocGrpTag);
            this.Document = mrtool.internal.plots.toolplot.ProperOrthogonalDecompositionPlot(...
                this.ToolData,this.DocumentGroupTag+this.ID);
            this.Tab = mrtool.internal.tabs.ProperOrthogonalDecompositionTab(...
                this.ToolData,this.Document,App, this.ID);
        end  
    end
end