function TBBlockPaths = getTunableBlockPaths(TunableBlockObjects)
% Utility function to get block paths of TunableBlocks in a cell array.

% Copyright 2013 The MathWorks, Inc.

    TBBlockPaths = arrayfun(@(x) x.Name,TunableBlockObjects,'UniformOutput',false);
end