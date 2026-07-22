classdef pzgroup < matlab.mixin.SetGet & matlab.mixin.Copyable & matlab.mixin.Heterogeneous
%sisodata.pzgroup class
%    sisodata.pzgroup properties:
%       Parent - Property is of type 'MATLAB array'  
%       Type - Property is of type 'string'  
%       Zero - Property is of type 'MATLAB array'  
%       Pole - Property is of type 'MATLAB array'  
%       VirtualProperties - Property is of type 'MATLAB array'  
%
%    sisodata.pzgroup methods:
%       beyondnf -  Returns true for root with natural frequency beyond Nyquist freq.
%       describe -  Provides group description.
%       getParameterSpec -  Gets the parameter spec forthe pz group
%       getTypeZeroPole - returns struct of type poles and zeros
%       movelog -  Generate log entry with new location of moved root
%       notchwidth -  Computes X-axis positions of notch width markers.
%       resetParameterSpec -  Make param spec dirty for pzgroups
%       save -   Creates copy of pzgroup data.
%       utIsIntOrDiff -  checks if pzgroup is an integrator or differentiator


properties (Access=protected, SetObservable)
    %PARAMSPEC Property is of type 'handle' 
    ParamSpec = [];
end

properties (SetObservable)
    %PARENT Property is of type 'MATLAB array' 
    Parent = [];
    %TYPE Property is of type 'string' 
    Type = '';
    %ZERO Property is of type 'MATLAB array' 
    Zero = [];
    %POLE Property is of type 'MATLAB array' 
    Pole = [];
    %VIRTUALPROPERTIES Property is of type 'MATLAB array' 
    VirtualProperties = [];
end


events 
    PZDataChanged
