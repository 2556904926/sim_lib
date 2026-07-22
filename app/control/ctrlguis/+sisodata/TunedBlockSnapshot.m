classdef TunedBlockSnapshot
%sisodata.TunedBlockSnapshot class
%    sisodata.TunedBlockSnapshot properties:
%       Name - Property is of type 'ustring'  
%       Description - Property is of type 'ustring'  
%
%    sisodata.TunedBlockSnapshot methods:
%       display - method for snapshot
%       getProperty -  Returns the property specified by PropName
%       setProperty -  Sets the property specified by PropName with PropValue


properties 
    %NAME Property is of type 'ustring' 
    Name = '';
    %DESCRIPTION Property is of type 'ustring' 
    Description = '';
end

properties (Access=protected)
    %TS Property is of type 'double' 
    Ts = 0;
    %TSORIG Property is of type 'double' 
    TsOrig = 0;
    %PARAMETERS Property is of type 'MATLAB array' 
    Parameters = [];
    %PAR2ZPKFCN Property is of type 'MATLAB array' 
    Par2ZpkFcn = [];
    %C2DMETHOD Property is of type 'MATLAB array' 
    C2DMethod = [];
    %D2CMETHOD Property is of type 'MATLAB array' 
    D2CMethod = [];
    %AUXDATA Property is of type 'MATLAB array' 
    AuxData = [];
end


    methods 
        function obj = set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function obj = set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function obj = set.Ts(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Ts')
        value = double(value); %  convert to double
        obj.Ts = value;
        end

        function obj = set.TsOrig(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','TsOrig')
        value = double(value); %  convert to double
        obj.TsOrig = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function display(this)
       % Display method for snapshot
       
       
       this.get
       end  % display
       
        %----------------------------------------
       function Prop = getProperty(this,PropName)
       % Returns the property specified by PropName
       
       
       Prop = this.(PropName);
       end  % getProperty
       
        %----------------------------------------
       function this = setLoopView(this,PropName,PropValue)
       % Sets the property specified by PropName with PropValue
       
       
       this.(PropName) = PropValue;
       end  % setLoopView
       
end  % public methods 

end  % classdef

