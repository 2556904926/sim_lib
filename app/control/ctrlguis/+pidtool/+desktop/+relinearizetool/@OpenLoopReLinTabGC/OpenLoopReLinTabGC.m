classdef OpenLoopReLinTabGC < handle
    %
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties
        TPComponent
        InputSection
        SimulationSection
        LinearizeSection
        ReLinTC
    end
    
    methods
        function this = OpenLoopReLinTabGC(relintc)
            %OPENLOOPRELINTABGC constructor
            %
            
            this.ReLinTC = relintc;
            this.TPComponent = matlab.ui.internal.toolstrip.Tab('Open Loop Re-Linearization');
            this.TPComponent.Tag = tempname;
            this.InputSection = pidtool.desktop.relinearizetool.gc.InputSection(this.ReLinTC);
            this.SimulationSection = pidtool.desktop.relinearizetool.gc.SimulationSection(this.ReLinTC);
            this.LinearizeSection = pidtool.desktop.relinearizetool.gc.LinearizeSection(this.ReLinTC);
            
            this.build();
        end
        function build(this)
            %BUILD build object
            %
            
            this.TPComponent.add(this.InputSection.TPComponent);
            this.TPComponent.add(this.SimulationSection.TPComponent);
            this.TPComponent.add(this.LinearizeSection.TPComponent);
        end
        
    end
end