end  % events

    methods(Sealed)
        function varargout = set(obj,varargin)
            [varargout{1:nargout}] = set@matlab.mixin.SetGet(obj,varargin{:});
        end
        function varargout = get(obj,varargin)
            [varargout{1:nargout}] = get@matlab.mixin.SetGet(obj,varargin{:});
        end
    end

    methods  % constructor block
        function h = pzgroup
        %PZGROUP  Constructor for pole/zero group object.
        
        %   Author(s): P. Gahinet
        
        
        % Create class instance
                
        
        end  % pzgroup
        
    end  % constructor block

    methods 
        function set.Type(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Type')
        obj.Type = value;
        end

        function set.Zero(obj,value)
        obj.Zero = LocalSetPoleZero(obj,value);
        end

        function set.Pole(obj,value)
        obj.Pole = LocalSetPoleZero(obj,value);
        end

        function set.ParamSpec(obj,value)
            % DataType = 'handle'
        if ~isempty(value)
            validateattributes(value,{'handle'},{'scalar'}, '','ParamSpec')
        end
        obj.ParamSpec = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function boo = beyondnf(Group,PZType,tol)
       %BEYONDNF  Returns true for root with natural frequency beyond Nyquist freq.
       %
       %   For a group G of discrete-time roots, 
       %       G.BEYONDNF(PZTYPE,TOL)       PZTYPE = 'pole','zero'
       %   returns 1 when there's no nearby root of the same type (real or complex) 
       %   with natural frequency < pi/Ts.
       % 
       %   Nearby is defined as 
       %       min | log(z)/s - 1 | < TOL   
       %   where min taken over all s of same type with |s|<pi.                                  
       
       %   Author(s): P. Gahinet
       
       z = get(Group,PZType);
       z = z(1);  % nominal root value z
       
       if any(strcmp(Group.Type,{'Real','LeadLag'}))
           % Real root
           boo = (z<=0 | abs(log(z))>(1+tol)*pi);
       else
           boo = (abs(log(z))>(1+tol)*pi);
       end
           
           
           
       end  % beyondnf
       
        %----------------------------------------
       function Description = describe(Group,Ts)
       %DESCRIBE  Provides group description.
       
       %   Author(s): P. Gahinet
       
       
       if Ts
           DomainVar = 'z';
       else
           DomainVar = 's';
       end
       
       % Construct description
       switch Group.Type  
       case 'Real'
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
           
       case 'Complex'
           % Complex pole/zero
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
               
       case 'LeadLag'
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
       
          
       case 'Notch'
          % Notch filter. 
          Z = Group.Zero(1);
          P = Group.Pole(1);
          Description = {'Notch';...
              getString(message('Control:compDesignTask:msgNotchCompensator',...
              DomainVar, ...
              sprintf('%.3g %s %.3gi',real(Z),'+/-',abs(imag(Z))), ...
              DomainVar, ...
              sprintf('%.3g %s %.3gi',real(P),'+/-',abs(imag(P)))))};
       end
       
       end  % describe
       
        %----------------------------------------
       function Value = getParameterSpec(this)
       % getParameterSpec  Gets the parameter spec forthe pz group
       
       
       % Get param spec for pzgroup
       if isempty(this.ParamSpec)
           this.ParamSpec = this.createParamSpec;
       end
       
       Value = this.ParamSpec;
       end  % getParameterSpec
       
        %----------------------------------------
       function h = getTypeZeroPole(this)
       %getTypeZeroPole returns struct of type poles and zeros
       
       
       
       h = struct('Type', this.Type, 'Zero', this.Zero, 'Pole', this.Pole);
       
       
       end  % getTypeZeroPole
       
        %----------------------------------------
       function Status = movelog(Group,PZID,Ts)
       %MOVELOG  Generate log entry with new location of moved root
       
       %   Author(s): P. Gahinet
       
       if Ts
           DomainVar = 'z';
       else
           DomainVar = 's';
       end
       
       switch Group.Type
       case {'Real','LeadLag'}
           R = get(Group,PZID);
           if strcmpi(PZID,'zero')
               Status = getString(message('Control:compDesignTask:msgMoveRealCompensatorZero', ...
               DomainVar,sprintf('%.3g',R)));
           else
               Status = getString(message('Control:compDesignTask:msgMoveRealCompensatorPole', ...
                   DomainVar,sprintf('%.3g',R)));
           end
           
       case 'Complex'
           R = get(Group,PZID);
           if strcmpi(PZID,'zero')
               Status = getString(message('Control:compDesignTask:msgMoveComplexCompensatorZeros',...
                   DomainVar,...
                   sprintf('%.3g %s %.3gi',real(R(1)),'+/-',abs(imag(R(1))))));
           else
               Status = getString(message('Control:compDesignTask:msgMoveComplexCompensatorPoles',...
                   DomainVar,...
                   sprintf('%.3g %s %.3gi',real(R(1)),'+/-',abs(imag(R(1))))));
           end
           
       case 'Notch'
           Z = Group.Zero(1); 
           P = Group.Pole(1);
           Status = getString(message('Control:compDesignTask:msgMoveNotchCompensator' ,...
               DomainVar,...
               sprintf('%.3g %s %.3gi',real(Z),'+/-',abs(imag(Z))),...
               DomainVar, ...
               sprintf('%.3g %s %.3gi',real(P),'+/-',abs(imag(P)))));
       end
       end  % movelog
       
        %----------------------------------------
       function w = notchwidth(NotchGroup,Ts)
       %NOTCHWIDTH  Computes X-axis positions of notch width markers.
       
       %   Author(s): P. Gahinet
       
       % Notch (s^2+2*Zeta1*w0*s+w0^2)/(s^2+2*Zeta2*w0*s+w0^2) with Zeta1<=Zeta2
       
       % Markers are located at DepthFraction of the total notch depth in dB
       % (for an isolated notch)
       DepthFraction = 0.25;
       
       % Get zero and pole damping (1st column of Zeta -> zero, 2nd column -> Pole
       [w0,Zeta] = damp([NotchGroup.Zero(1);NotchGroup.Pole(1)],Ts);   
       Zeta2 = Zeta.^2;
       w0 = w0(1);
       
       % Frequency-axis positions W given by
       %     x^2 + 4 Zeta1^2 (x+1)
       %     --------------------- = (Zeta1/Zeta2)^(2*DepthFraction) = THETA
       %     x^2 + 4 Zeta2^2 (x+1)
       % with x = (W/W0)^2 - 1.      
       % Rewrite as x^2 - 2 beta x - 2 beta = 0 where
       %     BETA = 2 (Zeta1^2 - THETA * Zeta2^2) / (THETA-1).
       theta = (Zeta2(1)/Zeta2(2))^DepthFraction;   % right-hand side
       % RE: As Zeta1/Zeta2 -> 1, BETA -> 2 * (1/DepthFraction-1) * Zeta1^2
       if abs(theta-1)<1e-2
           beta = 2 * (1/DepthFraction-1) * Zeta2(1);
       else
           beta = 2 * (Zeta2(1) - theta * Zeta2(2)) / (theta-1);
       end
       
       % Solve for x
       d = sqrt(beta^2 + 2*beta);
       w = [w0 * sqrt(1+beta-d) ; w0 * sqrt(1+beta+d)];
       
       % Limit x values to Nyquist frequency in discrete time
       if Ts,
           nf = pi/Ts;
           w = min(w,nf);
           if w0>0.999*nf
               % Do not display right marker (can't be moved and prevents moving notch)
               w(2) = NaN;
           end
       end
           
       
       end  % notchwidth
       
        %----------------------------------------
       function resetParameterSpec(this)
       % Make param spec dirty for pzgroups
       
       
       this.ParamSpec = [];
       end  % resetParameterSpec
       
        %----------------------------------------
       function Design = save(this)
       %SAVE   Creates copy of pzgroup data.
       
       
       Design = struct('Type',this.Type,'Zero',this.Zero,'Pole',this.Pole);
       
       
       
       
       end  % save
       
        %----------------------------------------
       function b = utIsIntOrDiff(this,Ts)
       % checks if pzgroup is an integrator or differentiator
       
       
       b = false;
       
           
       end  % utIsIntOrDiff
       
end  % public methods 

end  % classdef

function Value = LocalSetPoleZero(this,Value)
% Make VirtualProperties Dirty
this.VirtualProperties = [];
end  % LocalSetPoleZero




    


  
