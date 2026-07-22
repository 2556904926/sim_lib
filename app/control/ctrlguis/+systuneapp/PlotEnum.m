classdef (Hidden) PlotEnum    
    % Plot enumeration for plot types that are used in Control System Tuner
    % App.
    
    % Copyright 2013 The MathWorks, Inc.    
    
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
            if strcmp(tag,systuneapp.PlotEnum.Bode.Tag)
                plotenum = systuneapp.PlotEnum.Bode;
            elseif strcmp(tag,systuneapp.PlotEnum.Nichols.Tag)
                plotenum = systuneapp.PlotEnum.Nichols;
            elseif strcmp(tag,systuneapp.PlotEnum.Nyquist.Tag)
                plotenum = systuneapp.PlotEnum.Nyquist;
            elseif strcmp(tag,systuneapp.PlotEnum.Step.Tag)
                plotenum = systuneapp.PlotEnum.Step;
            elseif strcmp(tag,systuneapp.PlotEnum.Impulse.Tag)
                plotenum = systuneapp.PlotEnum.Impulse;
            elseif strcmp(tag,systuneapp.PlotEnum.SingularValue.Tag)
                plotenum = systuneapp.PlotEnum.SingularValue;
            elseif strcmp(tag,systuneapp.PlotEnum.PoleZeroMap.Tag)
                plotenum = systuneapp.PlotEnum.PoleZeroMap;
            elseif strcmp(tag,systuneapp.PlotEnum.IOPoleZeroMap.Tag)
                plotenum = systuneapp.PlotEnum.IOPoleZeroMap;
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
            arguments
                isfrd (1,1) logical = false;
            end
            if isfrd
                plottypes = [systuneapp.PlotEnum.Bode;...
                    systuneapp.PlotEnum.Nichols;...
                    systuneapp.PlotEnum.Nyquist;];
            else
                plottypes = [systuneapp.PlotEnum.Step;...
                    systuneapp.PlotEnum.Bode;...
                    systuneapp.PlotEnum.Impulse;...
                    systuneapp.PlotEnum.Nyquist;...
                    systuneapp.PlotEnum.Nichols;...
                    systuneapp.PlotEnum.SingularValue;...
                    systuneapp.PlotEnum.PoleZeroMap;...
                    systuneapp.PlotEnum.IOPoleZeroMap];
            end
        end
        
        function title = getNewPlotTitle(tag)
            switch tag
                case 'bode'
                    title = getString(message('Control:systunegui:PlotNewBode'));
                case 'nichols'
                    title = getString(message('Control:systunegui:PlotNewNichols'));
                case 'nyquist'
                    title = getString(message('Control:systunegui:PlotNewNyquist'));
                case 'step'
                    title = getString(message('Control:systunegui:PlotNewStep'));
                case 'impulse'
                    title = getString(message('Control:systunegui:PlotNewImpulse'));
                case 'sigma'    
                    title = getString(message('Control:systunegui:PlotNewSingularValue'));
                case 'pzmap'
                    title = getString(message('Control:systunegui:PlotNewPoleZeroMap'));
                case 'iopzmap'
                    title = getString(message('Control:systunegui:PlotNewIOPoleZeroMap'));
            end
        end
    end
    
end

% LocalWords:  plottypectl plotpickerctl
