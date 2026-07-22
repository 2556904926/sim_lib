function [M,Samples] = sampleBlock(M,varargin)
%SAMPLEBLOCK   Samples Control Design blocks.
%
%   B = SAMPLEBLOCK(A,NAME,VALS) samples one Control Design block in the
%   generalized model A. The string NAME specifies the block name and the
%   array VALS specifies N sample values for the block. The output B is a
%   generalized model of size [SIZE(A) N] obtained by replacing the block
%   by its sample values.
%
%   B = SAMPLEBLOCK(A,NAMESET,VALSET) concurrently samples multiple blocks.
%   NAMESET is a cell array of block names, and VALSET is a cell array of
%   N sample values for each block. B is again of size [SIZE(A) N].
%
%   B = SAMPLEBLOCK(A,NAME1,VALS1,NAME2,VALS2,...) independently samples
%   multiple blocks. NAME1,NAME2,... contain the names of the blocks to
%   sample, and VALS1,VALS2,... contain the corresponding sample values.
%   If VALS1,VALS2,... contain N1,N2,... samples values, A is evaluated
%   over a sampling grid of size [N1 N2 ...] and the resulting B is of size
%   [SIZE(A) N1 N2 ...].
%
%   [B,SAMPLES] = SAMPLEBLOCK(A,...) also returns a struct array SAMPLES
%   of size [N 1] or [N1 N2 ...] containing the block replacement values
%   for each sampling point.
%
%   Note:
%    * VALS can be an N-entry numeric vector, a 3D array of N matrices 
%      stacked along the third dimension, or an LTI array with N models
%    * B and A are of the same type unless all blocks are sampled, in which 
%      case B is a double, SS, or FRD array
%    * Block names that do not appear in A are ignored.
%
%   Example 1: 
%      % Create the first-order model G(s) = 1/(tau*s+1) where tau is a
%      % tunable real parameter
%      tau = realp('tau',5);
%      G = tf(1,[tau 1]);
%      % Evaluate this transfer function for tau=3,4,..,7. The result is
%      % a 5x1 array of first-order model.
%      Gs = sampleBlock(G,'tau',3:7);
%
%   Example 2:
%      % Create a matrix M = [a b*c] where a,b,c are tunable scalars:
%      a = realp('a',1);  b = realp('b',3);  c = realp('c',0);
%      M = [a b*c];
%      % Pick 5 samples for a and 3 samples for (b,c) and evaluate
%      % M over the corresponding 5x3 grid of (a,b,c) combinations:
%      as = 0.8:0.1:1.2;
%      bs = [2 3 4];
%      cs = [-1 0 1];
%      Ms = sampleBlock(M,'a',as,{'b','c'},{bs,cs})
%
%   See also rsampleBlock, replaceBlock, getValue, ControlDesignBlock, 
%   genlti, genmat, InputOutputModel.

%   Copyright 2003-2011 The MathWorks, Inc.
ni = length(varargin);
if rem(ni,2)~=0
   error(message('Control:general:InvalidSyntaxForCommand','sampleBlock','sampleBlock'))
else
   Names = varargin(1:2:end);
   Values = varargin(2:2:end);
   if ~all(cellfun(@isStringVec,Names))
      error(message('Control:lftmodel:sampleblock1'))
   end
end
ndim = numel(Names);

% Convert block to LFT model for simplicity
if isa(M,'ControlDesignBlock')
   M = feval(M.toClosed(),M);
end
   
% Get full block set and consolidate block name/value lists
if isa(M,'ltipack.LFTModelArray')
   Blocks = M.Blocks;
else
   Blocks = struct;
end
BlockNames = fieldnames(Blocks);
for ct=1:ndim
   S = Names{ct};
   V = Values{ct};
   if ischar(S)
      S = {S};
   else
      S = S(:);
   end
   if iscell(V)
      V = V(:);
   else
      V = {V};
   end
   if ~(numel(V)==numel(S) && all(cellfun(@isValidValue,V)))
      error(message('Control:lftmodel:sampleblock4'))
   end
   ix = find(ismember(S,BlockNames));  % preserves order
   Names{ct} = S(ix);
   Values{ct} = V(ix);
end
SampledBlockNames = cat(1,Names{:});
nblk = numel(SampledBlockNames);
[~,iu] = unique(SampledBlockNames);
if numel(iu)<nblk
   im = setdiff(1:nblk,iu);
   error(message('Control:lftmodel:sampleblock3',SampledBlockNames{im(1)}))
end

% Compute number of samples per dimension
N = cell(1,ndim);
for ct=1:ndim
   S = Names{ct};
   V = Values{ct};
   nblk = numel(S);
   if nblk>0
      Ns = zeros(nblk,1);
      for k=1:nblk
         blk = Blocks.(S{k});
         % Check I/O size and compute number of samples
         [Ns(k),V{k}] = localCheckSize(V{k},iosize(blk));
         if Ns(k)<0
            error(message('Control:lftmodel:sampleblock7',S{k}))
         end
         % Check LTI values 
         if isa(V{k},'numlti')
            if isa(blk,'StaticModel')
               error(message('Control:lftmodel:sampleblock6',S{k}))
            end
            % Value's sample time should be compatible with block's
            try
               V{k} = matchSamplingTime(V{k},blk);
               MatchingTs = (V{k}.Ts==blk.Ts);
            catch 
               MatchingTs = false;
            end
            if ~MatchingTs
               error(message('Control:lftmodel:sampleblock8',S{k}))
            end
            V{k} = ss(V{k});
         end
      end
      if any(diff(Ns))
         error(message('Control:lftmodel:sampleblock5'))
      end
      N{ct} = Ns(1);
      Values{ct} = V;
   else
      N{ct} = 1;
   end
end
   
% Sample selected blocks
if isempty(SampledBlockNames)
   % Return M (default = 1 sample per dimension)
   Samples = struct;
else
   SamplingSpec = struct('NumSamples',N,'BlockNames',Names,'BlockValues',Values);
   if nargout>1
      [M,Samples] = sampleBlock_(M,SamplingSpec);
   else
      M = sampleBlock_(M,SamplingSpec);
   end
end

% Return numeric or LTI array if resulting model is block free
if isa(M,'ltipack.LFTModelArray') && isBlockFree(M)
   M = getValue(M);
end

%------------------------
function boo = isStringVec(x)
if ischar(x)
   boo = isrow(x);
elseif iscellstr(x)
   boo = all(cellfun(@isrow,x));
else
   boo = false;
end

function boo = isValidValue(x)
boo = isnumeric(x) || (isa(x,'numlti') && ~isa(x,'FRDModel'));

function [N,V] = localCheckSize(V,ios)
% Determines number of samples. Returns -1 if value is not correctly
% formatted
if all(ios==1) && isnumeric(V) && isvector(V)
   % Ignore shape for scalar-valued block
   N = numel(V);
   V = reshape(V,[1 1 N]);
else
   s = size(V);
   if isequal(s([1 2]),ios)
      N = prod(s(3:end));
      V = V(:,:,:);
   else
      % Incompatible I/O size
      N = -1;
   end
end
