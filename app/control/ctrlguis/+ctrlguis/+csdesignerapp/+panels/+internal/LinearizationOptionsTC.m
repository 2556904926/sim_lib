classdef LinearizationOptionsTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for linearization options of Control System Tuner App.    
    
    % Copyright 2013-2020 The MathWorks, Inc.      

    properties(GetAccess = public, SetAccess = protected)                
        Data % linearizeOptions
        Architecture
        Parent
    end    
    
    properties (Constant, GetAccess=private)
        optionFields = ctrlguis.csdesignerapp.panels.internal.LinearizationOptionsTC.linearizeOptionsPublicFields();
    end    
    
    %%
    methods(Access = public)
        function this = LinearizationOptionsTC(Architecture,Parent)
            this = this@controllib.widget.internal.tc.AtomicComponent;            
            this.Architecture = Architecture;
            this.Parent = Parent;
            setOptions(this,getLinearizationOptions(this));                       
        end
        
        function setArchitecture(this, Architecture)
            this.Architecture = Architecture;
            setOptions(this,getLinearizationOptions(this));
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this,varargin)
            view = ctrlguis.csdesignerapp.panels.internal.LinearizationOptionsGC(this,varargin{:});
        end          
        function setOptions(this,newOptionSet)
            if isa(newOptionSet,'linearize.LinearizeOptions') || isa(newOptionSet,'linearize.SlTunerOptions')
                this.Data = newOptionSet;
                update(this);
            else
                error(message('Control:designerapp:LinearizationOptionsErrInvalidOptionStructure'));
            end  
        end                
        function setOptionField(this,fieldName,fieldValue)            
            % if one of the field value
            if any(strcmp(fieldName,this.optionFields))
                % if the value is different
                CurrentOptions = this.Architecture.getLinearizationOptions;
                if ~isequal(CurrentOptions.(fieldName),fieldValue)
                    this.Data.(fieldName) = fieldValue;
                    update(this);
                end

            else
                error(message('Control:designerapp:LinearizationOptionsErrInvalidOptionField',fieldName));
            end
        end                
        function options = getOptions(this)
            % getOptions Get the current instance of the options()
            options = this.Data;
        end
        function setLinearizationOptions(this)
            CurrentOptions = this.Architecture.getLinearizationOptions;
            % set linearization options when it's different
            if ~isequal(CurrentOptions,this.Data)
                this.Architecture.setLinearizationOptions(this.Data);
            end
        end
        
        function Options = getLinearizationOptions(this)            
            Options = this.Architecture.getLinearizationOptions;
        end
        
        function setSampleTime(this,SampleTime)
            if isnumeric(SampleTime) && isscalar(SampleTime) && isreal(SampleTime) && (SampleTime>0)
                setOptionField(this,'SampleTime',SampleTime)
            else
                error(message('Control:designerapp:LinearizationOptionsErrorSampleTime'));
            end                                                  
        end
        function setPrewarpFrequency(this,PrewarpFrequency)                 
            if isnumeric(PrewarpFrequency) && isscalar(PrewarpFrequency) && isreal(PrewarpFrequency) && (PrewarpFrequency>0)
                setOptionField(this,'PreWarpFreq',PrewarpFrequency)
            else
                error(message('Control:designerapp:LinearizationOptionsErrorPrewarpFrequency'));
            end              
        end        
    end
    methods (Static)
        function names = linearizeOptionsPublicFields()
            % the following gets hidden property names (fieldnames does not)
            m = ?linearize.LinearizeOptions;
            names = {m.PropertyList.Name}';
        end
    end
end