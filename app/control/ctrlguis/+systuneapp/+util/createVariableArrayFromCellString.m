function Arraystr = createVariableArrayFromCellString(Cellstr,VarName)
% Utility function to create variable array from cell string.

% Copyright 2014 The MathWorks, Inc.

% VarName = { 'Req1'; ...
%             'Req2'; ...
%             'ReqN' };
% where Reqs are the name of same type objects. The output is a string

% VarName = [ Req1 ; ...
%             Req2 ; ...
%             ReqN ]

if nargin<2
    VarName = '';
end

Arraystr = controllib.internal.codegen.appendMATLABCode('',Cellstr,VarName);
Arraystr = strrep(Arraystr,'''',' '); % remove quotation
Arraystr = strrep(Arraystr,'{','[');
Arraystr = strrep(Arraystr,'}',']');