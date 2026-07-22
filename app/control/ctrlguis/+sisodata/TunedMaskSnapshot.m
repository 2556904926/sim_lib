classdef TunedMaskSnapshot < sisodata.TunedBlockSnapshot
%sisodata.TunedMaskSnapshot class
%   sisodata.TunedMaskSnapshot extends sisodata.TunedBlockSnapshot.
%

%    sisodata.TunedMaskSnapshot properties:
%       Name - Property is of type 'ustring'  
%       Description - Property is of type 'ustring'  
%       Value - Property is of type 'MATLAB array'  
%
%    sisodata.TunedMaskSnapshot methods:
%       getProperty -  Returns the property specified by PropName
%       utCheckParZPKFcn -  Checks to make sure the Par2ZPKFcn and ZPK2ParFcn are valid
%       utRestoreTunedMask -  Restores TunedMask from a TunedMaskSnapshot
%       utStoreTunedMask -  stores TunedMask into a TunedMaskSnapshot


properties 
    %VALUE Property is of type 'MATLAB array' 
    Value = zpk( 1 );
end


    methods 
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
           if iscell(this.Par2ZpkFcn)
               [junk,junk1] = feval(this.Par2ZpkFcn{1});
           else
               [junk,junk1] = feval(this.Par2ZpkFcn);
           end
       catch ME
           if strcmp(ME.identifier,'MATLAB:UndefinedFunction')
               ctrlMsgUtils.error('Control:compDesignTask:UnableToFindCompensatorFcns')
           end
       end
       
       
       end  % utCheckParZPKFcn
       
        %----------------------------------------
       function utRestoreTunedMask(this,TunedMask)
       % Restores TunedMask from a TunedMaskSnapshot
       
         
       TunedMask.Name = this.Name;
       
       TunedMask.Ts = this.Value.Ts;
       
       TunedMask.TsOrig = this.TsOrig;
       
       TunedMask.Par2ZPKFcn = this.Par2ZpkFcn;
       
       TunedMask.AuxData = this.AuxData;
       TunedMask.D2CMethod = this.D2CMethod;
       TunedMask.C2DMethod = this.C2DMethod;
       
       TunedMask.Parameters = this.Parameters;
       TunedMask.updateZPK;
       
       
       
       
       
       end  % utRestoreTunedMask
       
        %----------------------------------------
       function this = utStoreTunedMask(this,TunedMask);
       % stores TunedMask into a TunedMaskSnapshot
       
       
       
       this.Name = TunedMask.Name;
       
       this.Ts = TunedMask.Ts;
       this.TsOrig = TunedMask.TsOrig;
       
       this.Parameters = TunedMask.Parameters;
       this.Par2ZpkFcn = TunedMask.Par2ZPKFcn;
       
       this.AuxData = TunedMask.AuxData;
       this.C2DMethod = TunedMask.C2DMethod;
       this.D2CMethod = TunedMask.D2CMethod;
       
       
       
       
       
       end  % utStoreTunedMask
       
end  % public methods 

end  % classdef

