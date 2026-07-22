classdef PZGroupLeadLag < sisodata.pzgroup
%sisodata.PZGroupLeadLag class
%   sisodata.PZGroupLeadLag extends sisodata.pzgroup.
%

%    sisodata.PZGroupLeadLag properties:
%       Parent - Property is of type 'MATLAB array'  
%       Type - Property is of type 'string'  
%       Zero - Property is of type 'MATLAB array'  
%       Pole - Property is of type 'MATLAB array'  
%       VirtualProperties - Property is of type 'MATLAB array'  
%       PhaseMax - Property is of type 'double'  
%       Wmax - Property is of type 'double'  
%
%    sisodata.PZGroupLeadLag methods:
%       convertValue -  SETVALUE sets the value for the pzgroup based on Format
%       createParamSpec - Creates the parameters spec for lead lag group.
%       describe -  Provides group description.
%       getValue - sets the value for the pzgroup based on flag
%       setValue - sets the value for the pzgroup based on flag
%       updateVirtualProperties - for LeadLag


properties (SetObservable)
    %PHASEMAX Property is of type 'double' 
    PhaseMax = 0;
    %WMAX Property is of type 'double' 
    Wmax = 0;
end


    methods  % constructor block
        function h = PZGroupLeadLag(Parent)
        % Constructor
        
        
                h.Type = 'LeadLag';
        
        if nargin == 1
           h.Parent = Parent;
        end
           
        end  % PZGroupLeadLag
        
    end  % constructor block

    methods 
        function value = get.PhaseMax(obj)
        value = LocalGetVirtualProperty(obj,obj.PhaseMax,1);
        end
        function set.PhaseMax(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','PhaseMax')
        value = double(value); %  convert to double
        obj.PhaseMax = value;
        end

        function value = get.Wmax(obj)
        value = LocalGetVirtualProperty(obj,obj.Wmax,2);
        end
        function set.Wmax(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Wmax')
        value = double(value); %  convert to double
        obj.Wmax = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function NewValue = convertValue(this,Value,OldFormat,NewFormat,units)
       % SETVALUE sets the value for the pzgroup based on Format
       %
       % Format = 1,  Value =  [zero;pole]
       % Format = 2,  Value =  [PhaseMax;Wmax]
       
       
       
       if isequal(OldFormat, NewFormat)
          NewValue = Value;
       else
          %Set useful information
          Pmax = asin(1-eps); % Range imposed on valid phase inputs Phase < pi/2
          Wmin = 0;
          Ts   = this.Parent.Ts;
          if nargin < 5
             units.FrequencyUnits = 'rad/s';
             units.PhaseUnits = 'rad';
          end
       
          if OldFormat == 1;
             %Pole/Zero to Phase/Wn
             if all(isfinite(Value))
                %Have finite values to convert
                if (Ts == 0)
                   % continuous case
                   ZeroLocation = Value(1);
                   PoleLocation = Value(2);
                else
                   % discrete case
                   ZeroLocation = log(Value(1))/Ts;
                   PoleLocation = log(Value(2))/Ts;
                end
       
                % Calculate the maximum phase addition from lead/lag and freq
                % at which it occurs
                alpha    = ZeroLocation/PoleLocation;
                PhaseMax = unitconv(asin((1-alpha)/(1+alpha)),'rad',units.PhaseUnits);
                Wmax     = unitconv(-ZeroLocation/sqrt(alpha),'rad/s',units.FrequencyUnits);
             else
                %Non-finite values, return hard limits.
                if any(Value < 0)
                   %Assume lower limit
                   PhaseMax = unitconv(-Pmax,'rad',units.PhaseUnits);
                   Wmax     = 0;
                else
                   %Assume upper limit
                   PhaseMax = unitconv(Pmax,'rad',units.PhaseUnits);
                   Wmax     = inf;
                end
             end
             %Return converted value
             NewValue = [PhaseMax;Wmax];
          else
             %Phase/Wn to Pole/Zero
             Phasem = unitconv(Value(1),units.PhaseUnits,'rad');
             Wm     = unitconv(Value(2),units.FrequencyUnits,'rad/s');
          
             if all(isfinite(Value)) && abs(Value(1)) < Pmax && Value(2) >= Wmin
                %Have finite and valid values to convert
                
                % Zero = alpha * Pole
                alpha = (1-sin(Phasem))/(1+sin(Phasem));
                ZeroLoc = -Wm*sqrt(alpha);
                PoleLoc = ZeroLoc/alpha;
                if (Ts ~= 0)
                   %Discrete system
                   ZeroLoc = exp(ZeroLoc*Ts);
                   PoleLoc = exp(PoleLoc*Ts);
                end
                
             else
                %Non-finite values, return hard limits.
                if any(Value < 0)
                   %Assume lower limit
                   ZeroLoc = -inf;
                   PoleLoc = -inf;
                else
                   %Assume upper limit
                   ZeroLoc = inf;
                   PoleLoc = inf;
                end
             end
             %Return converted value
             NewValue = [ZeroLoc; PoleLoc];
          end
       end
       end  % convertValue
       
        %----------------------------------------
       function ParamSpec = createParamSpec(this)
       % CREATEPARAMSPEC Creates the parameters spec for lead lag group.
       %
       
       
       
       PID = modelpack.STParameterID(...
           sprintf('LeadLag (group %d)',find(this==this.Parent.PZGroup)), ...% Not translated
           [2,1], ...
           this.Parent.Identifier, ...
           'double', ...
           {''},...
           getString(message('Control:compDesignTask:strLeadLag')));
       ParamSpec = modelpack.STParameterSpec(PID,...
           {getString(message('Control:compDesignTask:strFormatZeroPole')),...
           getString(message('Control:compDesignTask:strFormatPhaseMaxWmax'))});
           ParamSpec.Minimum = [-inf;-inf];
           ParamSpec.Maximum = [inf;inf];
       
       ParamSpec.Known = true;
       ParamSpec.InitialValue = [this.Zero;this.Pole];
       
       ParamSpec.TypicalValue = [this.Zero;this.Pole];
       
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
       
       
       % Lead or lag network (s+tau1)/(s+tau2)
       if (~Ts && Group.Pole<=Group.Zero) || (Ts && abs(Group.Pole)<=abs(Group.Zero))
           ID = 'Lead';
           Description = {ID ; ...
               getString(message('Control:compDesignTask:msgLeadCompensator',...
               DomainVar,sprintf('%.3g',Group.Zero),DomainVar,sprintf('%.3g',Group.Pole)))};
       else
           ID = 'Lag';
           Description = {ID ; ...
               getString(message('Control:compDesignTask:msgLagCompensator',...
               DomainVar,sprintf('%.3g',Group.Zero),DomainVar,sprintf('%.3g',Group.Pole)))};
       end
       
       
       end  % describe
       
        %----------------------------------------
       function Value = getValue(this,Format,units)
       % GETVALUE sets the value for the pzgroup based on flag
       %
       % Format = 1,  Value =  [zero;pole]
       % Format = 2,  Value =  [PhaseMax;Wmax]
       
       %     $Date:  
       
       if (nargin == 1) || (Format == 1)
           Value = [this.Zero; this.Pole];
       else
           if nargin < 3
               units.FrequencyUnits = 'rad/s';
               units.PhaseUnits = 'rad';
           end
           
           if isempty(this.VirtualProperties)
               this.updateVirtualProperties;
           end
           PhaseMax = this.VirtualProperties(1);
           Wmax = this.VirtualProperties(2);
           
           Value = [unitconv(PhaseMax,'rad',units.PhaseUnits); ...
                    unitconv(Wmax,'rad/s',units.FrequencyUnits)];
       end
       
       end  % getValue
       
        %----------------------------------------
       function setValue(this,Value,Format,units)
       % SETVALUE sets the value for the pzgroup based on flag
       %
       % Format = 1,  Value =  [zero;pole]
       % Format = 2,  Value =  [PhaseMax;Wmax]
       
       
       
       if ~isreal(Value)
           ctrlMsgUtils.error('Control:compDesignTask:PZGroupLeadLag1')
       end
       
       if Format == 1
       
           this.Zero = Value(1);
           this.Pole =  Value(2);
       
       else
           
           if nargin < 4
               units.FrequencyUnits = 'rad/s';
               units.PhaseUnits = 'rad';
           end
           Phasem = unitconv(Value(1),units.PhaseUnits,'rad');
           Wm = unitconv(Value(2),units.FrequencyUnits,'rad/s');
           
           maxphasevalue = asin(1-eps); % Range imposed on valid phase inputs Phasem < pi/4
           if (abs(Phasem) > maxphasevalue)
               ZeroLoc = NaN;
               PoleLoc = NaN;
           else
               % Zero = alpha * Pole
               alpha = (1-sin(Phasem))/(1+sin(Phasem));
       
               ZeroLoc = -Wm*sqrt(alpha);
               PoleLoc = ZeroLoc/alpha;
               
               Ts = this.Parent.Ts;
               if (Ts ~= 0)
                   ZeroLoc = exp(ZeroLoc*Ts);
                   PoleLoc = exp(PoleLoc*Ts);
               end
           end
           this.Zero = ZeroLoc;
           this.Pole =  PoleLoc;
       
       end
       
       end  % setValue
       
        %----------------------------------------
       function updateVirtualProperties(this)
       % UPDATEVIRTUALPROPERTIES for LeadLag
       
       %     $Date:  
       
       if isempty(this.Pole) || isempty(this.Zero)
           this.VirtualProperties = [NaN; NaN];
       else
       
           Ts = this.Parent.Ts;
           if (Ts == 0)
               ZeroLocation = this.Zero;
               PoleLocation = this.Pole;
           else
               % discrete case
               ZeroLocation = log(this.Zero)/Ts;
               PoleLocation = log(this.Pole)/Ts;
           end
       
           % Calculate the maximum phase addition from lead/lag and freq
           % at which it occurs
           alpha = ZeroLocation/PoleLocation;
           PhaseMax = asin((1-alpha)/(1+alpha));
           Wmax = -ZeroLocation/sqrt(alpha);
           this.VirtualProperties = [PhaseMax;Wmax];
       end
       end  % updateVirtualProperties
       
end  % public methods 

end  % classdef

function Value = LocalGetVirtualProperty(this,ValueStored,idx)

if isempty(this.VirtualProperties)
    this.updateVirtualProperties;
end

Value = this.VirtualProperties(idx);
end  % LocalGetVirtualProperty


function LocalSetMinMax(ParamSpec)
if ParamSpec.Format == 1
    ParamSpec.Minimum = [-inf;-inf];
    ParamSpec.Maximum = [inf;inf];
else
    maxphase = asin(1-eps);
    ParamSpec.Minimum = [-maxphase ; 0 ];
    ParamSpec.Maximum = [maxphase; Inf];
end
end  % LocalSetMinMax
