function response = addResponseToChart(this,hChart,sys,nameValueArgs)
% addResponseToChart  Adds LTI model to chart to create response

% Copyright 2023 The MathWorks, Inc. 

arguments
    this
    hChart
    sys
    nameValueArgs.NominalIndex = []
    nameValueArgs.Style controllib.chart.internal.options.ResponseStyle = controllib.chart.internal.options.ResponseStyle.empty
end

if hasdelay(sys)
    if sys.Ts
        sys = absorbDelay(sys);
    else
        sys = pade(sys,this.Preferences.PadeOrder);
    end
end
addSystem(hChart,sys);

response = hChart.Responses(end);
response.SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;

hChart.Responses(1).NominalIndex = nameValueArgs.NominalIndex;

if ~isempty(nameValueArgs.Style)
    hChart.Responses(end).Style = nameValueArgs.Style;
end

end