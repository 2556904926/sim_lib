function expr = getExpression(Finfo,pNames)
% Pulls out expression for expansion basis in terms of input variables

%   Copyright 1986-2017 The MathWorks, Inc.
T = regexp(Finfo.function,'@\(([^\)]+)\)(.+)','tokens');
vars = strip(split(T{1}{1},','));
expr = [' ' T{1}{2} ' '];
for ct=1:numel(vars)
   Pat = "(\W)("+vars(ct)+")(\W)";
   Rep = "$1" + pNames(ct) + "$3";
   % Twice to process x,x,x,x correctly
   expr = regexprep(expr,Pat,Rep);
   expr = regexprep(expr,Pat,Rep);
end
expr = strip(expr);
% Remove brackets
if strncmp(expr,'[',1)
   expr = extractBetween(expr,2,strlength(expr)-1);
end
% Add proper spacing
expr = regexprep(expr,'(\S)(,)','$1 ,');
expr = regexprep(expr,'(,)(\S)',', $2');
