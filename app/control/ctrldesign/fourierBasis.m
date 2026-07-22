function F = fourierBasis(m,varargin)
%fourierBasis  Generates Fourier series expansion for gain surface tuning.
%
%   Basis function expansions are needed to parameterize gain surfaces and
%   tune gain schedules (see tunableSurface). For gain surfaces that depend
%   periodically on the scheduling variables (for example, a gain scheduled
%   as a function of angular position), use fourierBasis to generate
%   periodic Fourier series expansions.
%
%   F = FOURIERBASIS(M) returns a function handle F that evaluates to the
%   first m harmonics of exp(i*pi*x):
%      F(x) = [cos(pi*x) sin(pi*x) cos(2*pi*x) sin(2*pi*x) ...
%                                  cos(m*pi*x) sin(m*pi*x) ]
%   These are the first 2*m basis functions in the Fourier series expansion:
%      G(x) = a0/2 + SUM_k { ak cos(k*pi*x) + bk sin(k*pi*x) }
%   of a periodic gain G(x) satisfying G(-1) = G(1).
%
%   F = FOURIERBASIS(M,N) constructs an N-dimensional Fourier basis for
%   periodic functions on [-1,1]^N. This basis is obtained by outer (tensor)
%   product of Fourier bases with M harmonics along each dimension. The 
%   function F takes N values and returns a vector with (2*M+1)^N-1 
%   entries. For N=3, for example, this is equivalent to
%      F1 = fourierBasis(M)
%      F = ndBasis(F1,F1,F1)
%
%   F = FOURIERBASIS(...,VARNAMES) specifies the variable names as a char 
%   vector (monovariable) or a cell array of char vectors (multi-variable).
%   For example
%      F = FOURIERBASIS(3,2,{'alpha','V'})
%
%   Note: If the gain surface G is periodic in the scheduling variable x
%   with period P, make sure that the corresponding InputScaling entry is
%   set to P/2 to ensure consistency with the FOURIERBASIS period (P=2).
%   When using the default normalization, the x values in G.SamplingGrid 
%   must span exactly one period [a,a+P] to satisfy this requirement. Type
%   "help tunableSurface.Normalization" for more details.
%
%   See also polyBasis, ndBasis, tunableSurface, systune.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(1,3)
if ~(isnumeric(m) && isscalar(m) && isreal(m) && m>=1 && m<Inf && m==round(m))
   error(message('Control:lftmodel:fourierBasis1'))
end
% Process VARARGIN
varNames = [];
switch nargin
   case 1
      N = 1;
   case 2
      if isnumeric(varargin{1})
         N = varargin{1};
      else
         N = 1;  varNames = varargin{1};
      end
   case 3
      N = varargin{1};  varNames = varargin{2};
end
% Check N
if ~(isnumeric(N) && isscalar(N) && isreal(N) && N>=1 && N<Inf && N==round(N))
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
FDATA = repmat({@(x)localFourierBasis(1,m,x)},[1 N]);  % N variables
F = FNC(FDATA);
end

%-------
function y = localFourierBasis(N,m,varargin)
if N==1
   pix = pi * varargin{1};
   y = zeros(1,2*m);
   for ct=1:m
      aux = ct*pix;
      y(2*ct-1) = cos(aux);
      y(2*ct) = sin(aux);
   end
else
   % Recursive implementation
   y1 = [1 , localFourierBasis(N-1,m,varargin{1:N-1})];
   y2 = [1 , localFourierBasis(1,m,varargin{N})];
   y = y1' * y2;  % outer product
   y = reshape(y(2:end),[1 numel(y)-1]);
end
end

