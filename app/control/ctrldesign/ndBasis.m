function F = ndBasis(varargin)
%ndBasis   Builds N-dimensional basis function expansion from lower-dimensional
%          expansions.
%
%   Basis function expansions are needed to parameterize gain surfaces and 
%   tune gain schedules (see tunableSurface). The complexity of such
%   expansions grows with the number N of scheduling variables. You can use
%   NDBASIS to build N-dimensional expansions from low-dimensional ones. 
%   NDBASIS is similar to NDGRID in the way it spatially replicates the 
%   expansions along each dimension.
%
%   F = NDBASIS(F1,F2) forms the outer (tensor) product of the basis function
%   expansions F1 and F2. If F1(x1) = [F1_i(x1)] and F2(x2) = [F2_j(x2)],
%   then F is a function of (x1,x2) with generic term 
%      F_ij(x1,x2) = F1_i(x1) * F2_j(x2) .
%   The terms are listed in a column-oriented fashion with i varying first
%   then j.
%
%   F = NDBASIS(F1,F2,...,FN) forms the outer product of three or more
%   expansions F1,...,FN. The generic term of the expansion F is
%      F_i1,...,iN(x1,...,xN) = F1_i1(x1) * ... * FN_iN(xN) .
%   The terms are listed in the same order they are sorted in an N-D array,
%   with i1 varying first, then i2, then i3,... Each Fj can itself be a 
%   multi-dimensional basis function expansion.
%
%   Example: If F(x)=[x x^2] and G(y)=[y y^2], then H=ndBasis(F,G) is the
%   expansion H(x,y) = [x x^2 y y*x y*x^2 y^2 x*y^2 x^2*y^2]. Note that H
%   includes all monic terms in x,y of degree less than 2.  
%
%   Note: The NDBASIS operation is associative:
%      NDBASIS(F1,NDBASIS(F2,F3)) = NDBASIS(NDBASIS(F1,F2),F3) = 
%                                   NDBASIS(F1,F2,F3)
%
%   See also polyBasis, fourierBasis, tunableSurface, systune.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(1,Inf)
N = 0;
FDATA = [];
varNames = cell(0,1);
for ct=1:nargin
   F = varargin{ct};
   if ~isa(F,'function_handle')
      error(message('Control:lftmodel:BasisFunction1'))
   end
   nargs = nargin(F);
   if nargs<=0
      error(message('Control:lftmodel:BasisFunction2'))
   end
   N = N + nargs;
   % Flatten nested NDBASIS calls
   Finfo = functions(F);
   if contains(Finfo.function,'utFcnBasisOuterProduct(FDATA_')
      FDATA = [FDATA , Finfo.workspace{1}.FDATA_]; %#ok<*AGROW>
   else
      FDATA = [FDATA , {F}];
   end
   % Extract variable names
   aux = extractBetween(Finfo.function,'@(',')');
   varNames = [varNames ; split(aux(1),',')];
end

% Clear variable names if there are repetitions
if numel(unique(varNames))<numel(varNames)
   varNames = cellstr("x" + (1:N));
end

% Note: STR2FUNC obliterates contextual info so pass such info as parameters
args = sprintf('%s,',varNames{:});  args = args(1:end-1);
FNC = str2func(sprintf('@(FDATA_) @(%s) utFcnBasisOuterProduct(FDATA_,%s)',args,args));
F = FNC(FDATA);
end


%%%%%%%%%% DO NOT MODIFY BELOW - BACKWARD COMP WITH < R2017b %%%%%%%%%%%
function y = localNDBasis(FDATA,varargin)
nF = size(FDATA,2);
if nF==1
   y = FDATA{1}(varargin{:});
else
   % Recursive implementation
   F1 = FDATA{1,1};  narg1 = FDATA{2,1};
   y1 = [1 , F1(varargin{1:narg1})];
   y2 = [1 , localNDBasis(FDATA(:,2:nF),varargin{narg1+1:end})];
   y = y1' * y2;  % outer product
   y = reshape(y(2:end),[1 numel(y)-1]);
end
end