function M = replaceBlock(M,varargin)
%REPLACEBLOCK  Replaces or updates Control Design Blocks in generalized model.
%
%   M = REPLACEBLOCK(M,BLOCK1,VALUE1,BLOCK1,VALUE2,...) replaces the Control 
%   Design blocks BLOCK1,BLOCK2,... with the values VALUE1,VALUE2,... in 
%   the generalized model M. The strings BLOCK1,BLOCK2 specify the names 
%   of the blocks to be replaced, and VALUE1,VALUE2,... specify the replacement
%   values. A block can be replaced by any value compatible with its size, 
%   including another block, a matrix, an LTI model, or [] to denote its
%   current/nominal value. Blocks that do not appear in M are ignored. If 
%   all blocks are replaced by numeric values, the output M is a numeric
%   array or numeric LTI model.
%
%   M = REPLACEBLOCK(M,S) specifies the block names and replacement values
%   as a structure S. For example
%      M = replaceBlock(M,M0.Blocks)
%   replaces the blocks of M by their current value in M0, thus "sync-ing" 
%   M with M0.
%
%   M = REPLACEBLOCK(M,...,'-once') performs vectorized block replacement  
%   in model arrays M. Each block is replaced by a single value, but this 
%   value may change across the model array. Use a struct array S or cell 
%   arrays VALUE1,VALUE2,... to specify block replacement values for each 
%   model in M. For example, if M is a 2x3 array of models, then
%     * A 2x3 struct array S specifies one set of block values S(k) for
%       each model M(:,:,k)
%     * A 2x3 cell array VALUE1 causes BLOCK1 to be replaced by VALUE1{k} 
%       in M(:,:,k).
%   Numeric array formats are also accepted for VALUE1,VALUE2,... For 
%   example, VALUE1 can be a 2x3 array of LTI models, a numeric array of  
%   size [SIZE(BLOCK1) 2 3], or a 2x3 matrix when BLOCK1 is scalar-valued.
%   The array sizes of M,S,VALUE1,VALUE2,... must agree along non-singleton
%   dimensions and scalar expansion takes place along singleton dimensions.
%
%   MB = REPLACEBLOCK(M,...,'-batch') performs batch block replacement in  
%   model arrays M. Each block is replaced by an array of values, and the 
%   same values are used for all models in M. The resulting model MB is of
%   size [size(M) AS] when the array of block replacement values is of size
%   AS. 
%
%   Note that REPLACEBLOCK(M,...,'-once') and REPLACEBLOCK(M,...,'-batch')
%   produce the same result for a single model M, and that '-once' is the 
%   default behavior when these flags are omitted.
%
%   Example 1:
%     G = rss(3);     % a third-order SISO plant model
%     C = tunablePID('C','pid');  % pid controller block
%     T = feedback(G*C,1);          % closed-loop model
%
%     % Replace C by a pure gain of 5:
%     T1 = replaceBlock(T,'C',5);
%     % Replace C by the PI controller 5+0.1/s
%     T2 = replaceBlock(T,'C',pid(5,0.1));
%     % Replace C by its current value (@pid object):
%     T3 = replaceBlock(T,'C',[]);
%
%   Example 2:
%     a = realp('a',0);   b = realp('b',3);
%     M = [a+b 1 ; 0 1+a*b];  % 2x2 parametric matrix
%    
%     % Sample M over a 2x3 grid of (a,b) values. The result is
%     % 2x3 array of M values:
%     [aGrid,bGrid] = ndgrid([-1 1],[2 3 4]);
%     Ms = replaceBlock(M,'a',aGrid,'b',bGrid)
%
%   See also getValue, ControlDesignBlock, genlti, genmat, InputOutputModel.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% Resolve mode
[varargin{:}] = convertStringsToChars(varargin{:});
iFlag = find(strcmp(varargin,'-once') | strcmp(varargin,'-batch'));
if isempty(iFlag)
   BatchMode = false;
else
   BatchMode = strcmp(varargin{iFlag},'-batch');
   varargin(:,iFlag) = [];
end

