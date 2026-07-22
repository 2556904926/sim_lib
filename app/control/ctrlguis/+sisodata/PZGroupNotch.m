classdef PZGroupNotch < sisodata.pzgroup
%sisodata.PZGroupNotch class
%   sisodata.PZGroupNotch extends sisodata.pzgroup.
%

%    sisodata.PZGroupNotch properties:
%       Parent - Property is of type 'MATLAB array'  
%       Type - Property is of type 'string'  
%       Zero - Property is of type 'MATLAB array'  
%       Pole - Property is of type 'MATLAB array'  
%       VirtualProperties - Property is of type 'MATLAB array'  
%       Wn - Property is of type 'double'  
%       ZetaZero - Property is of type 'double'  
%       ZetaPole - Property is of type 'double'  
%       Depth - Property is of type 'double'  
%       Width - Property is of type 'double'  
%
%    sisodata.PZGroupNotch methods:
%       convertValue - converts value based on Format
%       createParamSpec - Creates parameter spec for notch group
%       describe -  Provides group description.
%       getValue - sets the value for the pzgroup based on flag
%       setValue - sets the value for the pzgroup based on flag
%       updateVirtualProperties - for Notch


properties (SetObservable)
    %WN Property is of type 'double' 
    Wn = 0;
    %ZETAZERO Property is of type 'double' 
    ZetaZero = 0;
    %ZETAPOLE Property is of type 'double' 
    ZetaPole = 0;
    %DEPTH Property is of type 'double' 
    Depth = 0;
    %WIDTH Property is of type 'double' 
    Width = 0;
