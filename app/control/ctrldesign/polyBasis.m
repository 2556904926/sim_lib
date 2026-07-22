function F = polyBasis(Type,m,varargin)
%polyBasis   Generates polynomial basis for gain surface tuning.
%
%   Basis function expansions are needed to parameterize gain surfaces and 
%   tune gain schedules (see tunableSurface). You can use POLYBASIS to 
%   generate standard polynomial expansions taking values in [-1,1]^N where
%   N is the number of scheduling variables.
%
%   F = POLYBASIS('canonical',M) returns a function handle F that evaluates
%   the first m powers of x:
%      F(x) = [x , x^2 , ... , x^m] .
%
%   F = POLYBASIS('chebyshev',M) returns a function handle F that evaluates
%   the first m Chebychev polynomials:
%      F(x) = [T1(x) , ... , Tm(x)]
%   with Tm+1(x) = 2 x Tm(x)- Tm-1(x) and T0(x)=1, T1(x)=x.
%
%   F = POLYBASIS(TYPE,M,N) constructs an N-dimensional polynomial 
%   expansion by taking the outer (tensor) product of 1-D polynomial 
%   expansions of degree M along each dimension. The string TYPE specifies 
%   the polynomial type as either 'canonical' or 'chebyshev'. The function 
%   F takes N values and returns a vector with (M+1)^N-1 entries. For
%   example, for N=3 and TYPE='canonical':
%      F(x,y,z) = [ x^i y^j z^k : 0<=i,j,k<=m, i+j+k>0 ]
%   Note that this is equivalent to
%      F1 = polyBasis('canonical',M)
%      F = ndBasis(F1,F1,F1)
%
%   F = POLYBASIS(TYPE,...,VARNAMES) specifies the variable names as a
%   char vector (monovariable) or a cell array of char vectors (multi-
%   variable). For example
%      F = POLYBASIS('chebyshev',3,2,{'alpha','V'})
%
%   See also fourierBasis, ndBasis, tunableSurface, systune.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(2,4)
Type = ltipack.matchKey(Type,{'canonical';'chebyshev'});
if isempty(Type)
   error(message('Control:lftmodel:polyBasis1'))
end
if ~(isnumeric(m) && isscalar(m) && isreal(m) && m>0 && m<Inf && m==round(m))
   error(message('Control:lftmodel:polyBasis2'))
end
% Process VARARGIN
varNames = [];
switch nargin
   case 2
      N = 1;   
   case 3
      if isnumeric(varargin{1})
         N = varargin{1};
      else
         N = 1;  varNames = varargin{1};
      end
   case 4
      N = varargin{1};  varNames = varargin{2};
end
% Check N
if ~(isnumeric(N) && isscalar(N) && isreal(N) && N>0 && N<Inf && N==round(N))
   error(message('Control:lftmodel:BasisFunction3'))
end
% Check VARNAMES
if isempty(varNames)
   varNames = cellstr("x"+(1:N));
else
   if ischar(varNames) || isstring(varNames)
      varNames = cellstr(varNames);
   end
   if ~(iscellstr(varNames) && numel(varNames)==N && all(cellfun(@isvarname,varNames)))
      error(message('Control:lftmodel:BasisFunction4'))
   end
end

% Note: STR2FUNC obliterates contextual info so pass such info as parameters
args = sprintf('%s,',varNames{:});  args = args(1:end-1);
FNC = str2func(sprintf('@(FDATA_) @(%s) utFcnBasisOuterProduct(FDATA_,%s)',args,args));
switch Type
   case 'canonical'
      FDATA = {@(x)localCanonical(m,x)};
   case 'chebyshev'
      FDATA = {@(x)localChebyshev(m,x)};
end
FDATA = repmat(FDATA,[1 N]);  % N variables
F = FNC(FDATA);
end

%-------
function y = localCanonical(m,x)
y = zeros(1,m);
y(1) = x;
for ct=1:m-1
   y(ct+1) = x * y(ct);
end
end

%-------
function y = localChebyshev(m,x)
if m==1
   y = x;
else
   y = zeros(1,m);
   y(1) = x;
   y(2) = 2*x^2-1;
   for ct=2:m-1
      y(ct+1) = 2 * x * y(ct) - y(ct-1);
   end
end
end

%%%%%%%%%% DO NOT MODIFY BELOW - BACKWARD COMP WITH < R2017b %%%%%%%%%%%
function y = localPolyBasis(N,P,varargin)
if N==1
   y = P(varargin{1});
else
   % Recursive implementation
   y1 = [1 , localPolyBasis(N-1,P,varargin{1:N-1})];
   y2 = [1 , P(varargin{N})];
   y = y1' * y2;  % outer product
   y = reshape(y(2:end),[1 numel(y)-1]);
end
end