% Get block data
if isa(M,'ControlDesignBlock')
   BlockData = struct(M.Name,M);
elseif isa(M,'ltipack.LFTModelArray')
   BlockData = M.Blocks;  % LFT model
else
   BlockData = struct;
end

try
   % Reduce all ways to specify block replacements to the following:
   % * BlockNames: cell vector of block names appearing in M
   % * BlockValues: cell vector of replacement values for each block.
   %   Each cell contains a block, numeric array, or model array.
   ni = length(varargin);
   if ni==1
      % REPLACEBLOCK(M,S)
      if isstruct(varargin{1})
         S = varargin{1};
         S = rmfield(S,setdiff(fieldnames(S),fieldnames(BlockData)));
         % Validate and format replacement values
         [BlockNames,BlockValues] = localStruct2Array(S,BlockData);
      else
         error(message('Control:general:InvalidSyntaxForCommand','replaceBlock','replaceBlock'))
      end
   else
      % REPLACEBLOCK(M,BLOCK1,VALUE1,BLOCK1,VALUE2,...)
      [VALID,BlockNames] = ltipack.isNameList(varargin(1:2:ni));
      if ~VALID
         error(message('Control:general:InvalidSyntaxForCommand','replaceBlock','replaceBlock'))
      end
      [BlockNames,ia] = intersect(BlockNames,fieldnames(BlockData));
      BlockValues = varargin(:,2*ia);
      % Validate and format replacement values
      for ct=1:numel(BlockNames)
         BlockValues{ct} = localCell2Array(...
            BlockValues{ct},BlockData.(BlockNames{ct}));
      end
   end
   
   % Quick exits
   if isempty(BlockValues)
      % Nothing to replace
      if isequal(BlockData,struct)
         % Return value for block-free LFT model for consistency with case
         % when all blocks of M are evaluated
         M = getValue_(M);
      end
      return
   elseif isa(M,'ControlDesignBlock')
      % Replacing a Control Design block by another block or some value
      M = BlockValues{1};
      return
   end
   
   % Replacing blocks in LFT model
   isBlock = cellfun(@(x) isa(x,'ControlDesignBlock'),BlockValues);
   isValue = (~isBlock);
   B2B = BlockValues(isBlock); % cache before transformed to gen* below
   
   % Match types and attributes (e.g., sample time). Resulting type is
   % always an LFT model
   [M,BlockValues{:}] = ltipack.matchType('lft',M,BlockValues{:});
   [M,BlockValues{:}] = matchAttributesN(M,BlockValues{:});
   B2V = BlockValues(isValue);
   
   % In batch mode, each model in M is replaced by a set of values. Add
   % leading singleton dimension to the value arrays for each non-singleton
   % array dimension of M.
   if BatchMode
      % Note: Drop the trailing 1 in array size of M to avoid extra
      % singleton dimension. For example, if M is a 3x1 array and the
      % value batch is 2x4, then the result should be 3x2x4
      % Last non-singleton array dimension in M
      nad = max([0,find(getArraySize(M)~=1,1,'last')]);
      for ct=1:numel(B2V)
         B2V{ct} = reshape(B2V{ct},[ones(1,nad),getArraySize(B2V{ct})]);
      end
   end
   
   % Match array sizes (ignoring block-to-block replacements)
   if any(isValue)
      try
         [M,B2V{:}] = matchArraySizeN(M,B2V{:});
      catch
         error(message('Control:lftmodel:repblock6'))
      end
   end
   
   % Perform block-to-value replacements
   if ~isempty(B2V)
      M = replaceB2V_(M,BlockNames(isValue),B2V);
   end
   
   % Perform block-to-block replacements (done last so that
   % replaceBlock(M,'a',1,'b',a) does not replace b by 1)
   if ~isempty(B2B)
      B2B = localAlignTs(B2B,M);
      M = replaceB2B_(M,BlockNames(isBlock),B2B);
   end
catch ME
   throw(ME)
end

% Return numeric or LTI array if there are no more blocks
if isBlockFree(M)
   M = getValue_(M);
end
end

%--------------------------- Local Functions --------------------