end


    methods  % constructor block
        function h = PZGroupNotch(Parent)
        % Constructor
        
        
                h.Type = 'Notch';
        
        if nargin == 1
           h.Parent = Parent;
        end
           
        end  % PZGroupNotch
        
    end  % constructor block

    methods 
        function value = get.Wn(obj)
        value = LocalGetVirtualProperty(obj,obj.Wn,1);
        end
        function set.Wn(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Wn')
        value = double(value); %  convert to double
        obj.Wn = value;
        end

        function value = get.ZetaZero(obj)
        value = LocalGetVirtualProperty(obj,obj.ZetaZero,2);
        end
        function set.ZetaZero(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','ZetaZero')
        value = double(value); %  convert to double
        obj.ZetaZero = value;
        end

        function value = get.ZetaPole(obj)
        value = LocalGetVirtualProperty(obj,obj.ZetaPole,3);
        end
        function set.ZetaPole(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','ZetaPole')
        value = double(value); %  convert to double
        obj.ZetaPole = value;
        end

        function value = get.Depth(obj)
        value = LocalGetVirtualProperty(obj,obj.Depth,4);
        end
        function set.Depth(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Depth')
        value = double(value); %  convert to double
        obj.Depth = value;
        end

        function value = get.Width(obj)
        value = LocalGetVirtualProperty(obj,obj.Width,5);
        end
        function set.Width(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Width')
        value = double(value); %  convert to double
        obj.Width = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function NewValue = convertValue(this,Value,OldFormat,NewFormat,units)
       % convertVALUE converts value based on Format
       %
       
       
       
       NewValue = Value;
       end  % convertValue
       
        %----------------------------------------
       function ParamSpec = createParamSpec(this)
       % CREATEPARAMSPEC Creates parameter spec for notch group
       
       
       PID = modelpack.STParameterID(...
           sprintf('Notch (group %d)',find(this==this.Parent.PZGroup)), ...% Not translated
           [3,1], ...
           this.Parent.Identifier, ...
           'double', ...
           {''},...
           getString(message('Control:compDesignTask:strNotch')));
       ParamSpec = modelpack.STParameterSpec(PID,{'Wn,Zz,Zp'});
       
       ParamSpec.Known        = true;
       ParamSpec.InitialValue = this.getValue;
       ParamSpec.TypicalValue = ParamSpec.InitialValue;
       ParamSpec.Minimum      = [0; -1; -1];
       ParamSpec.Maximum      = [Inf; 1; 1];
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
       
       % Notch filter.
       Z = Group.Zero(1);
       P = Group.Pole(1);
       Description = {'Notch';...
              getString(message('Control:compDesignTask:msgNotchCompensator',...
              DomainVar, ...
              sprintf('%.3g %s %.3gi',real(Z),'+/-',abs(imag(Z))), ...
              DomainVar, ...
              sprintf('%.3g %s %.3gi',real(P),'+/-',abs(imag(P)))))};
       
       end  % describe
       
        %----------------------------------------
       function Value = getValue(this,Format,units)
       % GETVALUE sets the value for the pzgroup based on flag
       %
       % Format = 1,  Value =  [Wn; Zetaz; Zetap]
       
       %     $Date:  
       
       
       if nargin < 3
           units.FrequencyUnits = 'rad/s';
       end
       
       if isempty(this.VirtualProperties)
           this.updateVirtualProperties;
       end
       Wn = this.VirtualProperties(1);
       ZetaZ = this.VirtualProperties(2);
       ZetaP = this.VirtualProperties(3);
       
       Value = [unitconv(Wn,'rad',units.FrequencyUnits); ZetaZ; ZetaP];
       
       
       end  % getValue
       
        %----------------------------------------
       function setValue(this,Value,Format,units)
       % SETVALUE sets the value for the pzgroup based on flag
       %
       % Format 1 [Wn, ZetaZ, ZetaP]
       
       
       if nargin < 4
           units.FrequencyUnits = 'rad/s';
       end
       
       Wn = unitconv(Value(1), units.FrequencyUnits, 'rad/s');
       Zeta1 = Value(2);
       Zeta2 = Value(3);
       
       if abs(Zeta1)>1
           Zeta1= sign(Zeta1);
       end
       
       if abs(Zeta2)>1
           Zeta1= sign(Zeta2);
       end
       
       ZeroLoc = -Zeta1*Wn + Wn*sqrt(Zeta1^2-1);
       ZeroLocation = [ZeroLoc; conj(ZeroLoc)];
       
       PoleLoc = -Zeta2*Wn + Wn*sqrt(Zeta2^2-1);
       PoleLocation = [PoleLoc; conj(PoleLoc)];
       
       Ts = this.Parent.Ts;
       if Ts ~= 0
           ZeroLocation = exp(ZeroLocation*Ts);
           PoleLocation = exp(PoleLocation*Ts);
       end
       
       this.Zero = ZeroLocation;
       this.Pole = PoleLocation;
       
       end  % setValue
       
        %----------------------------------------
       function updateVirtualProperties(this)
       % UPDATEVIRTUALPROPERTIES for Notch
       
       %     $Date:  
       
       if isempty(this.Pole) || isempty(this.Zero)
           this.VirtualProperties = [NaN; NaN; NaN; NaN; NaN];
       else
           Ts = this.Parent.Ts;
           [Wn, Zz] = damp(this.Zero(1), Ts);
           [Wn, Zp] = damp(this.Pole(1), Ts);
       
           % Calculate notch width and depth
           ndepth = Zz/Zp;
           nwidth = Localnotchwidth(ndepth, Zp);
       
           this.VirtualProperties = [Wn; Zz; Zp; ndepth; nwidth];
       end
       end  % updateVirtualProperties
       
       
       
       % ------------------------------------------------------------------------%
       % Function: Localnotchwidth
       % Purpose:  Calculates log notch width
       % ------------------------------------------------------------------------%

end  % public methods 

end  % classdef

function Value = LocalGetVirtualProperty(this, ValueStored, idx)

if isempty(this.VirtualProperties)
    this.updateVirtualProperties;
end

Value = this.VirtualProperties(idx);
end  % LocalGetVirtualProperty
function width = Localnotchwidth(depth,zeta2)
% Calculate notch width at percent depth p
%      s^2 + (2*Zeta1^2)*s + wn^2
% G(s)--------------
%      s^2 + (2*Zeta2^2)*s + wn^2
%
% Depth = Zeta1/Zeta2

p=.25; % percent depth for width calculation
alpha = depth^p;
if alpha == 1
    % alpha = 1 -> G(s)=1 Pole/Zero Cancelation
    width = NaN;
else
    % Calculate log width
    Beta =sqrt(zeta2^2*(alpha^2-depth^2)/(1-alpha^2));
    width = log10(1 + 2*Beta^2 + 2*Beta*sqrt(1+Beta^2));
end
end  % Localnotchwidth
