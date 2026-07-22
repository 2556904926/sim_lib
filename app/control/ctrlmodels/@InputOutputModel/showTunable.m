function showTunable(M)
%showTunable  Displays values of tunable blocks in generalized model.
%
%   showTunable(M) shows the current values of the tunable Control Design 
%   blocks (see tunableBlock) in the generalized model M.
%
%   Use showBlockValue(M) to see all Control Design blocks.
%
%   See also showBlockValue, getBlockValue, tunableBlock, ControlDesignBlock, 
%   genmat, genlti.

%   Copyright 1986-2015 The MathWorks, Inc.
if isParametric(M)
   % Show values of tunable blocks
   C = struct2cell(getBlocks(M));
   C = C(cellfun(@isParametric,C));
   for ct=1:numel(C)
      if ct>1
         fprintf('-----------------------------------\n')
      end
      showValue(C{ct})
   end
end
