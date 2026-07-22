classdef (Hidden) GenssConfigTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for genss configuration.
    
    % Copyright 2013 The MathWorks, Inc.    

    properties
        System
        Type
        ConfigGenss
        OKCallback %feval(fcn,ConfigGenss)
    end
    
    methods
        function obj = GenssConfigTC(AConfigGenSS)
                        
            if nargin == 0
                Sys = genss;
            else
                Sys = AConfigGenSS.System;
            end
            obj.System = Sys;
            obj.ConfigGenss = AConfigGenSS;
            
            obj.Type = 'ConfigGenss';
        end
        
        function view = createView(this)
            %CREATEVIEW Construct graphical component for the tool component
            %
            view = systuneapp.dialogs.MLConfig.GenssConfigGC(this);
        end
        
        function setData(this, System)
            this.System = System;
            update(this);
        end
        
        function System = getData(this)
            System = this.System;
        end
        
        function setSystem(this)
            try
                setConfigData(this.ConfigGenss,this.System);
            catch ME
                error(ME.message);
            end
        end
        
    end
    methods(Access = protected)
        function mUpdate(~)
        end
    end
end