function B2B = localAlignTs(B2B,M)
% Aligns sample time of block replacements with sample time of M.
if isa(M,'DynamicSystem')
   Ts = M.Ts;
   for ct=1:numel(B2B)
      if isa(B2B{ct},'DynamicSystem')
         B2B{ct}.Ts = Ts;
      end
   end
end
end

%-----------
function Value = localValidate(Value,Block)
% Validates and resolves single block value
if ischar(Value)
   % Accommodate RCTB 'NominalValue' and 'Random' flags
   Flag = ltipack.matchKey(Value,{'NominalValue','Random'});
   switch Flag
      case 'NominalValue'
         Value = [];
      case 'Random'
         Value = usample(Block,1);
      otherwise
         error(message('Control:lftmodel:repblock4',Block.Name))
   end
end
% Resolve and validate
if isequal(Value,[])
   % [] refers to nominal value
   Value = getValue_(Block);
elseif ~(isnumeric(Value) || isa(Value,'InputOutputModel'))
   % Invalid type (note: handle cell array of values upfront)
   error(message('Control:lftmodel:repblock3',Block.Name))
elseif ~isequal(size(Value),iosize(Block))
   % Invalid size
   error(message('Control:lftmodel:repblock2',Block.Name))
end
end

%------------
function [BlockNames,BlockValues] = localStruct2Array(S,BlockData)
% Validates and reformats replacement data specified as struct array.
BlockNames = fieldnames(S);
nblk = numel(BlockNames);
% Validate block values
C = struct2cell(S);
for ctB=1:nblk
   f = BlockNames{ctB};
   blk = BlockData.(f);
   for ct=1:numel(S)
      C{ctB,ct} = localValidate(C{ctB,ct},blk);
   end
end
% Format data as cell vector containing blocks or arrays of values
if isscalar(S)
   BlockValues = C;
else
   % Combine all values for a given field into 
   BlockValues = cell(nblk,1);
   AS = size(S);
   for ct=1:nblk
      if isa(C{ct,1},'ControlDesignBlock') && isequal(C{ct,:})
         % Block-to-block replacement: keep target block value
         BlockValues{ct} = C{ct,1};
      else
         % Block-to-value replacement
         VA = cat(3,C{ct,:}); % may error due to sample time mismatch,...
         if isnumeric(VA)
            BlockValues{ct} = reshape(VA,[size(VA,1),size(VA,2),AS]);
         else
            BlockValues{ct} = reshape(VA,AS);
         end
      end
   end
end
end

%------------
function ValueArray = localCell2Array(Values,Block)
% Validates and reformats replacement data specified in other formats than 
% struct array. The input VALUES can be [], a string, a numeric array, 
% a cell array, or a model array. On output, VALUES is always an array of
% matrices or models.
ios = iosize(Block);
sv = size(Values);
if ischar(Values) || isequal(Values,[])
   % Accommodate [] and RCTB flags 'NominalValue' and 'Random'
   ValueArray = localValidate(Values,Block);
elseif iscell(Values)
   % Cell array of values
   for ct=1:numel(Values)
      Values{ct} = localValidate(Values{ct},Block);
   end
   ValueArray = cat(3,Values{:});
   if isnumeric(ValueArray)
      ValueArray = reshape(ValueArray,[ios sv]);
   else  % I/O model
      ValueArray = reshape(ValueArray,sv);
   end
elseif isnumeric(Values)
   if all(ios==1) && any(sv(1:2)~=1)
      % Scalar-valued block: Treat [1 2 3] as a 1x3 array of values
      ValueArray = reshape(Values,[1 1 sv]);
   elseif isequal(sv(1:2),ios)
      ValueArray = Values;
   else
      error(message('Control:lftmodel:repblock2',Block.Name))
   end
elseif isa(Values,'InputOutputModel')
   % I/O model
   if isequal(iosize(Values),ios)
      ValueArray = Values;
   else
      error(message('Control:lftmodel:repblock2',Block.Name))
   end
else
   % Invalid type (note: handle cell array of values upfront)
   error(message('Control:lftmodel:repblock3',Block.Name))
end
end
