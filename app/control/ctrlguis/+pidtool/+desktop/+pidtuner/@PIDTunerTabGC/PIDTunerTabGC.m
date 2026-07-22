classdef PIDTunerTabGC < handle
    %PIDTUNERTABGC
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties
        TunerTC
        TPComponent
        PlantSection
        ControllerSection
        DesignSection
        TuningtoolsSection
        ResultsSection
        FrameWidth = 980
    end
    methods
        function this = PIDTunerTabGC(tunertc)
            %PIDTUNERTABGC
            
            this.TunerTC = tunertc;
            this.TPComponent = matlab.ui.internal.toolstrip.Tab(pidtool.utPIDgetStrings('cst', 'tunerdlg_title'));
            this.TPComponent.Tag = 'PIDTunerTabGC';
            this.PlantSection = pidtool.desktop.pidtuner.gc.PlantSection(this.TunerTC);
            if strcmp(this.TunerTC.ToolType, 'MATLAB')
                this.ControllerSection = pidtool.desktop.pidtuner.gc.ControllerSection(this.TunerTC);
            else
                this.ControllerSection = slctrlguis.pidtuner.gc.ControllerSection(this.TunerTC);
            end
            this.DesignSection = pidtool.desktop.pidtuner.gc.DesignSection(this.TunerTC);
            this.TuningtoolsSection = pidtool.desktop.pidtuner.gc.TuningtoolsSection(this.TunerTC);
            if strcmp(this.TunerTC.ToolType, 'MATLAB')
                this.ResultsSection = pidtool.desktop.pidtuner.gc.ResultsSection(this.TunerTC);
            else
                this.ResultsSection = slctrlguis.pidtuner.gc.ResultsSection(this.TunerTC);
            end
            this.build();
        end
        function build(this)
            %BUILD
            
            this.TPComponent.add(this.PlantSection.TPComponent);
            this.TPComponent.add(this.ControllerSection.TPComponent);
            this.TPComponent.add(this.DesignSection.TPComponent);
            this.TPComponent.add(this.TuningtoolsSection.TPComponent);
            this.TPComponent.add(this.ResultsSection.TPComponent);
            
        end
    end
end
