function [H,H0,varargout] = modalsep(G,varargin,optArgs)
%MODALSEP  Modal decomposition.
%
%   [H,H0] = MODALSEP(G) computes the modal decomposition
%
%      G(s) = H0 +  sum   Hj(s)
%                  j=1:m
%
%   of the LTI model G, where each modal component Hj(s) is associated
%   with a real pole, a complex pair, or a cluster of repeated poles.
%   MODALSEP packs the modal components Hj into the model array H and 
%   returns the static gain H0 separately. Use H(:,:,j) to retrieve Hj(s).
%
%   [H,H0] = MODALSEP(G,Name1=Value1,...) specifies options for controlling
%   the granularity and accuracy of the decomposition, see modalsepOptions
%   for details.
%
%   [H,H0] = MODALSEP(G,N,REGIONFCN) computes the modal decomposition
%
%      G(s) = H0 +  sum   Hj(s)
%                  j=1:N
%
%   where the modal components Hj(s) have their poles in disjoint regions
%   {Rj, j=1:N} of the complex plane. The function IR = REGIONFCN(P)
%   specifies the partition into N regions by assigning an integer IR
%   between 1 and N to any given pole P. You can specify this function
%   as a string or function handle. To use a function taking additional
%   arguments, use the syntax
%      REGIONFCN = @(p) MYFUNCTION(p,param1,..,paramP)
%
%   [H,H0,INFO] = MODALSEP(G,...) also returns a struct INFO with
%     * The block-diagonalizing transformations TL,TR. For explicit models,
%       TL*TR=I and (TR\A*TR,TR\B,C*TR,D) is block diagonal. For descriptor
%       models, (TL*A*TR,TL*B,C*TR,D,TL*E*TR) is block diagonal.
%     * For each modal component Hj, the average mode value and the
%       relative DC contribution.
%
%   Example 1: Compute the modal decomposition of a 10th-order state-space
%   model:
%      [H,H0] = modalsep(rss(10,2,2))
%
%   Example 2: Decompose G(z) = H0+H1(z)+H2(z) where H1 and H2 have their
%   poles inside and outside the unit disk:
%      % The function FCN returns 1 for inside and 2 for outside
%      FCN = @(p) 1+(abs(p)>=1);
%      [H,H0]  = modalsep(G,2,FCN)
%      H1 = H(:,:,1);  H2 = H(:,:,2);
%
%   See also MODALSEPOPTIONS, MODALSUM, MODALREAL, SSEQUIV, STABSEP, 
%            FREQSEP, LTI, BDSCHUR, BDQZ.

%   Author(s): P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc.
arguments
   G
end
arguments (Repeating)
   varargin
end
arguments
   optArgs.?ltioptions.modalsep;
end

if nmodels(G)~=1
   % Because H is itself an array of variable size
   error(message('Control:general:RequiresSingleModel','modalsep'))
end

opt = initOptions(ltioptions.modalsep,namedargs2cell(optArgs));

nv = numel(varargin);
if nv==0
   % Fine-grain modal decomposition
   try
      [H,H0,varargout{1:nargout-2}] = modalsep_(G,[],[],opt);
   catch E
      ltipack.throw(E,'command','modalsep',class(G))
   end
elseif nv>=2
   N = varargin{1};
   RFCN = varargin{2};
   if ~(isnumeric(N) && isscalar(N) && isreal(N) && N==floor(N) && N>0 && N<Inf)
      error(message('Control:transformation:modsep3'))
   end 
   if ischar(RFCN)
      RFCN = str2func(RFCN);
   end
   if nv>2
      RFCN = @(p) RFCN(p,varargin{3:nv});
   end
   try
      [H,H0,varargout{1:nargout-2}] = modalsep_(G,N,RFCN,opt);
   catch E
      ltipack.throw(E,'command','modalsep',class(G))
   end
else
   error(message('Control:general:InvalidNameValue'))
end

% Clear notes, userdata, etc
H.Name = '';  H.Notes = {};  H.UserData = [];
H0.Name = '';  H0.Notes = {};  H0.UserData = [];
