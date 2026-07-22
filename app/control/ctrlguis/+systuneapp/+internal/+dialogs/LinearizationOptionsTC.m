classdef (Hidden) LinearizationOptionsTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for linearization options of Control System Tuner App.    
    
    % Copyright 2020 The MathWorks, Inc.      

    properties(GetAccess = public, SetAccess = protected)                
        Data % linearizeOptions
        ControlDesignData
    end    
    
    properties (Constant, GetAccess=private)
        optionFields = ctrlguis.csdesignerapp.panels.internal.LinearizationOptionsTC.linearizeOptionsPublicFields();
    end    
    
    %%
    methods(Access = public)
        function this = LinearizationOptionsTC(ControlDesignData)
            this = this@controllib.widget.internal.tc.AtomicComponent;            
            this.ControlDesignData = ControlDesignData;
            setOptions(this,getLinearizationOptions(this));                       
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.LinearizationOptionsGC(this);
        end          
        function setOptions(this,newOptionSet)
            if isa(newOptionSet,'linearize.LinearizeOptions') || isa(newOptionSet,'linearize.SlTunerOptions')
                this.Data = newOptionSet;
                update(this);
            else
                error(message('Control:systunegui:LinearizationOptionsErrInvalidOptionStructure'));
            end  
        end                
        function setOptionField(this,fieldName,fieldValue)            
            % if one of the field value
            if any(strcmp(fieldName,this.optionFields))
                % if the value is different
                CurrentOptions = this.ControlDesignData.getLinearizationOptions;
                if ~isequal(CurrentOptions.(fieldName),fieldValue)
                    this.Data.(fieldName) = fieldValue;
                    update(this);
                end
            else
                error(message('Control:systunegui:LinearizationOptionsErrInvalidOptionField',fieldName));
            end
        end                
        function options = getOptions(this)
            % getOptions Get the current instance of the systuneOptions()
            options = this.Data;
        end
        function setLinearizationOptions(this)
            CurrentOptions = this.ControlDesignData.getLinearizationOptions;
            % set linearization options when it's different
            if ~isequal(CurrentOptions,this.Data)
                this.ControlDesignData.setLinearizationOptions(this.Data);
            end
        end
        
        function Options = getLinearizationOptions(this)            
            Options = this.ControlDesignData.getLinearizationOptions;
        end
        
        function setSampleTime(this,SampleTime)
            if isnumeric(SampleTime) && isscalar(SampleTime) && isreal(SampleTime) && isfinite(SampleTime) && (SampleTime>0) 
                setOptionField(this,'SampleTime',SampleTime)
            else
                error(message('Control:systunegui:LinearizationOptionsErrorSampleTime'));
            end                                                  
        end
        function setPrewarpFrequency(this,PrewarpFrequency)
            if isnumeric(PrewarpFrequency) && isscalar(PrewarpFrequency) && isreal(PrewarpFrequency)&& isfinite(PrewarpFrequency) && (PrewarpFrequency>0)
                setOptionField(this,'PreWarpFreq',PrewarpFrequency)
            else
                error(message('Control:systunegui:LinearizationOptionsErrorPrewarpFrequency'));
            end              
        end        
    end
end
