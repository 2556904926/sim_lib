function showBlockValue(M)
%showBlockValue  Displays block values in generalized model.
%
%   showBlockValue(M) shows the current/nominal values of the Control
%   Design blocks in the generalized model M.
%
%   Use showTunable(M) to see just the tunable (parametric) blocks.
%
%   See also showTunable, getBlockValue, ControlDesignBlock, genmat, genlti.

%   Copyright 1986-2020 The MathWorks, Inc.
if ~isGeneralized(M)
   error(message('Control:lftmodel:GeneralizedOnly','showBlockValue'))
end
C = struct2cell(getBlocks(M));
for ct=1:numel(C)
   if ct>1
      fprintf('-----------------------------------\n')
   end
   showValue(C{ct})
end