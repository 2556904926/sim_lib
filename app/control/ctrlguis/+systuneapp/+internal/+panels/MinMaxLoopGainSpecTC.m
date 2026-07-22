classdef MinMaxLoopGainSpecTC <  systuneapp.internal.panels.GainSpecTC
    % Tool component for Minimum and Maximum Loop Gain tuning goal specifications
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = MinMaxLoopGainSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GainSpecTC(Data);
        end
    end
    %% Tool-Component API
    methods     
        function view = createView(this)
            %Create the view
            view = systuneapp.internal.panels.MinMaxLoopGainSpecGC(this);
        end
     
        function this = computeMetaData(this)
            % Derive MetaData from Data whenever it is empty
            if this.Data.Create
                % If the tuning goal is created from GUI, open in the
                % basic mode
                this.MetaData.EnableGain = false;
            else
                % If the tuning goal was created elsewhere, open in
                % advanced mode
                this.MetaData.EnableGain = true;
            end
            
            % Call Parent computeMetaData to get Models and Gain metadata
            computeMetaData@systuneapp.internal.panels.GainSpecTC(this);
                        
            % Default values for fields not in data
            this.MetaData.F = 1;
            this.MetaData.G = 1;
        end
        
        function this = setF(this,Fexpr)
            % Set the Fmax or Fmin property
            F = evalin('base', Fexpr);
            if ~(isnumeric(F) && isscalar(F) && isreal(F) && isfinite(F) && F>0)
                error(message('Control:tuning:MaxLoopGainReq1'))
            else
                this.MetaData.F = F;
            end
        end
        
        function this = setG(this,Gexpr)
            % Set Gmax or Gmin property
            G = evalin('base', Gexpr);
            if ~(isnumeric(G) && isscalar(G) && isreal(G) && isfinite(G) && G>0)
                error(message('Control:tuning:MaxLoopGainReq2'))
            else
                this.MetaData.G = G;
            end
        end
                
         function this = setLoopScaling(this, LoopScaling)
            % Set the loop scaling property
            % Input 'LoopScaling' is either 'on' or 'off'
            this.Data.LoopScaling = LoopScaling;
         end
    end
    
end
