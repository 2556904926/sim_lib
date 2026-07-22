function [M,SingularFlag] = inv(M,varargin)
%INV  Computes the inverse of an input/output model.
%
%   MI = INV(M) computes the inverse model MI such that
%
%       y = M * u   <---->   u = MI * y 
%
%   The model M must have as many inputs as outputs.
%
%   For SS/GENSS/USS models, the inverse model is in implicit (DAE) form
%   by default. When the inverse is proper, you can use INV(SYS,'min') to
%   eliminate the extra states and obtain an inverse model with as many
%   states as SYS. This option is ignored for sparse models because it 
%   typically destroys sparsity.
%
%   See also INPUTOUTPUTMODEL/MLDIVIDE, INPUTOUTPUTMODEL/MRDIVIDE,
%   INPUTOUTPUTMODEL.

%   Author(s): P. Gahinet
%   Copyright 1986-2020 The MathWorks, Inc.
narginchk(1,2)
if nargin>1 && ~strcmpi(varargin{1},'min')
   error(message('Control:transformation:inv4'))
end
sizes = size(M);
if any(sizes==0)
   M = M.';  SingularFlag = false;  return
elseif sizes(1)~=sizes(2)
   error(message('Control:transformation:inv5'))
end
try
   % Convert to combinable type for *
   M = ltipack.matchType('mtimes',M);
   % Invert 
   [M,SingularFlag] = inv_(M,varargin{:});
   if nargout<2 && SingularFlag
      warning(message('Control:transformation:inv2'))
   end
   M = invMetaData(M);
catch E
   ltipack.throw(E,'command','inv',class(M))
end
