function DisplayText = createDisplayBlock(block)
% Utility function for display text of Tunable Block.

% Copyright 2013 The MathWorks, Inc.

BlockValue = getValue(getParameterization(block));
str = evalc('display(BlockValue)');
str = strsplit(str,'=\n');
str=str{2};
str = strsplit(str,'Name:');
DisplayText = str{1};
