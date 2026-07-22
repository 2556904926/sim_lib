classdef PZGroupReal < sisodata.pzgroup
%sisodata.PZGroupReal class
%   sisodata.PZGroupReal extends sisodata.pzgroup.
%

%    sisodata.PZGroupReal properties:
%       Parent - Property is of type 'MATLAB array'  
%       Type - Property is of type 'string'  
%       Zero - Property is of type 'MATLAB array'  
%       Pole - Property is of type 'MATLAB array'  
%       VirtualProperties - Property is of type 'MATLAB array'  
%
%    sisodata.PZGroupReal methods:
%       convertValue - converts the value based on Format
%       createParamSpec - creates parameter spec for real group
%       describe -  Provides group description.
%       getValue - sets the value for the pzgroup
%       setValue - sets the value for the pzgroup based on flag
%       utIsIntOrDiff -  checks if pzgroup is an integrator or differentiator



    methods  % constructor block
        function h = PZGroupReal(Parent)
        % Constructor
        
        
                h.Type = 'Real';
        
        if nargin == 1
           h.Parent = Parent;
        end
           
        end  % PZGroupReal
        
    end  % constructor block

    methods  % public methods
        %----------------------------------------
       function NewValue = convertValue(this,Value,OldFormat,NewFormat,units)
       % convertValue converts the value based on Format
       %
       
       
       NewValue = Value;
       end  % convertValue
       
        %----------------------------------------
       function ParamSpec = createParamSpec(this)
       % CREATEPARAMSPEC creates parameter spec for real group
       
       
       
       
       if isempty(this.Pole)
           str = 'Zero';
           strName = getString(message('Control:compDesignTask:strRealZero'));
           value = this.Zero;
       else
           str = 'Pole';
           strName = getString(message('Control:compDesignTask:strRealPole'));
           value = this.Pole;
       end
       
       
       PID = modelpack.STParameterID(...
           sprintf('Real %s (group %d)',str, find(this==this.Parent.PZGroup)), ...% Not translated
           [1,1], ...
           this.Parent.Identifier, ...
           'double', ...
           {''}, ...
           strName);
       ParamSpec = modelpack.STParameterSpec(PID);
       ParamSpec.Minimum      = -inf;
       ParamSpec.Maximum      = inf;
       ParamSpec.InitialValue = value;
       ParamSpec.Known        = true;
       ParamSpec.TypicalValue = value;
       
       end  % createParamSpec
       
        %----------------------------------------
       function Description = describe(Group,Ts)
       %DESCRIBE  Provides group description.
       
       %   Author(s): P. Gahinet
       
       
       if Ts
           DomainVar = 'z';
       else
           DomainVar = 's';
       end
       
       % Real pole/zero
       if isempty(Group.Pole)
           R = Group.Zero;   ID = 'Zero';
           Description = {ID ; ...
               getString(message('Control:compDesignTask:msgRealCompensatorZero',...
               DomainVar,sprintf('%.3g',R)))};
       else
           R = Group.Pole;   ID = 'Pole';
           Description = {ID ; ...
               getString(message('Control:compDesignTask:msgRealCompensatorPole',...
               DomainVar,sprintf('%.3g',R)))};
       end
       
           
       
       end  % describe
       
        %----------------------------------------
       function Value = getValue(this,Format,units)
       % GETVALUE sets the value for the pzgroup
       %
       
       %     $Date:  
       
       if isempty(this.Pole)
           Value = this.Zero;
       else
           Value = this.Pole;
       end
       
       end  % getValue
       
        %----------------------------------------
       function setValue(this,Value,Format,units)
       % SETVALUE sets the value for the pzgroup based on flag
       %
       
       
       if isscalar(Value) && isreal(Value)
           if isempty(this.Pole)
               this.Zero = Value;
           else
               this.Pole =  Value;
           end
       else
           ctrlMsgUtils.error('Control:compDesignTask:PZGroupReal1')
       end
       
       
       end  % setValue
       
        %----------------------------------------
       function b = utIsIntOrDiff(this,Ts)
       % checks if pzgroup is an integrator or differentiator
       
       
       if isequal(Ts,0);
           sz = 0;
       else 
           sz = 1;
       end
       
       if isequal(this.Zero,sz) || isequal(this.Pole,sz)
           b = true;
       else
           b = false;
       end
       
       
           
       end  % utIsIntOrDiff
       
end  % public methods 

end  % classdef

