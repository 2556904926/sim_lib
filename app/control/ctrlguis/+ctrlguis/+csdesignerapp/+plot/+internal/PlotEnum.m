classdef PlotEnum    
    % Plot enumeration for plot types that are used in Control System
    % Designer App.
    
    % Copyright 2014 The MathWorks, Inc.    
    
    enumeration
        % Plot names
        Bode ('bode')
        Nichols ('nichols')
        Nyquist ('nyquist')
        Step ('step')
        Impulse ('impulse')
        SingularValue ('sigma')
        PoleZeroMap ('pzmap')
        IOPoleZeroMap ('iopzmap')        
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
            import ctrlguis.csdesignerapp.plot.internal.PlotEnum;
            
            if strcmp(tag,PlotEnum.Bode.Tag)
                plotenum = PlotEnum.Bode;
            elseif strcmp(tag,PlotEnum.Nichols.Tag)
                plotenum = PlotEnum.Nichols;
            elseif strcmp(tag,PlotEnum.Nyquist.Tag)
                plotenum = PlotEnum.Nyquist;
            elseif strcmp(tag,PlotEnum.Step.Tag)
                plotenum = PlotEnum.Step;
            elseif strcmp(tag,PlotEnum.Impulse.Tag)
                plotenum = PlotEnum.Impulse;
            elseif strcmp(tag,PlotEnum.SingularValue.Tag)
                plotenum = PlotEnum.SingularValue;
            elseif strcmp(tag,PlotEnum.PoleZeroMap.Tag)
                plotenum = PlotEnum.PoleZeroMap;
            elseif strcmp(tag,PlotEnum.IOPoleZeroMap.Tag)
                plotenum = PlotEnum.IOPoleZeroMap;
            else
                plotenum = [];
            end
        end
        function icon = getIcon(tag,iswide)
            arguments
                tag
                iswide (1,1) logical = true;
            end
            switch tag
                case 'bode'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('bodePlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('bodePlot');
                    end
                case 'nichols'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('nicholsPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('nicholsPlot');
                    end
                case 'nyquist'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('nyquistPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('nyquistPlot');
                    end
                case 'step'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('stepPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('stepPlot');
                    end
                case 'impulse'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('impulsePlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('impulsePlot');
                    end
                case 'sigma'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('sigmaPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('singularValuePlot');
                    end
                case 'pzmap'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('pzPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('pZPlot');
                    end
                case 'iopzmap'
                    if iswide
                        icon = matlab.ui.internal.toolstrip.Icon('ioPzPlotWide');
                    else
                        icon = matlab.ui.internal.toolstrip.Icon('iOPZPlot');
                    end
            end
        end
        function plottypes = getPlotTypes(isfrd)
            import ctrlguis.csdesignerapp.plot.internal.PlotEnum;
            if isfrd
                plottypes = [PlotEnum.Bode;...
                    PlotEnum.Nichols;...
                    PlotEnum.Nyquist;];
            else
                plottypes = [PlotEnum.Step;...
                    PlotEnum.Bode;...
                    PlotEnum.Impulse;...
                    PlotEnum.Nyquist;...
                    PlotEnum.Nichols;...
                    PlotEnum.SingularValue;...
                    PlotEnum.PoleZeroMap;...
                    PlotEnum.IOPoleZeroMap];
            end
        end
        
        function title = getNewPlotTitle(tag)
            switch tag
                case 'bode'
                    title = getString(message('Control:designerapp:PlotNewBode'));
                case 'nichols'
                    title = getString(message('Control:designerapp:PlotNewNichols'));
                case 'nyquist'
                    title = getString(message('Control:designerapp:PlotNewNyquist'));
                case 'step'
                    title = getString(message('Control:designerapp:PlotNewStep'));
                case 'impulse'
                    title = getString(message('Control:designerapp:PlotNewImpulse'));
                case 'sigma'    
                    title = getString(message('Control:designerapp:PlotNewSingularValue'));
                case 'pzmap'
                    title = getString(message('Control:designerapp:PlotNewPoleZeroMap'));
                case 'iopzmap'
                    title = getString(message('Control:designerapp:PlotNewIOPoleZeroMap'));
            end
        end
    end
    
end

% LocalWords:  plottypectl plotpickerctl
