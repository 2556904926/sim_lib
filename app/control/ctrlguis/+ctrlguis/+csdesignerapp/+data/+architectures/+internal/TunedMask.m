classdef TunedMask < ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock
    % TunedLTI  Class for managing tuned blocks that support tuning of
    % poles and zeros of system
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    % Public Properties
    properties
        FixedDynamics
    end
    
    methods
        function this = TunedMask(ID, sys)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock(ID, sys);
            % REVISIT: add listener to parameters post set
        end
        
        function b = isGainBlock(this)
            b = false;
        end
        
        function Value = get.FixedDynamics(this)
            Value = getValue(this);
        end
        
        function intializeWithBlockConfig(this,BlockConfig,RateConversionMethod,BlockStruct)
            this.Path = BlockConfig.BlockPath;

            this.TsOrig = getTs(BlockConfig);
            
            InPars             = BlockStruct.TunableParameters;
            this.Name          = BlockConfig.Name;
            this.Parameters    = InPars;
            % REVISIT
            %         TunedBlocks(ct).AuxData       = struct('InportPort',BlockStruct.Inport,...
            %             'OutportPort',BlockStruct.Outport);
            this.Par2ZpkFcn    = BlockStruct.EvalFcn;
            
            % Get the sample times
            if iscell(this.Par2ZpkFcn)
                zpkTuned = feval(this.Par2ZpkFcn{1},InPars,this.Par2ZpkFcn{2:end});
            else
                zpkTuned = this.Par2ZpkFcn(InPars);
            end
            
            this.TsOrig = zpkTuned.Ts;
            
            % Determine C2D/D2C methods
            if strcmpi(RateConversionMethod{1},'prewarp')
                C2DMethod = RateConversionMethod;
            else
                C2DMethod = RateConversionMethod(1);
            end
            this.C2DMethod = C2DMethod;
            this.D2CMethod = C2DMethod;
            
        end
        %% Gains - ZPK for graphical editor and Formatted for pzeditor
        function Gain = getZPKGain(this, flag)
            if nargin==1
                Gain = this.Data_.k;
            elseif strcmpi(flag(1),'m')
                Gain = abs(this.Data_.k);
            else
                Gain = sign(this.Data_.k);
            end
        end
        
        function Gain = getFormattedGain(this)
            %GETGAIN  Gets the formatted gain of the TunedZPKdata.
            %
            % If zpkdata is empty update it
            if isempty(this.Data_)
                this.updateZPK;
            end
            
            Gain = this.Data_.k / formatfactor(this);
        end
        
        function setValue(this,S)
            % REVISIT Verify size etc.
            OldName = this.Name;
            
            if isnumeric(S)
                S = ss(S);
            end
            this.Data_ = zpk(S);
            
            if isempty(this.Data_.Name)
                this.Name = OldName;
            end
            notifyValueChanged(this)
        end
        
        function [p,z] = getPZ(this)
            % GETPZ Returns the poles and zeros of the TunedMask
            
            % If zpkdata is empty update it
            if isempty(this.Data_)
                this.updateZPK;
            end
            
            p = [this.Data_.p{:}];
            z = [this.Data_.z{:}];
        end
        
        function Value = getZPKParameterSpec(this)
            Value = [];
        end
        
        function b = utIsGainTunable(this)
            % Used to determine if gain is tunable for the TunedZPK
            b = false;
        end
        
        function boo = isStatic(this)
            % Checks if compensator is static
            boo = isstatic(this.Data_);
        end
        
        function bool = isTunable(this)
            bool = false;
        end
        
        function b = isAddpzAllowed(this,GroupType,PZType)
            b = false;
        end
        
        function bool = isDeletepzAllowed(this, PZGroup)
            bool = false;
        end
        
        %% MODEL DATA
        function D = zpk(this)
            %ZPK   Get ZPK model of tunable model.
            D = this.Data_;
        end
        
        function D = ss(this)
            D = ss(this.Data_);
        end
        
        %% UPDATE
        function updateZPK(this)
            % UPDATEZPK Calculates the zpk representation from the parameters
            
            if iscell(this.Par2ZpkFcn)
                [zpkTuned,zpkFixed] = feval(this.Par2ZpkFcn{1},this.Parameters,this.Par2ZpkFcn{2:end});
            else
                [zpkTuned,zpkFixed] = this.Par2ZpkFcn(this.Parameters);
            end
            this.Data_ = localConvertTs(this,zpkTuned*zpkFixed);
        end
        
        %% LOAD/SAVE
        function S = saveSession(this) 
            S = struct(...
                'Name', this.Name, ...
                'Identifier', this.Identifier, ...
                'Ts', this.Ts, ...
                'TsOrig', this.TsOrig,...
                'Format', this.Format, ...
                'Par2ZPKFcn', this.Par2ZpkFcn, ...
                'MaskParamSpec', this.MaskParamSpec, ...
                'Path', this.Path, ...
                'C2DMethod', this.C2DMethod, ...
                'D2CMethod', this.D2CMethod, ...
                'Parameters', this.Parameters, ...
                'Value', this.Data_);
        end
        
        function loadSession(this,S)            
            this.Parameters = S.Parameters;
            this.updateZPK;
            notifyValueChanged(this)
            
        end
    end
    
end


function zpkdata = localConvertTs(this,zpkdata)

Ts = this.Ts;
TsOrig = this.TsOrig;

if ~isequal(Ts,TsOrig)
    if isequal(Ts,0)
        %d2c
        p = d2cOptions;
        if numel(this.D2CMethod)==1
            p.Method = this.D2CMethod{1};
        else
            p.Method = 'tustin';
            p.PrewarpFrequency = this.D2CMethod{2};
        end
        zpkdata =  d2c(zpkdata,p);
    else
        if isequal(TsOrig,0)
            %c2d
            p = c2dOptions;
            if numel(this.C2DMethod)==1
                p.Method = this.C2DMethod{1};
            else
                p.Method = 'tustin';
                p.PrewarpFrequency = this.C2DMethod{2};
            end
            zpkdata =  c2d(zpkdata,Ts,p);
        else
            %d2d
            p = d2dOptions;
            if numel(this.C2DMethod)==1
                p.Method = this.C2DMethod{1};
            else
                p.Method = 'tustin';
                p.PrewarpFrequency = this.C2DMethod{2};
            end
            zpkdata =  d2d(zpkdata,Ts,p);
        end
    end
end
end
