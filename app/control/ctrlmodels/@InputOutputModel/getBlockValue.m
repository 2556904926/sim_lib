function varargout = getBlockValue(M,varargin)
%getBlockValue  Evaluate block components in generalized model.
%
%   VAL = getBlockValue(M,BLOCKNAME) takes a generalized model M (see
%   GENMAT and GENLTI) and returns the current/nominal value of the
%   Control Design block with name BLOCKNAME. Type "M.Blocks" for the
%   list of Control Design blocks in M.
%
%   [VAL1,VAL2,...] = getBlockValue(M,BLOCK1,BLOCK2,...) returns the
%   values VAL1,VAL2,... of the Control Design blocks with names
%   BLOCK1,BLOCK2,...
%
%   S = getBlockValue(M) returns a structure S containing the values of
%   all Control Design blocks in M. The fields of S are named after the
%   blocks.
%
%   See also setBlockValue, showBlockValue, ControlDesignBlock, genmat, genlti.

%   Copyright 1986-2020 The MathWorks, Inc.
ni = nargin;
no = max(1,nargout);
if ~isGeneralized(M)
   error(message('Control:lftmodel:GeneralizedOnly','getBlockValue'))
elseif ~(isstring(varargin) || iscellstr(varargin))
   error(message('Control:lftmodel:getBlockValue2'))
end

S = getBlocks(M);
if ni==1
   % S = getBlockValue(M)
   if no>1
      error(message('Control:lftmodel:getBlockValue1'))
   end
   Values = structfun(@(x) getValue(x),S,'UniformOutput',false);
   varargout = {Values};
else
   % [VAL1,VAL2,...] = getBlockValue(M,BLOCK1,BLOCK2,...)
   if no>ni-1
      error(message('Control:lftmodel:getBlockValue1'))
   end
   BlockNames = fieldnames(S);
   BlockData = struct2cell(S);
   [ism,loc] = ismember(string(varargin(1:no)),BlockNames);
   if all(ism)
      varargout = cellfun(@(x) getValue(x),BlockData(loc),'UniformOutput',false);
   else
      error(message('Control:lftmodel:BlockName3',varargin{find(~ism,1)}))
   end
end
