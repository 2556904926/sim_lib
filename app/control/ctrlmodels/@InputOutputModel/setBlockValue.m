function M = setBlockValue(M,varargin)
%setBlockValue  Updates block in generalized model.
%
%   M = setBlockValue(M,BLOCKNAME,VAL) modifies the value of the Control
%   Design block with name BLOCKNAME in the generalized model M. The
%   specified value VAL must be compatible with the block type and attributes.
%   Type "M.Blocks" for a list of Control Design blocks in M.
%
%   M = setBlockValue(M,BLOCKVALUES) modifies the values of several blocks
%   at once. BLOCKVALUES is a structure whose fields specify the block names
%   and their values. Blocks not listed in BLOCKVALUES are unchanged.
%
%   M = setBlockValue(M,MREF) updates the Control Design blocks in M to match
%   their values in the generalized model MREF. This is equivalent to
%       M = setBlockValue(M,MREF.Blocks)
%   and is useful to propagate tuned parameter values from one model to all
%   other models depending on the same parameters.
%
%   Example: Suppose your control system has two tunable blocks B1 and B2,
%   and that C0 and T0 are generalized models of the overall controller and
%   closed-loop system parameterized by B1,B2. If you use
%      T = hinfstruct(T0)
%   to tune B1,B2, the resulting model T contains the tuned values of B1,B2.
%   To push these values to the controller model C0, use
%      C = setBlockValue(C0,T)
%   Note that C is still a generalized model. If you just want to evaluate
%   the controller for the tuned values of B1,B2, use
%      CVal = getValue(C0,T)
%   instead.
%
%   See also getBlockValue, showBlockValue, ControlDesignBlock, genmat, genlti.

%   Copyright 1986-2011 The MathWorks, Inc.
if ~isGeneralized(M)
   return % no-op
end
ni = nargin;
narginchk(2,3)
% Reduce all input formats to a BLOCKVALUES struct
if ni==2
   arg = varargin{1};
   if isstruct(arg)
      % setBlockValue(M,BLOCKVALUES)
      S = arg;
   elseif isa(arg,'ControlDesignBlock')
      S = cell2struct({arg},arg.Name);
   elseif isa(arg,'ltipack.LFTModelArray')
      % setBlockValue(M,MREF)
      S = arg.Blocks;
   else
      error(message('Control:lftmodel:setBlockValue1'))
   end
else
   % setBlockValue(M,BLOCKNAME,VAL)
   if ~isvarname(varargin{1})
      error(message('Control:lftmodel:BlockName1'))
   end
   S = cell2struct(varargin(2),varargin(1));
end
% Apply new values
try
   M = setBlockValue_(M,S);
catch ME
   throw(ME)
end

      
