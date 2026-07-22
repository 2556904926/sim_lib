classdef PZGroupLeadLag < ctrlguis.csdesignerapp.data.architectures.internal.PZGroup
    % Class for managing lead/lag pole zero groups
    
    % Copyright 2015 The MathWorks, Inc.
    
    properties (Dependent = true, SetAccess=private)
        PhaseMax
        WMax
    end
    
    
    %% Public Methods
    methods
        function this = PZGroupLeadLag(Parent)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.PZGroup(Parent);
            this.Type = 'LeadLag';
        end
        
        function PhaseMax = get.PhaseMax(this)
            if isempty(this.Pole_) || isempty(this.Zero_)
                PhaseMax = NaN;
            else
                alpha = getAlpha(this);
                PhaseMax = asin((1-alpha)/(1+alpha));
            end
        end
        
        function WMax = get.WMax(this)
            if isempty(this.Pole_) || isempty(this.Zero_)
                WMax = NaN;
            else
                Ts = this.Parent.getTs;
                if (Ts == 0)
                    ZeroLocation = this.Zero_;
                else
                    % discrete case
                    ZeroLocation = log(this.Zero_)/Ts;
                end
                alpha = getAlpha(this);
                WMax = -ZeroLocation/sqrt(alpha);
            end
            
        end
               
        function NewValue = convertValue(this,Value,OldFormat,NewFormat,units)
            % Conver value between formats
            %
            % Format = 1,  Value =  [zero;pole]
            % Format = 2,  Value =  [PhaseMax;Wmax]
            
            if isequal(OldFormat, NewFormat)
                NewValue = Value;
            else
                %Set useful information
                Pmax = asin(1-eps); % Range imposed on valid phase inputs Phase < pi/2
                Wmin = 0;
                Ts   = this.Parent.getTs;
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
            
        end
        
        function Description = describe(Group,Ts)
            %DESCRIBE  Provides group description.
            
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
        
        function Value = getValue(this,Format,units)
            % GETVALUE sets the value for the pzgroup based on flag
            %
            % Format = 1,  Value =  [zero;pole]
            % Format = 2,  Value =  [PhaseMax;Wmax]
            
            if (nargin == 1) || (Format == 1)
                Value = [this.Zero_; this.Pole_];
            else
                if nargin < 3
                    units.FrequencyUnits = 'rad/s';
                    units.PhaseUnits = 'rad';
                end
                
                PhaseMax = this.PhaseMax;
                WMax = this.WMax;
                
                Value = [unitconv(PhaseMax,'rad',units.PhaseUnits); ...
                    unitconv(WMax,'rad/s',units.FrequencyUnits)];
            end
        end
        
        function setValue(this,Value,Format,units)
            % SETVALUE sets the value for the pzgroup based on flag
            % setValue(this,Value,Format,units)
            %
            % Format = 1,  Value =  [zero;pole]
            % Format = 2,  Value =  [PhaseMax;Wmax]
            
            if ~isreal(Value)
                ctrlMsgUtils.error('Control:compDesignTask:PZGroupLeadLag1')
            end
            
            if Format == 1
                this.Zero_ = Value(1);
                this.Pole_ =  Value(2);
            else
                if nargin < 4
                    units.FrequencyUnits = 'rad/s';
                    units.PhaseUnits = 'rad';
                end
                Phasem = unitconv(Value(1),units.PhaseUnits,'rad');
                Wm = unitconv(Value(2),units.FrequencyUnits,'rad/s');
                
                maxphasevalue = asin(1-eps); % Range imposed on valid phase inputs Phasem < pi/4
                if (abs(Phasem) > maxphasevalue)
                    alpha = (1-sin(maxphasevalue))/(1+sin(maxphasevalue));
                else
                    alpha = (1-sin(Phasem))/(1+sin(Phasem));
                end
                % Zero = alpha * Pole
                ZeroLoc = -Wm*sqrt(alpha);
                PoleLoc = ZeroLoc/alpha;
                
                Ts = this.Parent.getTs;
                if (Ts ~= 0)
                    ZeroLoc = exp(ZeroLoc*Ts);
                    PoleLoc = exp(PoleLoc*Ts);
                end               
                
                this.Zero_ = ZeroLoc;
                this.Pole_ =  PoleLoc;
            end
            notify(this,'PZDataChanged')
        end
        
        function ParamSpec = createParamSpec(this)
            % CREATEPARAMSPEC Creates the parameters spec for lead lag group.
            %
           
            PID = modelpack.CSDParameterID(...
                sprintf('LeadLag (group %d)',find(arrayfun(@(x)isequal(x,this),this.Parent.PZGroup))), ...% Not translated
                [2,1], ...
                this.Parent.getIdentifier, ...
                'double', ...
                {''},...
                getString(message('Control:compDesignTask:strLeadLag')));
            ParamSpec = modelpack.CSDParameterSpec(PID,...
                {getString(message('Control:compDesignTask:strFormatZeroPole')),...
                getString(message('Control:compDesignTask:strFormatPhaseMaxWmax'))});
            ParamSpec.Minimum = [-inf;-inf];
            ParamSpec.Maximum = [inf;inf];
            
            ParamSpec.Known = true;
            ParamSpec.InitialValue = [this.Zero_;this.Pole_];
            
            ParamSpec.TypicalValue = [this.Zero_;this.Pole_];
            
%             ParamSpec.Listeners = handle.listener(ParamSpec,ParamSpec.findprop('Format'),...
%                 'PropertyPostSet',@(hSrc,hData) LocalSetMinMax(ParamSpec));
        end
    end
    
    %% Private Methods
    methods (Access = private)
        function alpha = getAlpha(this)
            % Calculate the maximum phase addition from lead/lag and freq
            % at which it occurs
            Ts = this.Parent.getTs;
            if (Ts == 0)
                ZeroLocation = this.Zero_;
                PoleLocation = this.Pole_;
            else
                % discrete case
                ZeroLocation = log(this.Zero_)/Ts;
                PoleLocation = log(this.Pole_)/Ts;
            end
            alpha = ZeroLocation/PoleLocation;
        end
        
    end
    
end

%% LOCAL FUNCTIONS --------------------------------------------------------
% function LocalSetMinMax(ParamSpec)
% if ParamSpec.Format == 1
%     ParamSpec.Minimum = [-inf;-inf];
%     ParamSpec.Maximum = [inf;inf];
% else
%     maxphase = asin(1-eps);
%     ParamSpec.Minimum = [-maxphase ; 0 ];
%     ParamSpec.Maximum = [maxphase; Inf];
% end
% end