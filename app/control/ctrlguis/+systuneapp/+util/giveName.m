function Name = giveName(NameRoot,NameList)
% Utility function to give a different name from available names.
% NameRoot is string and NameList is cell array of strings

% Copyright 2013 The MathWorks, Inc.

n=1;
CurrentName = sprintf('%s%d',NameRoot,n);
while any(strcmpi(NameList,CurrentName))
    n = n+1;
    CurrentName = sprintf('%s%d',NameRoot,n);
end
Name = CurrentName;