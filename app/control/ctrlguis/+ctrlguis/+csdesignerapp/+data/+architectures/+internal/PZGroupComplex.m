classdef PZGroupComplex < ctrlguis.csdesignerapp.data.architectures.internal.PZGroup
    % Class that manages a pair of complex poles/ complex zeros
    
    % Copyright 2015 The MathWorks, Inc.
    
    methods (Sealed = true)
        function this = PZGroupComplex(Parent)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.PZGroup(Parent);
            this.Type = 'Complex';
        end
        
        function [Zeta,Wn] = getDependentProperties(this)
            if isempty(this.Pole_) && isempty(this.Zero_)
                Zeta = NaN;
                Wn = NaN;
            else
                if isempty(this.Pole_)
                    Location = this.Zero_(1);
                else
                    Location = this.Pole_(1);
                end
                [Wn, Zeta] = damp(Location, this.Parent.getTs);
            end
        end
        
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
                Ts      = this.Parent.getTs;
                if nargin < 5
                    units.FrequencyUnits = 'rad/s';
                end
                
                if OldFormat == 1;
                    %Real/Imag to Zeta/Wn
                    if all(isfinite(Value))
                        %Have finite values to convert
                        [Wn, Zeta] = damp(Value(1)+1i*Value(2), Ts);
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
        end
        
        function Description = describe(this,Ts)
            %DESCRIBE  Provides group description.
            
            if Ts
                DomainVar = 'z';
            else
                DomainVar = 's';
            end
            
            
            if isempty(this.Pole_)
                R = this.Zero_(1);   ID = 'Zero';
                Description = {ID ; ...
                    getString(message('Control:compDesignTask:msgComplexCompensatorZeros',...
                    DomainVar,sprintf('%.3g %s %.3gi', real(R),'+/-',abs(imag(R)))))};
            else
                R = this.Pole_(1);   ID = 'Pole';
                Description = {ID ; ...
                    getString(message('Control:compDesignTask:msgComplexCompensatorPoles',...
                    DomainVar,sprintf('%.3g %s %.3gi', real(R),'+/-',abs(imag(R)))))};
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
                Status = getString(message('Control:compDesignTask:msgMoveComplexCompensatorZeros',...
                    DomainVar,...
                    sprintf('%.3g %s %.3gi',real(R(1)),'+/-',abs(imag(R(1))))));
            else
                Status = getString(message('Control:compDesignTask:msgMoveComplexCompensatorPoles',...
                    DomainVar,...
                    sprintf('%.3g %s %.3gi',real(R(1)),'+/-',abs(imag(R(1))))));
            end
        end
        
        function Value = getValue(this,Format,units)
            % GETVALUE sets the value for the pzgroup based on flag
            %
            % Format = 1; Value = [Real; Imag];
            % Format = 2; Value = [Zeta, Wn];
            
            if (nargin == 1) || (Format == 1);
                if isempty(this.Pole_)
                    Location = this.Zero_(1);
                else
                    Location = this.Pole_(1);
                end
                Value = [real(Location); imag(Location)];
            else
                if nargin < 3
                    units.FrequencyUnits = 'rad/s';
                end
                [Zeta, Wn] = getDependentProperties(this);
                
                Value = [Zeta; unitconv(Wn,'rad/s',units.FrequencyUnits)];
            end
        end
        
        function setValue(this,Value,Format,units)
            % SETVALUE sets the value for the pzgroup based on Format
            % setValue(this,Value,Format,units)
            %
            % Format = 1; Value = [Real; Imag];
            % Format = 2; Value = [Zeta, Wn];
            
            if Format == 1
                R = Value(1);
                I = Value(2);
                if isempty(this.Pole_)
                    this.Zero_ = [R+1i*I; R-1i*I];
                else
                    this.Pole_ =  [R+1i*I; R-1i*I];
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
                
                Ts = this.Parent.getTs;
                if Ts ~= 0
                    Location = exp(Location*Ts);
                end
                
                if isempty(this.Pole)
                    this.Zero_ = Location;
                else
                    this.Pole_ = Location;
                end
            end
            notify(this,'PZDataChanged')
        end
        
        function ParamSpec = createParamSpec(this)
            % getParameterSpec  Gets the parameter spec forthe pz group
            
            if isempty(this.Pole)
                str = 'Zero';
                strName = getString(message('Control:compDesignTask:strComplexZero'));
                value = [real(this.Zero_(1));imag(this.Zero_(1))];
            else
                str = 'Pole';
                strName = getString(message('Control:compDesignTask:strComplexPole'));
                value = [real(this.Pole_(1));imag(this.Pole_(1))];
            end
            
            
            PID = modelpack.CSDParameterID(...
                sprintf('Complex %s (group %d)',str,find(arrayfun(@(x)isequal(x,this),this.Parent.PZGroup))), ...% Not translated
                [2,1], ...
                this.Parent.getIdentifier, ...
                'double', ...
                {''}, ...
                strName);
            ParamSpec              = modelpack.CSDParameterSpec(PID, ...
                {getString(message('Control:compDesignTask:strFormatRealImag')), ...
                getString(message('Control:compDesignTask:strFormatZetaWn'))});
            ParamSpec.Known        = true;
            ParamSpec.Minimum      = [-inf; 0];
            ParamSpec.Maximum      = [inf; inf];
            ParamSpec.InitialValue = value;
            ParamSpec.TypicalValue = value;
            
%             ParamSpec.Listeners = handle.listener(ParamSpec,ParamSpec.findprop('Format'),...
%                 'PropertyPostSet',@(hSrc,hData) LocalSetMinMax(ParamSpec));
            
        end

    end
end

%% LOCAL FUNCTIONS --------------------------------------------------------
% function LocalSetMinMax(ParamSpec)
% if ParamSpec.Format == 1
%     ParamSpec.Minimum = [-inf; 0];
%     ParamSpec.Maximum = [inf; inf];
% else
%     ParamSpec.Minimum = [-1 ; 0 ];
%     ParamSpec.Maximum = [1; inf];
% end
% end