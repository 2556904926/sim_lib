function DisplayText = createDisplayBlock(block)
% Utility function for display text of Tunable Block.

% Copyright 2013 The MathWorks, Inc.

BlockValue = getValue(block);
str = evalc('display(BlockValue)');
str = strsplit(str,'=\n');
str=str{2};
str = strsplit(str,getString(message('Control:ltiobject:DispName','')));
DisplayText = str{1};
