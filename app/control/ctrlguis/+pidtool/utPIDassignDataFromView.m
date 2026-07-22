function datahandle = utPIDassignDataFromView(datahandle,dataproperty,...
   viewhandle,viewproperty, Pos)
% Qualify and apply text field entry for a nonnegative real scalar.
% Pos: Boolean: true means the parameter is required to be nonnegative.

% Copyright 2013 The MathWorks, Inc.

str = viewhandle.(viewproperty);
conversion = '%0.3g';

OldValueStr = num2str(datahandle.(dataproperty),conversion);
OldValue = str2double(OldValueStr);

if strcmp(str,OldValueStr)
   return
end

if isempty(str)
   Value = OldValue;
else
   try
      Value = evalin('base', str);      
      if ~(isscalar(Value) && isreal(Value) && isnumeric(Value) && allfinite(Value)) || ...
            (Pos && Value<0)
         Value = OldValue;
      end      
   catch
      % restore old value
      Value = OldValue;
   end
end
viewhandle.(viewproperty) = num2str(Value,conversion);
datahandle.(dataproperty) = Value;
end
