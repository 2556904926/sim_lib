function DisplayText = createDisplayMatrix(a)
% Utility function for display text of a matrix.

% Copyright 2013 The MathWorks, Inc.

nrow = size(a,1);

for ct=1:nrow
    DisplayText{ct}=num2str(a(ct,:));
end