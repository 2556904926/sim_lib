classdef PZGroupComplex < sisodata.pzgroup
%sisodata.PZGroupComplex class
%   sisodata.PZGroupComplex extends sisodata.pzgroup.
%

%    sisodata.PZGroupComplex properties:
%       Parent - Property is of type 'MATLAB array'  
%       Type - Property is of type 'string'  
%       Zero - Property is of type 'MATLAB array'  
%       Pole - Property is of type 'MATLAB array'  
%       VirtualProperties - Property is of type 'MATLAB array'  
%       Zeta - Property is of type 'double'  
%       Wn - Property is of type 'double'  
%
%    sisodata.PZGroupComplex methods:
%       convertValue - converts value based on Format
%       createParamSpec -  getParameterSpec  Gets the parameter spec forthe pz group
%       describe -  Provides group description.
%       getValue - sets the value for the pzgroup based on flag
%       setValue - sets the value for the pzgroup based on Format
%       updateVirtualProperties - Updates virtual properties for complex pzgroup


properties (SetObservable)
    %ZETA Property is of type 'double' 
    Zeta = 0;
    %WN Property is of type 'double' 
    Wn = 0;
end


    methods  % constructor block
        function h = PZGroupComplex(Parent)
        % Constructor
        
        
                h.Type = 'Complex';
        
        if nargin == 1
           h.Parent = Parent;
        end
           
        end  % PZGroupComplex
        
    end  % constructor block

    methods 
        function value = get.Zeta(obj)
        value = LocalGetVirtualProperty(obj,obj.Zeta,1);
        end
        function set.Zeta(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Zeta')
        value = double(value); %  convert to double
        obj.Zeta = value;
        end

        function value = get.Wn(obj)
        value = LocalGetVirtualProperty(obj,obj.Wn,2);
        end
        function set.Wn(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Wn')
        value = double(value); %  convert to double
        obj.Wn = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function NewValue = convertValue(this,Value,OldFormat,NewFormat,units)
       % convertVALUE converts value based on Format
       %
       % Format = 1; Value = [Real; Imag]; 
       % Format = 2; Value = [Zeta, Wn];
       
       
       
       if isequal(OldFormat, NewFormat)
          NewValue = Value;
       else
          %Set Useful information
          Wmin    = 0;
          ZetaMax = 1;
          Ts      = this.Parent.Ts;
          if nargin < 5
             units.FrequencyUnits = 'rad/s';
          end
       
          if OldFormat == 1;
             %Real/Imag to Zeta/Wn
             if all(isfinite(Value))
                %Have finite values to convert
                [Wn, Zeta] = damp(Value(1)+i*Value(2), Ts);
             else
                %Non-finite values, return hard limits.
                if any(Value < 0)
                   %Assume lower limit
                   Zeta = -1;
                   Wn   = 0;
                else
                   %Assume upper limit
                   Zeta = 1;
                   Wn   = inf;
                end
             end
             %Return converted value
             NewValue = [Zeta;unitconv(Wn,'rad/s',units.FrequencyUnits)];
          else
             %Zeta/Wn to Real/Imag
             if all(isfinite(Value)) && abs(Value(1)) <= ZetaMax && Value(2) > Wmin
                %Have finite and valid values to convert
                Zeta = Value(1);
                if abs(Zeta)>1
                   Zeta = sign(Zeta);
                end
                Wn = unitconv(Value(2), units.FrequencyUnits, 'rad/s');
                Loc = -Zeta*Wn + Wn*sqrt(Zeta^2-1);
                if Ts ~= 0
                   Loc = exp(Loc*Ts);
                end
                NewValue = [real(Loc);imag(Loc)];
             else
                %Non-finite values, return hard limits.
                if any(Value < 0)
                   %Assume lower limit
                   NewValue = [-inf;-inf];
                else
                   %Assume upper limit
                   NewValue = [inf;inf];
                end
             end
          end
       end
       end  % convertValue
       
        %----------------------------------------
       function ParamSpec = createParamSpec(this)
       % getParameterSpec  Gets the parameter spec forthe pz group
       
       
       
       if isempty(this.Pole)
           str = 'Zero';
           strName = getString(message('Control:compDesignTask:strComplexZero'));
           value = [real(this.Zero(1));imag(this.Zero(1))];
       else
           str = 'Pole';
           strName = getString(message('Control:compDesignTask:strComplexPole'));
           value = [real(this.Pole(1));imag(this.Pole(1))];
       end
       
       
       PID = modelpack.STParameterID(...
           sprintf('Complex %s (group %d)',str,find(this==this.Parent.PZGroup)), ... % Not translated
           [2,1], ...
           this.Parent.Identifier, ...
           'double', ...
           {''}, ...
           strName);
       ParamSpec              = modelpack.STParameterSpec(PID, ...
           {getString(message('Control:compDesignTask:strFormatRealImag')), ...
            getString(message('Control:compDesignTask:strFormatZetaWn'))});
       ParamSpec.Known        = true;
       ParamSpec.Minimum      = [-inf; 0];
       ParamSpec.Maximum      = [inf; inf];
       ParamSpec.InitialValue = value;
       ParamSpec.TypicalValue = value;
       
       ParamSpec.Listeners = event.proplistener(this,this.findprop('Format'),...
           'PostSet',@(hSrc,hData) LocalSetMinMax(ParamSpec));
       end  % createParamSpec
       
       
       
       %% LOCAL FUNCTIONS --------------------------------------------------------

        %----------------------------------------
       function Description = describe(Group,Ts)
       %DESCRIBE  Provides group description.
       
       %   Author(s): P. Gahinet
       
       
       if Ts
           DomainVar = 'z';
       else
           DomainVar = 's';
       end
       
       
       if isempty(Group.Pole)
           R = Group.Zero(1);   ID = 'Zero';
           Description = {ID ; ...
               getString(message('Control:compDesignTask:msgComplexCompensatorZeros',...
               DomainVar,sprintf('%.3g %s %.3gi', real(R),'+/-',abs(imag(R)))))};
       else
           R = Group.Pole(1);   ID = 'Pole';
           Description = {ID ; ...
               getString(message('Control:compDesignTask:msgComplexCompensatorPoles',...
               DomainVar,sprintf('%.3g %s %.3gi', real(R),'+/-',abs(imag(R)))))};
       end
       
       
       end  % describe
       
        %----------------------------------------
       function Value = getValue(this,Format,units)
       % GETVALUE sets the value for the pzgroup based on flag
       %
       % Format = 1; Value = [Real; Imag]; 
       % Format = 2; Value = [Zeta, Wn];
       
       %     $Date:  
       
       if (nargin == 1) || (Format == 1);
           if isempty(this.Pole)
               Location = this.Zero(1);
           else
               Location = this.Pole(1);
           end
           Value = [real(Location); imag(Location)];
       else
           if nargin < 3
               units.FrequencyUnits = 'rad/s';
           end
           if isempty(this.VirtualProperties)
               this.updateVirtualProperties
           end
           Zeta = this.VirtualProperties(1);
           Wn = this.VirtualProperties(2);
       
           Value = [Zeta; unitconv(Wn,'rad/s',units.FrequencyUnits)];
       end
       
       
       
       
       
       end  % getValue
       
        %----------------------------------------
       function setValue(this,Value,Format,units)
       % SETVALUE sets the value for the pzgroup based on Format
       %
       % Format = 1; Value = [Real; Imag]; 
       % Format = 2; Value = [Zeta, Wn];
       
       
       if Format == 1
           R = Value(1);
           I = Value(2);
           if isempty(this.Pole)
               this.Zero = [R+i*I; R-i*I];
           else
               this.Pole =  [R+i*I; R-i*I];
           end
       else
           Zeta = Value(1);
           if abs(Zeta)>1
               Zeta = sign(Zeta);
           end
           if nargin < 4
               units.FrequencyUnits = 'rad/s';
           end
           Wn = unitconv(Value(2), units.FrequencyUnits, 'rad/s');
           Loc = -Zeta*Wn + Wn*sqrt(Zeta^2-1);
           Location = [Loc; conj(Loc)];
           
           Ts = this.Parent.Ts;
           if Ts ~= 0
               Location = exp(Location*Ts);
           end
           
           if isempty(this.Pole)
               this.Zero = Location;
           else
               this.Pole = Location;
           end
           
       end
               
       end  % setValue
       
        %----------------------------------------
       function updateVirtualProperties(this)
       % UPDATEVIRTUALPROPERTIES Updates virtual properties for complex pzgroup
       
       %     $Date:  
       
       if isempty(this.Pole) && isempty(this.Zero)
           this.VirtualProperties = [NaN; NaN];
       else
           if isempty(this.Pole)
               Location = this.Zero(1);
           else
               Location = this.Pole(1);
           end
           [Wn, Zeta] = damp(Location, this.Parent.Ts);
       
           this.VirtualProperties = [Zeta; Wn];
       end
       end  % updateVirtualProperties
       
end  % public methods 

end  % classdef

function Value = LocalGetVirtualProperty(this,StoredValue,idx)

if isempty(this.VirtualProperties)
    this.updateVirtualProperties;
end

Value = this.VirtualProperties(idx);
end  % LocalGetVirtualProperty





function LocalSetMinMax(ParamSpec)
if ParamSpec.Format == 1
    ParamSpec.Minimum = [-inf; 0];
    ParamSpec.Maximum = [inf; inf];
else
   
    ParamSpec.Minimum = [-1 ; 0 ];
    ParamSpec.Maximum = [1; inf];
end
end  % LocalSetMinMax
