classdef LTIDataSource < controllib.chart.internal.utils.ModelSource
    %LTIDATASOURCE
    
    % Copyright 2024 The MathWorks, Inc.

    properties (SetObservable = true)
        isSelectedPlant logical = false
        PlantName char = ''
        Name char = ''
    end

    methods
        function this = LTIDataSource(Model)
            this@controllib.chart.internal.utils.ModelSource(Model);
        end
    end
end