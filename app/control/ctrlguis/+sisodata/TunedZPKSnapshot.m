classdef TunedZPKSnapshot < sisodata.TunedBlockSnapshot
%sisodata.TunedZPKSnapshot class
%   sisodata.TunedZPKSnapshot extends sisodata.TunedBlockSnapshot.
%

%    sisodata.TunedZPKSnapshot properties:
%       Name - Property is of type 'ustring'  
%       Description - Property is of type 'ustring'  
%       Value - Property is of type 'MATLAB array'  
%
%    sisodata.TunedZPKSnapshot methods:
%       getProperty -  Returns the property specified by PropName
%       utCheckParZPKFcn -  Checks to make sure the Par2ZPKFcn and ZPK2ParFcn are valid
%       utExportStructure -  Export for load into designer app
%       utRestoreTunedZPK -  Restores TunedZPK from a TunedZPKSnapshot
%       utStoreTunedZPK -  stores TunedZPK into a TunedZPKSnapshot


properties 
    %VALUE Property is of type 'MATLAB array' 
    Value = [];
end

properties (Access=protected)
    %CONSTRAINTS Property is of type 'MATLAB array' 
    Constraints = [];
    %ZPK2PARFCN Property is of type 'MATLAB array' 
    ZPK2ParFcn = [];
    %ZPKGAIN Property is of type 'double' 
    ZPKGain = 0;
    %PZGROUP Property is of type 'MATLAB array' 
    PZGroup = [];
    %FIXEDDYNAMICS Property is of type 'MATLAB array' 
    FixedDynamics = [];
    %INITIALVALUE Property is of type 'MATLAB array' 
    InitialValue = [];
end

properties (Hidden)
    %VARIABLE Property is of type 'ustring'  (hidden)
    Variable = '';
