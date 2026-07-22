classdef (Abstract) PZGroup < handle & matlab.mixin.Heterogeneous
    %  PZGROUP abstract class
    
    % Copyright 2015 The MathWorks, Inc.
    
    %% Properties
    properties (GetAccess = public, SetAccess  = protected)
        Parent      % Parent Tunable block
        Type        % Real, Complex, LeadLag, Notch
    end
    
    properties (Dependent)
        Zero   % Zeros zeros 
        Pole   % Poles 
    end
    
    properties (Access = protected)
        Pole_
        Zero_   
        ParamSpec_   % Parameter spec
    end
    
    
    %% Public Absract Methods
    methods (Abstract = true)
        Description = describe(this,Ts)
        Status = movelog(this)
        setValue(this,Value,Format,Units)
        Value = getValue(this,Format,Units)
        ParamSpec = createParamSpec(this)
    end
    
    %% Public Methods
    methods
        
        function boo = beyondnf(this, PZType, tol)
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
            z = this.(PZType);
            z = z(1);
            if any(strcmp(this.Type,{'Real','LeadLag'}))
                % Real root
                boo = (z<=0 | abs(log(z))>(1+tol)*pi);
            else
                boo = (abs(log(z))>(1+tol)*pi);
            end
        end
        
        function NewValue = convertValue(~,Value,~,~,~)
            % convertValue converts the value based on Format
            NewValue = Value;
        end
        
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
            
        end
      
        function Design = save(this)
            %SAVE   Creates copy of pzgroup data.
            Design = struct('Type', this.Type, ...
                'Zero', this.Zero, ...
                'Pole', this.Pole);
        end
        
        function PZGroupCopy = copy(this)
            ClassName = strcat('PZGroup',this.Type);
            PZGroupCopy = ctrlguis.csdesignerapp.data.architectures.internal.(ClassName)(this.Parent);
            PZGroupCopy.Pole = this.Pole;
            PZGroupCopy.Zero = this.Zero;
        end
        
        function Value = getParameterSpec(this)
            % getParameterSpec  Gets the parameter spec forthe pz group
            
            % Get param spec for pzgroup
            if isempty(this.ParamSpec_)
                this.ParamSpec_ = createParamSpec(this);
            end
            
            Value = this.ParamSpec_;
        end
        
    end
    
    %% Set and Get methods
    methods

        function set.Zero(this,Value)
            this.Zero_ = Value;
            notify(this,'PZDataChanged')
        end
        
        function set.Pole(this,Value)
            this.Pole_ = Value;
            notify(this,'PZDataChanged')
        end
        
        function Value = get.Zero(this)
            Value = this.Zero_;
        end
        
        function Value = get.Pole(this)
            Value = this.Pole_;
        end
                  
    end
    
    %% Protected Methods
    methods(Access=protected)
        function this = PZGroup(Parent)
            this.Parent = Parent;
        end
    end
    
    %% eVENTS
    events
        PZDataChanged
    end
end