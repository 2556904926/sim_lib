function Name = createVariableName(Name)
% Turn identifier into valid variable name.

try
    Name = ltipack.createVarName(Name);
catch
    error(message('Control:systunegui:InvalidVariableName',Name));
end