classdef (Hidden) SystuneGUIOptionsTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for options of Control System Tuner App.    
    
    % Copyright 2013 The MathWorks, Inc.  

    properties(GetAccess = public, SetAccess = protected)        
        % System tuning data
        Data
    end
    
    properties (Constant, GetAccess=private)
        %get field names of the systuneOptions()
        optionFields = fieldnames(systuneOptions());
    end
    properties (Transient)
       OptionsListener 
    end
    
    %%
    methods(Access = public)
        function this = SystuneGUIOptionsTC(SystemTuningData)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            
            this.Data = SystemTuningData;
            setOptions(this,SystemTuningData.Options);
            
            this.OptionsListener = addlistener(SystemTuningData,'Options','PostSet',@(hSrc,hData) update(this));            
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.SystuneGUIOptionsGC(this);
        end          
        function delete(this)
            delete(this.OptionsListener); 
        end
        function setOptions(this,newOptionSet)
            % newOptionsSet input must be of class rctoptions.systune. It
            % can be generated using systuneOptions()
            if isa(newOptionSet,'rctoptions.systune')
                this.Data.Options = newOptionSet;
                update(this);
            else
                error(message('Control:systunegui:SystuneGUIOptionsErrInvalidOptionStructure'));
            end  
        end                
        function setOptionField(this,fieldName,fieldValue)
            % setOptionField Set the 'fieldName' field of the
            % systuneOptions() instance being edited to 'fieldValue'
            if any(strcmp(fieldName,this.optionFields))
                this.Data.Options.(fieldName) = fieldValue;
                update(this);
                this.Data.ControlDesignData.setDirty(true);
            else
                error(message('Control:systunegui:SystuneGUIOptionsErrInvalidOptionField',fieldName));
            end
        end                
        function options = getOptions(this)
            % getOptions Get the current instance of the systuneOptions()
            %
            % options = getOptions(this)
            options = this.Data.Options;
        end
    end
end
