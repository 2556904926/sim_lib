function sys = ss2ss(sys,T)
%SS2SS  State coordinate transformation for state-space models.
%
%   SYS = SS2SS(SYS,T) performs the similarity transformation z = Tx on the
%   state vector x of the state-space model SYS. The resulting state-space 
%   model is
%
%               .       -1        
%               z = [TAT  ] z + [TB] u
%                       -1
%               y = [CT   ] z + D u 
%
%   for explicit models and
%
%           -1  .      -1        
%        [ET  ] z = [AT  ] z + B u
%                      -1
%               y = [CT  ] z + D u  .
%
%   for descriptor models.
%
%   SS2SS is applicable to both continuous- and discrete-time models. For 
%   arrays of state-space models, the transformation T is applied to each 
%   individual model in the array. For GENSS and USS models, T is applied
%   to the state vector of the interconnection model (first output argument 
%   of GETLFTMODEL).
%
%   See also SSEQUIV, BALREAL, MODALREAL, SS, SPARSS, GENSS, GETLFTMODEL.

%   Copyright 1986-2020 The MathWorks, Inc.
narginchk(2,3)
if nmodels(sys)==0
   return
end

% Check dimensions
if ~(ismatrix(T) && size(T,1)==size(T,2))
   error(message('Control:transformation:ss2ss1'))
end
try
  sys = ss2ss_(sys,T);
catch E
   ltipack.throw(E,'command','ss2ss',class(sys))
end