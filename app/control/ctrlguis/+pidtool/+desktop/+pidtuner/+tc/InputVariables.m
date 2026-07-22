classdef InputVariables < handle
    %INPUTVARIABLES
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties (Dependent, AbortSet, SetObservable)
        WC
    end
    
    properties (AbortSet, SetObservable)
        PM = 60
        DesignDomain = 'time'
    end
    properties
        MaxWC = 10
        MinWC = 0.1
    end
    properties (Dependent = true, AbortSet)
        ResponseTime
        TransientBehavior
        MaxRT
        MinRT
    end
    properties (Access = private)
        WC_ = 1;
    end
    events
        WCLimitsReset
    end
    methods
        function this = InputVariables()
            %INPUTVARIABLES
            
        end
        function set.WC(this, val)
            %SET
            
            this.WC_ = val;
            
        end
        function set.PM(this, val)
            %SET
            
            this.PM = val;
            
        end
        function val = get.WC(this)
            %GET
            
            val = this.WC_;
        end
        function val = get.ResponseTime(this)
            %GET
            
            val = 2/this.WC_;
        end
        function set.ResponseTime(this, val)
            %SET
            
            this.WC = 2/val;
        end
        function val = get.TransientBehavior(this)
            %GET
            
            val = this.PM/100;
        end
        function set.TransientBehavior(this, val)
            %SET
            
            this.PM = 100*val;
        end
        function val = get.MaxRT(this)
            val = 2/this.MinWC;
        end
        function val = get.MinRT(this)
            val = 2/this.MaxWC;
        end
        function set.MaxRT(this, val)
            this.MinWC = 2/val;
        end
        function set.MinRT(this, val)
            this.MaxWC = 2/val;
        end
        function resetMinMaxWC(this)
            this.MaxWC = this.WC*10;
            this.MinWC = this.WC/10;
            notify(this, 'WCLimitsReset');
        end
        function setWC_(this, val)
            this.WC_ = val;
        end
    end
end
