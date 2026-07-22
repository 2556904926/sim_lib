classdef (Hidden) PlotEnum
    % Plot enumeration for plot types that are used in Model Reducer
    % App.
    
    % Copyright 2015 The MathWorks, Inc.    
    
    enumeration
        % Plot names
        Step ("step")
        Impulse ("impulse")
        Bode ("bode")
        Nichols ("nichols")
        Nyquist ("nyquist")
        SingularValue ("sigma")
        PoleZeroMap ("pzmap")
        IOPoleZeroMap ("iopzmap")  
    end

    properties
        Tag
    end

    methods
        function obj = PlotEnum(tag)
            obj.Tag = tag;
        end
    end
    
    methods (Static)
        function plotenum = getPlot(tag)
            arguments
                tag (1,1) string {mustBeMember(tag,["bode";"nichols";"nyquist";"step";"impulse";"sigma";"pzmap";"iopzmap"])}
            end
            switch tag
                case mrtool.PlotEnum.Step.Tag
                    plotenum = mrtool.PlotEnum.Step;
                case mrtool.PlotEnum.Impulse.Tag
                    plotenum = mrtool.PlotEnum.Impulse;
                case mrtool.PlotEnum.Bode.Tag
                    plotenum = mrtool.PlotEnum.Bode;
                case mrtool.PlotEnum.Nichols.Tag
                    plotenum = mrtool.PlotEnum.Nichols;
                case mrtool.PlotEnum.Nyquist.Tag
                    plotenum = mrtool.PlotEnum.Nyquist;
                case mrtool.PlotEnum.SingularValue.Tag
                    plotenum = mrtool.PlotEnum.SingularValue;
                case mrtool.PlotEnum.PoleZeroMap.Tag
                    plotenum = mrtool.PlotEnum.PoleZeroMap;
                case mrtool.PlotEnum.IOPoleZeroMap.Tag
                    plotenum = mrtool.PlotEnum.IOPoleZeroMap;
            end
        end

        function icon = getIcon(tag,iswide)
            arguments
                tag (1,1) string {mustBeMember(tag,["step";"impulse";"bode";"nichols";"nyquist";"sigma";"pzmap";"iopzmap"])}
                iswide (1,1) logical = true
            end
            switch tag
                case "step"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('stepPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('stepPlot');
                    end
                case "impulse"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('impulsePlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('impulsePlot');
                    end
                case "bode"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('bodePlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('bodePlot');
                    end
                case "nichols"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('nicholsPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('nicholsPlot');
                    end
                case "nyquist"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('nyquistPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('nyquistPlot');
                    end
                case "sigma"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('sigmaPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('singularValuePlot');
                    end
                case "pzmap"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('pzPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('pZPlot');
                    end
                case "iopzmap"
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('ioPzPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('iOPZPlot');
                    end
            end
        end

        function plottypes = getPlotTypes()
            plottypes = [mrtool.PlotEnum.Step;...
                mrtool.PlotEnum.Impulse;...
                mrtool.PlotEnum.Bode;...
                mrtool.PlotEnum.Nichols;...
                mrtool.PlotEnum.Nyquist;...
                mrtool.PlotEnum.SingularValue;...
                mrtool.PlotEnum.PoleZeroMap;...
                mrtool.PlotEnum.IOPoleZeroMap];
        end
        
        function title = getNewPlotTitle(tag)
            arguments
                tag (1,1) string {mustBeMember(tag,["step";"impulse";"bode";"nichols";"nyquist";"sigma";"pzmap";"iopzmap"])}
            end
            switch tag
                case "step"
                    title = getString(message('Control:mrtool:PlotGalleryNewStep'));
                case "impulse"
                    title = getString(message('Control:mrtool:PlotGalleryNewImpulse'));
                case "bode"
                    title = getString(message('Control:mrtool:PlotGalleryNewBode'));
                case "nichols"
                    title = getString(message('Control:mrtool:PlotGalleryNewNichols'));
                case "nyquist"
                    title = getString(message('Control:mrtool:PlotGalleryNewNyquist'));
                case "sigma"   
                    title = getString(message('Control:mrtool:PlotGalleryNewSingularValue'));
                case "pzmap"
                    title = getString(message('Control:mrtool:PlotGalleryNewPoleZeroMap'));
                case "iopzmap"
                    title = getString(message('Control:mrtool:PlotGalleryNewIOPoleZeroMap'));
            end
        end
    end
    
end