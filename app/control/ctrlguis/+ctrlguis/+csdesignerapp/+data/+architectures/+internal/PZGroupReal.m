classdef PZGroupReal < ctrlguis.csdesignerapp.data.architectures.internal.PZGroup
    % Class that handles real pole/ real zero
    
    % Copyright 2015 The MathWorks, Inc.
    
    methods (Sealed = true)
        function this = PZGroupReal(Parent)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.PZGroup(Parent);
            this.Type = 'Real';
        end
        
        function Status = movelog(this,PZID,Ts)
            %MOVELOG  Generate log entry with new location of moved root
            
            if Ts
                DomainVar = 'z';
            else
                DomainVar = 's';
            end
            R = this.(PZID);
            if strcmpi(PZID,'zero')
                Status = getString(message('Control:compDesignTask:msgMoveRealCompensatorZero', ...
                    DomainVar,sprintf('%.3g',R)));
            else
                Status = getString(message('Control:compDesignTask:msgMoveRealCompensatorPole', ...
                    DomainVar,sprintf('%.3g',R)));
            end
        end
        
        function Description = describe(this,Ts)
            %DESCRIBE  Provides group description

            if Ts
                DomainVar = 'z';
            else
                DomainVar = 's';
            end
            
            % Real pole/zero
            if isempty(this.Pole_)
                R = this.Zero_;   
                ID = 'Zero';
                Description = {ID ; ...
                    getString(message('Control:compDesignTask:msgRealCompensatorZero',...
                    DomainVar,sprintf('%.3g',R)))};
            else
                R = this.Pole_;   
                ID = 'Pole';
                Description = {ID ; ...
                    getString(message('Control:compDesignTask:msgRealCompensatorPole',...
                    DomainVar,sprintf('%.3g',R)))};
            end
        end
        
        function Value = getValue(this,~,~)
            % GETVALUE sets the value for the pzgroup
            
            if isempty(this.Pole_)
                Value = this.Zero_;
            else
                Value = this.Pole_;
            end
        end
        
        function setValue(this,Value,~,~)
            % SETVALUE sets the value for the pzgroup based on flag
            % setValue(this,Value,Format,units)
            
            if isscalar(Value) && isreal(Value)
                if isempty(this.Pole_)
                    this.Zero_ = Value;
                else
                    this.Pole_ =  Value;
                end
            else
                error(message('Control:compDesignTask:PZGroupReal1'))
            end
            notify(this,'PZDataChanged')
        end
        
        function ParamSpec = createParamSpec(this)
            % CREATEPARAMSPEC creates parameter spec for real group
            
            if isempty(this.Pole_)
                str = 'Zero';
                strName = getString(message('Control:compDesignTask:strRealZero'));
                value = this.Zero;
            else
                str = 'Pole';
                strName = getString(message('Control:compDesignTask:strRealPole'));
                value = this.Pole_;
            end
            
            
            PID = modelpack.CSDParameterID(...
                sprintf('Real %s (group %d)',str, find(arrayfun(@(x)isequal(x,this),this.Parent.PZGroup))), ...% Not translated
                [1,1], ...
                this.Parent.getIdentifier, ...
                'double', ...
                {''}, ...
                strName);
            ParamSpec = modelpack.CSDParameterSpec(PID);
            ParamSpec.Minimum      = -inf;
            ParamSpec.Maximum      = inf;
            ParamSpec.InitialValue = value;
            ParamSpec.Known        = true;
            ParamSpec.TypicalValue = value;
        end

    end
end