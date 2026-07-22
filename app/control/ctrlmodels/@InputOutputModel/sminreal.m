function varargout = sminreal(M,varargin)
%SMINREAL  Eliminates structurally disconnected states, delays, and blocks.
%
%   MS = SMINREAL(M) simplifies the model M by eliminating all model
%   components that are not connected to any input or output.
%
%   [MS,XKEEP] = SMINREAL(M) also returns a logical vector XKEEP indicating
%   which states are retained (TRUE) and which states are discarded (FALSE).
%
%   In state-space models, SMINREAL eliminates all states and internal
%   delay signals that are structurally disconnected from the inputs and
%   outputs. The simplified model MS is structurally minimal, that is,
%   generically minimal when randomizing the nonzero entries of A,B,C,E.
%
%   In generalized models, SMINREAL further eliminates all tunable or
%   uncertain blocks that are structurally disconnected from the inputs
%   and outputs.
%
%   In gridded LTV/LPV models, SMINREAL eliminates states and internal 
%   delays that are structurally disconnected for *all* models. The 
%   remaining states and internal delay signals are the *same* for all 
%   models across the grid. The syntax
%      [MAS,XKEEP] = SMINREAL(MA,'consistent')
%   performs this state-consistent reduction for state-space arrays MA  
%   with uniform state dimension. XKEEP is always a vector in this case.
%
%   See also MINREAL, SMINDAE, SS, SPARSS, MECHSS, LTVSS, LPVSS, 
%   SSINTERPOLANT, GENSS, GENMAT, GENFRD.

%   Copyright 1986-2024 The MathWorks, Inc.
try
   [varargout{1:nargout}] = sminreal_(M,varargin{:});
catch ME
   ltipack.throw(ME,'command','sminreal',class(M))
end
% Note: Do not reduce LFT models to double or LTI when no blocks are left.
% This makes the output type unpredictable and code that tries to access
% M.Blocks property may fail.