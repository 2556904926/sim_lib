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
addResponse(hChart,sys);

response = hChart.Responses(end);

% Chart does not throw error. Throw response exception if it is not about
% unsupported improper sys. (We don't want to throw error about improper
% sys because user might be in the process of adding more poles. The chart
% shows a blank response in this case, and it is updated when the system is
% proper).
if ~isempty(response.DataException) && ...
        ~strcmp(response.DataException.identifier,'Control:analysis:NotSupportedSimulationImproperSys')
    throw(response.DataException);
end

response.SemanticColor = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;

hChart.Responses(1).NominalIndex = nameValueArgs.NominalIndex;

if ~isempty(nameValueArgs.Style)
    hChart.Responses(end).Style = nameValueArgs.Style;
end

end