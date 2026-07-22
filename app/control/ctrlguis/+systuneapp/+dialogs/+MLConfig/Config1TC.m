classdef (Hidden) Config1TC < controllib.widget.internal.tc.AtomicComponent
    % Tool Component for Configuration 1.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = public, SetObservable)
        F
        C
        G
        H
        Type
        Config1
        OKCallback %feval(fcn,Config1)
    end

    methods
        
        function this = Config1TC(varargin)
            if nargin == 0
                Data.F = 1;
                Data.C = 1;
                Data.G = 1;
                Data.H = 1;
            elseif nargin == 1 && isa(varargin{1}, 'systuneapp.data.MatlabConfigData.Config1')
                this.Config1 = varargin{1};

                Data.C = getParameterization(this.Config1.C);
                Data.F = getParameterization(this.Config1.F);
                Data.G = this.Config1.G;
                Data.H = this.Config1.H;
            elseif nargin == 1
                Data.C = varargin{1};
                Data.F = 1;
                Data.G = 1;
                Data.H = 1;
            elseif nargin == 4
                Data.C = varargin{1};
                Data.F = varargin{2};
                Data.G = varargin{3};
                Data.H = varargin{4};
            end
            
            setData(this, Data);
            
            if isempty(this.Config1)
                this.Config1 = systuneapp.data.MatlabConfigData.Config1(this.C,this.F,this.G,this.H);
            end
            
            this.Type = 'Config1';

        end
        
        function setData(this, Data)
            this.F = Data.F;
            this.C = Data.C;
            this.G = Data.G;
            this.H = Data.H;
        end
        
        function Data = getData(this)
            Data.F = this.F;
            Data.C = this.C;
            Data.G = this.G;
            Data.H = this.H;
        end
        
        function setDimensions(~)
        end
        
        function setSystem(this, Data, UserData)
            try
                if isnumeric(Data.C)
                    Data.C = tunableSS('C', Data.C);
                end
                if isnumeric(Data.F)
                    Data.F = tunableSS('F', Data.F);
                end
                if isnumeric(Data.G)
                    Data.G = ss(Data.G);
                end
                if isnumeric(Data.H)
                    Data.H = ss(Data.H);
                end
                    
                setConfigData(this.Config1,Data.C,Data.F,Data.G,Data.H);
                
                if isfield(UserData, 'C') && ~isa(Data.C, 'realp')
                    Data.C = getBlockParam(this.Config1, 'C');
                    Data.C.UserData = UserData.C;
                    setBlockParam(this.Config1, 'C', Data.C) ;
                end
                if isfield(UserData, 'F')  && ~isa(Data.C, 'realp')
                    Data.F = getBlockParam(this.Config1, 'F');
                    Data.F.UserData = UserData.F;
                    setBlockParam(this.Config1, 'F', Data.F) ;
                end
                if isfield(UserData, 'G')
                    Data.G.UserData = UserData.G;
                    this.Config1.G = Data.G;
                end
                if isfield(UserData, 'H')
                    Data.H.UserData = UserData.H;
                    this.Config1.H  = Data.H;
                end
                
            catch ME
                error(ME.message);
            end     
        end
           
    end
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.dialogs.MLConfig.Config1GC(this);
        end
    end
    methods(Access = protected)
        function mUpdate(~)
        end
    end
    
   
    
end
