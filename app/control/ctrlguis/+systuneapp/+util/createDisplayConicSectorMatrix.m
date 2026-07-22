function DisplayText = createDisplayConicSectorMatrix(Q)
% Utility function for display text of conic sector matrix Q.

% Copyright 2015 The MathWorks, Inc.

if isa(Q,'DynamicSystem') 
    sysValue = getValue(tf(Q));
    str = evalc('display(sysValue)');
    str = strsplit(str,'=\n');
    str=str{2};
    str = strsplit(str,'Name:');
    DisplayText = str{1};
else
    nrow = size(Q,1);    
    for ct=1:nrow
        DisplayText{ct}=num2str(Q(ct,:));
    end
end
