classdef TunedMask < sisodata.TunedBlock
%sisodata.TunedMask class
%   sisodata.TunedMask extends sisodata.TunedBlock.
%

%    sisodata.TunedMask properties:
%       Name - Property is of type 'ustring'  
%       Identifier - Property is of type 'string'  
%       Description - Property is of type 'ustring'  
%       Format - Property is of type 'string'  
%       Ts - Property is of type 'double'  
%       TsOrig - Property is of type 'double'  
%       MaskParamSpec - Property is of type 'MATLAB array'  
%       Parameters - Property is of type 'MATLAB array'  
%       SSData - Property is of type 'MATLAB array'  
%       Par2ZpkFcn - Property is of type 'MATLAB array'  
%       C2DMethod - Property is of type 'MATLAB array'  
%       D2CMethod - Property is of type 'MATLAB array'  
%       AuxData - Property is of type 'MATLAB array'  
%       ZPKData - Property is of type 'MATLAB array'  
%       PZGroup - Property is of type 'MATLAB array'  
%       FixedDynamics - Property is of type 'MATLAB array'  
%
%    sisodata.TunedMask methods:
%       addListeners -  add listeners to keep parameters and zpk in sync
%       getFormattedGain -  GETGain Returns the formatted gain of the TunedMask
%       getPZ - Returns the poles and zeros of the TunedMask
%       getZPKGain -   Get ZPK model gain.
%       import -  compensator data.
%       isAddpzAllowed -  Checks if adding the pole/zero violates any constraints.
%       isStatic -  Checks if compensator is static
%       isTunable - Determines if block is tunable based on constraints and sample
%       reset -  Cleans up dependent data when core data changes.
%       save -   Creates backup of compensator data.
%       setParameterValue - set parameter value of the idx parameter and updates zpk
%       setParameters -  setPARAMS set parameters and updates zpk representation
%       ss -   Get SS model of tunable model.
%       updateZPK - Calculates the zpk representation from the parameters
%       utIsGainTunable -  Used to determine if gain is tunable for the TunedZPK
%       zpk -   Get ZPK model of tunable model.


properties (SetObservable)
    %ZPKDATA Property is of type 'MATLAB array' 
    ZPKData = [];
    %PZGROUP Property is of type 'MATLAB array' 
    PZGroup = [];
    %FIXEDDYNAMICS Property is of type 'MATLAB array' 
    FixedDynamics = [];