end


    methods 
        function obj = set.ZPKGain(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','ZPKGain')
        value = double(value); %  convert to double
        obj.ZPKGain = value;
        end

        function obj = set.Variable(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Variable = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function Prop = getProperty(this,PropName)
       % Returns the property specified by PropName
       
       
       Prop = this.(PropName);
       end  % getProperty
       
        %----------------------------------------
       function utCheckParZPKFcn(this)
       % Checks to make sure the Par2ZPKFcn and ZPK2ParFcn are valid
       
       
       if isempty(this.Value)
           this.Value = 1;
       end
       
       
       % Check that function handles are valid g292839
       try
           if ~isempty(this.ZPK2ParFcn)
               if iscell(this.ZPK2ParFcn)
                   junk = feval(this.ZPK2ParFcn{1});
               else
                   junk = feval(this.ZPK2ParFcn);
               end
           end
           if ~isempty(this.Par2ZpkFcn)
               if iscell(this.Par2ZpkFcn)
                   [junk,junk1] = feval(this.Par2ZpkFcn{1});
               else
                   [junk,junk1] = feval(this.Par2ZpkFcn);
               end
           end
       catch ME
           if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
               ctrlMsgUtils.error('Control:compDesignTask:UnableToFindCompensatorFcns')
           end
       end
       
       
       end  % utCheckParZPKFcn
       
        %----------------------------------------
       function TB = utExportStructure(this)
       % Export for load into designer app
       TB =  struct(...
           'Name', this.Name, ...
           'Identifier', 'C', ...
           'Ts', this.Ts, ...
           'TsOrig', this.TsOrig,...
           'Format', 'zeropolegain', ...
           'Par2ZPKFcn', {this.Par2ZpkFcn}, ...
           'ZPK2ParFcn', {this.ZPK2ParFcn}, ...
           'MaskParamSpec', [], ...
           'Path', this.Name, ...
           'C2DMethod', this.C2DMethod, ...
           'D2CMethod', this.D2CMethod, ...
           'Constraints', this.Constraints, ...
           'FixedDynamics', this.FixedDynamics, ...
           'Parameters', this.Parameters, ...
           'PZGroup', this.PZGroup, ...
           'ZPKGain',this.ZPKGain, ...
           'Value', this.Value);
       
       try %#ok<TRYNC> 
           if TB.Ts ~= TB.Value.Ts
               TB.Ts = TB.Value.Ts;
           end
       end
       end  % utExportStructure
       
        %----------------------------------------
       function utRestoreTunedZPK(this,TunedZPK)
       % Restores TunedZPK from a TunedZPKSnapshot
       
       
       
       if isempty(this.Value)
           this.Value = 1;
       end
       
       zpkValue = getPrivateData(chgTimeUnit(zpk(this.Value),'seconds'));
           
       TunedZPK.Name = this.Name;
       TunedZPK.Variable = this.Variable;
       
       TunedZPK.Ts = zpkValue.Ts;
       
       TunedZPK.TsOrig = this.TsOrig;
       
       TunedZPK.Par2ZpkFcn = this.Par2ZpkFcn;
       TunedZPK.ZPK2ParFcn = this.ZPK2ParFcn;
       TunedZPK.Constraints = this.Constraints;
       
       TunedZPK.AuxData = this.AuxData;
       TunedZPK.D2CMethod = this.D2CMethod;
       TunedZPK.C2DMethod = this.C2DMethod;
       
       if isequal(zpkValue,this.InitialValue) && isTunable(TunedZPK)
           % Store PZGroups as struct
           PZGroup = sisodata.pzgroup.empty(0,1);
           for ct = length(this.PZGroup):-1:1
               PZGroup(ct) = sisodata.(['PZGroup',this.PZGroup(ct).Type])(TunedZPK);
               set(PZGroup(ct),'Zero', this.PZGroup(ct).Zero(:),'Pole',this.PZGroup(ct).Pole(:))
           end
           TunedZPK.PZGroup = PZGroup;
           TunedZPK.FixedDynamics = this.FixedDynamics;
           TunedZPK.setZPKGain(this.ZPKGain);
           TunedZPK.Parameters = this.Parameters;
           TunedZPK.updateParams;
       
       else
           if isTunable(TunedZPK)
               TunedZPK.Parameters = this.Parameters;
               % Since the parameters are the truth in this case clear out the
               % fixed dynamics.
               if ~isempty(TunedZPK.FixedDynamics)
                   TunedZPK.FixedDynamics = ltipack.zpkdata({zeros(0,1)},{zeros(0,1)},1,TunedZPK.Ts);
               end
       
               TunedZPK.updatePZGroups(zpkValue);
               TunedZPK.setZPKGain(zpkValue.k);
               TunedZPK.updateParams;
               %% Update the zpk data since the parameter update may change the
               %% number of fixed elements.
               TunedZPK.updateZPK;
           else
               TunedZPK.Parameters = this.Parameters;
               TunedZPK.updateZPK;
           end
       end
       
       TunedZPK.addListeners;
       
       
       
       end  % utRestoreTunedZPK
       
        %----------------------------------------
       function this = utStoreTunedZPK(this,TunedZPK);
       % stores TunedZPK into a TunedZPKSnapshot
       
       
       
       this.Name = TunedZPK.Name;
       this.Variable = TunedZPK.Variable;
       
       this.Ts = TunedZPK.Ts;
       this.TsOrig = TunedZPK.TsOrig;
       
       this.Parameters = TunedZPK.Parameters;
       this.Par2ZpkFcn = TunedZPK.Par2ZpkFcn;
       this.ZPK2ParFcn = TunedZPK.ZPK2ParFcn;
       this.Constraints = TunedZPK.Constraints;
       this.FixedDynamics = TunedZPK.FixedDynamics;
       
       this.AuxData = TunedZPK.AuxData;
       this.C2DMethod = TunedZPK.C2DMethod;
       this.D2CMethod = TunedZPK.D2CMethod;
       
       % Store PZGroups as struct
       PZGroup = repmat(struct('Type','','Zero',[],'Pole',[]),[0,1]);
       
       for ct = length(TunedZPK.PZGroup):-1:1
           PZGroup(ct) = getTypeZeroPole(TunedZPK.PZGroup(ct));
       end
       
       this.PZGroup = PZGroup;
       
       this.ZPKGain = getZPKGain(TunedZPK);
       
       InitValue =  zpk(TunedZPK);
       this.Value = zpk(InitValue.z,InitValue.p,InitValue.k,TunedZPK.Ts);
       this.InitialValue = InitValue ;
       
       
       
       
       end  % utStoreTunedZPK
       
end  % public methods 

end  % classdef

