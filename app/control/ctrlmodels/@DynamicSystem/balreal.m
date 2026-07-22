function [sysb,g,TL,TR] = balreal(sys,opt,optArgs)
%BALREAL  Compute balanced state-space realization.
%
%   [SYSB,G] = BALREAL(SYS) computes a balanced state-space realization
%   of the LTI model SYS. For stable models, SYSB is an equivalent
%   realization for which the controllability and observability Gramians
%   are equal and diagonal, their diagonal entries forming the vector G
%   of Hankel singular values. This balances the input-to-state and
%   state-to-output energy transfers, and small entries of G indicate
%   states that can be removed with XELIM.
%
%   [SYSB,G] = BALREAL(SYS,Name1=Value1,Name2=Value2,...) specifies
%   additional options, see BALREALOPTIONS for details.
%
%   [SYSB,G,TL,TR] = BALREAL(SYS,...) also returns the balancing state
%   transformations TL,TR. For SYS with state x and matrices (A,B,C,D,E),
%   the balanced realization is (TL*A*TR,TL*B,C*TL,D,TL*E*TR) and the state
%   transformation is x = TR*x_b. Note that TL*E*TR=I for stable SYS.
%
%   Note:
%     * If SYS has unstable poles, its stable part is isolated, balanced,
%       and added back to the unstable part to form SYSB. The entries of G
%       corresponding to unstable modes are set to Inf.
%     * Use reducespec rather than BALREAL and XELIM for model reduction
%       purposes.
%
%   Example:
%     sys = zpk([-3 -.5],[-1e-6 -.4999 -10],1);
%     % Treat -1e-6 as unstable, notice small entry of G due to near
%     % pole/zero cancellation.
%     [sysb,g] = balreal(sys,Focus='rel',Offset=.001)
%
%   See also BALREALOPTIONS, SSEQUIV, GRAM, XELIM, REDUCESPEC, SS.

%   Copyright 1986-2023 The MathWorks, Inc.
arguments
   sys
   opt = []; 
   optArgs.?ltioptions.balreal;
end

if numsys(sys)~=1
   error(message('Control:general:RequiresSingleModel','balreal'))
elseif any(iosize(sys)==0)
   % System without input or output
   error(message('Control:transformation:NotSupportedNoInputsorOutputs','balreal'))
end

% Resolve options and support obsolete syntax:
%  * Pre-R14sp2: balreal(sys,condt) (now ignored)
%  * Pre-R2023b: balreal(sys,balredOptions(...))
if ~isa(opt,'ltioptions.balreal')
   opt = initOptions(ltioptions.balreal,namedargs2cell(optArgs));
end
% Validate options (may warn about unsupported combinations)
opt = validate(opt);

try
   if isa(sys,'StateSpaceModel')
      [sysb,g,TL,TR] = balreal_(sys,opt);
   else
      % Set TL=TR=[] when not a state-space model
      [sysb,g] = balreal_(sys,opt);
      TL = []; TR = [];
   end      
catch E
   ltipack.throw(E,'command','balreal',class(sys))
end
