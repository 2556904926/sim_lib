classdef session < matlab.mixin.SetGet & matlab.mixin.Copyable
% Defines properties for @session class (SISO Tool session)
% Version history
% 1.0 -> R12.1 (struct)
% 2.0 -> R13   (struct)
% 3.0 -> R14   (class)
%sisogui.session class
%    sisogui.session properties:
%       Designs - Property is of type 'handle vector'  
%       History - Property is of type 'MATLAB array'  
%       Preferences - Property is of type 'MATLAB array'  
%       EditorSettings - Property is of type 'MATLAB array'  
%       ViewerSettings - Property is of type 'MATLAB array'  
%       Version - Property is of type 'double'  (read only) 

%   Copyright 2015-2023 The MathWorks, Inc.


properties (SetAccess=protected, SetObservable)
    %VERSION Property is of type 'double'  (read only)
    Version = 3.0;
end

properties (SetObservable)
    %DESIGNS Property is of type 'handle vector' 
    Designs = [];
    %HISTORY Property is of type 'MATLAB array' 
    History = [];
    %PREFERENCES Property is of type 'MATLAB array' 
    Preferences = [];
    %EDITORSETTINGS Property is of type 'MATLAB array' 
    EditorSettings = [];
    %VIEWERSETTINGS Property is of type 'MATLAB array' 
    ViewerSettings = [];
end


    methods 
        function set.Designs(obj,value)
            % DataType = 'handle vector'
        validateattributes(value,{'handle'}, {'vector'},'','Designs')
        obj.Designs = value;
        end

        function set.History(obj,value)
        obj.History = LocalSetValue(obj,value);
        end

        function set.Version(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Version')
        value = double(value); %  convert to double
        obj.Version = value;
        end

    end   % set and get functions 
end  % classdef

function valueStored = LocalSetValue(this, ProposedValue)

valueStored = ProposedValue(:);
end  % LocalSetValue

