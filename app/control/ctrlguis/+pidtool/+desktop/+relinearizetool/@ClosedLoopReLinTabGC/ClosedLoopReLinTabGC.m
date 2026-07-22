classdef ClosedLoopReLinTabGC < handle
    %
    
    % Copyright 2013-2018 The MathWorks, Inc.
    
    properties
        TPComponent
        SimulationSection
        LinearizeSection
        ReLinTC
    end
    
    methods
        function this = ClosedLoopReLinTabGC(relintc)
            %OPENLOOPRELINTABGC constructor
            %
            
            this.ReLinTC = relintc;
            this.TPComponent = matlab.ui.internal.toolstrip.Tab(pidtool.utPIDgetStrings('scd','strCLReLin'));
            this.TPComponent.Tag = tempname;
            this.SimulationSection = pidtool.desktop.relinearizetool.gc.SimulationSection(this.ReLinTC);
            this.LinearizeSection = pidtool.desktop.relinearizetool.gc.LinearizeSection(this.ReLinTC);
            
            this.build();
        end
        function build(this)
            %BUILD build object
            %
            
            this.TPComponent.add(this.SimulationSection.TPComponent);
            this.TPComponent.add(this.LinearizeSection.TPComponent);
        end
        
    end
end