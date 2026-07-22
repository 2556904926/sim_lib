classdef system
%sisodata.system class
%    sisodata.system properties:
%       Name - Property is of type 'ustring'  
%       Value - Property is of type 'MATLAB array'  
%
%    sisodata.system methods:
%       display - method for @fixedsnap class
%       utExportStructure -  Export for load into designer app


properties 
    %NAME Property is of type 'ustring' 
    Name = '';
    %VALUE Property is of type 'MATLAB array' 
    Value = [];
end

properties (Access=protected)
    %VERSION Property is of type 'double' 
    Version = 1.0;
end

properties (Hidden)
    %VARIABLE Property is of type 'ustring'  (hidden)
    Variable = '';
end


    methods 
        function obj = set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function obj = set.Value(obj,value)
        obj.Value = LocalSetValue(obj,value);
        end

        function obj = set.Variable(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Variable = value;
        end

        function obj = set.Version(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Version')
        value = double(value); %  convert to double
        obj.Version = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function display(this)
       % Display method for @fixedsnap class
       
       disp(get(this))
       end  % display
       
        %----------------------------------------
       function FB = utExportStructure(this)
       % Export for load into designer app
       FB = struct(...
           'Description', this.Name, ...
           'Value', this.Value, ...
           'Identifier', this.Name);
       end  % utExportStructure
       
end  % public methods 

end  % classdef

function v = LocalSetValue(this,v)
% Checks incoming model value
if ~(isa(v,'double') || isa(v,'DynamicSystem'))
   ctrlMsgUtils.error('Control:compDesignTask:FixedModelData')
end
end  % LocalSetValue

