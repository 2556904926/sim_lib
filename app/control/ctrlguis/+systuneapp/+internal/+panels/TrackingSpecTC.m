classdef (Hidden) TrackingSpecTC <  systuneapp.internal.panels.GenericTuningGoalSpecTC
    % Tool component for Tracking tuning goal specifications
    
    % Copyright 2013 The MathWorks, Inc
    properties(GetAccess = public, SetAccess = public, SetObservable)
    end
    
    methods
        function this = TrackingSpecTC(Data)
            % Call parent constructor
            this = this@systuneapp.internal.panels.GenericTuningGoalSpecTC(Data);
        end
    end
    
    %% Tool-Component API
    methods     
        function view = createView(this)
            % Create the view
            view = systuneapp.internal.panels.TrackingSpecGC(this);
        end
           
        function this = computeMetaData(this)
            % Derive MetaData from Data whenever it is empty
            if this.Data.Create
                %If the tuning goal is created from GUI, open in the
                %time domain specifications config
                this.MetaData.EnableFreqDomainSpec = false;
            else
                %If the tuning goal was created elsewhere, open in
                %frequency domain specifications config
                this.MetaData.EnableFreqDomainSpec = true;
            end
            
            % Call Parent computeMetaData to get Models and MaxError metadata
            computeMetaData@systuneapp.internal.panels.GenericTuningGoalSpecTC(this, 'MaxError', this.Data.MaxError);
            
            % Default values for fields not in data
            this.MetaData.ResponseTime = 1;
            this.MetaData.PeakError = 1;
            this.MetaData.DCError = 1e-3;
            
            if isempty(this.Data.InputScaling)
                this.MetaData.InputScaling = [1, 1];
            else
                this.MetaData.InputScaling = this.Data.InputScaling;
            end
            
        end
                
        function this = setRT(this,RTExpr)
            % Set the Response Time
            RT = evalin('base', RTExpr);
            this.MetaData.ResponseTime = RT;
        end
        
        function this = setDCError(this,DCErrorExpr)
            % The user is asked to enter percent DC Error. Convert and
            % store if checks pass. (Local check to pass gui specific error
            % message)
            DCError = evalin('base', DCErrorExpr);
            if (isnumeric(DCError) && isscalar(DCError) && ...
                    isreal(DCError) && DCError>=0 && DCError<100)
                this.MetaData.DCError = DCError/100;
            else
                error(message('Control:systunegui:TrackingSpecErrDCError'))
            end
        end
       
        function this = setPeakError(this,PeakErrorExpr)
            % The user is asked to enter percent Peak Error. Convert and
            % store if checks pass. (Local check to pass gui specific error
            % message)
            PeakError = evalin('base', PeakErrorExpr);
            if (isnumeric(PeakError) && isscalar(PeakError) && ...
                    isreal(PeakError) && PeakError>=100 && PeakError<Inf)
                this.MetaData.PeakError = PeakError/100;
            else
                error(message('Control:systunegui:TrackingSpecErrPeakError'))
            end
        end      
        
        function this = setMaxError(this, MaxErrorExpr)
            % Set the MaxError property
            MaxErrorVal = evalin('base',MaxErrorExpr);
            if isnumeric(MaxErrorVal)
                % If numeric, set to dc gain
                this.Data.MaxError = zpk(MaxErrorVal);
            else
                this.Data.MaxError = MaxErrorVal;
            end
            this.MetaData.MaxError = MaxErrorExpr;
        end
        
        function this = setScalingAmplitude(this,ScalingAmplitudeExpr)
            % Set the input amplitude for scaling
            
            % Scaling amplitude can be empty. Account for that.
            if nargin == 1
                ScalingAmplitude = [];
            else
                ScalingAmplitude = evalin('base', ScalingAmplitudeExpr);
            end
            
            this.Data.InputScaling = ScalingAmplitude;
            
            if ~isempty(this.Data.InputScaling)
                % update the metadata only if the input scaling is not
                % empty
                this.MetaData.InputScaling = ScalingAmplitude;
            end
        end
               
    end
    
end
