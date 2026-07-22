classdef MRRelativeErrorPlot < mrtool.internal.plots.MRAbstractFrequencyPlot 
    % Relative error plot.
    
    % Author(s): A. Ouellette
    % Copyright 2023-2024 The MathWorks, Inc. 

    %% Properties
    properties (Constant,Access=protected)
        TitleMsgID = "Control:mrtool:RelErrorTitle";  
    end

    %% Constructor
    methods
        function this = MRRelativeErrorPlot(Parent,ToolData)
            this = this@mrtool.internal.plots.MRAbstractFrequencyPlot(Parent,ToolData);                                 
        end
    end

    %% Protected methods
    methods (Access=protected)
        function createFrequencyPlot(this)
            sys = computeRelativeSystem(this);
            this.PlotHandle = sigmaplot(this.Parent,sys);
        end

        function updatePlotData(this)
            sys = computeRelativeSystem(this);
            this.ReducedSystemResponse.SourceData.Model = sys;
            updateSelectorWidget(this);
        end
        
        function setLegend(this)
            this.ReducedSystemResponse.Name = getString(message('Control:mrtool:ErrorLegend',mat2str(order(this.ReducedSystem)')));
        end        
    end

    %% Private methods
    methods (Access=private)
        function System = computeRelativeSystem(this)
            targetFRD = this.ToolData.TargetFRD;
            reducedFRD = this.ToolData.ReducedFRD;
            h = targetFRD.ResponseData;
            hr = reducedFRD.ResponseData;
            [ny,nu,nw,na] = size(hr);
            E = zeros(ny,nu,nw,na);
            for ii = 1:nw
                hk = h(:,:,ii);
                for jj = 1:na
                    hrk = hr(:,:,ii,jj);
                    alpha = getRegularization(this.ToolData);
                    if ny>nu
                        [~,r] = qr([hk;alpha*eye(nu)],"econ","vector");
                        E(:,:,ii,jj) = (hk-hrk)/r;
                    else
                        [~,r] = qr([hk';alpha*eye(ny)],"econ","vector");
                        E(:,:,ii,jj) = r'\(hk-hrk);
                    end
                end
            end
            System = frd(E,targetFRD.Frequency);
            System.SamplingGrid = reducedFRD.SamplingGrid;
        end
    end
end