function [M,Samples] = rsampleBlock(M,varargin)
%RSAMPLEBLOCK   Randomly samples Control Design blocks.
% 
%   [B,SAMPLES] = RSAMPLEBLOCK(A,NAMES,N) randomly samples a subset of the 
%   Control Design blocks in the generalized model A. The string or cell 
%   array of strings NAMES specifies which blocks to sample by name, and N 
%   specifies how many samples to use. The output B is a generalized model
%   of size [SIZE(A) N] obtained by replacing the sampled blocks by their
%   randomized values. B and A are of the same type unless all blocks are
%   sampled, in which case B is a double, SS, or FRD array. The N-by-1 
%   struct array SAMPLES contains the sample values of the selected blocks. 
%   Any entry of NAMES that does not appear in A is ignored.
%
%   [B,SAMPLES] = RSAMPLEBLOCK(A,NAMES1,N1,NAMES2,N2,...) takes N1 samples
%   of the blocks listed in NAMES1, N2 samples of the blocks listed in
%   NAMES2, and so on. The resulting B has size [SIZE(A) N1 N2 ...].
%
%   Example 1: 
%      % Create an uncertain model of G(s) = g/(tau*s+1) where g varies
%      % in [3,5] and tau = 0.5 +/- 30%
%      g = ureal('g',4);
%      tau = ureal('tau',.5,'Percentage',30);
%      G = tf(g,[tau 1]);
%      % Create an tunable PI controller
%      C = tunablePID('C','pi');
%      % Form the closed-loop system
%      T = feedback(G*C,1);
%      % Pick 20 random values of (g,tau) ands sample T accordingly. Ts
%      % is a 20-by-1 array of genss models with one tunable block "C".
%      Ts = rsampleBlock(T,{'g','tau'},20)
%
%   Example 2:
%      % Create a matrix M = [a b*c] where a,b,c are tunable scalars:
%      a = realp('a',1);  b = realp('b',3);  c = realp('c',0);
%      M = [a b*c];
%      % Pick 5 samples for a and 3 samples for (b,c) and evaluate
%      % M over the corresponding 5x3 grid of (a,b,c) combinations:
%      M1 = rsampleBlock(M,'a',5,{'b';'c'},3)
%      % Alternatively, evaluate M for 15 sample values of (a,b,c):
%      M2 = rsampleBlock(M,{'a';'b';'c'},15)
%
%   See also sampleBlock, replaceBlock, getValue, ControlDesignBlock, 
%   genlti, genmat, InputOutputModel.

%   Copyright 2003-2011 The MathWorks, Inc.
ni = length(varargin);
if rem(ni,2)~=0
   error(message('Control:general:InvalidSyntaxForCommand','rsampleBlock','rsampleBlock'))
else
   Names = varargin(1:2:end);
   N = varargin(2:2:end);
   if ~all(cellfun(@isStringVec,Names))
      error(message('Control:lftmodel:sampleblock1'))
   elseif ~all(cellfun(@isPositiveInt,N))
      error(message('Control:lftmodel:sampleblock2'))
   end
end

% Convert block to LFT model for simplicity
if isa(M,'ControlDesignBlock')
   M = feval(M.toClosed(),M);
end
   
% Get full block set and consolidate block name lists
if isa(M,'ltipack.LFTModelArray')
   Blocks = M.Blocks;
else
   Blocks = struct;
end
BlockNames = fieldnames(Blocks);
for ct=1:numel(Names)
   S = Names{ct};
   if ischar(S)
      S = {S};
   else
      S = S(:);
   end
   Names{ct} = S(ismember(S,BlockNames));  % preserves order
end
SampledBlockNames = cat(1,Names{:});
nblk = numel(SampledBlockNames);
[~,iu] = unique(SampledBlockNames);
if numel(iu)<nblk
   im = setdiff(1:nblk,iu);
   error(message('Control:lftmodel:sampleblock3',SampledBlockNames{im(1)}))
end

% Sample selected blocks
if nblk==0
   % Replicate M to match size of sample grid
   M = repmat(M,[ones(1,localNDims(M)) N{:}]);
   Samples = struct;
else
   Vals = cellfun(@(X) cell(size(X)),Names,'UniformOutput',false);
   SamplingSpec = struct('NumSamples',N,'BlockNames',Names,'BlockValues',Vals);
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
function boo = isPositiveInt(x)
boo = isnumeric(x) && isscalar(x) && isreal(x) && rem(x,1)==0 && x>0;

function boo = isStringVec(x)
if ischar(x)
   boo = isrow(x);
elseif iscellstr(x)
   boo = all(cellfun(@isrow,x));
else
   boo = false;
end

function ND = localNDims(M)
% SIZE for I/O models returns [1 2 3 1] for a 3x1 array of models.
% Drop the trailing 1 to avoid extra singleton dimension in batch mode.
s = size(M);
ND = length(s);
if ND==4 && s(4)==1
   ND = 3;
end
