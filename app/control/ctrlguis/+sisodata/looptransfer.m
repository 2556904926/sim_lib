classdef looptransfer
%sisodata.looptransfer class
%    sisodata.looptransfer properties:
%       Type - Property is of type 'string'  
%       Index - Property is of type 'MATLAB array'  
%       Description - Property is of type 'ustring'  
%       ExportAs - Property is of type 'ustring'  
%       Style - Property is of type 'string'  


properties 
    %TYPE Property is of type 'string' 
    Type = '';
    %INDEX Property is of type 'MATLAB array' 
    Index = [];
    %DESCRIPTION Property is of type 'ustring' 
    Description = '';
    %EXPORTAS Property is of type 'ustring' 
    ExportAs = '';
    %STYLE Property is of type 'string' 
    Style = '';
end


    methods 
        function obj = set.Type(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Type')
        obj.Type = value;
        end

        function obj = set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function obj = set.ExportAs(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.ExportAs = value;
        end

        function obj = set.Style(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Style')
        obj.Style = value;
        end

    end   % set and get functions 
end  % classdef