end


    methods 
        function value = get.FixedDynamics(obj)
        value = LocalGetFixedDynamics(obj,obj.FixedDynamics);
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addListeners(this)
       % add listeners to keep parameters and zpk in sync
       
       
       Listeners.Parameters =  event.proplistener(this,this.findprop('Parameters'), ...
           'PostSet',@(h,evt) LocalupdateZPK(h,evt,this));
       
       this.Listeners = Listeners;
       end  % addListeners
       
       

        %----------------------------------------
       function k = getFormattedGain(this)
       % GETGain Returns the formatted gain of the TunedMask
       
       
       % If zpkdata is empty update it
       if isempty(this.ZPKData)
           this.updateZPK;
       end
       
       k = this.zpkdata.k / formatfactor(this);
       end  % getFormattedGain
       
        %----------------------------------------
       function [p,z] = getPZ(this)
       % GETPZ Returns the poles and zeros of the TunedMask
       
       
       % If zpkdata is empty update it
       if isempty(this.ZPKData)
           this.updateZPK;
       end
       
       p = [this.ZPKData.p{:}];
       z = [this.ZPKData.z{:}];
       end  % getPZ
       
        %----------------------------------------
       function Gain = getZPKGain(this,flag)
       %GETZPKGAIN   Get ZPK model gain.
       %
       %   GAIN = GETZPKGAIN(MODEL) computes the gain of the ZPK representation of MODEL.
       %   GAIN = GETZPKGAIN(MODEL,'sign') computes the sign of the ZPK gain.
       %   GAIN = GETZPKGAIN(MODEL,'mag') computes the magnitude of the ZPK gain.
       
       %   Author(s): P. Gahinet
       
       if nargin==1
          Gain = this.ZPKData.k;
       elseif strcmpi(flag(1),'m')
          Gain = abs(this.ZPKData.k);
       else
          Gain = sign(this.ZPKData.k);
       end
       end  % getZPKGain
       
        %----------------------------------------
       function import(this,TunedMaskSnapshot)
       % Imports compensator data.
       %
       
       
       
       utRestoreTunedMask(TunedMaskSnapshot,this);
       
       
       
       end  % import
       
        %----------------------------------------
       function b = isAddpzAllowed(this,GroupType,PZType)
       % Checks if adding the pole/zero violates any constraints.
       %
       
       
       b = false;
       end  % isAddpzAllowed
       
        %----------------------------------------
       function boo = isStatic(this)
       % Checks if compensator is static
       
       boo = isstatic(this.ZPKData);
       end  % isStatic
       
        %----------------------------------------
       function bool = isTunable(this)
       % isTunable Determines if block is tunable based on constraints and sample
       % time
       
       
       bool = false;
       
       end  % isTunable
       
        %----------------------------------------
       function reset(this,Scope)
       % Cleans up dependent data when core data changes.
       %
       %   RESET(this,'all')
       %   RESET(this,'gain')
       
       
       this.SSData.d = [];
       
       end  % reset
       
        %----------------------------------------
       function Design = save(this,Design)
       %SAVE   Creates backup of compensator data.
       
       
       if nargin == 1
           Design = sisodata.TunedMaskSnapshot;
       end
       
       Design = utStoreTunedMask(Design,this);
       end  % save
       
        %----------------------------------------
       function setParameterValue(this,idx,Value)
       % setParameterValue set parameter value of the idx parameter and updates zpk
       % representation
       
       
       CurrentValue = this.Parameters(idx).Value;
       
       this.Parameters(idx).Value = Value;
       try
           this.updateZPK;
       catch
           this.Parameters(idx).Value = CurrentValue;
       end
       end  % setParameterValue
       
        %----------------------------------------
       function setParameters(this,Parameters)
       % setPARAMS set parameters and updates zpk representation
       
       
       CurrentValue = this.Parameters;
       
       this.Parameters = Parameters;
       try
           this.updateZPK;
       catch
           this.Parameters = CurrentValue;
       end
       end  % setParameters
       
        %----------------------------------------
       function D = ss(this)
       %SS   Get SS model of tunable model.
       %
       %   D = SS(MODEL) returns the @ssdata representation of MODEL.
       % 
       
       if isempty(this.SSData.d)
          % Recompute normalized state-space model
          this.SSData = ss(this.ZPKData);
       end
       D = this.SSData;
       
       end  % ss
       
        %----------------------------------------
       function updateZPK(this)
       % UPDATEZPK Calculates the zpk representation from the parameters
       
       
       if iscell(this.Par2ZpkFcn)
           [zpkTuned,zpkFixed] = feval(this.Par2ZpkFcn{1},this.Parameters,this.Par2ZpkFcn{2:end});
       else
           [zpkTuned,zpkFixed] = this.Par2ZpkFcn(this.Parameters);
       end
       this.ZPKData = getPrivateData(localConvertTs(this,zpkTuned*zpkFixed));
       end  % updateZPK
       
       
       
       %%

        %----------------------------------------
       function b = utIsGainTunable(this)
       % Used to determine if gain is tunable for the TunedZPK
       
       
       b = false;
       
       
       
       
           
       
       end  % utIsGainTunable
       
        %----------------------------------------
       function D = zpk(this)
       %ZPK   Get ZPK model of tunable model.
       %
       %   D = ZPK(MODEL) returns the @zpkdata representation of MODEL.
       
       
       D = this.ZPKData;     
       
       end  % zpk
       
end  % public methods 


    methods (Hidden) % possibly private or hidden
        %----------------------------------------
       function Value = getZPKParameterSpec(this)
       %
       
       
       Value = [];
       end  % getZPKParameterSpec
       
end  % possibly private or hidden 

end  % classdef

function Value = LocalGetFixedDynamics(this,StoredValue)

Value = this.ZPKData;
end  % LocalGetFixedDynamics
function LocalupdateZPK(es,ed,this)
this.updateZPK;
end  % LocalupdateZPK


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
end  % localConvertTs
