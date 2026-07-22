classdef PZGroupNotch < ctrlguis.csdesignerapp.data.architectures.internal.PZGroup
    % Class for managing notch pole zero groups
    
    % Copyright 2015 The MathWorks, Inc.
    
    properties(Dependent = true, SetAccess=private)
        Wn
        ZetaZero
        ZetaPole
        Depth
        Width
    end
    
    methods
        function this = PZGroupNotch(Parent)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.PZGroup(Parent);
            this.Type = 'Notch';
        end
        
        function Wn = get.Wn(this)
            [Wn,~,~] = localDamp(this);
        end
        
        function Zz = get.ZetaZero(this)
            [~,Zz,~] = localDamp(this);
        end
        
        function Zp = get.ZetaPole(this)
            [~,~,Zp] = localDamp(this);
        end
        
        function ndepth = get.Depth(this)
            [~,zz,zp] = localDamp(this);
            if isnan(zz) || isnan(zp)
                ndepth = NaN;
            else
                ndepth = zz/zp;
            end
        end
        
        function nWidth = get.Width(this)
            [~,zz,zp] = localDamp(this);
            if isnan(zz) || isnan(zp)
                nWidth = NaN;
            else
                nDepth = this.Depth;
                
                % Calculate notch width at percent depth p
                %      s^2 + (2*Zeta1^2)*s + wn^2
                % G(s)--------------
                %      s^2 + (2*Zeta2^2)*s + wn^2
                %
                % Depth = Zeta1/Zeta2
                
                p=.25; % percent depth for width calculation
                alpha = nDepth^p;
                if alpha == 1
                    % alpha = 1 -> G(s)=1 Pole/Zero Cancelation
                    nWidth = NaN;
                else
                    % Calculate log width
                    Beta =sqrt(zp^2*(alpha^2-nDepth^2)/(1-alpha^2));
                    nWidth = log10(1 + 2*Beta^2 + 2*Beta*sqrt(1+Beta^2));
                end
            end
        end
        
        function [Wn,Zz,Zp] = localDamp(this)
            if isempty(this.Pole_) || isempty(this.Zero_)
                Wn = NaN;
                Zz = NaN;
                Zp = NaN;
            else
                Ts = this.Parent.getTs;
                [Wn, Zz] = damp(this.Zero_(1), Ts);
                [Wn, Zp] = damp(this.Pole_(1), Ts);
            end
        end
        
        function Description = describe(this,Ts)
            if Ts
                DomainVar = 'z';
            else
                DomainVar = 's';
            end
            
            % Notch filter.
            Z = this.Zero_(1);
            P = this.Pole_(1);
            Description = {'Notch';...
                getString(message('Control:compDesignTask:msgNotchCompensator',...
                DomainVar, ...
                sprintf('%.3g %s %.3gi',real(Z),'+/-',abs(imag(Z))), ...
                DomainVar, ...
                sprintf('%.3g %s %.3gi',real(P),'+/-',abs(imag(P)))))};
        end
        
        function Status = movelog(this,PZID,Ts)
            %MOVELOG  Generate log entry with new location of moved root
            
            if Ts
                DomainVar = 'z';
            else
                DomainVar = 's';
            end
            Z = this.Zero_(1);
            P = this.Pole_(1);
            Status = getString(message('Control:compDesignTask:msgMoveNotchCompensator' ,...
                DomainVar,...
                sprintf('%.3g %s %.3gi',real(Z),'+/-',abs(imag(Z))),...
                DomainVar, ...
                sprintf('%.3g %s %.3gi',real(P),'+/-',abs(imag(P)))));
            
        end
        
        function Value = getValue(this,~,units)
            % GETVALUE sets the value for the pzgroup based on flag
            %
            % Format = 1,  Value =  [Wn; Zetaz; Zetap]
            
            if nargin < 3
                units.FrequencyUnits = 'rad/s';
            end
            W = this.Wn;
            ZetaZ = this.ZetaZero;
            ZetaP = this.ZetaPole;
            
            Value = [unitconv(W,'rad',units.FrequencyUnits); ZetaZ; ZetaP];
        end
        
        function setValue(this,Value,~,units)
            % SETVALUE sets the value for the pzgroup based on flag
            % setValue(this,Value,Format,units)
            %
            % Format 1 [Wn, ZetaZ, ZetaP]

            if nargin < 4
                units.FrequencyUnits = 'rad/s';
            end
            
            W = unitconv(Value(1), units.FrequencyUnits, 'rad/s');
            Zeta1 = Value(2);
            Zeta2 = Value(3);
            
            if abs(Zeta1)>1
                Zeta1= sign(Zeta1);
            end
            
            if abs(Zeta2)>1
                Zeta1= sign(Zeta2);
            end
            
            ZeroLoc = -Zeta1*W + W*sqrt(Zeta1^2-1);
            ZeroLocation = [ZeroLoc; conj(ZeroLoc)];
            
            PoleLoc = -Zeta2*W + W*sqrt(Zeta2^2-1);
            PoleLocation = [PoleLoc; conj(PoleLoc)];
            
            Ts = this.Parent.getTs;
            if Ts ~= 0
                ZeroLocation = exp(ZeroLocation*Ts);
                PoleLocation = exp(PoleLocation*Ts);
            end
            
            this.Zero_ = ZeroLocation;
            this.Pole_ = PoleLocation;
            notify(this,'PZDataChanged')
        end
        
        function ParamSpec = createParamSpec(this)
            % CREATEPARAMSPEC Creates parameter spec for notch group
            
            PID = modelpack.CSDParameterID(...
                sprintf('Notch (group %d)',find(arrayfun(@(x)isequal(x,this),this.Parent.PZGroup))), ...% Not translated
                [3,1], ...
                this.Parent.getIdentifier, ...
                'double', ...
                {''},...
                getString(message('Control:compDesignTask:strNotch')));
            ParamSpec = modelpack.CSDParameterSpec(PID,{'Wn,Zz,Zp'});
            
            ParamSpec.Known        = true;
            ParamSpec.InitialValue = this.getValue;
            ParamSpec.TypicalValue = ParamSpec.InitialValue;
            ParamSpec.Minimum      = [0; -1; -1];
            ParamSpec.Maximum      = [Inf; 1; 1];
        end
        
        function w = notchwidth(this,Ts)
            %NOTCHWIDTH  Computes X-axis positions of notch width markers.

            % Notch (s^2+2*Zeta1*w0*s+w0^2)/(s^2+2*Zeta2*w0*s+w0^2) with Zeta1<=Zeta2
            
            % Markers are located at DepthFraction of the total notch depth in dB
            % (for an isolated notch)
            DepthFraction = 0.25;
            
            % Get zero and pole damping (1st column of Zeta -> zero, 2nd column -> Pole
            [w0,Zeta] = damp([this.Zero_(1);this.Pole_(1)],Ts);
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
            
        end
        
    end
end